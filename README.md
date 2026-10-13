# Matte OS

A dark, minimal desktop for a VFX and gaming PC, built as a custom [Bazzite](https://bazzite.gg) image with [Universal Blue's image template](https://github.com/ublue-os/image-template).

- **Base:** `bazzite-nvidia-open` (KDE Plasma stays installed as a backup session)
- **Desktop:** [niri](https://github.com/niri-wm/niri), a scrolling tiling Wayland compositor
- **Shell:** [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) as a stand-in, until Matte OS's own Quickshell shell is ready
- **Apps:** Kitty, Dolphin, and Zen browser (installed as a Flatpak on first boot)
- **Tweaks:** NVIDIA memory fix for niri, Windows-style shortcuts, 165 Hz monitors

## What's where

| Path | What it does |
| --- | --- |
| `Containerfile` | Picks the base image and runs the build script |
| `build_files/build.sh` | Installs packages and applies tweaks during the build |
| `system_files/etc/niri/config.kdl` | Default niri config for every user |
| `system_files/etc/nvidia/...` | NVIDIA profile that stops niri using too much VRAM |
| `system_files/usr/share/matte-os/flatpaks.list` | Flatpak apps installed on first boot |

## Switching an installed Bazzite system to Matte OS

```bash
sudo bootc switch ghcr.io/sakurastixs/matte-os:latest
systemctl reboot
```

To go back to the previous version at any point, pick it in the boot menu, or run `sudo bootc rollback`.

## Image signing

Builds are signed with cosign. The private key lives only in the repository secret `SIGNING_SECRET`; the public key is `cosign.pub`. Never commit `cosign.key`.

## Credits

Built on the work of the Universal Blue, Bazzite, niri and DankMaterialShell projects. Template licence: Apache-2.0 (see `LICENSE`).
