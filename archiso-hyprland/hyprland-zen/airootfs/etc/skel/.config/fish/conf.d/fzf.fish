# Only source fzf scripts if they exist
if test -d /usr/share/fzf
    if test -f /usr/share/fzf/key-bindings.fish
        source /usr/share/fzf/key-bindings.fish
    end
    if test -f /usr/share/fzf/completion.fish
        source /usr/share/fzf/completion.fish
    end
end
