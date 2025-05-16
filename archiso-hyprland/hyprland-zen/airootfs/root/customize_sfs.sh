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

# Add VM compatibility variables
cat > /etc/environment.d/hyprland-vm.conf << EOFVM
WLR_NO_HARDWARE_CURSORS=1
WLR_RENDERER_ALLOW_SOFTWARE=1
EOFVM

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
Environment="WLR_NO_HARDWARE_CURSORS=1"
Environment="WLR_RENDERER_ALLOW_SOFTWARE=1"
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
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
exec Hyprland
EOFSTART
chmod +x /usr/local/bin/start-hyprland

# Make sure critical directories exist and have correct permissions
mkdir -p /etc/skel/.local/share /etc/skel/.cache
chmod 755 /etc/skel/.local /etc/skel/.local/share /etc/skel/.cache

echo "customize_sfs.sh completed successfully!"