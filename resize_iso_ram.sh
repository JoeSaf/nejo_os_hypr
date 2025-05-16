#!/bin/bash
# Script to resize the RAM allocated to the live ISO from 1G to 4G

set -e  # Exit on error

# Working directory - expected to be the archiso config directory
WORK_DIR="$(pwd)"

echo "Modifying boot configuration to increase RAM from 1G to 4G..."

# Update SYSLINUX configuration (BIOS boot)
SYSLINUX_CONF_DIR="$WORK_DIR/syslinux"
if [ -d "$SYSLINUX_CONF_DIR" ]; then
    echo "Updating SYSLINUX configuration..."
    
    # Find and modify all .cfg files that contain the mem parameter
    find "$SYSLINUX_CONF_DIR" -name "*.cfg" -type f -exec grep -l "mem=1G" {} \; | while read -r file; do
        echo "Modifying $file"
        sed -i 's/mem=1G/mem=4G/g' "$file"
    done
else
    echo "SYSLINUX configuration directory not found. Creating it..."
    mkdir -p "$SYSLINUX_CONF_DIR/archiso_head.cfg"
    
    # Create basic configuration with 4G RAM
    cat > "$SYSLINUX_CONF_DIR/archiso_head.cfg" << 'EOF'
SERIAL 0 38400
UI vesamenu.c32
MENU TITLE Arch Linux
MENU BACKGROUND splash.png

MENU WIDTH 78
MENU MARGIN 4
MENU ROWS 7
MENU VSHIFT 10
MENU TABMSGROW 14
MENU CMDLINEROW 14
MENU HELPMSGROW 16
MENU HELPMSGENDROW 29

# Refer to http://syslinux.zytor.com/wiki/index.php/Doc/menu

MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #9033ccff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std
EOF

    # Create default configuration with 4G RAM
    cat > "$SYSLINUX_CONF_DIR/archiso_sys.cfg" << 'EOF'
INCLUDE boot/syslinux/archiso_head.cfg

LABEL arch
TEXT HELP
Boot the Arch Linux live medium.
It allows you to install Arch Linux or perform system maintenance.
ENDTEXT
MENU LABEL Boot Arch Linux
LINUX boot/x86_64/vmlinuz-linux
INITRD boot/intel-ucode.img,boot/amd-ucode.img,boot/x86_64/initramfs-linux.img
APPEND archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% cow_spacesize=4G mem=4G

INCLUDE boot/syslinux/archiso_tail.cfg
EOF

    # Create tail configuration
    cat > "$SYSLINUX_CONF_DIR/archiso_tail.cfg" << 'EOF'
LABEL existing
TEXT HELP
Boot an existing operating system.
Press TAB to edit the disk and partition number to boot.
ENDTEXT
MENU LABEL Boot existing OS
COM32 chain.c32
APPEND hd0 0

# http://www.memtest.org/
LABEL memtest
TEXT HELP
Run Memtest86+ (RAM test)
ENDTEXT
MENU LABEL Run Memtest86+ (RAM test)
LINUX boot/memtest

LABEL reboot
TEXT HELP
Reboot computer.
ENDTEXT
MENU LABEL Reboot
COM32 reboot.c32

LABEL poweroff
TEXT HELP
Power off computer.
ENDTEXT
MENU LABEL Power off
COM32 poweroff.c32
EOF
fi

# Update GRUB configuration (EFI boot)
GRUB_CONF_DIR="$WORK_DIR/grub"
if [ -d "$GRUB_CONF_DIR" ]; then
    echo "Updating GRUB configuration..."
    
    # Find and modify all files that contain the mem parameter
    find "$GRUB_CONF_DIR" -type f -exec grep -l "mem=1G" {} \; | while read -r file; do
        echo "Modifying $file"
        sed -i 's/mem=1G/mem=4G/g' "$file"
    done
    
    # Also update cowspace parameter if it exists
    find "$GRUB_CONF_DIR" -type f -exec grep -l "cow_spacesize=" {} \; | while read -r file; do
        echo "Updating cow_spacesize in $file"
        sed -i 's/cow_spacesize=[0-9]\+G/cow_spacesize=4G/g' "$file"
    done
else
    echo "GRUB configuration directory not found. No changes made to EFI boot."
fi

# Update systemd-boot configuration (EFI boot)
BOOT_CONF_DIR="$WORK_DIR/efiboot"
if [ -d "$BOOT_CONF_DIR" ]; then
    echo "Updating systemd-boot configuration..."
    
    # Find and modify all files that contain the mem parameter
    find "$BOOT_CONF_DIR" -type f -exec grep -l "mem=1G" {} \; | while read -r file; do
        echo "Modifying $file"
        sed -i 's/mem=1G/mem=4G/g' "$file"
    done
    
    # Also update cowspace parameter if it exists
    find "$BOOT_CONF_DIR" -type f -exec grep -l "cow_spacesize=" {} \; | while read -r file; do
        echo "Updating cow_spacesize in $file"
        sed -i 's/cow_spacesize=[0-9]\+G/cow_spacesize=4G/g' "$file"
    done
else
    echo "systemd-boot configuration directory not found. No changes made to EFI boot."
fi

# Update loader entries
LOADER_DIR="$WORK_DIR/airootfs/usr/share/efiboot/entries"
if [ -d "$LOADER_DIR" ]; then
    echo "Updating loader entries..."
    
    # Find and modify all files that contain the mem parameter
    find "$LOADER_DIR" -type f -exec grep -l "mem=1G" {} \; | while read -r file; do
        echo "Modifying $file"
        sed -i 's/mem=1G/mem=4G/g' "$file"
    done
    
    # Also update cowspace parameter if it exists
    find "$LOADER_DIR" -type f -exec grep -l "cow_spacesize=" {} \; | while read -r file; do
        echo "Updating cow_spacesize in $file"
        sed -i 's/cow_spacesize=[0-9]\+G/cow_spacesize=4G/g' "$file"
    done
else
    echo "Loader entries directory not found. No changes made to EFI boot loader entries."
fi

echo "RAM allocation and cowspace size updated from 1G to 4G."
echo "Run './build.sh' to rebuild the ISO with the new configuration."
