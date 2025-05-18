#!/bin/bash

# Wait for Hyprland to fully initialize
sleep 3

# Initialize swww if not already running
if ! pgrep swww-daemon > /dev/null; then
    swww init
    sleep 1
fi

# Set a specific default wallpaper
DEFAULT_WALLPAPER="/usr/share/backgrounds/nejo/ign_cityRainOther.png"

# If the default doesn't exist but there are other wallpapers, use one of those
if [ ! -f "$DEFAULT_WALLPAPER" ]; then
    DEFAULT_WALLPAPER=$(find /usr/share/backgrounds/nejo -type f -name "*.jpg" -o -name "*.png" | head -n1)
fi

# Apply the wallpaper
if [ -f "$DEFAULT_WALLPAPER" ]; then
    swww img "$DEFAULT_WALLPAPER" --transition-type none
    echo "Set default wallpaper: $DEFAULT_WALLPAPER"
else
    echo "No wallpaper found to set"
fi
