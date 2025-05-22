function random_fastfetch
    # Directory with ASCII art
    set ASCII_DIR "$HOME/.config/fastfetch/ascii-art"
    
    # Check if directory exists and has files
    if not test -d "$ASCII_DIR"
        fastfetch
        return
    end
    
    # Get list of art files
    set ART_FILES $ASCII_DIR/*.txt
    
    # Check if any files exist
    if test (count $ART_FILES) -eq 0
        fastfetch
        return
    end
    
    # Pick a random file
    set RANDOM_INDEX (random 1 (count $ART_FILES))
    set SELECTED_FILE $ART_FILES[$RANDOM_INDEX]
    
    # Run fastfetch with the selected art
    fastfetch -l "$SELECTED_FILE" --logo-width 32 --color-keys green
end
