#!/bin/bash
# Script to make the skeleton directory owned by the current user
# for easier development and modification

set -e  # Exit on error

# Get current user (the one who launched sudo)
if [ -n "$SUDO_USER" ]; then
    CURRENT_USER="$SUDO_USER"
else
    CURRENT_USER="$(whoami)"
fi

# Working directory - expected to be the archiso config directory
WORK_DIR="$(pwd)"
SKEL_DIR="$WORK_DIR/airootfs/etc/skel"

echo "Setting ownership of skeleton directory to $CURRENT_USER..."

# Ensure the skel directory exists
if [ -d "$SKEL_DIR" ]; then
    # Change ownership of the skel directory to the current user
    chown -R "$CURRENT_USER:$CURRENT_USER" "$SKEL_DIR"
    echo "Ownership of $SKEL_DIR changed to $CURRENT_USER:$CURRENT_USER"
    
    # Set appropriate permissions
    chmod -R u+rw "$SKEL_DIR"
    find "$SKEL_DIR" -type d -exec chmod u+x {} \;
    
    echo "Permissions set to allow full modification by $CURRENT_USER"
else
    echo "Error: Skeleton directory not found at $SKEL_DIR"
    echo "Creating the directory structure..."
    
    # Create the skel directory if it doesn't exist
    mkdir -p "$SKEL_DIR"
    chown -R "$CURRENT_USER:$CURRENT_USER" "$SKEL_DIR"
    chmod -R u+rwx "$SKEL_DIR"
    
    echo "Created $SKEL_DIR with ownership $CURRENT_USER:$CURRENT_USER"
fi

# Ensure customize_airootfs.sh handles ownership correctly
CUSTOMIZE_SCRIPT="$WORK_DIR/airootfs/root/customize_airootfs.sh"

if [ -f "$CUSTOMIZE_SCRIPT" ]; then
    echo "Ensuring customize_airootfs.sh handles ownership correctly..."
    
    # Temporarily change ownership of the script to modify it
    ORIG_OWNER=$(stat -c "%U:%G" "$CUSTOMIZE_SCRIPT")
    chown "$CURRENT_USER:$CURRENT_USER" "$CUSTOMIZE_SCRIPT"
    
    # Check if the script has the correct ownership transfer command
    if ! grep -q "chown -R liveuser:liveuser /home/liveuser" "$CUSTOMIZE_SCRIPT"; then
        # If not found, add the command
        if grep -q "cp -a /etc/skel/. /home/liveuser/" "$CUSTOMIZE_SCRIPT"; then
            # Add after the cp command
            sed -i '/cp -a \/etc\/skel\/. \/home\/liveuser\//a \
# Fix ownership for the liveuser home directory\
chown -R liveuser:liveuser /home/liveuser/' "$CUSTOMIZE_SCRIPT"
        else
            # If no cp command, add the whole block
            echo -e "\n# Copy skeleton to liveuser home and fix ownership\ncp -a /etc/skel/. /home/liveuser/\nchown -R liveuser:liveuser /home/liveuser/" >> "$CUSTOMIZE_SCRIPT"
        fi
        echo "Updated customize_airootfs.sh to fix liveuser home ownership"
    else
        echo "customize_airootfs.sh already contains ownership correction"
    fi
    
    # Restore original ownership of the script
    chown "$ORIG_OWNER" "$CUSTOMIZE_SCRIPT"
fi

echo "Done! You can now modify the files in $SKEL_DIR without sudo."
echo "Remember that when the ISO is built, the files will be properly handled."
echo "No need to change ownership back to root - the ISO build process will handle it correctly."
