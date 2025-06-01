#!/bin/bash

# Simple Wallpaper Selector with Dynamic Theming
# Uses fuzzel for selection, swww for wallpaper, and matugen for theming

WALLPAPERS_DIR="$HOME/dotfiles/assets/wallpapers"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
THEME_SCRIPT="$SCRIPT_DIR/wallpaper-theme-changer.sh"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /tmp/wallpaper-selector.log
}

# Function to get wallpaper list for fuzzel
get_wallpaper_list() {
    find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort
}

# Function to format wallpaper names for display
format_for_display() {
    while read -r wallpaper; do
        basename "$wallpaper"
    done
}

# Main execution
main() {
    log_message "=== Wallpaper Selector Started ==="
    
    # Check if swww is running
    if ! pgrep -x swww-daemon > /dev/null; then
        log_message "Starting swww daemon..."
        swww init
        sleep 1
    fi
    
    # Get wallpaper list and show fuzzel selector
    log_message "Showing wallpaper selector..."
    wallpaper_list=$(get_wallpaper_list)
    
    if [ -z "$wallpaper_list" ]; then
        log_message "Error: No wallpapers found in $WALLPAPERS_DIR"
        notify-send "Wallpaper Selector" "No wallpapers found in directory" -u critical
        exit 1
    fi
    
    # Show fuzzel with wallpaper names
    selected_name=$(echo "$wallpaper_list" | format_for_display | fuzzel --dmenu --prompt="Select Wallpaper: ")
    
    if [ -z "$selected_name" ]; then
        log_message "No wallpaper selected, exiting"
        exit 0
    fi
    
    # Find the full path of selected wallpaper
    selected_wallpaper=$(echo "$wallpaper_list" | grep "/$selected_name$")
    
    if [ ! -f "$selected_wallpaper" ]; then
        log_message "Error: Selected wallpaper not found: $selected_wallpaper"
        notify-send "Wallpaper Selector" "Selected wallpaper not found" -u critical
        exit 1
    fi
    
    log_message "Selected wallpaper: $selected_wallpaper"
    
    # Set wallpaper with swww
    log_message "Setting wallpaper with swww..."
    if swww img "$selected_wallpaper" --transition-type wipe --transition-duration 2; then
        log_message "Wallpaper set successfully"
    else
        log_message "Error: Failed to set wallpaper"
        notify-send "Wallpaper Selector" "Failed to set wallpaper" -u critical
        exit 1
    fi
    
    # Apply dynamic theming
    log_message "Applying dynamic theme..."
    if [ -x "$THEME_SCRIPT" ]; then
        "$THEME_SCRIPT" "$selected_wallpaper"
        if [ $? -eq 0 ]; then
            log_message "Theme applied successfully"
            notify-send "Theme Updated" "Wallpaper and theme changed to $(basename "$selected_wallpaper")" -i "$selected_wallpaper"
        else
            log_message "Theme application failed"
            notify-send "Theme Update Failed" "Wallpaper changed but theme failed" -u normal
        fi
    else
        log_message "Warning: Theme script not found or not executable: $THEME_SCRIPT"
        notify-send "Wallpaper Changed" "Wallpaper set to $(basename "$selected_wallpaper")" -i "$selected_wallpaper"
    fi
    
    log_message "=== Wallpaper Selector Finished ==="
}

# Run main function
main "$@" 