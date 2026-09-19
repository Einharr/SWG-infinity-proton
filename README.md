# SWG Infinity Proton

Unofficial Steam Deck support for SWG Infinity. It provides a patched Proton
build, the required WebView2 runtime, and a direct Steam installer. Lutris is
not used.

## Install

In Desktop Mode, open Konsole and run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Einharr/SWG-infinity-proton/main/install.sh)"
```

Complete the official setup at its default location, close it, then return to
Konsole and press Enter. Start `SWG Infinity` from Gaming Mode.

For a complete removal or a clean reinstall test, follow
[UNINSTALL.md](UNINSTALL.md).

If several Steam accounts are configured on the Deck, set the target account
explicitly:

```bash
STEAM_USER_ID=12345678 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Einharr/SWG-infinity-proton/main/install.sh)"
```

## Build

Requirements: Linux or WSL2, Docker or Podman, Git, `tar`, `xz`, and sufficient
disk space. The build is pinned to specific dwproton and Wine commits.

```bash
bash ./build.sh
```

The patched runner and checksum are written to `dist/`.

## Repository layout

- `build.sh` and `patches/`: reproducible Proton build source.
- `install.sh`: downloads and verifies the prebuilt GitHub Release assets.
- `install-deck.sh`: installs Proton, WebView2, the launcher, and Steam shortcut.
- `steam-shortcut.py`: updates Steam shortcut and compatibility configuration.
- `UNINSTALL.md`: complete removal and clean reinstall.
- GitHub Releases: prebuilt Proton and WebView2 binary parts used by `install.sh`.

## License

The scripts and patch are MIT-licensed. The Proton runner, WebView2, and their
bundled components remain under their respective upstream licenses; see
`THIRD-PARTY-NOTICES.md`.
