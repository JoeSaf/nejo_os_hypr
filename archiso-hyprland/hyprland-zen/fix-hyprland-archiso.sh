#!/bin/bash

# Fix Hyprland Archiso issues
# This script applies all necessary fixes to make Hyprland work properly in the ISO

set -e  # Exit on error

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}Applying fixes for Hyprland Archiso${NC}"
echo -e "${BLUE}=========================================${NC}"

# Check if we're in the right directory
if [[ ! -d "airootfs" || ! -f "profiledef.sh" ]]; then
    echo -e "${RED}Error: This script must be run from the root of your archiso directory${NC}"
    echo -e "${YELLOW}Please change to your archiso directory and try again${NC}"
    exit 1
fi

echo -e "${GREEN}Starting fixes...${NC}"

# 1. Create customize_sfs.sh script
echo -e "${BLUE}Creating customize_sfs.sh script...${NC}"
mkdir -p airootfs/root
cat > airootfs/root/customize_sfs.sh << 'EOF'
#!/bin/bash

# Make script exit on error
set -e

echo "Running customize_sfs.sh to prepare the live environment..."

# Fix environment variables for Wayland
mkdir -p /etc/environment.d/
cat > /etc/environment.d/wayland.conf << EOFENV
XDG_RUNTIME_DIR=/run/user/1000
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
XDG_CURRENT_DESKTOP=Hyprland
GDK_BACKEND=wayland
QT_QPA_PLATFORM=wayland
EOFENV

# Create and set permissions for XDG_RUNTIME_DIR
mkdir -p /run/user/1000
chown 1000:1000 /run/user/1000
chmod 700 /run/user/1000

# Fix fish fzf integration to avoid errors
mkdir -p /etc/skel/.config/fish/conf.d/
cat > /etc/skel/.config/fish/conf.d/fzf.fish << EOFFZF
# Only source fzf scripts if they exist
if test -d /usr/share/fzf
    if test -f /usr/share/fzf/key-bindings.fish
        source /usr/share/fzf/key-bindings.fish
    end
    if test -f /usr/share/fzf/completion.fish
        source /usr/share/fzf/completion.fish
    end
end
EOFFZF

# Fix Hyprland window rule syntax in config
sed -i 's/{gamecontrol}/^(gamecontrol)$/g' /etc/skel/.config/hypr/hyprland.conf 2>/dev/null || true
sed -i 's/{wm-connection-editor}/^(nm-connection-editor)$/g' /etc/skel/.config/hypr/hyprland.conf 2>/dev/null || true
sed -i 's/{bluetooth-manager}/^(blueman-manager)$/g' /etc/skel/.config/hypr/hyprland.conf 2>/dev/null || true
sed -i 's/{thunar}/^(thunar)$/g' /etc/skel/.config/hypr/hyprland.conf 2>/dev/null || true

# Make sure firstboot.sh is executable
chmod +x /usr/local/bin/firstboot.sh 2>/dev/null || true
chmod +x /usr/local/bin/setup-network 2>/dev/null || true
chmod +x /usr/local/bin/welcome-app 2>/dev/null || true
chmod +x /usr/local/bin/fix-hyprland 2>/dev/null || true

# Improve Hyprland autostart service to include proper environment variables
cat > /etc/systemd/system/hyprland-autostart.service << EOFHYPR
[Unit]
Description=Hyprland Auto Start
After=display-manager.service
After=getty@tty1.service
After=firstboot.service

[Service]
Type=simple
User=liveuser
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="XDG_SESSION_TYPE=wayland"
Environment="XDG_SESSION_DESKTOP=Hyprland"
Environment="XDG_CURRENT_DESKTOP=Hyprland"
Environment="GDK_BACKEND=wayland"
Environment="QT_QPA_PLATFORM=wayland"
WorkingDirectory=/home/liveuser
ExecStartPre=/bin/sleep 1
ExecStart=/usr/bin/Hyprland
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOFHYPR

# Create a wrapper script to manually start Hyprland if needed
mkdir -p /usr/local/bin
cat > /usr/local/bin/start-hyprland << EOFSTART
#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland
exec Hyprland
EOFSTART
chmod +x /usr/local/bin/start-hyprland

# Make sure critical directories exist and have correct permissions
mkdir -p /etc/skel/.local/share /etc/skel/.cache
chmod 755 /etc/skel/.local /etc/skel/.local/share /etc/skel/.cache

echo "customize_sfs.sh completed successfully!"
EOF
chmod +x airootfs/root/customize_sfs.sh

# 2. Update firstboot.sh script
echo -e "${BLUE}Updating firstboot.sh script...${NC}"
# First check if the file exists
if [[ -f "airootfs/usr/local/bin/firstboot.sh" ]]; then
    # Make a backup
    cp airootfs/usr/local/bin/firstboot.sh airootfs/usr/local/bin/firstboot.sh.bak
    
    # Add the XDG_RUNTIME_DIR fix to the existing script before the exit line
    sed -i '/^exit/i # Ensure XDG_RUNTIME_DIR exists and has correct permissions\nmkdir -p \/run\/user\/1000\nchown 1000:1000 \/run\/user\/1000\nchmod 700 \/run\/user\/1000' airootfs/usr/local/bin/firstboot.sh
else
    # Create directory if it doesn't exist
    mkdir -p airootfs/usr/local/bin
    
    # Create a new firstboot.sh script
    cat > airootfs/usr/local/bin/firstboot.sh << 'EOF'
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

# Ensure XDG_RUNTIME_DIR exists and has correct permissions
mkdir -p /run/user/1000
chown 1000:1000 /run/user/1000
chmod 700 /run/user/1000

# Try to run setup-network if it exists
if [ -x /usr/local/bin/setup-network ]; then
    /usr/local/bin/setup-network
fi

echo "$(date): Firstboot script completed"
exit 0
EOF
fi
chmod +x airootfs/usr/local/bin/firstboot.sh

# 3. Update profiledef.sh to include the new file permissions
echo -e "${BLUE}Updating profiledef.sh with file permissions...${NC}"
# Backup the original profiledef.sh
cp profiledef.sh profiledef.sh.bak

# Check if file_permissions already exists in profiledef.sh
if grep -q "file_permissions=" profiledef.sh; then
    # Update existing file_permissions
    if ! grep -q '"/root/customize_sfs.sh"' profiledef.sh; then
        # Add customize_sfs.sh to file permissions
        sed -i '/file_permissions=(/a \ \ ["/root/customize_sfs.sh"]="0:0:755"' profiledef.sh
    fi
    
    # Add other permissions if they don't exist
    if ! grep -q '"/usr/local/bin/firstboot.sh"' profiledef.sh; then
        sed -i '/file_permissions=(/a \ \ ["/usr/local/bin/firstboot.sh"]="0:0:755"' profiledef.sh
    fi
    
    if ! grep -q '"/usr/local/bin/setup-network"' profiledef.sh; then
        sed -i '/file_permissions=(/a \ \ ["/usr/local/bin/setup-network"]="0:0:755"' profiledef.sh
    fi
    
    if ! grep -q '"/usr/local/bin/welcome-app"' profiledef.sh; then
        sed -i '/file_permissions=(/a \ \ ["/usr/local/bin/welcome-app"]="0:0:755"' profiledef.sh
    fi
    
    if ! grep -q '"/usr/local/bin/fix-hyprland"' profiledef.sh; then
        sed -i '/file_permissions=(/a \ \ ["/usr/local/bin/fix-hyprland"]="0:0:755"' profiledef.sh
    fi
else
    # Add file_permissions if it doesn't exist
    echo 'file_permissions=(' >> profiledef.sh
    echo '  ["/etc/shadow"]="0:0:400"' >> profiledef.sh
    echo '  ["/root"]="0:0:750"' >> profiledef.sh
    echo '  ["/root/customize_sfs.sh"]="0:0:755"' >> profiledef.sh
    echo '  ["/usr/local/bin/firstboot.sh"]="0:0:755"' >> profiledef.sh
    echo '  ["/usr/local/bin/setup-network"]="0:0:755"' >> profiledef.sh
    echo '  ["/usr/local/bin/welcome-app"]="0:0:755"' >> profiledef.sh
    echo '  ["/usr/local/bin/fix-hyprland"]="0:0:755"' >> profiledef.sh
    echo ')' >> profiledef.sh
fi

# 4. Fix Hyprland configuration if it exists
echo -e "${BLUE}Updating Hyprland configuration...${NC}"
HYPRLAND_CONF="airootfs/etc/skel/.config/hypr/hyprland.conf"
if [[ -f "$HYPRLAND_CONF" ]]; then
    # Make a backup
    cp "$HYPRLAND_CONF" "${HYPRLAND_CONF}.bak"
    
    # Fix window rule syntax
    sed -i 's/{gamecontrol}/^(gamecontrol)$/g' "$HYPRLAND_CONF" 2>/dev/null || true
    sed -i 's/{wm-connection-editor}/^(nm-connection-editor)$/g' "$HYPRLAND_CONF" 2>/dev/null || true
    sed -i 's/{bluetooth-manager}/^(blueman-manager)$/g' "$HYPRLAND_CONF" 2>/dev/null || true
    sed -i 's/{thunar}/^(thunar)$/g' "$HYPRLAND_CONF" 2>/dev/null || true
    
    echo -e "${GREEN}Hyprland configuration updated${NC}"
else
    echo -e "${YELLOW}Hyprland configuration not found, skipping...${NC}"
fi

# 5. Update hyprland-autostart.service
echo -e "${BLUE}Updating hyprland-autostart.service...${NC}"
HYPRSERVICE="airootfs/etc/systemd/system/hyprland-autostart.service"
if [[ -f "$HYPRSERVICE" ]]; then
    # Make a backup
    cp "$HYPRSERVICE" "${HYPRSERVICE}.bak"
    
    # Create an improved service file
    cat > "$HYPRSERVICE" << 'EOF'
[Unit]
Description=Hyprland Auto Start
After=display-manager.service
After=getty@tty1.service
After=firstboot.service

[Service]
Type=simple
User=liveuser
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="XDG_SESSION_TYPE=wayland"
Environment="XDG_SESSION_DESKTOP=Hyprland"
Environment="XDG_CURRENT_DESKTOP=Hyprland"
Environment="GDK_BACKEND=wayland"
Environment="QT_QPA_PLATFORM=wayland"
WorkingDirectory=/home/liveuser
ExecStartPre=/bin/sleep 1
ExecStart=/usr/bin/Hyprland
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${GREEN}hyprland-autostart.service updated${NC}"
else
    # Create directory if it doesn't exist
    mkdir -p airootfs/etc/systemd/system
    
    # Create service file
    cat > "$HYPRSERVICE" << 'EOF'
[Unit]
Description=Hyprland Auto Start
After=display-manager.service
After=getty@tty1.service
After=firstboot.service

[Service]
Type=simple
User=liveuser
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="XDG_SESSION_TYPE=wayland"
Environment="XDG_SESSION_DESKTOP=Hyprland"
Environment="XDG_CURRENT_DESKTOP=Hyprland"
Environment="GDK_BACKEND=wayland"
Environment="QT_QPA_PLATFORM=wayland"
WorkingDirectory=/home/liveuser
ExecStartPre=/bin/sleep 1
ExecStart=/usr/bin/Hyprland
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${GREEN}hyprland-autostart.service created${NC}"
fi

# 6. Create Hyprland manual start script
echo -e "${BLUE}Creating start-hyprland script...${NC}"
mkdir -p airootfs/usr/local/bin
cat > airootfs/usr/local/bin/start-hyprland << 'EOF'
#!/bin/bash

# Script to manually start Hyprland with correct environment variables
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland

# Check if NVIDIA GPU is present and set appropriate variables
if lspci | grep -i nvidia > /dev/null; then
    export LIBVA_DRIVER_NAME=nvidia
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export WLR_NO_HARDWARE_CURSORS=1
fi

# Create runtime directory if it doesn't exist
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Start Hyprland
exec Hyprland
EOF
chmod +x airootfs/usr/local/bin/start-hyprland

# 7. Create fish configuration with fixed fzf integration
echo -e "${BLUE}Fixing fish configuration...${NC}"
mkdir -p airootfs/etc/skel/.config/fish/conf.d
cat > airootfs/etc/skel/.config/fish/conf.d/fzf.fish << 'EOF'
# Only source fzf scripts if they exist
if test -d /usr/share/fzf
    if test -f /usr/share/fzf/key-bindings.fish
        source /usr/share/fzf/key-bindings.fish
    end
    if test -f /usr/share/fzf/completion.fish
        source /usr/share/fzf/completion.fish
    end
end
EOF

# 8. Create necessary directories and set permissions
echo -e "${BLUE}Creating necessary directories and setting permissions...${NC}"
mkdir -p airootfs/etc/skel/.local/share
mkdir -p airootfs/etc/skel/.cache
chmod 755 airootfs/etc/skel/.local
chmod 755 airootfs/etc/skel/.local/share
chmod 755 airootfs/etc/skel/.cache

# 9. Create environment.d configuration for Wayland
echo -e "${BLUE}Creating environment.d configuration for Wayland...${NC}"
mkdir -p airootfs/etc/environment.d
cat > airootfs/etc/environment.d/wayland.conf << 'EOF'
XDG_RUNTIME_DIR=/run/user/1000
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
XDG_CURRENT_DESKTOP=Hyprland
GDK_BACKEND=wayland
QT_QPA_PLATFORM=wayland
EOF

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}All fixes have been applied!${NC}"
echo -e "${YELLOW}You can now build your ISO using your preferred method.${NC}"
echo -e "${BLUE}=========================================${NC}"
