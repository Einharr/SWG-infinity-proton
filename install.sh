#!/usr/bin/env bash
set -euo pipefail

readonly REPO="${SWG_PROTON_REPO:-Einharr/SWG-infinity-proton}"
readonly API="https://api.github.com/repos/$REPO/releases/latest"
readonly TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

GAME_ID="${1:-}"
if [ -z "$GAME_ID" ]; then
  mapfile -t configs < <(find "$HOME/.var/app/net.lutris.Lutris/config/lutris/games" \
    -maxdepth 1 -type f -iname '*swg*.yml' -print 2>/dev/null || true)
  if [ "${#configs[@]}" -ne 1 ]; then
    echo "Usage: $0 LUTRIS_GAME_ID" >&2
    echo "Could not determine a unique SWG Lutris game. Matching YAML files:" >&2
    printf '  %s\n' "${configs[@]}" >&2
    exit 2
  fi
  GAME_ID="$(basename "${configs[0]}" | sed -E 's/^[^0-9]*([0-9]+).*$/\1/')"
fi
case "$GAME_ID" in (*[!0-9]*|'') echo "LUTRIS_GAME_ID must be numeric" >&2; exit 2;; esac

command -v curl >/dev/null
command -v python3 >/dev/null
json="$(curl -fsSL "$API")"
asset_url() {
  python3 - "$1" "$json" <<'PY'
import json, sys
name, raw = sys.argv[1], sys.argv[2]
for asset in json.loads(raw).get("assets", []):
    if asset.get("name") == name:
        print(asset["browser_download_url"])
        raise SystemExit
raise SystemExit(f"release asset not found: {name}")
PY
}

download_asset() {
  local name="$1" dest="$2" url
  url="$(asset_url "$name" 2>/dev/null || true)"
  if [ -n "$url" ]; then
    curl -fL "$url" -o "$dest"
  else
    curl -fL "https://media.githubusercontent.com/media/$REPO/main/assets/$name" -o "$dest"
  fi
}

download_parts() {
  local prefix="$1" count="$2" dest="$3" i name url
  : > "$dest"
  for ((i=0; i<count; i++)); do
    name="${prefix}$(printf '%02d' "$i")"
    url="$(asset_url "$name" 2>/dev/null || true)"
    [ -n "$url" ] || url="https://media.githubusercontent.com/media/$REPO/main/assets/$name"
    curl -fL "$url" >> "$dest"
  done
}

runner_name="SWG-Proton-1-test1.tar.xz"
webview_name="WebView2-Fixed-151.0.4129.107-x64.zip"
if asset_url "$runner_name" >/dev/null 2>&1; then
  download_asset "$runner_name" "$TMP/$runner_name"
else
  download_parts "runner.part." 6 "$TMP/$runner_name"
fi
if asset_url "$webview_name" >/dev/null 2>&1; then
  download_asset "$webview_name" "$TMP/$webview_name"
else
  download_parts "webview.part." 6 "$TMP/$webview_name"
fi
curl -fsSL "https://raw.githubusercontent.com/$REPO/main/install-deck.sh" \
  -o "$TMP/install-deck.sh"
chmod +x "$TMP/install-deck.sh"

yaml="$(find "$HOME/.var/app/net.lutris.Lutris/config/lutris/games" \
  -maxdepth 1 -type f -iname "*swg*$GAME_ID*.yml" -print -quit 2>/dev/null || true)"
if [ -z "$yaml" ]; then
  yaml="$(find "$HOME/.var/app/net.lutris.Lutris/config/lutris/games" \
    -maxdepth 1 -type f -iname "*$GAME_ID*.yml" -print -quit 2>/dev/null || true)"
fi

args=("$TMP/$runner_name" "$TMP/$webview_name" "$GAME_ID")
[ -n "$yaml" ] && args+=("$yaml")
bash "$TMP/install-deck.sh" "${args[@]}"
