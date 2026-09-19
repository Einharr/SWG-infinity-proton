# SWG Infinity Proton

An unofficial Proton compatibility build and Steam Deck installer for the
current SWG Infinity Launcher. It fixes the launcher crash in
`ole32!RevokeDragDrop` and supplies the fixed WebView2 runtime required on
SteamOS. Lutris is not used.

## Install

In Desktop Mode, open Konsole and run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Einharr/SWG-infinity-proton/main/install.sh)"
```

The installer downloads the official Infinity Launcher, installs it into a
dedicated Steam Proton prefix, installs `SWG-Proton` and WebView2, creates the
`SWG Infinity` Non-Steam shortcut, assigns the custom compatibility tool, and
applies the confirmed Gamescope WSI workaround required in Gaming Mode.
Steam opens the official setup once; complete it, close the setup window, and
press Enter in Konsole. The script then changes the same shortcut from the
setup executable to the installed launcher. Keep the default installation
location offered by the setup.

Open the new shortcut and let Infinity Launcher download the game data. No
Lutris game or Lutris ID is required.

For a complete removal or a clean reinstall test, follow
[UNINSTALL.md](UNINSTALL.md).

If several Steam accounts are configured on the Deck, set the target account
explicitly:

```bash
STEAM_USER_ID=12345678 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Einharr/SWG-infinity-proton/main/install.sh)"
```

## Build

Requirements: WSL2 or Linux, Docker/Podman, Git, `tar`, `xz`, and sufficient
disk space.

```bash
bash ./build.sh
```

`build.sh` pins dwproton and Wine, applies the fix from `patches/`, and writes
the runner, checksum, and build metadata to `dist/`.

- Build inputs: `build.sh`, `patches/`, and `VERSION`.
- Build output: `dist/SWG-Proton-1-test1.tar.xz` plus checksum and build info.
- Prebuilt binaries: GitHub Release assets contain the runner and WebView2 in
  split parts; `install.sh` downloads, reassembles, and verifies them.
- Deck setup: `install-deck.sh` installs the binaries, while
  `steam-shortcut.py` creates and configures the Steam shortcut.

## License

The scripts and patch are MIT-licensed. The Proton runner, WebView2, and their
bundled components remain under their respective upstream licenses; see
`THIRD-PARTY-NOTICES.md`.
