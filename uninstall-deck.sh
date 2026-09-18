#!/usr/bin/env bash
set -euo pipefail

readonly BUILD_NAME="SWG-Proton-1-test1"
STEAM_TOOL="$HOME/.steam/root/compatibilitytools.d/$BUILD_NAME"
timestamp="$(date +%Y%m%d-%H%M%S)"

# Keep the runner recoverable instead of deleting it.
if [ -d "$STEAM_TOOL" ]; then
  mv "$STEAM_TOOL" "$STEAM_TOOL.uninstalled-$timestamp"
fi

echo "SWG-Proton was disabled without deleting its files."
echo "The Steam shortcut, prefix, launcher, WebView2, and game data were preserved."
echo "Steam configuration backups are under ~/.local/share/swg-infinity/backups/."
