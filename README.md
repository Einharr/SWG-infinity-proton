# SWG Infinity Proton

An unofficial Proton compatibility build and Steam Deck launcher for SWG
Infinity. The Wine patch fixes the Infinity Launcher crash in
`ole32!RevokeDragDrop`; the wrapper supplies the fixed WebView2 runtime and
X11 environment required on SteamOS.

## Install

In Desktop Mode, open Konsole and run:

```bash
curl -fsSL https://raw.githubusercontent.com/Einharr/SWG-infinity-proton/main/install.sh \
  | bash -s -- 11
```

Replace `11` with the numeric Lutris game ID. The script downloads the latest
release assets, installs the custom runner, installs WebView2, updates the
Lutris YAML, and creates `~/.local/bin/swg-infinity-deck`.

To find the ID through the desktop UI, open Dolphin, press `Ctrl+L`, and open:

```text
~/.var/app/net.lutris.Lutris/config/lutris/games
```

Find the SWG YAML file, for example `swg-11.yml`; the number is the Lutris
game ID. From Konsole, the same directory can be listed with:

```bash
find ~/.var/app/net.lutris.Lutris/config/lutris/games \
  -maxdepth 1 -type f -iname '*swg*.yml' -print
```

Add that launcher to Steam as a Non-Steam Game. Do not select another Proton
version for the shortcut; it launches through Lutris.

## Build

Requirements: WSL2 or Linux, Docker/Podman, Git, `tar`, `xz`, and sufficient
disk space.

```bash
bash ./build.sh
```

The build pins the dwproton and Wine commits, applies the patch in
`patches/`, and writes the runner archive to `dist/`. Release binaries are
published as GitHub Release assets, not committed to the repository.

## License

The scripts and patch are MIT-licensed. The Proton runner and its bundled
components remain under their respective upstream licenses; see the files
inside the release archive and `THIRD-PARTY-NOTICES.md`.
