function update-mirrors --description "Update pacman mirrors to fastest"
    sudo pacman -Syy
    sudo pacman -S --needed reflector
    sudo reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    sudo pacman -Syy
end
