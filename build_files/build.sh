#!/bin/bash
# Matte OS image build script.
# Runs once inside the image while GitHub Actions builds it, on top of Bazzite (NVIDIA, open modules).

set -ouex pipefail

### 1. Desktop: niri (scrolling tiling) plus what it needs around it
# Weak dependencies are skipped so niri's suggested extras (waybar, fuzzel, mako...) stay out;
# DankMaterialShell covers all of that. Because of that, anything we do want has to be named here.
#   gnome-keyring-pam      unlocks the keyring with your login password (it's only a weak dependency)
#   plymouth-plugin-script, plymouth-scripts  run and install the Matte OS boot animation
#   gh                     GitHub CLI, so `git push` can sign in
#   jetbrains-mono-fonts-all  the terminal font from the style guide
dnf5 install -y --setopt=install_weak_deps=False \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    gnome-keyring \
    gnome-keyring-pam \
    playerctl \
    wl-clipboard \
    plymouth-plugin-script \
    plymouth-scripts \
    gh \
    jetbrains-mono-fonts-all

### 2. Stand-in shell until Matte OS's own is ready: DankMaterialShell (brings in Quickshell)
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr enable avengemedia/dms
dnf5 install -y --setopt=install_weak_deps=False dms
# Disable the COPRs again so they don't stay enabled on installed systems;
# DMS updates arrive with each rebuilt image instead.
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable avengemedia/danklinux

### 3. Default apps (Dolphin comes with the base; Zen installs as a Flatpak on first boot)
dnf5 install -y kitty

### 4. Matte OS's own files: configs, scripts, branding, boot animation
# Copied after the packages so nothing a package installs can overwrite them.
cp -avf "/ctx/system_files"/. /
chmod +x /usr/libexec/matte-os/* /usr/bin/matte-*

### 5. Keep xwaylandvideobridge out of niri sessions (it opens an empty window there)
shopt -s nullglob
for desktop_file in /etc/xdg/autostart/*xwaylandvideobridge*.desktop; do
    grep -q '^NotShowIn=' "$desktop_file" || sed -i '/^\[Desktop Entry\]/a NotShowIn=niri;' "$desktop_file"
done
shopt -u nullglob

### 6. Keyring: unlocked at login, and the one niri sessions use for passwords
# The PAM module hands your login password to the systemd-managed daemon through this socket.
systemctl --global enable gnome-keyring-daemon.socket
# Start the daemon with every niri session, so it owns the Secret Service before any app asks.
mkdir -p /usr/lib/systemd/user/niri.service.wants
ln -sf ../gnome-keyring-daemon.service /usr/lib/systemd/user/niri.service.wants/gnome-keyring-daemon.service
# Animated wallpapers start with niri too (they stay off until `matte-wallpaper set` is run).
ln -sf ../matte-wallpaper.service /usr/lib/systemd/user/niri.service.wants/matte-wallpaper.service

### 7. Branding: name and logo in the boot menu, system info and About pages
sed -i \
    -e 's/^NAME=.*/NAME="Matte OS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Matte OS"/' \
    -e 's/^BOOTLOADER_NAME="Bazzite/BOOTLOADER_NAME="Matte OS/' \
    -e 's/^LOGO=.*/LOGO=matte-os-logo/' \
    -e 's/^ANSI_COLOR=.*/ANSI_COLOR="0;38;2;125;211;252"/' \
    /usr/lib/os-release
fc-cache -f /usr/share/fonts/plus-jakarta-sans
if command -v gtk-update-icon-cache >/dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor
fi

### 8. Boot animation: make Matte OS's Plymouth theme the default and rebuild the initramfs
# (the splash lives inside the initramfs). Same dracut options Bazzite uses for its own build.
plymouth-set-default-theme matte
mapfile -t kernels < <(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
if (( ${#kernels[@]} != 1 )); then
    echo "Expected exactly one kernel in /usr/lib/modules, found: ${kernels[*]}" >&2
    exit 1
fi
kernel="${kernels[0]}"
/usr/bin/dracut --no-hostonly --kver "$kernel" --reproducible --zstd -v --add ostree --add fido2 \
    -f "/usr/lib/modules/$kernel/initramfs.img"
chmod 0600 "/usr/lib/modules/$kernel/initramfs.img"

### 9. Services
systemctl enable matte-os-flatpaks.service

### 10. Fail the build on a broken niri config, rather than at your login screen
niri validate -c /etc/niri/config.kdl
