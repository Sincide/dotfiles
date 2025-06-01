#!/bin/bash

# Wallpaper Restoration Script for Hyprland Startup
# Restores the last selected wallpaper AND applies full theme on startup

LAST_WALLPAPER_FILE="$HOME/.config/dynamic-theming/last-wallpaper"
DEFAULT_WALLPAPER="$HOME/dotfiles/assets/wallpapers/dark/evilpuccin.png"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
THEME_CHANGER="$DOTFILES_DIR/scripts/wallpaper-theme-changer-optimized.sh"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /tmp/wallpaper-restore.log
}

# Function to ensure swww daemon is running
ensure_swww_daemon() {
    log_message "Checking swww daemon status..."
    
    # Check if daemon is already running
    if pgrep -x "swww-daemon" > /dev/null; then
        log_message "swww-daemon already running, checking responsiveness..."
        
        # Test if daemon is responsive
        if swww query &>/dev/null; then
            log_message "✅ swww-daemon is running and responsive"
            return 0
        else
            log_message "⚠️ swww-daemon running but unresponsive, restarting..."
            pkill -x swww-daemon 2>/dev/null || true
            sleep 1
        fi
    fi
    
    # Start daemon if not running or was unresponsive
    log_message "Starting swww daemon..."
    swww-daemon &
    sleep 2
    
    # Verify daemon started successfully
    if swww query &>/dev/null; then
        log_message "✅ swww-daemon started successfully"
        return 0
    else
        log_message "❌ Failed to start swww-daemon"
        return 1
    fi
}

# Main restoration function
restore_wallpaper() {
    log_message "=== Wallpaper + Theme Restoration Started ==="
    
    # Ensure swww daemon is running and responsive
    if ! ensure_swww_daemon; then
        log_message "❌ Cannot proceed without working swww daemon"
        return 1
    fi
    
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
    
    # Load AI configuration for startup
    local ai_config_file="$DOTFILES_DIR/config/dynamic-theming/ai-config.conf"
    if [ -f "$ai_config_file" ]; then
        source "$ai_config_file"
        log_message "AI config loaded: ENABLE_AI_OPTIMIZATION=$ENABLE_AI_OPTIMIZATION"
        export ENABLE_AI_OPTIMIZATION
    fi
    
    # Apply wallpaper AND full theme using the optimized theme changer
    log_message "Applying wallpaper and theme using optimized changer..."
    
    if [ -x "$THEME_CHANGER" ]; then
        # Use "startup" as force flag to ensure fresh theme generation
        if "$THEME_CHANGER" "$target_wallpaper" "startup" > /tmp/wallpaper-theme-startup.log 2>&1; then
            log_message "✅ Wallpaper and theme restored successfully: $(basename "$target_wallpaper")"
            log_message "Theme restoration details: /tmp/wallpaper-theme-startup.log"
        else
            log_message "❌ Error: Failed to restore wallpaper and theme"
            log_message "Check /tmp/wallpaper-theme-startup.log for details"
            
            # Fallback: At least set the wallpaper
            log_message "Attempting fallback wallpaper-only restoration..."
            if swww img "$target_wallpaper" --transition-type fade --transition-duration 1; then
                log_message "Fallback wallpaper set successfully"
            else
                log_message "Fallback wallpaper setting also failed"
            fi
        fi
    else
        log_message "❌ Error: Theme changer not found: $THEME_CHANGER"
        
        # Fallback: Simple wallpaper setting
        log_message "Attempting simple wallpaper restoration..."
        if swww img "$target_wallpaper" --transition-type fade --transition-duration 1; then
            log_message "Simple wallpaper restored successfully: $(basename "$target_wallpaper")"
        else
            log_message "Error: Failed to restore wallpaper"
        fi
    fi
    
    log_message "=== Wallpaper + Theme Restoration Finished ==="
}

# Run restoration
restore_wallpaper "$@" 