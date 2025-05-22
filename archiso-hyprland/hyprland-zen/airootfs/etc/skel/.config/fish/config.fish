# Startup message
function fish_greeting
    echo "Welcome to NeJo Arch Linux Hyprland Live Environment!"
    echo "- Username: liveuser"
    echo "- Password: liveuser"
    echo "- Type 'sudo' to get root privileges without password"
end

# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL foot
set -gx BROWSER firefox
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DATA_HOME $HOME/.local/share

# Hyprland environment variables
set -gx XDG_SESSION_TYPE wayland
set -gx XDG_SESSION_DESKTOP Hyprland
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx GDK_BACKEND wayland,x11
set -gx QT_QPA_PLATFORM wayland
set -gx SDL_VIDEODRIVER wayland
set -gx JAVA_AWT_WM_NONREPARENTING 1

# Path
fish_add_path $HOME/.local/bin

# Aliases
alias ls='exa --icons -la'
alias ll='exa --icons -la'
alias la='exa --icons -a'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
alias vim='nvim'
alias please='sudo'
alias refresh='source ~/.config/fish/config.fish'
alias startdesktop='exec Hyprland'

# Run random ASCII art fastfetch on shell start
function run_fastfetch
    # Define the directory containing ASCII art files
    set ASCII_DIR "$HOME/.config/fastfetch/ascii-art"
    
    # If ASCII art directory doesn't exist or is empty, use regular fastfetch
    if not test -d "$ASCII_DIR"; or test (count "$ASCII_DIR"/*.txt) -eq 0
        if command -v fastfetch > /dev/null 2>&1
            fastfetch --color-keys green
        end
        return
    end
    
    # Get a random ASCII art file
    set ASCII_FILES "$ASCII_DIR"/*.txt
    set RANDOM_INDEX (random 1 (count $ASCII_FILES))
    set SELECTED_FILE $ASCII_FILES[$RANDOM_INDEX]
    
    # Run fastfetch with the selected ASCII art file
    if command -v fastfetch > /dev/null 2>&1
        fastfetch -l "$SELECTED_FILE" --logo-width 32 --color-keys green
    end
end

# Call the function to run fastfetch
run_fastfetch

# Enable starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Enable fzf keybindings - with error handling
if test -d /usr/share/fzf
    # Source key bindings safely
    set -l key_bindings_file /usr/share/fzf/key-bindings.fish
    if test -f $key_bindings_file
        source $key_bindings_file 2>/dev/null
    end
    
    # Source completion safely
    set -l completion_file /usr/share/fzf/completion.fish
    if test -f $completion_file
        source $completion_file 2>/dev/null
    end
end

# Setup completions
if test -d ~/.config/fish/completions
    for file in ~/.config/fish/completions/*.fish
        if test -f $file
            source $file
        end
    end
end

# Add autocompletion for git
if command -v git > /dev/null
    set -l git_completion_path (dirname (dirname (command -v git)))/share/git/completions/git-completion.bash
    if test -f $git_completion_path
        bash -c "source $git_completion_path && complete -p git" | string replace -r '^complete (.+) git$' 'complete -c git $1' | source
    end
end

# Add Pacman completion
function __fish_complete_pacman
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    
    # Simplified pacman completions
    switch $cmd[2]
        case '-S' '--sync'
            command pacman -Ssq | sort | uniq
        case '-R' '--remove'
            command pacman -Qsq | sort | uniq
        case '-Q' '--query'
            command pacman -Qsq | sort | uniq
    end
end

complete -c pacman -n "__fish_complete_pacman" -a "(__fish_complete_pacman)"

# Add systemctl completion
function __fish_complete_systemctl_units
    systemctl list-units --all --no-legend --no-pager | string replace -r '●\s+' '' | string replace -r '\s+loaded.*$' '' | string match -v '*.*'
end

complete -c systemctl -n "__fish_seen_subcommand_from start stop restart enable disable status" -a "(__fish_complete_systemctl_units)"