#!/bin/bash

# Enhanced Wallpaper Selector with Categories and Dynamic Theming
# Uses fuzzel for selection, swww for wallpaper, and matugen for theming

WALLPAPERS_DIR="$HOME/dotfiles/assets/wallpapers"
# Use absolute path to avoid issues when running from different contexts
SCRIPT_DIR="$HOME/dotfiles/scripts"
THEME_SCRIPT="$SCRIPT_DIR/wallpaper-theme-changer-optimized.sh"
TRANSITION_ENGINE="$SCRIPT_DIR/transition-engine.sh"
# State file to remember last wallpaper
LAST_WALLPAPER_FILE="$HOME/.config/dynamic-theming/last-wallpaper"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /tmp/wallpaper-selector.log
}

# Function to save last wallpaper for startup restoration
save_last_wallpaper() {
    local wallpaper_path="$1"
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$LAST_WALLPAPER_FILE")"
    
    # Save wallpaper path
    echo "$wallpaper_path" > "$LAST_WALLPAPER_FILE"
    log_message "Saved last wallpaper: $wallpaper_path"
}



# Function to get available categories
get_categories() {
    find "$WALLPAPERS_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r category_path; do
        category_name=$(basename "$category_path")
        wallpaper_count=$(find "$category_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | wc -l)
        if [ "$wallpaper_count" -gt 0 ]; then
            echo "$category_name ($wallpaper_count)"
        fi
    done | sort
}

# Function to get wallpapers from a specific category
get_wallpapers_from_category() {
    local category="$1"
    find "$WALLPAPERS_DIR/$category" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort
}

# Function to get all wallpapers (for "All Wallpapers" option)
get_all_wallpapers() {
    find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort
}

# Function to format wallpaper names for display
format_for_display() {
    while read -r wallpaper; do
        basename "$wallpaper"
    done
}

# Function to show category selection
show_category_menu() {
    log_message "Showing category menu..."
    
    # Get categories with wallpaper counts
    categories=$(get_categories)
    
    if [ -z "$categories" ]; then
        log_message "Error: No categories with wallpapers found"
        notify-send "Wallpaper Selector" "No wallpapers found in any category" -u critical
        return 1
    fi
    
    # Add "All Wallpapers" option at the top
    all_count=$(get_all_wallpapers | wc -l)
    category_options="All Wallpapers ($all_count)
$categories"
    
    # Show fuzzel with categories
    selected_category=$(echo "$category_options" | fuzzel --dmenu --prompt="Select Category: ")
    
    if [ -z "$selected_category" ]; then
        log_message "No category selected, exiting"
        return 1
    fi
    
    # Extract category name (remove count)
    category_name=$(echo "$selected_category" | sed 's/ (.*)$//')
    log_message "Selected category: $category_name"
    echo "$category_name"
}

# Function to show wallpaper selection within a category
show_wallpaper_menu() {
    local category="$1"
    
    log_message "Showing wallpapers for category: $category"
    
    # Get wallpapers based on category
    if [ "$category" = "All Wallpapers" ]; then
        wallpaper_list=$(get_all_wallpapers)
    else
        wallpaper_list=$(get_wallpapers_from_category "$category")
    fi
    
    if [ -z "$wallpaper_list" ]; then
        log_message "Error: No wallpapers found in category: $category"
        notify-send "Wallpaper Selector" "No wallpapers found in $category" -u critical
        return 1
    fi
    
    # Show fuzzel with wallpaper names
    selected_name=$(echo "$wallpaper_list" | format_for_display | fuzzel --dmenu --prompt="Select Wallpaper from $category: ")
    
    if [ -z "$selected_name" ]; then
        log_message "No wallpaper selected, exiting"
        return 1
    fi
    
    # Find the full path of selected wallpaper
    selected_wallpaper=$(echo "$wallpaper_list" | grep "/$selected_name$")
    
    if [ ! -f "$selected_wallpaper" ]; then
        log_message "Error: Selected wallpaper not found: $selected_wallpaper"
        notify-send "Wallpaper Selector" "Selected wallpaper not found" -u critical
        return 1
    fi
    
    log_message "Selected wallpaper: $selected_wallpaper"
    echo "$selected_wallpaper"
}

# Function to set wallpaper and apply theme
apply_wallpaper_and_theme() {
    local wallpaper_path="$1"
    
    log_message "Setting wallpaper: $wallpaper_path"
    
    # Generate dynamic transition parameters
    local transition_params=""
    if [ -x "$TRANSITION_ENGINE" ]; then
        transition_params=$("$TRANSITION_ENGINE" "$wallpaper_path" "category")
        log_message "Using dynamic transition: $transition_params"
    else
        transition_params="--transition-type wipe --transition-duration 2"
        log_message "Using fallback transition: $transition_params"
    fi
    
    # Set wallpaper with swww and dynamic transitions
    if swww img "$wallpaper_path" $transition_params; then
        log_message "Wallpaper set successfully"
        
        # Save wallpaper for startup restoration
        save_last_wallpaper "$wallpaper_path"
        
        # Verify wallpaper applied to all monitors
        sleep 1
        monitor_count=$(swww query | wc -l)
        if [ "$monitor_count" -gt 0 ]; then
            log_message "Wallpaper verified on $monitor_count monitor(s)"
        else
            log_message "Warning: Could not verify wallpaper application"
        fi
    else
        log_message "Error: Failed to set wallpaper"
        notify-send "Wallpaper Selector" "Failed to set wallpaper" -u critical
        return 1
    fi
    
    # Apply dynamic theming
    log_message "Applying dynamic theme..."
    if [ -x "$THEME_SCRIPT" ]; then
        "$THEME_SCRIPT" "$wallpaper_path" "force"
        if [ $? -eq 0 ]; then
            log_message "Theme applied successfully"
            notify-send "Theme Updated" "Wallpaper and theme changed to $(basename "$wallpaper_path")" -i "$wallpaper_path"
        else
            log_message "Theme application failed"
            notify-send "Theme Update Failed" "Wallpaper changed but theme failed" -u normal
        fi
    else
        log_message "Warning: Theme script not found or not executable: $THEME_SCRIPT"
        notify-send "Wallpaper Changed" "Wallpaper set to $(basename "$wallpaper_path")" -i "$wallpaper_path"
    fi
}

# Main execution
main() {
    log_message "=== Enhanced Wallpaper Selector Started ==="
    
    # Enhanced swww daemon management with recovery
    log_message "Checking swww daemon status..."
    
    if ! pgrep -x swww-daemon > /dev/null; then
        log_message "swww daemon not running, starting..."
        swww-daemon &
        sleep 2
        log_message "swww daemon started"
    else
        # Check if daemon is responsive by testing query
        if ! swww query &>/dev/null; then
            log_message "swww daemon unresponsive, restarting..."
            swww kill &>/dev/null
            sleep 2
            swww-daemon &
            sleep 2
            log_message "swww daemon restarted"
        else
            log_message "swww daemon running and responsive"
        fi
    fi
    
    # Step 1: Show category selection
    selected_category=$(show_category_menu)
    if [ $? -ne 0 ] || [ -z "$selected_category" ]; then
        log_message "Category selection failed or cancelled"
        exit 1
    fi
    
    # Step 2: Show wallpaper selection within category
    selected_wallpaper=$(show_wallpaper_menu "$selected_category")
    if [ $? -ne 0 ] || [ -z "$selected_wallpaper" ]; then
        log_message "Wallpaper selection failed or cancelled"
        exit 1
    fi
    
    # Step 3: Apply wallpaper and theme
    apply_wallpaper_and_theme "$selected_wallpaper"
    if [ $? -eq 0 ]; then
        log_message "=== Enhanced Wallpaper Selector Finished Successfully ==="
    else
        log_message "=== Enhanced Wallpaper Selector Finished with Errors ==="
        exit 1
    fi
}

# Run main function
main "$@" 