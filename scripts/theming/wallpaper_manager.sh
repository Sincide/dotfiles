#!/usr/bin/env bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/dotfiles/assets/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to apply wallpaper and generate colors
apply_wallpaper() {
    local wallpaper="$1"
    
    # Save the wallpaper path to cache for persistence
    echo "$wallpaper" > "$CACHE_DIR/current_wallpaper"
    
    # Set the wallpaper using swww
    swww img "$wallpaper" --transition-fps 60 --transition-type grow --transition-pos center
    
    # Generate material colors using matugen with config from dotfiles
    # Correct syntax: matugen image [OPTIONS] <IMAGE>
    matugen image --config ~/dotfiles/matugen/config.toml "$wallpaper"
    
    # Restart applications to apply new colors
    echo "🔄 Reloading applications with new theme..."
    
    # Check if we're running under Wayland/Hyprland
    if [[ "$WAYLAND_DISPLAY" ]] && pgrep -x Hyprland > /dev/null; then
        echo "  • Reloading Hyprland configuration..."
        hyprctl reload
        
        # Restart Waybar (only under Wayland)
        if pgrep -x waybar > /dev/null; then
            echo "  • Restarting Waybar..."
            pkill waybar
            sleep 0.5
        fi
        echo "  • Starting Waybar..."
        waybar > /dev/null 2>&1 &
        
        # Restart Dunst
        if pgrep -x dunst > /dev/null; then
            echo "  • Restarting Dunst..."
            pkill dunst
            sleep 0.5
        fi
        echo "  • Starting Dunst..."
        dunst > /dev/null 2>&1 &
        
        # Reload Kitty configurations
        echo "  • Reloading Kitty configurations..."
        killall -USR1 kitty 2>/dev/null || echo "    (No kitty instances to reload)"
        
    else
        echo "  ⚠️  Not running under Hyprland - applications won't be restarted"
        echo "     Start Hyprland session and run 'wallpaper_manager.sh restore' to apply theme"
    fi
    
    echo "✅ Theme colors generated successfully!"
    echo "💡 New colors: Primary: $(grep 'primary' ~/dotfiles/waybar/colors.css | head -1 | cut -d'#' -f2 | cut -d';' -f1)"
}

# Function to select category and then wallpaper
select_wallpaper() {
    # First, let user select category
    local categories=$(find "$WALLPAPER_DIR" -mindepth 1 -type d -printf "%f\n" | sort)
    local category=$(echo "$categories" | fuzzel --dmenu --prompt="Select category: ")
    
    if [ -z "$category" ]; then
        exit 0
    fi
    
    # Then, let user select wallpaper from category
    local wallpapers=$(find "$WALLPAPER_DIR/$category" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -printf "%f\n")
    local wallpaper=$(echo "$wallpapers" | fuzzel --dmenu --prompt="Select wallpaper from $category: ")
    
    if [ -n "$wallpaper" ]; then
        apply_wallpaper "$WALLPAPER_DIR/$category/$wallpaper"
    fi
}

# Main script
case "$1" in
    "select")
        select_wallpaper
        ;;
    "restore")
        if [ -f "$CACHE_DIR/current_wallpaper" ]; then
            WALLPAPER=$(cat "$CACHE_DIR/current_wallpaper")
            if [ -f "$WALLPAPER" ]; then
                apply_wallpaper "$WALLPAPER"
            fi
        fi
        ;;
    *)
        echo "Usage: $0 [select|restore]"
        echo "  select  - Open fuzzel to select a new wallpaper"
        echo "  restore - Restore the last used wallpaper"
        exit 1
        ;;
esac