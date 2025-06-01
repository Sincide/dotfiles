#!/bin/bash

# Optimized Dynamic Wallpaper Theme Changer
# Target: Sub-2 second theme changes with parallel processing
# Version: Performance-Optimized

WALLPAPER_PATH="$1"
FORCE_REGENERATION="$2"  # Add force flag for manual wallpaper changes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Performance tracking
START_TIME=$(date +%s.%N)

# Function to log messages with timing
log_message() {
    local current_time=$(date +%s.%N)
    local elapsed=$(echo "$current_time - $START_TIME" | bc -l)
    printf "[%.3f] %s - %s\n" "$elapsed" "$(date '+%H:%M:%S')" "$1" >> /tmp/wallpaper-theme-optimized.log
}

# Function to reload applications in parallel (MAJOR OPTIMIZATION)
reload_applications_parallel() {
    log_message "Starting parallel application reloads..."
    
    # Start all reloads in background simultaneously
    (
        # Waybar reload (fixed - ensure both instances)
        log_message "Managing Waybar instances..."
        
        # Kill all existing waybar processes
        pkill waybar 2>/dev/null
        sleep 0.3
        
        # Start both waybar instances fresh
        log_message "Starting top waybar..."
        waybar -s ~/.config/waybar/style-dynamic.css &>/dev/null &
        sleep 0.2
        
        log_message "Starting bottom waybar..."
        waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css &>/dev/null &
        sleep 0.2
        
        # Verify both instances started
        waybar_count=$(pgrep -x waybar | wc -l)
        log_message "Waybar instances started: $waybar_count (should be 2)"
        
        if [ "$waybar_count" -eq 2 ]; then
            log_message "Waybar restart successful - both instances running"
        else
            log_message "Warning: Expected 2 waybar instances, got $waybar_count"
        fi
    ) &
    local waybar_pid=$!
    
    (
        # Dunst reload (fixed warnings)
        if pgrep -x dunst > /dev/null; then
            log_message "Restarting Dunst..."
            pkill dunst 2>/dev/null
            sleep 0.2
            # Start with fixed config (no deprecated options)
            dunst -config ~/.config/dunst/dunstrc-dynamic &>/dev/null &
            log_message "Dunst restart complete"
        fi
    ) &
    local dunst_pid=$!
    
    (
        # Kitty reload (fastest - just signal)
        if pgrep -x kitty > /dev/null; then
            log_message "Updating Kitty colors..."
            pkill -USR1 kitty
            log_message "Kitty color update complete"
        fi
    ) &
    local kitty_pid=$!
    
    (
        # Fuzzel color update (optimized)
        if [ -f ~/.config/fuzzel/fuzzel-dynamic.ini ]; then
            log_message "Updating Fuzzel colors..."
            python3 -c "
import re
try:
    with open('$HOME/.config/fuzzel/fuzzel.ini', 'r') as f:
        main_config = f.read()
    with open('$HOME/.config/fuzzel/fuzzel-dynamic.ini', 'r') as f:
        dynamic_config = f.read()
    
    colors_match = re.search(r'\[colors\].*?(?=\n\[|\Z)', dynamic_config, re.DOTALL)
    if colors_match:
        new_colors = colors_match.group(0)
        main_config = re.sub(r'\[colors\].*?(?=\n\[|\Z)', new_colors, main_config, flags=re.DOTALL)
        with open('$HOME/.config/fuzzel/fuzzel.ini', 'w') as f:
            f.write(main_config)
        print('ok')
    else:
        print('error: no colors section')
except Exception as e:
    print(f'error: {e}')
"
            log_message "Fuzzel color update complete"
        fi
    ) &
    local fuzzel_pid=$!
    
    (
        # Hyprland reload (instant)
        if command -v hyprctl > /dev/null; then
            log_message "Reloading Hyprland..."
            hyprctl reload &>/dev/null
            log_message "Hyprland reload complete"
        fi
    ) &
    local hyprland_pid=$!
    
    (
        # GTK theme reload (force application restart for theme changes)
        log_message "Triggering GTK theme reload..."
        
        # Clear GTK theme cache
        rm -rf ~/.cache/gtk-* 2>/dev/null
        
        # Force GTK theme reload by temporarily changing and restoring theme
        current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'catppuccin-mocha-blue-standard+default'")
        if [ -n "$current_theme" ] && [ "$current_theme" != "''" ]; then
            gsettings set org.gnome.desktop.interface gtk-theme ""
            sleep 0.1
            gsettings set org.gnome.desktop.interface gtk-theme "$current_theme"
            log_message "GTK theme reload complete"
        fi
        
        # Send signal to existing GTK applications to reload
        pkill -USR1 thunar 2>/dev/null || true
        
    ) &
    local gtk_pid=$!
    
    # Wait for all parallel operations to complete
    log_message "Waiting for parallel reloads to complete..."
    wait $waybar_pid $dunst_pid $kitty_pid $fuzzel_pid $hyprland_pid $gtk_pid
    
    log_message "All parallel application reloads completed"
}

# Function to check if theme regeneration is needed (CACHING OPTIMIZATION)
needs_theme_regeneration() {
    local wallpaper="$1"
    local cache_dir="$HOME/.cache/dynamic-theming"
    local wallpaper_hash=$(md5sum "$wallpaper" | cut -d' ' -f1)
    local cache_file="$cache_dir/last-theme-$wallpaper_hash"
    
    # Create cache directory if needed
    mkdir -p "$cache_dir"
    
    # Check if we've already processed this exact wallpaper
    if [ -f "$cache_file" ]; then
        # Check if generated files still exist and are newer than wallpaper
        local waybar_config="$HOME/.config/waybar/style-dynamic.css"
        if [ -f "$waybar_config" ] && [ "$waybar_config" -nt "$wallpaper" ]; then
            log_message "Theme cache HIT - skipping matugen regeneration"
            return 1  # No regeneration needed
        fi
    fi
    
    log_message "Theme cache MISS - regeneration needed"
    # Mark this wallpaper as processed
    touch "$cache_file"
    return 0  # Regeneration needed
}

# Function to set wallpaper with optimized transitions
set_wallpaper_optimized() {
    local wallpaper="$1"
    
    log_message "Setting wallpaper: $(basename "$wallpaper")"
    
    # Check swww daemon status
    if ! pgrep -x swww-daemon > /dev/null; then
        log_message "Starting swww daemon..."
        swww-daemon &
        sleep 1
    fi
    
    # Generate transition parameters
    local transition_params="--transition-type fade --transition-duration 1"
    if [ -f "$DOTFILES_DIR/scripts/transition-engine.sh" ]; then
        transition_params=$("$DOTFILES_DIR/scripts/transition-engine.sh" "$wallpaper" "smart" 2>/dev/null || echo "--transition-type fade --transition-duration 1")
        log_message "Using transition: $transition_params"
    fi
    
    # Set wallpaper
    if swww img "$wallpaper" $transition_params 2>/dev/null; then
        log_message "Wallpaper set successfully"
        
        # Save for startup restoration
        local last_wallpaper_file="$HOME/.config/dynamic-theming/last-wallpaper"
        mkdir -p "$(dirname "$last_wallpaper_file")"
        echo "$wallpaper" > "$last_wallpaper_file"
        log_message "Saved wallpaper for startup restoration"
        
        return 0
    else
        log_message "Error: Failed to set wallpaper"
        return 1
    fi
}

# Optimized theme generation
generate_theme_optimized() {
    local wallpaper="$1"
    
    if [ ! -f "$wallpaper" ]; then
        log_message "Error: Wallpaper file not found: $wallpaper"
        return 1
    fi
    
    log_message "Starting optimized wallpaper and theme change for: $(basename "$wallpaper")"
    
    # Step 1: Set wallpaper first (fast)
    if ! set_wallpaper_optimized "$wallpaper"; then
        log_message "Wallpaper setting failed"
        return 1
    fi
    
    # Step 2: Check if theme regeneration is needed (caching optimization)
    if [ "$FORCE_REGENERATION" != "force" ] && ! needs_theme_regeneration "$wallpaper"; then
        log_message "Skipping matugen - using cached theme"
        reload_applications_parallel
        return 0
    elif [ "$FORCE_REGENERATION" = "force" ]; then
        log_message "Force regeneration requested - bypassing cache"
    fi
    
    # Step 3: Run matugen (already fast at ~50ms)
    if command -v matugen > /dev/null; then
        log_message "Running matugen color extraction..."
        if matugen image "$wallpaper" --mode dark > /tmp/matugen-optimized.log 2>&1; then
            log_message "Matugen extraction complete"
            reload_applications_parallel
            return 0
        else
            log_message "Error: Matugen failed. Check /tmp/matugen-optimized.log"
            return 1
        fi
    else
        log_message "Error: Matugen not found"
        return 1
    fi
}

# Function to create optimized dunst config (fix warnings)
create_optimized_dunst_config() {
    local source_config="$HOME/.config/dunst/dunstrc-dynamic"
    local temp_config="/tmp/dunstrc-dynamic-fixed"
    
    if [ -f "$source_config" ]; then
        # Fix deprecated height and offset syntax
        sed -e 's/^height = \([0-9]*\)$/height = (0, \1)/' \
            -e 's/^offset = \([0-9]*x[0-9]*\)$/offset = (\1)/' \
            -e 's/\([0-9]*\)x\([0-9]*\)/\1, \2/' \
            "$source_config" > "$temp_config"
        
        # Replace original with fixed version
        cp "$temp_config" "$source_config"
        log_message "Dunst config warnings fixed"
    fi
}

# Main optimized execution
main() {
    log_message "=== OPTIMIZED Wallpaper Theme Changer Started ==="
    log_message "Target: Sub-2 second theme changes"
    
    # If no wallpaper provided, try to detect current wallpaper
    if [ -z "$WALLPAPER_PATH" ]; then
        if command -v swww > /dev/null; then
            WALLPAPER_PATH=$(swww query 2>/dev/null | head -n1 | awk '{print $NF}')
            log_message "Auto-detected wallpaper: $WALLPAPER_PATH"
        fi
    fi
    
    if [ -z "$WALLPAPER_PATH" ]; then
        log_message "Error: No wallpaper path provided or detected"
        exit 1
    fi
    
    # Fix dunst config issues before starting
    create_optimized_dunst_config
    
    # Generate optimized theme
    if generate_theme_optimized "$WALLPAPER_PATH"; then
        local end_time=$(date +%s.%N)
        local total_time=$(echo "$end_time - $START_TIME" | bc -l)
        
        log_message "OPTIMIZATION SUCCESS - Total time: ${total_time}s"
        
        # Send success notification
        if command -v notify-send > /dev/null; then
            notify-send "⚡ Fast Theme Update" "Completed in ${total_time}s" -i "$WALLPAPER_PATH"
        fi
    else
        log_message "OPTIMIZATION FAILED"
        
        if command -v notify-send > /dev/null; then
            notify-send "Theme Update Failed" "Check logs for details" -u critical
        fi
        exit 1
    fi
    
    log_message "=== OPTIMIZED Wallpaper Theme Changer Finished ==="
}

# Run main function
main "$@" 