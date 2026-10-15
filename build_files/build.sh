#!/bin/bash
# Matte OS image build script.
# Runs once inside the image while GitHub Actions builds it, on top of Bazzite (NVIDIA, open modules).

set -ouex pipefail

### 1. Matte OS's own files: niri config, NVIDIA tweak, first-boot Flatpak installer
cp -avf "/ctx/system_files"/. /
chmod +x /usr/libexec/matte-os/install-flatpaks /usr/libexec/matte-os/polkit-agent

### 2. Desktop: niri (scrolling tiling) plus what it needs around it
# Weak dependencies are skipped so niri's suggested extras (waybar, fuzzel, mako...) stay out;
# DankMaterialShell covers all of that.
dnf5 install -y --setopt=install_weak_deps=False \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    gnome-keyring \
    playerctl \
    wl-clipboard

### 3. Quickshell runs Iris (Matte OS's own shell). DankMaterialShell is installed only because it brings
### Quickshell in, and as an emergency fallback session. Iris is what starts by default.
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr enable avengemedia/dms
dnf5 install -y --setopt=install_weak_deps=False dms
# Disable the COPRs again so they don't stay enabled on installed systems;
# DMS updates arrive with each rebuilt image instead.
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable avengemedia/danklinux

### 4. Default apps (Dolphin comes with the base; Zen installs as a Flatpak on first boot)
# fuzzel is a temporary launcher until Iris has its own
dnf5 install -y kitty fuzzel

### 4b. Password prompts: a polkit agent (asks for your password when an app needs admin rights).
dnf5 install -y polkit-gnome || echo "polkit-gnome not available, relying on the KDE agent that ships with the base"
found_agent=""
for agent in /usr/libexec/polkit-gnome-authentication-agent-1 /usr/libexec/kf6/polkit-kde-authentication-agent-1 \
    /usr/libexec/polkit-kde-authentication-agent-1 /usr/lib/polkit-kde-authentication-agent-1 /usr/lib64/libexec/polkit-kde-authentication-agent-1; do
    [[ -x "$agent" ]] && found_agent="$agent" && break
done
[[ -n "$found_agent" ]] || { echo "No polkit agent found in the image"; exit 1; }

### 4c. Fonts used by Iris (all open licence), downloaded at build time
FONT_DIR=/usr/share/fonts/matte-os
mkdir -p "$FONT_DIR"
FONT_BASE=https://github.com/google/fonts/raw/main/ofl
curl -fsSL -o "$FONT_DIR/InstrumentSerif-Regular.ttf" "$FONT_BASE/instrumentserif/InstrumentSerif-Regular.ttf"
curl -fsSL -o "$FONT_DIR/InstrumentSerif-Italic.ttf"  "$FONT_BASE/instrumentserif/InstrumentSerif-Italic.ttf"
curl -fsSL -o "$FONT_DIR/HankenGrotesk.ttf"           "$FONT_BASE/hankengrotesk/HankenGrotesk%5Bwght%5D.ttf"
curl -fsSL -o "$FONT_DIR/HankenGrotesk-Italic.ttf"    "$FONT_BASE/hankengrotesk/HankenGrotesk-Italic%5Bwght%5D.ttf"
curl -fsSL -o "$FONT_DIR/JetBrainsMono.ttf"           "$FONT_BASE/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf"
curl -fsSL -o "$FONT_DIR/OFL-InstrumentSerif.txt"     "$FONT_BASE/instrumentserif/OFL.txt"
curl -fsSL -o "$FONT_DIR/OFL-HankenGrotesk.txt"       "$FONT_BASE/hankengrotesk/OFL.txt"
curl -fsSL -o "$FONT_DIR/OFL-JetBrainsMono.txt"       "$FONT_BASE/jetbrainsmono/OFL.txt"
fc-cache -f "$FONT_DIR"

### 4d. Dark look for apps: GTK/Flatpak dark preference and the Matte OS KDE colour scheme (files are in system_files)
glib-compile-schemas /usr/share/glib-2.0/schemas

### 5. Keep xwaylandvideobridge out of niri sessions (it opens an empty window there)
shopt -s nullglob
for desktop_file in /etc/xdg/autostart/*xwaylandvideobridge*.desktop; do
    grep -q '^NotShowIn=' "$desktop_file" || sed -i '/^\[Desktop Entry\]/a NotShowIn=niri;' "$desktop_file"
done
shopt -u nullglob

### 6. Branding: the name shown in the boot menu and system info
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Matte OS"/' /usr/lib/os-release

### 7. Services
systemctl enable matte-os-flatpaks.service

### 8. Fail the build on a broken niri config, rather than at your login screen
niri validate -c /etc/niri/config.kdl
niri validate -c /etc/niri/config-dms.kdl

### 9. Boot animation (Plymouth): the Iris aperture opens and its blades shoot out into a small solar system.
# This rebuilds the initial RAM disk. If a boot ever fails, pick the previous Matte OS entry in the boot menu
# (or run `sudo bootc rollback` once you are in).
dnf5 install -y plymouth-plugin-script
# the animation frames travel as one archive (made by tools/make-boot-frames.py)
tar -xzf /ctx/boot-frames.tar.gz -C /usr/share/plymouth/themes/matte
plymouth-set-default-theme matte
KERNEL_VERSION="$(ls /usr/lib/modules | head -n1)"
dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"
chmod 0600 "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"
