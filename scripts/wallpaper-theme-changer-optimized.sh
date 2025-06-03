#!/bin/bash

# Optimized Dynamic Wallpaper Theme Changer with AI Integration
# Target: Sub-2 second theme changes with parallel processing + optional AI enhancement
# Version: Performance-Optimized + AI-Enhanced

WALLPAPER_PATH="$1"
FORCE_REGENERATION="$2"  # Add force flag for manual wallpaper changes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# AI Enhancement Configuration
ENABLE_AI_OPTIMIZATION="${ENABLE_AI_OPTIMIZATION:-true}"   # AI features enabled - vision + mathematical analysis
AI_PIPELINE_SCRIPT="$DOTFILES_DIR/scripts/ai/ai-color-pipeline.sh"

# Performance tracking
START_TIME=$(date +%s.%N)

# Function to log messages with timing
log_message() {
    local current_time=$(date +%s.%N)
    local elapsed=$(echo "$current_time - $START_TIME" | bc -l)
    printf "[%.3f] %s - %s\n" "$elapsed" "$(date '+%H:%M:%S')" "$1" >> /tmp/wallpaper-theme-optimized.log
}

# Function to run AI-enhanced color generation
generate_ai_enhanced_colors() {
    local wallpaper="$1"
    
    log_message "🧠 AI Enhancement: Starting intelligent color optimization..."
    
    # Check if AI pipeline exists
    if [ ! -f "$AI_PIPELINE_SCRIPT" ]; then
        log_message "⚠️  AI pipeline not found: $AI_PIPELINE_SCRIPT"
        log_message "🔄 Falling back to standard matugen..."
        return 1
    fi
    
    # Run AI pipeline
    local ai_start_time=$(date +%s.%N)
    if "$AI_PIPELINE_SCRIPT" "$wallpaper" > /tmp/ai-pipeline-output.log 2>/tmp/ai-pipeline-error.log; then
        local ai_end_time=$(date +%s.%N)
        local ai_duration=$(echo "$ai_end_time - $ai_start_time" | bc -l)
        
        log_message "🎨 AI Enhancement: Color optimization completed in ${ai_duration}s"
        log_message "📊 AI results saved to: /tmp/ai-optimized-colors.json"
        
        # Verify AI output was generated
        if [ -f "/tmp/ai-optimized-colors.json" ] && [ -s "/tmp/ai-optimized-colors.json" ]; then
            # The AI pipeline handles the matugen integration internally
            # and generates all necessary theme files
            log_message "✅ AI-optimized theme files generated successfully"
            return 0
        else
            log_message "⚠️  AI output file missing or empty"
            return 1
        fi
    else
        local ai_end_time=$(date +%s.%N)
        local ai_duration=$(echo "$ai_end_time - $ai_start_time" | bc -l)
        
        log_message "❌ AI Enhancement failed after ${ai_duration}s"
        log_message "📋 Error details: $(tail -1 /tmp/ai-pipeline-error.log 2>/dev/null || echo 'No error details')"
        return 1
    fi
}

# Function to run standard matugen color generation
generate_standard_colors() {
    local wallpaper="$1"
    
    log_message "🎨 Standard: Running matugen color extraction..."
    
    if command -v matugen > /dev/null; then
        # Use matugen with the config from ~/.config/matugen/
        if matugen image "$wallpaper" --config ~/.config/matugen/config.toml > /tmp/matugen-optimized.log 2>&1; then
            log_message "✅ Standard: Matugen extraction complete"
            return 0
        else
            log_message "❌ Standard: Matugen failed. Check /tmp/matugen-optimized.log"
            return 1
        fi
    else
        log_message "❌ Error: Matugen not found"
        return 1
    fi
}

# Function to reload applications in parallel (PERFORMANCE OPTIMIZATION)
reload_applications_parallel() {
    log_message "Starting parallel application reloads..."
    
    (
        # Waybar reload (very fast) - BOTH WAYBARS
        log_message "Reloading Waybar instances..."
        
        # Kill existing waybar instances
        pkill -x waybar 2>/dev/null || true
        sleep 0.1
        
        # Start BOTH waybar instances like your original setup
        # Main waybar (top) with dynamic theme
        waybar -s ~/.config/waybar/style-dynamic.css &>/tmp/waybar-main.log &
        log_message "Started main Waybar (top)"
        
        # Bottom waybar with dynamic theme
        waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css &>/tmp/waybar-bottom.log &
        log_message "Started bottom Waybar"
        
    ) &
    local waybar_pid=$!
    
    (
        # Dunst reload (fast)
        log_message "Reloading Dunst..."
        if command -v dunst > /dev/null; then
            pkill -x dunst 2>/dev/null || true
            sleep 0.1
            dunst &>/dev/null &
            log_message "Dunst reload complete"
        fi
    ) &
    local dunst_pid=$!
    
    (
        # Kitty reload (instant)
        log_message "Reloading Kitty..."
        if command -v kitty > /dev/null; then
            pkill -USR1 kitty 2>/dev/null || true
            log_message "Kitty reload complete"
        fi
    ) &
    local kitty_pid=$!
    
    (
        # Fuzzel theme update and cache clear
        log_message "Updating Fuzzel colors..."
        
        # Update Fuzzel colors (copy from generated dynamic config)
        if [ -f ~/.config/fuzzel/fuzzel-dynamic.ini ]; then
            # Extract colors section from dynamic config and update main config
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
            log_message "Fuzzel colors updated from dynamic config"
        else
            log_message "Dynamic fuzzel config not found"
        fi
        
        # Clear cache
        rm -rf ~/.cache/fuzzel 2>/dev/null || true
        log_message "Fuzzel cache cleared"
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
    
    (
        # Material You Dynamic Icon Theming (NEW!)
        log_message "Updating Material You icons..."
        
        # Check if icon theming is enabled
        local icon_theme_enabled="true"  # TODO: Make this configurable
        
        if [ "$icon_theme_enabled" = "true" ] && [ -f "$DOTFILES_DIR/experiments/material-you-icons/scripts/thunar-material-you.sh" ]; then
            # Generate Material You icons for current wallpaper (protected from signals)
            (
                trap "" SIGUSR1 SIGUSR2 SIGTERM  # Ignore signals during icon generation
                "$DOTFILES_DIR/experiments/material-you-icons/scripts/thunar-material-you.sh" "$WALLPAPER_PATH" &>/tmp/material-you-icons.log
            )
            
            # Install the generated theme to system location
            if [ -d "$DOTFILES_DIR/experiments/material-you-icons/icon-themes/MaterialYou-Thunar" ]; then
                mkdir -p ~/.local/share/icons
                cp -r "$DOTFILES_DIR/experiments/material-you-icons/icon-themes/MaterialYou-Thunar" ~/.local/share/icons/ 2>/dev/null || true
                log_message "MaterialYou-Thunar theme installed"
            fi
            
            # Apply the Material You icon theme
            gsettings set org.gnome.desktop.interface icon-theme 'MaterialYou-Thunar' 2>/dev/null || true
            
            # Clear icon cache to force reload
            rm -rf ~/.cache/icon-theme.cache 2>/dev/null || true
            
            log_message "Material You icons updated"
        else
            log_message "Material You icons disabled or script not found"
        fi
        
    ) &
    local icons_pid=$!
    

    
    # Wait for all parallel operations to complete
    log_message "Waiting for parallel reloads to complete..."
    wait $waybar_pid $dunst_pid $kitty_pid $fuzzel_pid $hyprland_pid $gtk_pid $icons_pid
    
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

# Optimized theme generation with AI integration
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
        log_message "Skipping color generation - using cached theme"
        reload_applications_parallel
        return 0
    elif [ "$FORCE_REGENERATION" = "force" ]; then
        log_message "Force regeneration requested - bypassing cache"
    fi
    
    # Step 3: AI-Enhanced or Standard Color Generation
    local color_generation_success=false
    
    if [ "$ENABLE_AI_OPTIMIZATION" = "true" ]; then
        log_message "🧠 AI Enhancement enabled - attempting intelligent color optimization"
        
        if generate_ai_enhanced_colors "$wallpaper"; then
            log_message "🎉 AI Enhancement successful - using AI-optimized colors"
            color_generation_success=true
        else
            log_message "⚠️  AI Enhancement failed - falling back to standard colors"
            if generate_standard_colors "$wallpaper"; then
                color_generation_success=true
            fi
        fi
    else
        log_message "🎨 AI Enhancement disabled - using standard color generation"
        if generate_standard_colors "$wallpaper"; then
            color_generation_success=true
        fi
    fi
    
    # Step 4: Apply theme if color generation succeeded
    if [ "$color_generation_success" = true ]; then
        log_message "✅ Color generation successful - applying theme"
        reload_applications_parallel
        return 0
    else
        log_message "❌ Color generation failed"
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

# Main optimized execution with AI integration
main() {
    log_message "=== OPTIMIZED Wallpaper Theme Changer with AI Integration Started ==="
    log_message "🎯 Target: Sub-2 second theme changes"
    log_message "🧠 AI Enhancement: ${ENABLE_AI_OPTIMIZATION}"
    
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
        
        local enhancement_status="⚡ Standard"
        if [ "$ENABLE_AI_OPTIMIZATION" = "true" ]; then
            enhancement_status="🧠 AI-Enhanced"
        fi
        
        log_message "🎉 OPTIMIZATION SUCCESS - Total time: ${total_time}s"
        
        # Send success notification with AI status
        if command -v notify-send > /dev/null; then
            notify-send "$enhancement_status Theme Update" "Completed in ${total_time}s" -i "$WALLPAPER_PATH"
        fi
    else
        log_message "💥 OPTIMIZATION FAILED"
        
        if command -v notify-send > /dev/null; then
            notify-send "Theme Update Failed" "Check logs for details" -u critical
        fi
        exit 1
    fi
    
    log_message "=== OPTIMIZED Wallpaper Theme Changer Finished ==="
}

# Run main function
main "$@" 