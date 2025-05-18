#!/bin/bash

# Create user systemd directory if it doesn't exist
mkdir -p ~/.config/systemd/user/

# Copy service and timer files if they don't exist
if [ ! -f ~/.config/systemd/user/wallpaper-changer.service ]; then
    cp /etc/skel/.config/systemd/user/wallpaper-changer.service ~/.config/systemd/user/
fi

if [ ! -f ~/.config/systemd/user/wallpaper-changer.timer ]; then
    cp /etc/skel/.config/systemd/user/wallpaper-changer.timer ~/.config/systemd/user/
fi

# Enable and start the timer
systemctl --user daemon-reload
systemctl --user enable --now wallpaper-changer.timer
systemctl --user start wallpaper-changer.service
