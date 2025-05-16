#!/bin/bash
# Script to integrate skeleton setup with the build process

# Run the skeleton setup script
./setup_skeleton_dir.sh

# Update the customize_airootfs.sh script to copy skel to the liveuser
if [ -f "airootfs/root/customize_airootfs.sh" ]; then
    # Check if the copy command already exists in the script
    if ! grep -q "cp -a /etc/skel/. /home/liveuser/" "airootfs/root/customize_airootfs.sh"; then
        # Find the line where liveuser ownership is set
        sed -i '/chown -R liveuser:liveuser \/home\/liveuser/i \
# Copy skeleton directory contents to liveuser home\
cp -a /etc/skel/. /home/liveuser/' "airootfs/root/customize_airootfs.sh"
        echo "Updated customize_airootfs.sh to copy skel directory to liveuser"
    else
        echo "customize_airootfs.sh already contains the copy skel command"
    fi
else
    echo "Error: customize_airootfs.sh not found in airootfs/root/"
    exit 1
fi

echo "Skeleton directory integrated with build process"
echo "Run './build.sh' to rebuild the ISO with the new configuration"
