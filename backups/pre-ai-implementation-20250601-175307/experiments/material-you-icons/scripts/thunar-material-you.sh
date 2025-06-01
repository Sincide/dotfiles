#!/bin/bash

# Material You Dynamic Icon Theming - Thunar Focus
# SAFETY: Only works in experiments/ directory, doesn't modify system icons
# Targets folder icons and common file types seen in Thunar

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
EXPERIMENTS_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$(dirname "$(dirname "$EXPERIMENTS_DIR")")"

# Safety check - only work in experiments directory
if [[ ! "$SCRIPT_DIR" == *"experiments/material-you-icons"* ]]; then
    echo "❌ SAFETY ERROR: This script only works in experiments/material-you-icons/ directory"
    exit 1
fi

log_message() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a /tmp/thunar-material-you.log
}

# Extract Material You colors from wallpaper
extract_material_colors() {
    local wallpaper="$1"
    local mode="${2:-dark}"
    
    log_message "Extracting Material You colors for Thunar icons..."
    
    # Get JSON colors from matugen
    local colors_json
    colors_json=$(matugen image "$wallpaper" --mode "$mode" --json hex --dry-run)
    
    # Extract colors optimized for folder theming
    if command -v jq &> /dev/null; then
        MATERIAL_PRIMARY=$(echo "$colors_json" | jq -r ".colors.$mode.primary")
        MATERIAL_SECONDARY=$(echo "$colors_json" | jq -r ".colors.$mode.secondary") 
        MATERIAL_TERTIARY=$(echo "$colors_json" | jq -r ".colors.$mode.tertiary")
        MATERIAL_PRIMARY_CONTAINER=$(echo "$colors_json" | jq -r ".colors.$mode.primary_container")
        MATERIAL_SECONDARY_CONTAINER=$(echo "$colors_json" | jq -r ".colors.$mode.secondary_container")
        MATERIAL_SURFACE=$(echo "$colors_json" | jq -r ".colors.$mode.surface")
        MATERIAL_ON_SURFACE=$(echo "$colors_json" | jq -r ".colors.$mode.on_surface")
    else
        # Fallback parsing
        MATERIAL_PRIMARY=$(echo "$colors_json" | grep -o '"primary":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_SECONDARY=$(echo "$colors_json" | grep -o '"secondary":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_TERTIARY=$(echo "$colors_json" | grep -o '"tertiary":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_PRIMARY_CONTAINER=$(echo "$colors_json" | grep -o '"primary_container":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_SECONDARY_CONTAINER=$(echo "$colors_json" | grep -o '"secondary_container":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_SURFACE=$(echo "$colors_json" | grep -o '"surface":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_ON_SURFACE=$(echo "$colors_json" | grep -o '"on_surface":"[^"]*"' | cut -d'"' -f4)
    fi
    
    log_message "Material colors for Thunar theming:"
    log_message "  Primary (main folders): $MATERIAL_PRIMARY"
    log_message "  Secondary (special folders): $MATERIAL_SECONDARY" 
    log_message "  Tertiary (accent folders): $MATERIAL_TERTIARY"
    log_message "  Primary Container: $MATERIAL_PRIMARY_CONTAINER"
    log_message "  Secondary Container: $MATERIAL_SECONDARY_CONTAINER"
}

# Function to recolor a folder icon
recolor_folder_icon() {
    local input_svg="$1"
    local output_svg="$2"
    local color_type="${3:-primary}"  # primary, secondary, tertiary
    
    if [[ ! -f "$input_svg" ]]; then
        log_message "❌ Input SVG not found: $input_svg"
        return 1
    fi
    
    log_message "Recoloring folder icon: $(basename "$input_svg") -> $color_type"
    
    # Copy original
    cp "$input_svg" "$output_svg"
    
    # Choose colors based on folder type
    local target_color
    case "$color_type" in
        "primary")
            target_color="$MATERIAL_PRIMARY"
            ;;
        "secondary") 
            target_color="$MATERIAL_SECONDARY"
            ;;
        "tertiary")
            target_color="$MATERIAL_TERTIARY"
            ;;
        "primary_container")
            target_color="$MATERIAL_PRIMARY_CONTAINER"
            ;;
        *)
            target_color="$MATERIAL_PRIMARY"
            ;;
    esac
    
    # Papirus folder colors to replace (analyzed from folder icons)
    # Main folder colors (blues and oranges)
    sed -i "s/#5294cf/$target_color/g" "$output_svg"  # Papirus blue
    sed -i "s/#4877b1/$target_color/g" "$output_svg"  # Darker blue
    sed -i "s/#6ba4e7/$target_color/g" "$output_svg"  # Light blue
    sed -i "s/#5aa3e7/$target_color/g" "$output_svg"  # Another blue
    sed -i "s/#4285f4/$target_color/g" "$output_svg"  # Google blue
    
    # Orange folder colors
    sed -i "s/#ff6f00/$target_color/g" "$output_svg"  # Orange
    sed -i "s/#ff8f00/$target_color/g" "$output_svg"  # Light orange
    sed -i "s/#ff5722/$target_color/g" "$output_svg"  # Red-orange
    
    # Generic folder colors
    sed -i "s/#42a5f5/$target_color/g" "$output_svg"  # Material blue
    sed -i "s/#1976d2/$target_color/g" "$output_svg"  # Material blue dark
    
    log_message "✅ Folder recolored with $color_type color: $target_color"
}

# Create Thunar-optimized Material You theme
create_thunar_material_theme() {
    local theme_name="MaterialYou-Thunar"
    local theme_dir="$EXPERIMENTS_DIR/icon-themes/$theme_name"
    
    log_message "Creating Thunar-optimized Material You theme: $theme_name"
    
    # Create theme structure
    mkdir -p "$theme_dir/48x48/places"
    mkdir -p "$theme_dir/48x48/apps"
    mkdir -p "$theme_dir/22x22/places"
    mkdir -p "$theme_dir/16x16/places"
    
    # Create index.theme
    cat > "$theme_dir/index.theme" << EOF
[Icon Theme]
Name=Material You Thunar
Comment=Material You colors optimized for Thunar file manager
Inherits=Papirus-Dark,Papirus,Adwaita
Directories=48x48/places,48x48/apps,22x22/places,16x16/places

[48x48/places]
Size=48
Context=Places
Type=Fixed

[48x48/apps]
Size=48
Context=Applications
Type=Fixed

[22x22/places]
Size=22
Context=Places
Type=Fixed

[16x16/places]
Size=16
Context=Places
Type=Fixed
EOF

    # Copy and recolor essential folder icons
    local papirus_places="/usr/share/icons/Papirus/48x48/places"
    
    # Essential folder icons for Thunar
    local folder_icons=(
        "folder.svg:primary"
        "folder-open.svg:primary" 
        "folder-documents.svg:secondary"
        "folder-download.svg:tertiary"
        "folder-music.svg:tertiary"
        "folder-pictures.svg:secondary"
        "folder-videos.svg:secondary"
        "folder-desktop.svg:primary_container"
        "folder-home.svg:primary"
        "user-home.svg:primary"
    )
    
    log_message "Processing essential Thunar folder icons..."
    
    for icon_spec in "${folder_icons[@]}"; do
        IFS=':' read -r icon_name color_type <<< "$icon_spec"
        
        if [[ -f "$papirus_places/$icon_name" ]]; then
            recolor_folder_icon "$papirus_places/$icon_name" "$theme_dir/48x48/places/$icon_name" "$color_type"
            
            # Also create smaller sizes (copy and scale if needed)
            if [[ -f "/usr/share/icons/Papirus/22x22/places/$icon_name" ]]; then
                cp "/usr/share/icons/Papirus/22x22/places/$icon_name" "$theme_dir/22x22/places/$icon_name"
            fi
            if [[ -f "/usr/share/icons/Papirus/16x16/places/$icon_name" ]]; then
                cp "/usr/share/icons/Papirus/16x16/places/$icon_name" "$theme_dir/16x16/places/$icon_name"
            fi
        else
            log_message "⚠️  Icon not found: $icon_name"
        fi
    done
    
    log_message "✅ Thunar Material You theme created: $theme_dir"
}

# Safe testing with auto-rollback
test_thunar_theme() {
    local theme_name="MaterialYou-Thunar"
    local theme_dir="$EXPERIMENTS_DIR/icon-themes/$theme_name"
    
    if [[ ! -d "$theme_dir" ]]; then
        log_message "❌ Thunar theme not found: $theme_dir"
        return 1
    fi
    
    # Backup current theme
    local current_theme
    current_theme=$(gsettings get org.gnome.desktop.interface icon-theme)
    
    log_message "🎯 Testing Thunar Material You theme (15-second test)"
    log_message "Current theme backed up: $current_theme"
    log_message ""
    log_message "🔍 WHAT TO CHECK:"
    log_message "  1. Open Thunar file manager"
    log_message "  2. Look at folder icons - they should be colored with wallpaper colors"
    log_message "  3. Check Documents, Downloads, Music, Pictures folders"
    log_message "  4. Notice how colors match your wallpaper theme"
    log_message ""
    
    # Apply test theme
    gsettings set org.gnome.desktop.interface icon-theme "$theme_name"
    
    log_message "✅ Thunar theme applied! Open Thunar now to see Material You folders!"
    log_message "Theme will auto-rollback in 15 seconds..."
    
    # Extended time for Thunar testing
    sleep 15
    
    # Restore original theme
    gsettings set org.gnome.desktop.interface icon-theme "$current_theme"
    log_message "✅ Original theme restored: $current_theme"
}

# Main function
main() {
    log_message "=== Material You Thunar Icon Theming Started ==="
    
    # Check dependencies
    if ! command -v inkscape &> /dev/null; then
        log_message "❌ Inkscape not found. Please install: sudo pacman -S inkscape"
        exit 1
    fi
    
    # Use current wallpaper or default
    local wallpaper="${1:-$DOTFILES_DIR/assets/wallpapers/dark/evilpuccin.png}"
    
    if [[ ! -f "$wallpaper" ]]; then
        log_message "❌ Wallpaper not found: $wallpaper"
        exit 1
    fi
    
    # Extract colors
    extract_material_colors "$wallpaper" "dark"
    
    # Create Thunar-optimized theme
    create_thunar_material_theme
    
    log_message "✅ Thunar Material You theming complete!"
    log_message ""
    log_message "🎯 To test in Thunar (15-second safe test):"
    log_message "  ./thunar-material-you.sh test"
    log_message ""
    log_message "🎯 To apply permanently:"
    log_message "  gsettings set org.gnome.desktop.interface icon-theme 'MaterialYou-Thunar'"
    log_message "🎯 To restore:"
    log_message "  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'"
    
    log_message "=== Thunar Material You Session Complete ==="
}

# Handle different modes
case "${1:-}" in
    "test")
        test_thunar_theme
        ;;
    *)
        main "$@"
        ;;
esac 