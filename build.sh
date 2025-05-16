#!/bin/bash

set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Configuration
WORK_DIR="$(pwd)/archiso-hyprland"
OUT_DIR="$(pwd)/out"
PROFILE_NAME="hyprland-zen"
ARCHISO_VERSION="$(pacman -Q archiso | awk '{print $2}' | cut -d- -f1)"

# Create directories
mkdir -p "$WORK_DIR" "$OUT_DIR"

echo "==> Creating custom Arch Linux ISO with Hyprland and Fish"
echo "==> Using archiso version: $ARCHISO_VERSION"

# Copy the releng profile to our custom profile
echo "==> Copying base profile"
cp -r /usr/share/archiso/configs/releng/ "$WORK_DIR/$PROFILE_NAME"
cd "$WORK_DIR/$PROFILE_NAME"

# Modify packages.x86_64
echo "==> Updating package list"
# Remove linux kernel
sed -i '/^linux$/d' packages.x86_64
sed -i '/^linux-headers$/d' packages.x86_64
sed -i '/^linux-firmware$/d' packages.x86_64
sed -i '/^linux-firmware-whence$/d' packages.x86_64

# Add our custom packages
cat >> packages.x86_64 << EOF
# Kernel
linux-zen
linux-zen-headers
linux-firmware
linux-firmware-whence

# Display system
hyprland
xdg-desktop-portal-hyprland
waybar
wofi
foot
wl-clipboard
slurp
grim
swappy
swww
kanshi
libnotify
dunst

# Add Xorg for compatibility
xorg-server-xwayland
xorg-xinit
xorg-xwayland

# GPU Drivers - add these explicitly
mesa
vulkan-intel
vulkan-radeon
xf86-video-amdgpu
xf86-video-ati
xf86-video-intel
xf86-video-nouveau
nvidia
nvidia-utils

# Sound and Bluetooth
pipewire
wireplumber
pipewire-pulse
pipewire-alsa
pipewire-jack
bluez
bluez-utils
alsa-utils
pamixer

# Shell and tools
fish
starship
neovim
git
bat
ripgrep
fzf
htop
btop
exa
wget
curl
unzip
zip
jq
man-db
man-pages

# Network
networkmanager
network-manager-applet
wpa_supplicant
iwd
dhcpcd

# Filesystem
gvfs
gvfs-mtp
udisks2
ntfs-3g
exfat-utils

# Other utilities
firefox
thunar
thunar-archive-plugin
thunar-volman
tumbler
ffmpegthumbnailer
polkit-gnome
gnome-keyring
irqbalance
power-profiles-daemon
imagemagick

# Add fonts
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
ttf-jetbrains-mono-nerd
ttf-dejavu

# Dependencies for display system
wayland
libinput
xdg-desktop-portal
xdg-utils

# Add systemd autologin support
systemd-sysvcompat

# Add zenity for welcome dialog
zenity
EOF

# Create airootfs structure
echo "==> Creating airootfs structure"
mkdir -p airootfs/etc/skel/.config/{fish,hypr,waybar,wofi,foot,starship}
mkdir -p airootfs/etc/skel/Pictures
mkdir -p airootfs/etc/skel/.config/hypr/scripts
mkdir -p airootfs/etc/skel/Pictures/wallpapers
mkdir -p airootfs/etc/skel/Desktop

# Set up autologin
mkdir -p airootfs/etc/systemd/system/getty@tty1.service.d/
cat > airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f liveuser' --noclear --autologin liveuser %I \$TERM
EOF

# Create Hyprland auto-start service
mkdir -p airootfs/etc/systemd/system/
cat > airootfs/etc/systemd/system/hyprland-autostart.service << EOF
[Unit]
Description=Hyprland Auto Start
After=getty@tty1.service

[Service]
Type=simple
User=liveuser
Environment=XDG_SESSION_TYPE=wayland
Environment=GDK_BACKEND=wayland
Environment=QT_QPA_PLATFORM=wayland
ExecStart=/usr/bin/Hyprland
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create customization script
echo "==> Creating customize_airootfs.sh script"
cat > airootfs/root/customize_airootfs.sh << 'EOF'
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
EOF

chmod +x airootfs/root/customize_airootfs.sh

# Create Hyprland basic configuration with minimal startup
echo "==> Creating Hyprland configuration"
cat > airootfs/etc/skel/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration

# Monitor setup
monitor=,preferred,auto,1

# Set environment variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,qt5ct
env = GDK_BACKEND,wayland,x11
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = _JAVA_AWT_WM_NONREPARENTING,1

# Autostart programs
exec-once = waybar
exec-once = nm-applet --indicator
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = welcome-app

# Basic appearance
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    cursor_inactive_timeout = 5
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
        new_optimizations = true
    }
    drop_shadow = true
    shadow_range = 15
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
}

dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = true
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(thunar)$
windowrule = float, title:^(btop)$

# Device-specific configuration detection
# Detect if running on NVIDIA
exec-once = nvidia-settings -q NvidiaDriverVersion >/dev/null 2>&1 && echo "env = LIBVA_DRIVER_NAME,nvidia" >> /tmp/hypr/nvidia && echo "env = __GLX_VENDOR_LIBRARY_NAME,nvidia" >> /tmp/hypr/nvidia

# Keybindings
$mainMod = SUPER

# Application shortcuts
bind = $mainMod, Return, exec, foot
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, E, exec, thunar
bind = $mainMod, B, exec, firefox
bind = $mainMod, escape, exec, wlogout
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | swappy -f -

# Window management
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, Q, exit,
bind = $mainMod, F, fullscreen,
bind = $mainMod, Space, togglefloating,
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, S, togglesplit, # dwindle

# Move focus
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move windows
bind = $mainMod SHIFT, H, movewindow, l
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, K, movewindow, u
bind = $mainMod SHIFT, J, movewindow, d
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Volume control
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t

# Brightness control
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF

# Create fish configuration
echo "==> Creating fish configuration"
cat > airootfs/etc/skel/.config/fish/config.fish << 'EOF'
# Startup message
function fish_greeting
    echo "Welcome to Arch Linux Hyprland Live Environment!"
    echo "- Username: liveuser"
    echo "- Password: liveuser"
    echo "- Type 'sudo' to get root privileges without password"
end

# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL foot
set -gx BROWSER firefox
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DATA_HOME $HOME/.local/share

# Hyprland environment variables
set -gx XDG_SESSION_TYPE wayland
set -gx XDG_SESSION_DESKTOP Hyprland
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx GDK_BACKEND wayland,x11
set -gx QT_QPA_PLATFORM wayland
set -gx SDL_VIDEODRIVER wayland
set -gx _JAVA_AWT_WM_NONREPARENTING 1

# Path
fish_add_path $HOME/.local/bin

# Aliases
alias ls='exa --icons'
alias ll='exa --icons -la'
alias la='exa --icons -a'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
alias vim='nvim'
alias please='sudo'
alias refresh='source ~/.config/fish/config.fish'
alias startdesktop='exec Hyprland'

# Enable starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Enable fzf keybindings
if test -d /usr/share/fzf
    source /usr/share/fzf/key-bindings.fish
    source /usr/share/fzf/completion.fish
end

# Setup completions
if test -d ~/.config/fish/completions
    for file in ~/.config/fish/completions/*.fish
        source $file
    end
end

# Add autocompletion for git
if command -v git > /dev/null
    set -l git_completion_path (dirname (dirname (command -v git)))/share/git/completions/git-completion.bash
    if test -f $git_completion_path
        bash -c "source $git_completion_path && complete -p git" | string replace -r '^complete (.+) git$' 'complete -c git $1' | source
    end
end

# Add Pacman completion
function __fish_complete_pacman
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    
    set -l completions

    # Simplified pacman completions
    switch $cmd[2]
        case '-S' '--sync'
            command pacman -Ssq | sort | uniq
        case '-R' '--remove'
            command pacman -Qsq | sort | uniq
        case '-Q' '--query'
            command pacman -Qsq | sort | uniq
    end
end

complete -c pacman -n "__fish_complete_pacman" -a "(__fish_complete_pacman)"

# Add systemctl completion
function __fish_complete_systemctl_units
    systemctl list-units --all --no-legend --no-pager | string replace -r '●\s+' '' | string replace -r '\s+loaded.*$' '' | string match -v '*.*'
end

complete -c systemctl -n "__fish_seen_subcommand_from start stop restart enable disable status" -a "(__fish_complete_systemctl_units)"
EOF

# Create fish helper functions
mkdir -p airootfs/etc/skel/.config/fish/functions
cat > airootfs/etc/skel/.config/fish/functions/update-mirrors.fish << 'EOF'
function update-mirrors --description "Update pacman mirrors to fastest"
    sudo pacman -Syy
    sudo pacman -S --needed reflector
    sudo reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    sudo pacman -Syy
end
EOF

# Create waybar configuration
echo "==> Creating Waybar configuration"
mkdir -p airootfs/etc/skel/.config/waybar/
cat > airootfs/etc/skel/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "temperature", "battery", "tray"],
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}: {icon}",
        "format-icons": {
            "1": "󰈹",
            "2": "󰨞",
            "3": "󰆍",
            "4": "󱓷",
            "5": "󰙯",
            "urgent": "󰗖",
            "default": "󰊠"
        }
    },
    "hyprland/window": {
        "max-length": 50
    },
    "clock": {
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format": "{:%Y-%m-%d %H:%M}"
    },
    "cpu": {
        "format": "{usage}% 󰍛",
        "tooltip": false
    },
    "memory": {
        "format": "{}% 󰘚"
    },
    "temperature": {
        "critical-threshold": 80,
        "format": "{temperatureC}°C {icon}",
        "format-icons": ["󱃃", "󰔏", "󱃂"]
    },
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% 󰂄",
        "format-plugged": "{capacity}% 󰚥",
        "format-alt": "{time} {icon}",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) 󰖩",
        "format-ethernet": "{ipaddr}/{cidr} 󰈀",
        "tooltip-format": "{ifname} via {gwaddr} 󰛳",
        "format-linked": "{ifname} (No IP) 󰈀",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    "pulseaudio": {
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": "󰝟 {icon} {format_source}",
        "format-muted": "󰝟 {format_source}",
        "format-source": "{volume}% 󰍬",
        "format-source-muted": "󰍭",
        "format-icons": {
            "headphone": "󰋋",
            "hands-free": "󰋎",
            "headset": "󰋎",
            "phone": "󰏲",
            "portable": "󰏲",
            "car": "󰄋",
            "default": ["󰕿", "󰖀", "󰕾"]
        },
        "on-click": "pavucontrol"
    },
    "tray": {
        "icon-size": 21,
        "spacing": 10
    }
}
EOF

# Create waybar styles
cat > airootfs/etc/skel/.config/waybar/style.css << 'EOF'
* {
    font-family: "JetBrainsMono Nerd Font", "Noto Sans", sans-serif;
    font-size: 13px;
}

window#waybar {
    background-color: rgba(26, 27, 38, 0.9);
    color: #c0caf5;
    transition-property: background-color;
    transition-duration: .5s;
    border-radius: 0;
}

window#waybar.hidden {
    opacity: 0.2;
}

#workspaces button {
    color: #c0caf5;
    background-color: transparent;
    padding: 0 5px;
    border-radius: 5px;
}

#workspaces button:hover {
    background: rgba(96, 97, 108, 0.4);
    box-shadow: inset 0 -3px #c0caf5;
}

#workspaces button.active {
    background-color: rgba(96, 97, 108, 0.8);
    box-shadow: inset 0 -3px #c0caf5;
}

#clock,
#battery,
#cpu,
#memory,
#temperature,
#network,
#pulseaudio,
#custom-media,
#tray,
#mode,
#window {
    padding: 0 10px;
    margin: 6px 3px;
    color: #c0caf5;
    border-radius: 5px;
}

#battery {
    background-color: rgba(96, 97, 108, 0.4);
}

#battery.charging, #battery.plugged {
    color: #a6e3a1;
    background-color: rgba(96, 97, 108, 0.4);
}

@keyframes blink {
    to {
        background-color: #cba6f7;
        color: #1a1b26;
    }
}

#battery.critical:not(.charging) {
    background-color: #f7768e;
    color: #1a1b26;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#cpu {
    background-color: rgba(96, 97, 108, 0.4);
}

#memory {
    background-color: rgba(96, 97, 108, 0.4);
}

#network {
    background-color: rgba(96, 97, 108, 0.4);
}

#network.disconnected {
    background-color: #f7768e;
    color: #1a1b26;
}

#pulseaudio {
    background-color: rgba(96, 97, 108, 0.4);
}

#pulseaudio.muted {
    background-color: #f7768e;
    color: #1a1b26;
}

#temperature {
    background-color: rgba(96, 97, 108, 0.4);
}

#temperature.critical {
    background-color: #f7768e;
    color: #1a1b26;
}

#tray {
    background-color: rgba(96, 97, 108, 0.4);
}

#clock {
    background-color: rgba(96, 97, 108, 0.4);
    font-weight: bold;
}

#window {
    background-color: rgba(96, 97, 108, 0.4);
}
EOF

# Create wofi configuration
echo "==> Creating Wofi configuration"
mkdir -p airootfs/etc/skel/.config/wofi
cat > airootfs/etc/skel/.config/wofi/config << 'EOF'
width=600
height=350
mode=drun
prompt=Search...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=24
gtk_dark=true
EOF

cat > airootfs/etc/skel/.config/wofi/style.css << 'EOF'
window {
    margin: 0px;
    border: 2px solid #7aa2f7;
    border-radius: 15px;
    background-color: rgba(26, 27, 38, 0.9);
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
}

#input {
    padding: 10px;
    margin: 10px;
    border: none;
    border-radius: 10px;
    color: #c0caf5;
    background-color: rgba(96, 97, 108, 0.6);
}

#inner-box {
    margin: 5px;
    background-color: transparent;
}

#outer-box {
    margin: 5px;
    background-color: transparent;
}

#scroll {
    margin: 5px;
    background-color: transparent;
}

#text {
    margin: 5px;
    color: #c0caf5;
}

#entry:selected {
    border-radius: 10px;
    background-color: rgba(122, 162, 247, 0.6);
}

#text:selected {
    color: #1a1b26;
}
EOF

# Create foot terminal configuration
echo "==> Creating Foot terminal configuration"
mkdir -p airootfs/etc/skel/.config/foot
cat > airootfs/etc/skel/.config/foot/foot.ini << 'EOF'
# Foot terminal configuration

[main]
font=JetBrainsMono Nerd Font:size=11
include=~/.config/foot/themes/tokyonight.conf
pad=10x10
title=Foot Terminal
locked-title=no

[cursor]
style=block
blink=yes

[mouse]
hide-when-typing=yes

[colors]
alpha=0.9
foreground=c0caf5
background=1a1b26
EOF

mkdir -p airootfs/etc/skel/.config/foot/themes
cat > airootfs/etc/skel/.config/foot/themes/tokyonight.conf << 'EOF'
# TokyoNight colors for foot
[colors]
foreground=c0caf5
background=1a1b26
regular0=15161e
regular1=f7768e
regular2=9ece6a
regular3=e0af68
regular4=7aa2f7
regular5=bb9af7
regular6=7dcfff
regular7=a9b1d6
bright0=414868
bright1=f7768e
bright2=9ece6a
bright3=e0af68
bright4=7aa2f7
bright5=bb9af7
bright6=7dcfff
bright7=c0caf5
EOF

# Create starship configuration
echo "==> Creating Starship configuration"
mkdir -p airootfs/etc/skel/.config/starship
cat > airootfs/etc/skel/.config/starship.toml << 'EOF'
# Starship Prompt Configuration

# Don't print a new line at the start of the prompt
add_newline = false

# Make prompt a single line instead of two lines
[line_break]
disabled = true

# Replace the "❯" symbol in the prompt with "➜"
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

# Use custom format
format = """
[$username@$hostname](bold blue) in [${directory}](bold yellow)$git_branch$git_status
$character"""

[username]
style_user = "blue bold"
style_root = "red bold"
format = "[$user]($style)"
disabled = false
show_always = true

[hostname]
ssh_only = false
format = "[$hostname](bold blue)"
disabled = false

[directory]
truncation_length = 8
truncation_symbol = "…/"
home_symbol = "~"
read_only_style = "red"
read_only = " 🔒"
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = "🌱 "
truncation_length = 4
truncation_symbol = ""
format = " on [$symbol$branch]($style) "
style = "bold green"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold blue"
conflicted = "🏳"
up_to_date = "✓"
untracked = "🤷"
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
stashed = "📦"
modified = "📝"
staged = '[++\($count\)](green)'
renamed = "👅"
deleted = "🗑"

[cmd_duration]
min_time = 500
format = " took [$duration](bold yellow)"
EOF

# Create default bash profile for compatibility
echo "==> Creating bash profile"
cat > airootfs/etc/skel/.bash_profile << 'EOF'
# Bash profile for compatibility
# This will help ensure proper environment setup when using bash

# Set environment variables
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=foot
export BROWSER=firefox
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# Wayland environment variables
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# Add local bin to path
export PATH="$HOME/.local/bin:$PATH"

# Auto-start Hyprland on tty1 login (commented out since we use systemd service now)
# if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
#  exec Hyprland
# fi
EOF

# Create a debug script to help diagnose issues
echo "==> Creating debug helper script"
mkdir -p airootfs/usr/local/bin/
cat > airootfs/usr/local/bin/fix-hyprland << 'EOF'
#!/bin/bash

echo "Hyprland ISO Environment Diagnostics Tool"
echo "========================================"

# Check if user is root
if [[ $EUID -eq 0 ]]; then
   echo "[WARN] This script should NOT be run as root, but as the liveuser"
   echo "Please exit and run as liveuser"
   exit 1
fi

echo "[INFO] Running system checks..."

# Check necessary services
echo "[CHECK] Checking systemd services..."
systemctl --no-pager status hyprland-autostart
systemctl --no-pager status NetworkManager
systemctl --no-pager status bluetooth

# Check graphics drivers and hardware
echo -e "\n[CHECK] Checking graphics hardware..."
lspci | grep -i 'vga\|3d\|display'
echo -e "\n[CHECK] Loaded graphics modules:"
lsmod | grep -i 'nvidia\|amdgpu\|radeon\|intel\|i915\|nouveau'

# Check if Wayland is available
echo -e "\n[CHECK] Checking for Wayland availability..."
if [ -e /usr/share/wayland-sessions/hyprland.desktop ]; then
    echo "[OK] Hyprland desktop file exists"
else
    echo "[FAIL] Hyprland desktop file not found"
fi

# Check environment variables
echo -e "\n[CHECK] Checking environment variables..."
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "GDK_BACKEND=$GDK_BACKEND"
echo "QT_QPA_PLATFORM=$QT_QPA_PLATFORM"

# Check user permissions
echo -e "\n[CHECK] Checking user permissions..."
groups | grep -q "input" && echo "[OK] User in input group" || echo "[FAIL] User not in input group"
groups | grep -q "video" && echo "[OK] User in video group" || echo "[FAIL] User not in video group"

# Check if required components are installed
echo -e "\n[CHECK] Checking required packages..."
command -v Hyprland >/dev/null && echo "[OK] Hyprland is installed" || echo "[FAIL] Hyprland not found"
command -v waybar >/dev/null && echo "[OK] Waybar is installed" || echo "[FAIL] Waybar not found"
command -v foot >/dev/null && echo "[OK] Foot is installed" || echo "[FAIL] Foot not found"

echo -e "\n[INFO] If Hyprland is not starting correctly, try one of these commands:"
echo "1. Restart the autostart service: systemctl --user restart hyprland-autostart"
echo "2. Try starting Hyprland manually: Hyprland"
echo "3. Check Hyprland logs: journalctl -xe | grep -i hypr"
echo "4. Check if your graphics driver is loaded correctly (see above)"

echo -e "\nTroubleshooting complete"
EOF
chmod +x airootfs/usr/local/bin/fix-hyprland

# Create a firstboot service to handle initial setup
mkdir -p airootfs/etc/systemd/system/
cat > airootfs/etc/systemd/system/firstboot.service << 'EOF'
[Unit]
Description=Live Environment First Boot Setup
After=network.target
Before=hyprland-autostart.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firstboot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

mkdir -p airootfs/usr/local/bin/
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

echo "$(date): Firstboot script completed"
exit 0
EOF
chmod +x airootfs/usr/local/bin/firstboot.sh

# Create a welcome app
mkdir -p airootfs/usr/local/bin/
cat > airootfs/usr/local/bin/welcome-app << 'EOF'
#!/bin/bash

# Simple welcome dialog with zenity
zenity --info --title="Welcome to Arch Linux Hyprland" \
    --text="Welcome to the Arch Linux Hyprland Live Environment!

Username: liveuser
Password: liveuser

This live environment includes:
• Hyprland Wayland compositor
• Fish shell with starship prompt
• All necessary drivers and utilities

Enjoy your Arch Linux experience!"
EOF
chmod +x airootfs/usr/local/bin/welcome-app

# Create an installation guide
mkdir -p airootfs/etc/skel/Desktop/
cat > airootfs/etc/skel/Desktop/INSTALL.txt << 'EOF'
Arch Linux Hyprland Installation Guide
=====================================

This live environment comes with everything you need to install Arch Linux with Hyprland.

Quick Installation Steps:
1. Connect to the internet using NetworkManager: `nmtui` or `nmcli`
2. Partition your disk using `cfdisk /dev/sdX` (replace X with your disk)
3. Format the partitions (example: `mkfs.ext4 /dev/sdX1`)
4. Mount the partitions: `mount /dev/sdX1 /mnt`
5. Install base system: `pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware fish networkmanager`
6. Generate fstab: `genfstab -U /mnt >> /mnt/etc/fstab`
7. Chroot into the new system: `arch-chroot /mnt`
8. Set up time zone: `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`
9. Set up locale: Edit `/etc/locale.gen` and run `locale-gen`
10. Create hostname: `echo "myhostname" > /etc/hostname`
11. Set root password: `passwd`
12. Install and configure bootloader (e.g., GRUB)
13. Install Hyprland and all required packages: 
    - `pacman -S hyprland xdg-desktop-portal-hyprland waybar wofi foot ...` (add all packages from the live environment)

For a more detailed installation guide, refer to the Arch Wiki:
https://wiki.archlinux.org/title/Installation_guide
EOF

# Add GTK/Qt theming
mkdir -p airootfs/etc/skel/.config/gtk-3.0/
cat > airootfs/etc/skel/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF

# Add Qt configuration
mkdir -p airootfs/etc/skel/.config/qt5ct/
cat > airootfs/etc/skel/.config/qt5ct/qt5ct.conf << 'EOF'
[Appearance]
color_scheme_path=
custom_palette=false
style=Fusion
EOF

# Create network setup script for first boot
cat > airootfs/usr/local/bin/setup-network << 'EOF'
#!/bin/bash

# Ensure NetworkManager is running
systemctl --no-pager status NetworkManager || systemctl start NetworkManager

# Attempt to connect to any available networks
echo "Attempting to connect to wireless networks..."
nmcli radio wifi on
nmcli device wifi rescan
sleep 2

# Try to connect to open networks if available
OPEN_NETWORKS=$(nmcli -f SSID,SECURITY device wifi list | grep -v SECURITY | grep -- - | awk '{print $1}')
if [ -n "$OPEN_NETWORKS" ]; then
    FIRST_NETWORK=$(echo "$OPEN_NETWORKS" | head -1)
    echo "Attempting to connect to open network: $FIRST_NETWORK"
    nmcli device wifi connect "$FIRST_NETWORK" || true
fi

# Check connectivity
if ping -c 1 archlinux.org &>/dev/null; then
    echo "Network connection established successfully."
else
    echo "Please set up network manually using nmtui or nmcli."
    # Launch network manager TUI if in a terminal
    if [ -t 1 ]; then
        nmtui
    fi
fi
EOF
chmod +x airootfs/usr/local/bin/setup-network

# Add to firstboot script
echo "/usr/local/bin/setup-network" >> airootfs/usr/local/bin/firstboot.sh

# Make the build
echo "==> Verifying configuration before building"
# Check if necessary directories exist
for dir in airootfs/etc/skel/.config/{hypr,fish,waybar,wofi,foot}; do
    if [ ! -d "$dir" ]; then
        echo "ERROR: Directory $dir is missing!"
        exit 1
    fi
done

# Check if necessary files exist
for file in packages.x86_64 airootfs/root/customize_airootfs.sh; do
    if [ ! -f "$file" ]; then
        echo "ERROR: File $file is missing!"
        exit 1
    fi
done

echo "==> Building ISO"
mkdir -p "$OUT_DIR"
mkarchiso -v -w work -o "$OUT_DIR" .

echo "==> Done! ISO created at $OUT_DIR/"
echo "==> Remember to test the ISO in a virtual machine before using it."