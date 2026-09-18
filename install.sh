#!/usr/bin/env bash
set -euo pipefail

readonly REPO="${SWG_PROTON_REPO:-Einharr/SWG-infinity-proton}"
readonly API="https://api.github.com/repos/$REPO/releases/latest"
readonly RUNNER_SHA256="7e0b47f9ab773b693b255748366c1c2fd41a8f9b1662962f8210c86d7c12eae0"
readonly WEBVIEW_SHA256="7e6369c3341f941ccc062d2322f4f5afe43dbf5bb61a456765656afe65b14f1a"
readonly TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v curl >/dev/null
command -v python3 >/dev/null
command -v sha256sum >/dev/null

json="$(curl -fsSL "$API")"
asset_url() {
  python3 - "$1" "$json" <<'PY'
import json, sys
name, raw = sys.argv[1], sys.argv[2]
for asset in json.loads(raw).get("assets", []):
    if asset.get("name") == name and asset.get("state") == "uploaded":
        print(asset["browser_download_url"])
        raise SystemExit
raise SystemExit(f"release asset not found: {name}")
PY
}

download_asset() {
  local name="$1" dest="$2"
  curl -fL "$(asset_url "$name")" -o "$dest"
}

download_parts() {
  local prefix="$1" count="$2" dest="$3" i name
  : > "$dest"
  for ((i=0; i<count; i++)); do
    name="${prefix}$(printf '%02d' "$i")"
    curl -fL "$(asset_url "$name")" >> "$dest"
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

printf '%s  %s\n' "$RUNNER_SHA256" "$TMP/$runner_name" | sha256sum -c -
printf '%s  %s\n' "$WEBVIEW_SHA256" "$TMP/$webview_name" | sha256sum -c -

curl -fsSL "https://raw.githubusercontent.com/$REPO/main/install-deck.sh" \
  -o "$TMP/install-deck.sh"
curl -fsSL "https://raw.githubusercontent.com/$REPO/main/steam-shortcut.py" \
  -o "$TMP/steam-shortcut.py"
chmod +x "$TMP/install-deck.sh"

bash "$TMP/install-deck.sh" \
  "$TMP/$runner_name" \
  "$TMP/$webview_name" \
  "$TMP/steam-shortcut.py"
