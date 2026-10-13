#!/bin/bash
# Matte OS image build script.
# Runs once inside the image while GitHub Actions builds it, on top of Bazzite (NVIDIA, open modules).

set -ouex pipefail

### 1. Matte OS's own files: niri config, NVIDIA tweak, first-boot Flatpak installer
cp -avf "/ctx/system_files"/. /
chmod +x /usr/libexec/matte-os/install-flatpaks

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

### 3. Stand-in shell until Matte OS's own is ready: DankMaterialShell (brings in Quickshell)
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr enable avengemedia/dms
dnf5 install -y --setopt=install_weak_deps=False dms
# Disable the COPRs again so they don't stay enabled on installed systems;
# DMS updates arrive with each rebuilt image instead.
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable avengemedia/danklinux

### 4. Default apps (Dolphin comes with the base; Zen installs as a Flatpak on first boot)
dnf5 install -y kitty

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
