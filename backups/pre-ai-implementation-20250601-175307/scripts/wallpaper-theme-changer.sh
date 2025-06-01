#!/bin/bash

# Dynamic Wallpaper Theme Changer
# Integrates Waypaper with Matugen for automatic theming

WALLPAPER_PATH="$1"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /tmp/wallpaper-theme.log
}

# Function to reload applications
reload_applications() {
    log_message "Reloading applications with new theme..."
    
    # Restart Waybar (both bars)
    if pgrep -x waybar > /dev/null; then
        log_message "Restarting Waybar..."
        # Send reload signal first (gentle restart)
        pkill -SIGUSR2 waybar 2>/dev/null
        sleep 1
        
        # If that doesn't work, force restart
        if pgrep -x waybar > /dev/null; then
            log_message "Force restarting Waybar..."
            pkill -TERM waybar
            sleep 2
            # Start main waybar with dynamic theme
            if waybar -s ~/.config/waybar/style-dynamic.css &>/tmp/waybar-main.log & then
                log_message "Started main Waybar"
            else
                log_message "Failed to start main Waybar - check /tmp/waybar-main.log"
            fi
            
            # Start bottom waybar with dynamic theme  
            if waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css &>/tmp/waybar-bottom.log & then
                log_message "Started bottom Waybar"
            else
                log_message "Failed to start bottom Waybar - check /tmp/waybar-bottom.log"
            fi
            
            sleep 1
            # Verify waybar is actually running
            if pgrep -x waybar > /dev/null; then
                log_message "Waybar instances restarted successfully"
            else
                log_message "Warning: Waybar failed to start (not in Wayland environment?)"
            fi
        else
            log_message "Waybar reloaded with SIGUSR2"
        fi
    else
        log_message "Waybar not running, starting new instances..."
        # Start waybar instances if not running
        waybar -s ~/.config/waybar/style-dynamic.css > /dev/null 2>&1 &
        waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css > /dev/null 2>&1 &
        log_message "Waybar instances started"
    fi
    
    # Restart Dunst
    if pgrep -x dunst > /dev/null; then
        log_message "Restarting Dunst..."
        pkill dunst
        sleep 0.5
        dunst -config ~/.config/dunst/dunstrc-dynamic &
    fi
    
    # Update Kitty colors for all running instances
    if pgrep -x kitty > /dev/null; then
        log_message "Updating Kitty terminal colors..."
        # Send signal to all kitty instances to reload config
        pkill -USR1 kitty
    fi
    
    # Update Fuzzel colors (copy from generated dynamic config)
    if [ -f ~/.config/fuzzel/fuzzel-dynamic.ini ]; then
        log_message "Updating Fuzzel launcher colors..."
        # Simple approach: extract and replace colors section
        python3 -c "
import re
import sys

# Read both files
try:
    with open('$HOME/.config/fuzzel/fuzzel.ini', 'r') as f:
        main_config = f.read()
    with open('$HOME/.config/fuzzel/fuzzel-dynamic.ini', 'r') as f:
        dynamic_config = f.read()
    
    # Extract colors section from dynamic config
    colors_match = re.search(r'\[colors\].*?(?=\n\[|\Z)', dynamic_config, re.DOTALL)
    if colors_match:
        new_colors = colors_match.group(0)
        # Replace colors section in main config
        main_config = re.sub(r'\[colors\].*?(?=\n\[|\Z)', new_colors, main_config, flags=re.DOTALL)
        
        # Write back to main config
        with open('$HOME/.config/fuzzel/fuzzel.ini', 'w') as f:
            f.write(main_config)
        print('Fuzzel colors updated successfully')
    else:
        print('No colors section found in dynamic config')
except Exception as e:
    print(f'Error updating fuzzel colors: {e}')
"
    fi
    
    # Reload Hyprland configuration
    if command -v hyprctl > /dev/null; then
        log_message "Reloading Hyprland configuration..."
        hyprctl reload
    fi
    
    log_message "Application reload complete"
}

# Function to generate theme from wallpaper
generate_theme() {
    local wallpaper="$1"
    
    if [ ! -f "$wallpaper" ]; then
        log_message "Error: Wallpaper file not found: $wallpaper"
        return 1
    fi
    
    log_message "Generating theme from wallpaper: $wallpaper"
    
    # Run matugen to generate colors and templates
    if command -v matugen > /dev/null; then
        matugen image "$wallpaper" --mode dark > /tmp/matugen.log 2>&1
        if [ $? -eq 0 ]; then
            log_message "Matugen theme generation successful"
            reload_applications
            return 0
        else
            log_message "Error: Matugen failed. Check /tmp/matugen.log"
            return 1
        fi
    else
        log_message "Error: Matugen not found. Please install it first."
        return 1
    fi
}

# Function to detect current wallpaper from swww
detect_current_wallpaper() {
    if command -v swww > /dev/null; then
        swww query 2>/dev/null | head -n1 | awk '{print $NF}'
    fi
}

# Main execution
main() {
    log_message "=== Wallpaper Theme Changer Started ==="
    
    # If no wallpaper provided, try to detect current wallpaper
    if [ -z "$WALLPAPER_PATH" ]; then
        WALLPAPER_PATH=$(detect_current_wallpaper)
        log_message "No wallpaper provided, detected current: $WALLPAPER_PATH"
    fi
    
    if [ -z "$WALLPAPER_PATH" ]; then
        log_message "Error: No wallpaper path provided or detected"
        exit 1
    fi
    
    # Generate theme from wallpaper
    if generate_theme "$WALLPAPER_PATH"; then
        log_message "Theme change completed successfully"
        
        # Send notification
        if command -v notify-send > /dev/null; then
            notify-send "Theme Updated" "Desktop theme adapted to wallpaper colors" -i "$WALLPAPER_PATH"
        fi
    else
        log_message "Theme change failed"
        
        # Send error notification
        if command -v notify-send > /dev/null; then
            notify-send "Theme Update Failed" "Could not generate theme from wallpaper" -u critical
        fi
        exit 1
    fi
    
    log_message "=== Wallpaper Theme Changer Finished ==="
}

# Run main function
main "$@" 