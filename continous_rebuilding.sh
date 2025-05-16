#!/bin/bash
# Archiso build script

# Set the configuration directory
CONFIG_DIR="$(pwd)/archiso-hyprland/hyprland-zen"
OUT_DIR="$(pwd)/out"

# Ensure the build environment is set up
if [[ ! -d "$CONFIG_DIR/airootfs" ]]; then
    echo "Error: airootfs directory not found!"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

# Create the ISO
sudo mkarchiso -v -w work -o "$OUT_DIR" "$CONFIG_DIR"
