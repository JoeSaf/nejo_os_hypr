# NeJo-Arch Hyprland Edition 
## The following is the guidline to building using these scripts:

- for the first build, run 'build.sh' it will setup a set of common packcages, pacman.conf, the liveuser, and all other necessary initial xfce requirements under sddm

- to setup the user-skel directory,first run 'setup_skeleton_dir.sh' then run 'intergrate_skel.sh', this will execute and setup all necessary directories, permissions, symlink and add to the customize_airootfs,sh in the root dir

- since the skel dir will be created as root, inorder to return it to the user, run 'make_skel_user_owned.sh', this will change all permisions of the skel dir from root to user, allowing you to make regular edits


### Resizing the iso ram
- open and edit the 'resize_iso_ram.sh' currently the iso is set to run and build with 4G but if u want a lower value, just edit and run the script and it will do the rest for you

## WARNING!!!
- Running the 'build.sh' will format all your mods back to defaults so instead if your just rebuilding the iso run 'continous_rebuilding.sh -v' this will verbosely make your iso while preserving all your changes

### Branding
- branding of the iso will be found in the grub and syslinux directories, its well ordered so have no fear its straight foward.

- the following locations are where you will edit the live system

	-> skel, holds all to be seen in the live environment

	-> edit booted wallpapers in customize_airootfs.sh

	-> edit sddm wallpapers in customize_airootfs.sh

	-> edit the bootloader image in syslinux dir

	-> edit the branding of the iso in the grub

## Things to do:
- create a local repo in your pc and in there dump calamares and any other packages. 
- Calamares installer isn't available in the arch repo and so adding it to your packages.x86_64 will only cause build error telling your package not found.
- Look up online or use ai to guide you on properly setting up calamares for your branding
- Inside 'airootfs/etc/' the re is a branding file there named 'os-release' if you don't edit it it will always overide your syslinux changes, and also it a personal branding file for anyone to use, so you can edit it to suite your needs

## I'm still building this, so carefull. It's a working progress
