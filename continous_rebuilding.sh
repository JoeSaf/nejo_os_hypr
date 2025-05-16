#!/bin/bash
# Archiso build script

# Set the configuration directory
CONFIG_DIR="$(pwd)"

# Ensure the build environment is set up
if [[ ! -d "$CONFIG_DIR/airootfs" ]]; then
    echo "Error: airootfs directory not found!"
    exit 1
fi

# Create the ISO
mkarchiso -v .

