# Uninstall and clean reinstall

This procedure removes SWG Infinity completely so the installer can be tested
from a clean state.

> [!WARNING]
> This deletes the Proton prefix, installed launcher, downloaded game files,
> local settings, WebView2 runtime, and the custom Proton build. Server-side
> characters are not stored in these directories, but the game will need to be
> downloaded again.

## Remove everything

1. Switch the Steam Deck to Desktop Mode and open Steam.
2. Find **SWG Infinity** in the library.
3. Select **Manage > Remove non-Steam game from your library**.
4. Completely close Steam with **Steam > Exit**.
5. Open Konsole and run:

```bash
rm -rf -- \
  "$HOME/.steam/root/steamapps/compatdata/3680833707" \
  "$HOME/.steam/root/compatibilitytools.d/SWG-Proton-1-test1" \
  "$HOME/.local/share/swg-infinity"
```

The paths are deliberately limited to the fixed SWG Infinity shortcut ID,
this repository's compatibility tool, and this repository's local data.

## Install again

Run the current installer:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Einharr/SWG-infinity-proton/main/install.sh)"
```

Complete the official launcher setup using its default `C:\SWGInfinity`
location, close the setup window, return to Konsole, and press Enter. Then
switch to Gaming Mode and start **SWG Infinity**.

The installer applies the confirmed `ENABLE_GAMESCOPE_WSI=0` Gaming Mode
workaround automatically.

## Disable only the custom Proton build

The repository also includes `uninstall-deck.sh`. It only moves the custom
Proton build out of Steam's active compatibility-tools directory. It preserves
the Steam shortcut, Proton prefix, launcher, WebView2 runtime, and game files,
so it is not a clean uninstall.
