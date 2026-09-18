#!/usr/bin/env bash
set -euo pipefail

readonly BUILD_NAME="SWG-Proton-1-test1"

usage() {
  cat <<'EOF'
Usage:
  ./install-deck.sh RUNNER.tar.xz WEBVIEW2_DIR_OR_ZIP LUTRIS_GAME_ID [LUTRIS_YAML]

WEBVIEW2_DIR_OR_ZIP must be a directory directly containing msedgewebview2.exe,
or a WebView2-Fixed-*.zip bundle produced by this project.
LUTRIS_GAME_ID is the local numeric id used by lutris:rungameid/ID.
LUTRIS_YAML is optional; when supplied its Wine runner is changed to
SWG-Proton-1-test1 after a timestamped backup is made.
EOF
}

[ "$#" -ge 3 ] && [ "$#" -le 4 ] || { usage >&2; exit 2; }

ARCHIVE="$(realpath "$1")"
WEBVIEW_INPUT="$(realpath "$2")"
GAME_ID="$3"
LUTRIS_CONFIG="${4:-}"

test -f "$ARCHIVE"
if [ -f "$WEBVIEW_INPUT" ]; then
  case "$WEBVIEW_INPUT" in
    *.zip) command -v unzip >/dev/null || { echo "unzip is required for WebView2 ZIP" >&2; exit 1; } ;;
    *) echo "Second argument must be a WebView2 directory or .zip" >&2; exit 2 ;;
  esac
  WEBVIEW_DIR="$HOME/.local/share/swg-infinity/webview2-fixed"
  mkdir -p "$WEBVIEW_DIR"
  unzip -q -o "$WEBVIEW_INPUT" -d "$WEBVIEW_DIR"
else
  WEBVIEW_DIR="$WEBVIEW_INPUT"
fi
test -f "$WEBVIEW_DIR/msedgewebview2.exe"
case "$GAME_ID" in (*[!0-9]*|'') echo "LUTRIS_GAME_ID must be numeric" >&2; exit 2;; esac

STEAM_TOOLS="$HOME/.steam/root/compatibilitytools.d"
TOOL_DIR="$STEAM_TOOLS/$BUILD_NAME"
LUTRIS_RUNNERS="$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine"
timestamp="$(date +%Y%m%d-%H%M%S)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$STEAM_TOOLS" "$LUTRIS_RUNNERS" "$HOME/.local/bin" \
  "$HOME/.local/share/applications"
tar -C "$tmp" -xJf "$ARCHIVE"
test -f "$tmp/$BUILD_NAME/compatibilitytool.vdf"
test -x "$tmp/$BUILD_NAME/proton"

if [ -e "$TOOL_DIR" ]; then
  mv "$TOOL_DIR" "$TOOL_DIR.backup-$timestamp"
fi
mv "$tmp/$BUILD_NAME" "$TOOL_DIR"

lutris_tool="$LUTRIS_RUNNERS/$BUILD_NAME"
if [ -L "$lutris_tool" ] && [ "$(readlink -f "$lutris_tool")" = "$TOOL_DIR" ]; then
  :
elif [ -e "$lutris_tool" ] || [ -L "$lutris_tool" ]; then
  mv "$lutris_tool" "$lutris_tool.backup-$timestamp"
  ln -s "$TOOL_DIR" "$lutris_tool"
else
  ln -s "$TOOL_DIR" "$lutris_tool"
fi

if [ -n "$LUTRIS_CONFIG" ]; then
  LUTRIS_CONFIG="$(realpath "$LUTRIS_CONFIG")"
  test -f "$LUTRIS_CONFIG"
  count="$(grep -c '^  version:' "$LUTRIS_CONFIG" || true)"
  if [ "$count" -ne 1 ]; then
    echo "Expected exactly one '  version:' line in $LUTRIS_CONFIG; found $count" >&2
    exit 1
  fi
  cp "$LUTRIS_CONFIG" "$LUTRIS_CONFIG.before-$BUILD_NAME-$timestamp"
  sed -i "s|^  version:.*|  version: $BUILD_NAME|" "$LUTRIS_CONFIG"
fi

wine_webview="Z:$(printf '%s' "$WEBVIEW_DIR" | sed 's|/|\\|g')"
wrapper="$HOME/.local/bin/swg-infinity-deck"
cat > "$wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec /usr/bin/flatpak run \\
  --env=WAYLAND_DISPLAY= \\
  --env=WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS= \\
  --env='WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=$wine_webview' \\
  --env='WINEDLLOVERRIDES=mscoree,mshtml=' \\
  net.lutris.Lutris 'lutris:rungameid/$GAME_ID'
EOF
chmod +x "$wrapper"

desktop="$HOME/.local/share/applications/swg-infinity-deck.desktop"
cat > "$desktop" <<EOF
[Desktop Entry]
Name=SWG Infinity (SWG-Proton)
Comment=Launch SWG Infinity through Lutris with the Deck compatibility profile
Exec=$wrapper
Terminal=false
Type=Application
Categories=Game;
EOF

cat <<EOF
Installed runner: $TOOL_DIR
Lutris runner link: $lutris_tool
Launcher wrapper: $wrapper
Desktop entry: $desktop

Next steps:
  1. Restart Lutris and Steam completely.
  2. Confirm Lutris uses $BUILD_NAME for SWG Infinity.
  3. Test by running: $wrapper
  4. Add $wrapper to Steam as a Non-Steam Game for Game Mode.
EOF
