#!/bin/bash

# This script runs on first boot to do any necessary setup

# Create a log file
LOG="/var/log/firstboot.log"
exec > >(tee -a $LOG) 2>&1

echo "$(date): Running firstboot script..."

# Detect hardware and load appropriate drivers
echo "Detecting graphics hardware..."
if lspci | grep -i nvidia > /dev/null; then
    echo "NVIDIA GPU detected"
    # Ensure nvidia modules are loaded
    modprobe nvidia_drm
    modprobe nvidia_modeset
    modprobe nvidia_uvm
    modprobe nvidia
    
    # Set up NVIDIA-specific environment variables for Hyprland
    mkdir -p /etc/environment.d/
    cat > /etc/environment.d/nvidia-wayland.conf << EOFNVIDIA
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
EOFNVIDIA
fi

# Configure udev rules for input devices if needed
echo "Setting up input device permissions..."
cat > /etc/udev/rules.d/99-input.rules << EOFUDEV
KERNEL=="event*", SUBSYSTEM=="input", MODE="0666"
EOFUDEV
udevadm control --reload-rules
udevadm trigger

echo "$(date): Firstboot script completed"
exit 0
/usr/local/bin/setup-network
