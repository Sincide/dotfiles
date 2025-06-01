#!/bin/bash

# Wallpaper Restoration Script for Hyprland Startup
# Restores the last selected wallpaper from saved state

LAST_WALLPAPER_FILE="$HOME/.config/dynamic-theming/last-wallpaper"
DEFAULT_WALLPAPER="$HOME/dotfiles/assets/wallpapers/dark/evilpuccin.png"
TRANSITION_ENGINE="$HOME/dotfiles/scripts/transition-engine.sh"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /tmp/wallpaper-restore.log
}

# Main restoration function
restore_wallpaper() {
    log_message "=== Wallpaper Restoration Started ==="
    
    # Start swww daemon
    log_message "Starting swww daemon..."
    swww-daemon &
    sleep 2
    
    # Determine which wallpaper to use
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        last_wallpaper=$(cat "$LAST_WALLPAPER_FILE")
        
        if [ -f "$last_wallpaper" ]; then
            log_message "Restoring last wallpaper: $last_wallpaper"
            target_wallpaper="$last_wallpaper"
        else
            log_message "Last wallpaper not found: $last_wallpaper, using default"
            target_wallpaper="$DEFAULT_WALLPAPER"
        fi
    else
        log_message "No saved wallpaper found, using default"
        target_wallpaper="$DEFAULT_WALLPAPER"
    fi
    
    # Generate startup transition
    local transition_params=""
    if [ -x "$TRANSITION_ENGINE" ]; then
        transition_params=$("$TRANSITION_ENGINE" "$target_wallpaper" "startup")
        log_message "Using dynamic startup transition: $transition_params"
    else
        transition_params="--transition-type fade --transition-duration 1"
        log_message "Using fallback startup transition: $transition_params"
    fi
    
    # Set wallpaper with dynamic transition
    if swww img "$target_wallpaper" $transition_params; then
        log_message "Wallpaper restored successfully: $(basename "$target_wallpaper")"
    else
        log_message "Error: Failed to restore wallpaper"
    fi
    
    log_message "=== Wallpaper Restoration Finished ==="
}

# Run restoration
restore_wallpaper "$@" 