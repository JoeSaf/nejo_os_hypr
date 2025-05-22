# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
alias ls='ls -la --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ip='ip -c'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rs'
alias search='pacman -Ss'

# Set the PS1 prompt
PS1='\[\e[0;32m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] '

# Add /usr/local/bin to PATH
export PATH=$PATH:/usr/local/bin

# Run fastfetch on shell start
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi
