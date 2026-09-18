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
`SWG Infinity` Non-Steam shortcut, and assigns the custom compatibility tool.
Steam opens the official setup once; complete it, close the setup window, and
press Enter in Konsole. The script then changes the same shortcut from the
setup executable to the installed launcher. Keep the default installation
location offered by the setup.

Open the new shortcut and let Infinity Launcher download the game data. No
Lutris game or Lutris ID is required.

If the launcher works in Desktop Mode but Gaming Mode shows a Gamescope
`CreateSwapchainKHR` error or a black screen, follow
[GAMING-MODE-TESTS.md](GAMING-MODE-TESTS.md).

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

The build pins the dwproton and Wine commits, applies the patch in `patches/`,
and writes the runner archive to `dist/`. Release binaries are published as
GitHub Release assets.

## License

The scripts and patch are MIT-licensed. The Proton runner, WebView2, and their
bundled components remain under their respective upstream licenses; see
`THIRD-PARTY-NOTICES.md`.
