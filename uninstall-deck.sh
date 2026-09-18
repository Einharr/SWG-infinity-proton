#!/usr/bin/env bash
set -euo pipefail

readonly BUILD_NAME="SWG-Proton-1-test1"
STEAM_TOOL="$HOME/.steam/root/compatibilitytools.d/$BUILD_NAME"
LUTRIS_TOOL="$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/$BUILD_NAME"
timestamp="$(date +%Y%m%d-%H%M%S)"

# Keep the runner recoverable instead of deleting it.
if [ -L "$LUTRIS_TOOL" ]; then
  unlink "$LUTRIS_TOOL"
fi
if [ -d "$STEAM_TOOL" ]; then
  mv "$STEAM_TOOL" "$STEAM_TOOL.uninstalled-$timestamp"
fi
if [ -f "$HOME/.local/bin/swg-infinity-deck" ]; then
  mv "$HOME/.local/bin/swg-infinity-deck" \
    "$HOME/.local/bin/swg-infinity-deck.uninstalled-$timestamp"
fi
if [ -f "$HOME/.local/share/applications/swg-infinity-deck.desktop" ]; then
  mv "$HOME/.local/share/applications/swg-infinity-deck.desktop" \
    "$HOME/.local/share/applications/swg-infinity-deck.desktop.uninstalled-$timestamp"
fi

echo "SWG-Proton was disabled without deleting its files."
echo "Restore the timestamped Lutris YAML backup manually if install-deck.sh changed it."
