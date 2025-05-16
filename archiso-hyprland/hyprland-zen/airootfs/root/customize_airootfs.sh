#!/bin/bash

set -e

# Set fish as default shell for liveuser
sed -i 's/\/bin\/bash/\/bin\/fish/g' /etc/passwd

# Enable important services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable hyprland-autostart.service
systemctl enable firstboot.service

# Create liveuser with passwordless sudo
useradd -m -G wheel,audio,video,input,storage -s /bin/fish liveuser
echo "liveuser:liveuser" | chpasswd

# Configure sudo for wheel group
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Allow liveuser to use sudo without password (for live environment only)
echo "liveuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/liveuser

# Enable autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOFINNER
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f liveuser' --noclear --autologin liveuser %I \$TERM
EOFINNER

# Ensure the user has proper permissions for wayland
usermod -aG input,video liveuser

# Remove any xorg.conf if it exists
rm -f /etc/X11/xorg.conf

# Fix permissions
chown -R liveuser:liveuser /home/liveuser
