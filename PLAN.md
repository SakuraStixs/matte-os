# Matte OS: the plan on one page

**Matte OS is a dark, minimal Linux desktop for a VFX and gaming PC. You install it once and everything is already set up.**

## The one rule

Nothing is configured by hand inside the running OS. If it matters, it lives in this repo and arrives with the image. If a step has to be repeated after install, that is a bug in the repo, not a to-do for you.

## Continuity (the idea the whole project follows)

Every surface is one scene, not a set of separate themes: boot, login, wallpaper, shell, launcher and lock screen all draw from the same picture, so moving between them never feels like a cut. The wallpaper decides the look; the OS follows it.

This works on two levels, so changing wallpaper stays easy:

1. **Any wallpaper (automatic).** Pick any image and Iris pulls a palette from it (background, text, accent) and recolours the island, notifications, focus ring and launcher. No setup needed.
2. **Scenes (hand-made, full integration).** A scene is a folder: `wallpaper`, `scene.toml` (palette, line style, fonts) and optional launcher art. The default scene is the current wallpaper. Scenes can restyle surfaces beyond colour; a normal wallpaper gets the generic launcher in its own colours.

**Default scene launcher: a star system.** Apps are planets drawn in the wallpaper's own style (banded, ringed, speckled, swirled; thin white line on near-black), each generated from the app's name so it always looks the same. Frequent apps are bigger; related apps orbit close. Typing in the search narrows the sky: matches drift to the centre and light up, the rest fade. The launcher opens over the wallpaper itself so it feels like the sky continues.

Still to decide: what the launcher looks like for a wallpaper with no scene. Moving wallpapers (Wallpaper Engine) are dropped for now.

## The look

Everything takes its colours from the default wallpaper (`system_files/usr/share/backgrounds/matte-os/default.jpg`, 3840x1080, one half per monitor): near-black `#1F1F1F`, off-white `#F2F2F2`, muted grey `#5A5A5A`, black glass island with a thin white edge. No accent colour for now; white is the accent, like the line art.

## How it is built (3 layers)

| Layer | What goes in it | Where in the repo |
| --- | --- | --- |
| 1. Image | Packages, system config, branding, services | `build_files/build.sh`, `system_files/etc`, `system_files/usr` |
| 2. User defaults | Settings every new user gets on first login (themes, shell settings, default apps, wallpaper) | `system_files/etc/skel/...` (to add) |
| 3. First-boot jobs | Things that need network or a real user session (Flatpaks, distrobox, Wallpaper Engine) | `system_files/usr/libexec/matte-os/` + a systemd unit each |

Base: Bazzite (NVIDIA open) → niri → **Iris**, your own Quickshell shell, from the first install. DankMaterialShell stays installed only as a hidden emergency session ("Niri (DMS fallback)" at the login screen) and is removed once Iris is solid.

## What already works

- Custom image builds on GitHub, signed with cosign
- niri default config: Windows-style shortcuts, 165 Hz monitors, off-white focus ring, rounded corners
- NVIDIA fix for niri, Kitty and Dolphin installed, Zen installed on first boot, "Matte OS" name in boot menu
- Installed on your 1TB NVMe, dual-booting with Windows

## What you currently do by hand (this is the list to eliminate)

| Manual step today | How to make it automatic | Layer |
| --- | --- | --- |
| Install Bazzite, then run `bootc switch` | Build and publish a **Matte OS installer ISO** (the repo already has `build-disk.yml` and `disk_config/iso-*.toml`) so you install Matte OS directly | Image |
| Look: island, dark theme, wallpaper | Built into Iris itself (`system_files/etc/xdg/quickshell/iris/`), so there is nothing to configure | Image |
| Make Zen the default browser (Firefox today) | Default `mimeapps.list` in `/etc/skel`; remove Firefox from the image if you do not want it | User defaults |
| Logo, boot animation, login screen, wallpapers, icons, sounds | Plymouth theme + SDDM theme + wallpaper files in `/usr/share/matte-os/` | Image |
| Houdini needs OpenCL | The NVIDIA driver in Bazzite should already provide CUDA, OptiX and OpenCL. Check with `nvidia-smi` and `clinfo`, then Houdini's own GPU report; only change the image if something is missing. ZBrush has no Linux version, so it stays on Windows | Image |
| Claude Desktop in an Ubuntu distrobox named `claude` | A `distrobox.ini` in `/etc/skel` plus a one-time first-login job (`distrobox assemble`) | First-boot |
| Anti-cheat games | Stay on Windows. Dual boot is the answer, not something to fix | n/a |

## Testing in a VM (from Windows)

`tools/matte-vm.ps1` makes a Hyper-V VM (8 GB RAM, 6 CPUs, 80 GB disk, in `D:\VMs`). Run it from PowerShell in the repo folder; it asks for admin approval itself.

1. `.\tools\matte-vm.ps1 setup` (after the first run turns Hyper-V on, restart Windows and run it again)
2. `.\tools\matte-vm.ps1 start`, then install from the Bazzite ISO. Set the computer name to `matteos`.
3. In the VM: `sudo bootc switch ghcr.io/sakurastixs/matte-os:latest`, reboot, then `sudo systemctl enable --now sshd`. (Once the Matte OS installer ISO exists, install from that instead and skip the switch.)
4. `.\tools\matte-vm.ps1 eject`, then `.\tools\matte-vm.ps1 snapshot` for a clean starting point.
5. Edit from Windows: in VS Code use Remote-SSH to `you@matteos.mshome.net`. In the VM, clone the repo and link Iris into place:
   `ln -s ~/matte-os/system_files/etc/xdg/quickshell/iris ~/.config/quickshell/iris`, then `qs -c iris` to restart it after changes.

`restore` rolls the VM back to the last snapshot. If niri will not start in Hyper-V (no 3D graphics), the fallback is a VM in QEMU or VMware with virtio-gpu.

## Main monitor and lyrics

- The main monitor is the **right** one. The island lives there (Iris picks the rightmost screen by position), and the login and lock screens centre on it. The left monitor is a plain second screen.
- **Synced lyrics** are a small optional extra: one slim line under the island, timed to the song, switched on and off with a button on the island's music pill. It reads what is playing from the system's media controls (MPRIS) and fetches timed lyrics from a lyrics service. Phase 2.

## Phases

1. **Ready on install.** Installer ISO, Iris v0, and every row of the table above. Done when a fresh install needs zero changes before you start working.
   - Iris v0 must cover: island (workspaces, clock, active window), launcher, notifications, volume popup, quick controls (Wi-Fi, Bluetooth, power), lock screen, clipboard history.
   - Until each one exists, a stopgap keeps the key working (fuzzel for `Mod+Space`, `wpctl` for volume keys). Lock, notifications, clipboard and power menu have no stopgap yet.
2. **Signature features.** Render watch, command palette (replaces fuzzel), mode switcher (Desktop / VFX / Game).
3. **Polish.** Remove DMS, boot animation, sounds.

## Status of Iris v0

| Piece | State |
| --- | --- |
| Island: workspaces + clock | Skeleton written, **not yet tested** |
| Launcher | Stopgap (fuzzel) |
| Notifications, lock screen, clipboard, power menu, quick controls | Not started |

## Housekeeping

- `cosign.key` (the private signing key) sits in the repo folder. It is git-ignored, but check it was never committed (`git log --all -- cosign.key`). If it was, rotate the key, since the repo is public.
- The ISO config now lives in `disk_config/iso.toml` (the build workflow looks for that name). `iso-kde.toml` and `iso-gnome.toml` are unused template leftovers and can be deleted.
- Jarvis is a separate project and stays out of this repo.
