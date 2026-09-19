# SWG Infinity Proton

Steam Deck installer and custom Proton build for SWG Infinity. It installs the
official launcher, WebView2 runtime, Proton runner, and a ready-to-use Steam
shortcut.

## Install

In Desktop Mode, open Konsole and run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Einharr/SWG-infinity-proton/main/install.sh)"
```

Complete the official setup at its default location, close it, then return to
Konsole and press Enter. Start **SWG Infinity** from Gaming Mode.

For a clean reinstall, see [UNINSTALL.md](UNINSTALL.md).

## How it works

`install.sh` downloads and verifies the prebuilt Proton and WebView2 release
assets. `install-deck.sh` installs them, runs the official launcher setup in a
dedicated prefix, and creates the Steam shortcut.

The shortcut uses `SWG-Proton-1-test1` and these Launch Options (the installer
substitutes the actual home directory):

```text
ENABLE_GAMESCOPE_WSI=0 WAYLAND_DISPLAY= WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--disable-gpu --disable-gpu-compositing --disable-features=Vulkan" WEBVIEW2_BROWSER_EXECUTABLE_FOLDER="Z:\home\deck\.local\share\swg-infinity\webview2-fixed" WINEDLLOVERRIDES="mscoree,mshtml=" %command%
```

## Build

Requires Linux or WSL2, Docker/Podman, Git, `tar`, and `xz`.

```bash
bash ./build.sh
```

The runner, checksum, and build metadata are written to `dist/`.

## Files

- `build.sh`, `patches/` — reproducible Proton build.
- `install.sh`, `install-deck.sh` — download and Deck installation.
- `steam-shortcut.py` — Steam shortcut configuration.
- `UNINSTALL.md` — complete removal and clean reinstall.
- GitHub Releases — prebuilt Proton and WebView2 assets.

## License

Repository code is MIT-licensed. Bundled components retain their upstream
licenses; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
