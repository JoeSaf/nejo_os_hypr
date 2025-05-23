#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="NeJoLinux"
iso_label="NEJO_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Arch Linux <https://archlinux.org>"
iso_application="Arch Linux Live/Rescue DVD"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.systemd-boot.esp' 'uefi-x64.systemd-boot.esp'
           'uefi-ia32.systemd-boot.eltorito' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/usr/local/bin/fix-hyprland"]="0:0:755"
  ["/usr/local/bin/welcome-app"]="0:0:755"
  ["/usr/local/bin/setup-network"]="0:0:755"
  ["/usr/local/bin/firstboot.sh"]="0:0:755"
  ["/root/customize_sfs.sh"]="0:0:755"
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/launch-calamares"]="0:0:755"
  ["/usr/local/bin/change-wallpaper.sh"]="0:0:755"
  ["/usr/local/bin/enable-wallpaper-changer.sh"]="0:0:755"
  ["/usr/local/bin/set-default-wallpaper.sh"]="0:0:755"
  ["/usr/local/bin/hypr-bindings"]="0:0:755"
  ["/usr/local/bin/start-waybar"]="0:0:755"
  ["/usr/local/bin/setup-fastfetch-art"]="0:0:755"
)
