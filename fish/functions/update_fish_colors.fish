function update_fish_colors --description 'Update fish colors to match current theme'
    # This function can be called by your dynamic theme switcher
    # to update fish colors based on the current wallpaper/theme
    
    # Default Evil Space theme colors
    set -U fish_color_autosuggestion brblack
    set -U fish_color_cancel -r
    set -U fish_color_command brblue
    set -U fish_color_comment brblack
    set -U fish_color_cwd green
    set -U fish_color_cwd_root red
    set -U fish_color_end brgreen
    set -U fish_color_error brred
    set -U fish_color_escape brcyan
    set -U fish_color_history_current --bold
    set -U fish_color_host normal
    set -U fish_color_host_remote yellow
    set -U fish_color_normal normal
    set -U fish_color_operator brcyan
    set -U fish_color_param cyan
    set -U fish_color_quote yellow
    set -U fish_color_redirection cyan --bold
    set -U fish_color_search_match bryellow --background=brblack
    set -U fish_color_selection white --bold --background=brblack
    set -U fish_color_status red
    set -U fish_color_user brgreen
    set -U fish_color_valid_path --underline
    
    # Pager colors
    set -U fish_pager_color_completion normal
    set -U fish_pager_color_description B3A06D yellow -i
    set -U fish_pager_color_prefix normal --bold --underline
    set -U fish_pager_color_progress brwhite --background=cyan
    set -U fish_pager_color_selected_background -r
    
    echo "Fish colors updated to match Evil Space theme"
end 