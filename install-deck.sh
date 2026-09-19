#!/usr/bin/env bash
set -euo pipefail

readonly BUILD_NAME="SWG-Proton-1-test1"
readonly APP_ID="3680833707"
readonly INSTALLER_URL="https://updater.swginfinity.com/api/v2/launcher/download"

usage() {
  echo "Usage: $0 RUNNER.tar.xz WEBVIEW2.zip STEAM_SHORTCUT_HELPER.py" >&2
  exit 2
}

[ "$#" -eq 3 ] || usage
ARCHIVE="$(realpath "$1")"
WEBVIEW_ZIP="$(realpath "$2")"
SHORTCUT_HELPER="$(realpath "$3")"
test -f "$ARCHIVE"
test -f "$WEBVIEW_ZIP"
test -f "$SHORTCUT_HELPER"
command -v curl >/dev/null
command -v python3 >/dev/null

if [ -d "$HOME/.steam/root" ]; then
  STEAM_ROOT="$(readlink -f "$HOME/.steam/root")"
elif [ -d "$HOME/.local/share/Steam" ]; then
  STEAM_ROOT="$HOME/.local/share/Steam"
else
  echo "Steam installation was not found." >&2
  exit 1
fi

STEAM_TOOLS="$STEAM_ROOT/compatibilitytools.d"
TOOL_DIR="$STEAM_TOOLS/$BUILD_NAME"
COMPAT_DIR="$STEAM_ROOT/steamapps/compatdata/$APP_ID"
WEBVIEW_DIR="$HOME/.local/share/swg-infinity/webview2-fixed"
STATE_DIR="$HOME/.local/share/swg-infinity"
CONFIG_VDF="$STEAM_ROOT/config/config.vdf"
timestamp="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$STATE_DIR/backups/$timestamp"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

test -f "$CONFIG_VDF" || { echo "Steam config not found: $CONFIG_VDF" >&2; exit 1; }

if pgrep -x steam >/dev/null 2>&1; then
  echo "Stopping Steam before updating its shortcut database..."
  steam -shutdown >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    pgrep -x steam >/dev/null 2>&1 || break
    sleep 1
  done
  pgrep -x steam >/dev/null 2>&1 && {
    echo "Steam is still running. Exit Steam completely and rerun the installer." >&2
    exit 1
  }
fi

mkdir -p "$STEAM_TOOLS" "$STATE_DIR" "$BACKUP_DIR"
tar -C "$tmp" -xJf "$ARCHIVE"
test -f "$tmp/$BUILD_NAME/compatibilitytool.vdf"
test -x "$tmp/$BUILD_NAME/proton"
if [ -e "$TOOL_DIR" ]; then
  mv "$TOOL_DIR" "$TOOL_DIR.backup-$timestamp"
fi
mv "$tmp/$BUILD_NAME" "$TOOL_DIR"

mkdir -p "$WEBVIEW_DIR"
python3 -m zipfile -e "$WEBVIEW_ZIP" "$WEBVIEW_DIR"
test -f "$WEBVIEW_DIR/msedgewebview2.exe"

installer="$STATE_DIR/Infinity-Launcher-Setup.exe"
curl -fL "$INSTALLER_URL" -o "$installer"
test -s "$installer"

if [ -n "${STEAM_USER_ID:-}" ]; then
  USERDATA_DIR="$STEAM_ROOT/userdata/$STEAM_USER_ID"
  test -d "$USERDATA_DIR" || { echo "Unknown STEAM_USER_ID: $STEAM_USER_ID" >&2; exit 1; }
else
  USERDATA_DIR="$(find "$STEAM_ROOT/userdata" -mindepth 1 -maxdepth 1 -type d \
    -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
fi
test -n "$USERDATA_DIR"
SHORTCUTS_VDF="$USERDATA_DIR/config/shortcuts.vdf"

wine_webview="Z:$(printf '%s' "$WEBVIEW_DIR" | sed 's|/|\\|g')"
launch_options="ENABLE_GAMESCOPE_WSI=0 WAYLAND_DISPLAY= WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS=\"--disable-gpu --disable-gpu-compositing --disable-features=Vulkan\" WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=\"$wine_webview\" WINEDLLOVERRIDES=\"mscoree,mshtml=\" %command%"
installer_options="WAYLAND_DISPLAY= %command% /D=C:\\SWGInfinity"

python3 "$SHORTCUT_HELPER" \
  "$SHORTCUTS_VDF" \
  "$CONFIG_VDF" \
  "$BACKUP_DIR" \
  "$APP_ID" \
  "$BUILD_NAME" \
  "$installer" \
  "$STATE_DIR" \
  "$installer_options"

echo "Starting the Infinity Launcher setup through Steam and $BUILD_NAME..."
nohup steam -silent >/dev/null 2>&1 &
for _ in $(seq 1 30); do
  pgrep -x steam >/dev/null 2>&1 && break
  sleep 1
done
sleep 3
steam "steam://rungameid/$APP_ID" >/dev/null 2>&1 || true
echo
echo "Finish the Infinity Launcher setup window and close it."
read -r -p "Then return here and press Enter to finalize the Steam shortcut... "

steam -shutdown >/dev/null 2>&1 || true
for _ in $(seq 1 30); do
  pgrep -x steam >/dev/null 2>&1 || break
  sleep 1
done
pgrep -x steam >/dev/null 2>&1 && {
  echo "Steam is still running. Exit Steam completely and rerun the installer." >&2
  exit 1
}

launcher="$COMPAT_DIR/pfx/drive_c/SWGInfinity/infinity-launcher.exe"
if [ ! -f "$launcher" ]; then
  launcher="$(find "$COMPAT_DIR/pfx/drive_c" -type f -iname 'infinity-launcher.exe' -print -quit 2>/dev/null || true)"
fi
if [ -z "$launcher" ] || [ ! -f "$launcher" ]; then
  echo "infinity-launcher.exe was not found in the Steam prefix." >&2
  echo "Run the SWG Infinity shortcut again, complete setup, then rerun this installer." >&2
  exit 1
fi

launcher_dir="$(dirname "$launcher")"
python3 "$SHORTCUT_HELPER" \
  "$SHORTCUTS_VDF" \
  "$CONFIG_VDF" \
  "$BACKUP_DIR" \
  "$APP_ID" \
  "$BUILD_NAME" \
  "$launcher" \
  "$launcher_dir" \
  "$launch_options"

nohup steam -silent >/dev/null 2>&1 &

cat <<EOF
Installed runner: $TOOL_DIR
Installed WebView2: $WEBVIEW_DIR
Installed launcher: $launcher
Steam shortcut: SWG Infinity (appid $APP_ID)
Steam backups: $BACKUP_DIR

The SWG Infinity shortcut now targets the installed launcher and is mapped to
$BUILD_NAME. Open it and let Infinity Launcher download the game data.
EOF
