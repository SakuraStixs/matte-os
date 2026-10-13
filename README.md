# Matte OS

A dark, minimal desktop for a VFX and gaming PC, built as a custom [Bazzite](https://bazzite.gg) image with [Universal Blue's image template](https://github.com/ublue-os/image-template).

- **Base:** `bazzite-nvidia-open` (KDE Plasma stays installed as a backup session)
- **Desktop:** [niri](https://github.com/niri-wm/niri), a scrolling tiling Wayland compositor
- **Shell:** [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) in Island mode as a stand-in, with the Matte OS theme (dark, sky-blue `#7DD3FC`), until Matte OS's own Quickshell shell is ready
- **Apps:** Kitty, Dolphin, Zen browser and TIDAL (SONE) as Flatpaks on first boot, Claude Desktop (in a distrobox)
- **Branding:** aperture logo, boot animation, login screen background, wallpaper, Plus Jakarta Sans and JetBrains Mono
- **Extras:** modes (Normal, VFX, Game, Focus), animated wallpapers through Wallpaper Engine, keyring unlocked at login, hi-fi audio at native sample rates

## Commands

| Command | What it does |
| --- | --- |
| `matte-doctor` | Checks the setup (niri config, monitors, keyring, Claude, boot animation, wallpaper). `matte-doctor --fix` fixes what it safely can. Run it after updates. |
| `matte-mode` | Switches mode: `matte-mode set vfx`, or **Win+M** to step through VFX, Game and Focus, **Win+Shift+M** for Normal. `matte-mode list` says what each changes. |
| `matte-wallpaper` | Animated wallpapers: `setup` once, then `list` and `set <id>`. Paused automatically in VFX and Game modes. |
| `matte-claude-setup` | Sets up or repairs Claude Desktop in its `claude` distrobox. Launch Claude from the app list or with `claude-desktop`. |
| `matte-shell` | Runs Matte OS's own shell (Iris so far): `matte-shell try` tests it next to DMS, `matte-shell --dev try` runs your checkout with live reload. |

### Modes

| Mode | Power | Animated wallpaper | Do not disturb |
| --- | --- | --- | --- |
| Normal | as before | on | off |
| VFX | performance | paused | off (finished renders still notify) |
| Game | performance | paused | on |
| Focus | as before | on | on |

Add your own steps in `~/.config/matte-os/mode.d/` (executable files, called with `<new mode> <old mode>`).

### Animated wallpapers

Needs Wallpaper Engine owned and installed in Steam (it's a Windows app, so turn on Proton for it under its Compatibility settings), plus some Workshop wallpapers.

```bash
matte-wallpaper setup           # once: makes the "wallpaper" distrobox and builds linux-wallpaperengine
matte-wallpaper list            # your Workshop wallpapers
matte-wallpaper set 1845706469  # every screen; add --screen DP-3 for just one
```

Settings (FPS, scaling, sound, and whether pausing freezes or fully stops it) are in `~/.config/matte-os/wallpaper.conf`.

### Music and hi-fi audio

- **TIDAL** comes as [SONE](https://github.com/lullabyX/sone) (`io.github.lullabyX.sone`), a native TIDAL client, installed on first boot. Unlike the web player it streams at the track's own rate, up to 24-bit/192 kHz (MAX), and it shows up in the media controls. On NVIDIA it needs WebKit's DMA-BUF renderer off; the image sets that.
- **Sample rates:** PipeWire normally converts everything to 48 kHz. Matte OS lets the output switch to the music's own rate (44.1 to 192 kHz) when nothing else is playing, and uses a better resampler when it does have to convert.
- **Bit-perfect (optional):** SONE's exclusive mode sends audio straight to the DAC, but then nothing else can play sound at the same time, and the Flatpak needs device access first: `flatpak override --user --device=all io.github.lullabyX.sone`.
- `matte-doctor` shows the rate your USB DAC is running at while music plays.

### Claude Desktop and the keyring

Claude Desktop runs in an Ubuntu 24.04 distrobox called `claude`. The launcher starts it with `--password-store=gnome-libsecret`, because Electron doesn't recognise niri and would otherwise fall back to "no system keyring". gnome-keyring is unlocked with your login password by its PAM module, and once per account the "login" keyring is made the default (in case an app had another one created first), so nothing asks for a keyring password.

## What's where

| Path | What it does |
| --- | --- |
| `Containerfile` | Picks the base image and runs the build script |
| `build_files/build.sh` | Installs packages, copies Matte OS's files, sets up the keyring, branding and boot animation |
| `system_files/etc/niri/config.kdl` | niri config for this PC: includes the Matte OS base config and sets the monitors |
| `system_files/usr/share/matte-os/niri/config.kdl` | Matte OS's niri config: looks, shortcuts, shell, wallpaper layer rule |
| `system_files/usr/share/matte-os/dms/matte-theme.json` | The Matte OS theme for DankMaterialShell |
| `system_files/etc/skel/` | Defaults for new accounts (DMS Island layout, theme, fonts, logo, wallpaper) |
| `system_files/etc/xdg/kitty/kitty.conf` | Default Kitty look |
| `system_files/usr/share/plymouth/themes/matte/` | Boot animation: the aperture opens and its light rises into Iris |
| `system_files/usr/lib/plasmalogin/plasmalogin.conf.d/` | Login screen background |
| `system_files/usr/share/matte-os/shell/` | Matte OS's own Quickshell shell (phase 2): Iris |
| `system_files/usr/bin/` | The `matte-*` commands and the `claude-desktop` launcher |
| `system_files/usr/libexec/matte-os/mode.d/` | What each mode changes |
| `system_files/usr/share/pipewire/` | Native sample rates and better resampling |
| `system_files/usr/share/matte-os/flatpaks.list` | Flatpak apps installed on first boot (and `flatpak-overrides.list` for their tweaks) |
| `branding/` | Logo geometry and the script that renders icons, wallpapers and boot frames (`node branding/generate.mjs`) |

## Monitors

`/etc/niri/config.kdl` sets DP-4 on the left and DP-3 on the right, both 1920x1080 at 164.999 Hz. niri needs the exact rate that `niri msg outputs` shows; if it doesn't match, niri falls back to 60 Hz. `matte-doctor` shows what each screen is actually running.

## Switching an installed Bazzite system to Matte OS

```bash
sudo bootc switch ghcr.io/sakurastixs/matte-os:latest
systemctl reboot
```

Updates after that: `sudo bootc upgrade && systemctl reboot` (or let Bazzite's automatic updates do it). To go back to the previous version at any point, pick it in the boot menu, or run `sudo bootc rollback`.

After an update, run `matte-doctor`. Files in `/etc` you've edited on the PC keep your version instead of the image's; the doctor spots that for the niri config and can reset it.

## Image signing

Builds are signed with cosign. The private key lives only in the repository secret `SIGNING_SECRET`; the public key is `cosign.pub`. Never commit `cosign.key`.

## Credits

Built on the work of the Universal Blue, Bazzite, niri, Quickshell, DankMaterialShell and linux-wallpaperengine projects. Plus Jakarta Sans is by Tokotype (SIL Open Font License, see `system_files/usr/share/fonts/plus-jakarta-sans/OFL.txt`). Template licence: Apache-2.0 (see `LICENSE`).
