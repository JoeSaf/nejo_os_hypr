#!/bin/bash

# Path to wallpapers
WALLPAPER_DIR="/usr/share/backgrounds/nejo"

# Check if the wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Check if any supported wallpapers exist
WALLPAPERS=($WALLPAPER_DIR/*.{jpg,jpeg,png})
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Select a random wallpaper
RANDOM_WALLPAPER=${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}

# Check if swww is running, if not initialize it
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww init
    sleep 1
fi

# Set the wallpaper with a smooth transition
swww img "$RANDOM_WALLPAPER" --transition-type grow --transition-fps 60 --transition-duration 2

