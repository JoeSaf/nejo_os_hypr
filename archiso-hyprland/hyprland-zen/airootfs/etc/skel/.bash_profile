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
