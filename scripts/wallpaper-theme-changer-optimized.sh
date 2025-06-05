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

# Function to log to activity dashboard (for real-time monitoring)
log_activity() {
    local type="$1"
    local message="$2"
    local duration="$3"
    local timestamp=$(date '+%H:%M:%S')
    
    mkdir -p ~/.cache/matugen
    
    # Clear log when starting a new wallpaper change
    if [ "$type" = "start" ]; then
        > ~/.cache/matugen/activity.log  # Clear the log file
    fi
    
    if [ -n "$duration" ]; then
        # Format duration to 1 decimal place for readability
        local formatted_duration=$(echo "$duration" | sed 's/s$//' | awk '{printf "%.1fs", $1}')
        echo "[$timestamp] $type: $message ($formatted_duration)" >> ~/.cache/matugen/activity.log
    else
        echo "[$timestamp] $type: $message" >> ~/.cache/matugen/activity.log
    fi
}

# Function to check AI result cache
check_ai_cache() {
    local wallpaper="$1"
    local cache_dir="$HOME/.cache/matugen/ai-results"
    local wallpaper_hash=$(md5sum "$wallpaper" 2>/dev/null | cut -d' ' -f1)
    local cache_file="$cache_dir/ai-result-$wallpaper_hash.json"
    
    mkdir -p "$cache_dir"
    
    # Check if cached result exists and is valid
    if [ -f "$cache_file" ]; then
        # Verify cache file is not empty and has valid JSON
        if [ -s "$cache_file" ] && jq -e . "$cache_file" >/dev/null 2>&1; then
            # Copy cached result to expected location
            cp "$cache_file" "/tmp/ai-optimized-colors.json"
            log_message "💾 AI Cache: Using cached analysis for $(basename "$wallpaper")"
            log_activity "step" "Using cached AI analysis 🚀 (0.1s)"
            echo "cache_hit"
            return 0
        else
            # Remove invalid cache file
            rm -f "$cache_file"
        fi
    fi
    
    echo "cache_miss"
    return 1
}

# Function to save AI result to cache
save_ai_cache() {
    local wallpaper="$1"
    local cache_dir="$HOME/.cache/matugen/ai-results"
    local wallpaper_hash=$(md5sum "$wallpaper" 2>/dev/null | cut -d' ' -f1)
    local cache_file="$cache_dir/ai-result-$wallpaper_hash.json"
    
    mkdir -p "$cache_dir"
    
    # Save AI result to cache if it exists and is valid
    if [ -f "/tmp/ai-optimized-colors.json" ] && [ -s "/tmp/ai-optimized-colors.json" ]; then
        if jq -e . "/tmp/ai-optimized-colors.json" >/dev/null 2>&1; then
            cp "/tmp/ai-optimized-colors.json" "$cache_file"
            log_message "💾 AI Cache: Saved analysis for $(basename "$wallpaper")"
            return 0
        fi
    fi
    return 1
}

# Function to run AI-enhanced color generation
generate_ai_enhanced_colors() {
    local wallpaper="$1"
    
    log_message "🧠 AI Enhancement: Starting intelligent color optimization..."
    log_activity "step" "Starting AI color analysis"
    
    # Check cache first
    local cache_result=$(check_ai_cache "$wallpaper")
    if [ "$cache_result" = "cache_hit" ]; then
        log_message "🚀 AI Enhancement: Using cached result (instant)"
        return 0
    fi
    
    # Cache miss - proceed with full AI analysis
    log_message "🔍 AI Enhancement: No cache found, running full analysis..."
    log_activity "step" "Generating new AI analysis 🧠"
    
    # Check model warmth status for performance prediction
    if command -v ollama >/dev/null 2>&1 && ollama ps | grep -q "llava-llama3:8b"; then
        log_activity "step" "AI model is warm 🔥 (expecting 3-4s processing)"
    else
        log_activity "step" "AI model needs loading ❄️ (expecting 8-9s processing)"
    fi
    
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
            
            # Save result to cache for future use
            save_ai_cache "$wallpaper"
            
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
    log_activity "step" "Updating application themes"
    
    (
        # Waybar reload (very fast) - BOTH WAYBARS with timing
        local waybar_start_time=$(date +%s.%N)
        log_message "Reloading Waybar instances..."
        
        # Kill existing waybar instances
        pkill -x waybar 2>/dev/null || true
        sleep 0.1
        
        # Start BOTH waybar instances like your original setup
        # Main waybar (top) with dynamic theme
        waybar -s ~/.config/waybar/style-dynamic.css &>/tmp/waybar-main.log &
        local main_waybar_pid=$!
        log_message "Started main Waybar (top)"
        
        # Bottom waybar with dynamic theme
        waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css &>/tmp/waybar-bottom.log &
        local bottom_waybar_pid=$!
        log_message "Started bottom Waybar"
        
        # Wait a moment for waybars to fully initialize
        sleep 0.3
        
        # Check if both waybars started successfully
        local main_status="✅"
        local bottom_status="✅"
        if ! kill -0 $main_waybar_pid 2>/dev/null; then
            main_status="❌"
        fi
        if ! kill -0 $bottom_waybar_pid 2>/dev/null; then
            bottom_status="❌"
        fi
        
        local waybar_end_time=$(date +%s.%N)
        local waybar_duration=$(echo "$waybar_end_time - $waybar_start_time" | bc -l)
        local waybar_duration_formatted=$(echo "$waybar_duration" | awk '{printf "%.1fs", $1}')
        
        # Log to activity dashboard
        log_activity "step" "Main waybar reloaded $main_status ($waybar_duration_formatted)"
        log_activity "step" "Bottom waybar reloaded $bottom_status ($waybar_duration_formatted)"
        
        log_message "Both Waybars reloaded in ${waybar_duration_formatted}"
        
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
        # Fuzzel theme update - SYMLINK-AWARE cache preservation
        log_message "Updating Fuzzel colors (symlink-aware method)..."
        
        # Check if fuzzel.ini is a symlink (dotfiles setup)
        if [ -L ~/.config/fuzzel/fuzzel.ini ]; then
            log_message "Fuzzel config is symlinked - preserving original and using color overlay"
            
            # For symlinked configs, we can't modify the original file
            # Instead, we'll use environment variables or skip color updates
            # Fuzzel doesn't support includes, so we respect the symlinked config
            
            log_message "Skipping fuzzel color modification to preserve symlinked dotfiles config"
            log_message "Fuzzel will use static colors from dotfiles/config/fuzzel/fuzzel.ini"
            
        elif [ -f ~/.config/fuzzel/fuzzel-dynamic.ini ] && [ -f ~/.config/fuzzel/fuzzel.ini ]; then
            # Only for non-symlinked configs: safe to modify
            log_message "Updating fuzzel colors for non-symlinked config"
            
            # Preserve cache settings from existing config
            cache_line=$(grep "^cache=" ~/.config/fuzzel/fuzzel.ini 2>/dev/null || echo "")
            log_message "Preserving fuzzel cache settings: $cache_line"
            
            # Update colors while preserving cache and other settings
            python3 -c "
import re
import sys

try:
    with open('$HOME/.config/fuzzel/fuzzel.ini', 'r') as f:
        main_config = f.read()
    with open('$HOME/.config/fuzzel/fuzzel-dynamic.ini', 'r') as f:
        dynamic_config = f.read()
    
    # Extract colors section from dynamic config
    colors_match = re.search(r'\[colors\].*?(?=\n\[|\Z)', dynamic_config, re.DOTALL)
    if colors_match:
        new_colors = colors_match.group(0)
        # Replace colors section while preserving everything else
        updated_config = re.sub(r'\[colors\].*?(?=\n\[|\Z)', new_colors, main_config, flags=re.DOTALL)
        
        # Write back to main config
        with open('$HOME/.config/fuzzel/fuzzel.ini', 'w') as f:
            f.write(updated_config)
        
        print('Fuzzel colors updated successfully')
    else:
        print('No colors section found in dynamic config')
except Exception as e:
    print(f'Error updating fuzzel colors: {e}')
"
        else
            log_message "Dynamic fuzzel config not found or fuzzel.ini missing"
        fi
        
        # Symlink-aware cache preservation: respects dotfiles structure
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
    log_activity "step" "File detection and validation"
    wallpaper_start=$(date +%s.%N)
    if ! set_wallpaper_optimized "$wallpaper"; then
        log_message "Wallpaper setting failed"
        log_activity "error" "Wallpaper setting failed"
        return 1
    fi
    wallpaper_end=$(date +%s.%N)
    wallpaper_duration=$(echo "$wallpaper_end - $wallpaper_start" | bc -l)
    log_activity "step" "Wallpaper applied" "${wallpaper_duration}s"
    
    # Step 2: Check if theme regeneration is needed (caching optimization)
    if [ "$FORCE_REGENERATION" != "force" ] && ! needs_theme_regeneration "$wallpaper"; then
        log_message "Skipping color generation - using cached theme"
        log_activity "step" "Cache hit - using existing analysis" "0.0s"
        log_activity "step" "Applying cached color scheme"
        reload_applications_parallel
        return 0
    elif [ "$FORCE_REGENERATION" = "force" ]; then
        log_message "Force regeneration requested - bypassing cache"
    fi
    
    # Step 3: AI-Enhanced or Standard Color Generation
    local color_generation_success=false
    
    if [ "$ENABLE_AI_OPTIMIZATION" = "true" ]; then
        log_message "🧠 AI Enhancement enabled - attempting intelligent color optimization"
        log_activity "step" "Starting AI vision analysis"
        
        ai_generation_start=$(date +%s.%N)
        if generate_ai_enhanced_colors "$wallpaper"; then
            ai_generation_end=$(date +%s.%N)
            ai_generation_duration=$(echo "$ai_generation_end - $ai_generation_start" | bc -l)
            log_message "🎉 AI Enhancement successful - using AI-optimized colors"
            log_activity "step" "AI vision processing complete" "${ai_generation_duration}s"
            color_generation_success=true
        else
            ai_generation_end=$(date +%s.%N)
            ai_generation_duration=$(echo "$ai_generation_end - $ai_generation_start" | bc -l)
            log_message "⚠️  AI Enhancement failed - falling back to standard colors"
            log_activity "step" "AI analysis failed, using standard colors" "${ai_generation_duration}s"
            
            standard_start=$(date +%s.%N)
            if generate_standard_colors "$wallpaper"; then
                standard_end=$(date +%s.%N)
                standard_duration=$(echo "$standard_end - $standard_start" | bc -l)
                log_activity "step" "Standard color extraction" "${standard_duration}s"
                color_generation_success=true
            fi
        fi
    else
        log_message "🎨 AI Enhancement disabled - using standard color generation"
        log_activity "step" "Starting standard color extraction"
        
        standard_start=$(date +%s.%N)
        if generate_standard_colors "$wallpaper"; then
            standard_end=$(date +%s.%N)
            standard_duration=$(echo "$standard_end - $standard_start" | bc -l)
            log_activity "step" "Standard color extraction" "${standard_duration}s"
            color_generation_success=true
        fi
    fi
    
    # Step 4: Apply theme if color generation succeeded
    if [ "$color_generation_success" = true ]; then
        log_message "✅ Color generation successful - applying theme"
        log_activity "step" "Generating theme files"
        
        theme_apply_start=$(date +%s.%N)
        reload_applications_parallel
        theme_apply_end=$(date +%s.%N)
        theme_apply_duration=$(echo "$theme_apply_end - $theme_apply_start" | bc -l)
        
        log_activity "step" "Desktop theme applied" "${theme_apply_duration}s"
        return 0
    else
        log_message "❌ Color generation failed"
        log_activity "error" "Color generation failed"
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
    
    # Start activity logging for dashboard
    log_activity "start" "Wallpaper changed: $(basename "$WALLPAPER_PATH")"
    
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
        
        # Log completion to activity dashboard
        log_activity "complete" "Theme change complete" "${total_time}s"
        
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