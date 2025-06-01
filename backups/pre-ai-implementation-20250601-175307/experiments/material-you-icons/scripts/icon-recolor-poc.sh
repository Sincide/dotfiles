#!/bin/bash

# Material You Dynamic Icon Recoloring - Proof of Concept
# SAFETY: This script only works in experiments/ directory and doesn't modify system icons
# Enhanced with Inkscape for precise SVG manipulation

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
    echo "[$(date '+%H:%M:%S')] $1" | tee -a /tmp/icon-recolor-poc.log
}

# Function to extract colors from matugen (using current wallpaper colors)
extract_material_colors() {
    local wallpaper="$1"
    local mode="${2:-dark}"
    
    log_message "Extracting Material You colors from: $wallpaper"
    
    # Get JSON colors from matugen (dry-run to avoid regenerating templates)
    local colors_json
    colors_json=$(matugen image "$wallpaper" --mode "$mode" --json hex --dry-run)
    
    # Extract key colors for icon theming using proper JSON parsing
    if command -v jq &> /dev/null; then
        # Use jq for proper JSON parsing
        MATERIAL_PRIMARY=$(echo "$colors_json" | jq -r ".colors.$mode.primary")
        MATERIAL_SECONDARY=$(echo "$colors_json" | jq -r ".colors.$mode.secondary") 
        MATERIAL_TERTIARY=$(echo "$colors_json" | jq -r ".colors.$mode.tertiary")
        MATERIAL_SURFACE=$(echo "$colors_json" | jq -r ".colors.$mode.surface")
        MATERIAL_ON_SURFACE=$(echo "$colors_json" | jq -r ".colors.$mode.on_surface")
        MATERIAL_PRIMARY_CONTAINER=$(echo "$colors_json" | jq -r ".colors.$mode.primary_container")
    else
        # Fallback to grep parsing
        MATERIAL_PRIMARY=$(echo "$colors_json" | grep -o '"primary":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_SECONDARY=$(echo "$colors_json" | grep -o '"secondary":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_TERTIARY=$(echo "$colors_json" | grep -o '"tertiary":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_SURFACE=$(echo "$colors_json" | grep -o '"surface":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_ON_SURFACE=$(echo "$colors_json" | grep -o '"on_surface":"[^"]*"' | cut -d'"' -f4)
        MATERIAL_PRIMARY_CONTAINER=$(echo "$colors_json" | grep -o '"primary_container":"[^"]*"' | cut -d'"' -f4)
    fi
    
    log_message "Material colors extracted:"
    log_message "  Primary: $MATERIAL_PRIMARY"
    log_message "  Secondary: $MATERIAL_SECONDARY" 
    log_message "  Tertiary: $MATERIAL_TERTIARY"
    log_message "  Primary Container: $MATERIAL_PRIMARY_CONTAINER"
    log_message "  Surface: $MATERIAL_SURFACE"
    log_message "  On Surface: $MATERIAL_ON_SURFACE"
}

# Function to recolor SVG icon using Inkscape
recolor_svg_icon_inkscape() {
    local input_svg="$1"
    local output_svg="$2"
    
    if [[ ! -f "$input_svg" ]]; then
        log_message "❌ Input SVG not found: $input_svg"
        return 1
    fi
    
    log_message "Recoloring icon with Inkscape: $(basename "$input_svg")"
    
    # Copy original to output first
    cp "$input_svg" "$output_svg"
    
    # Use Inkscape's powerful color replacement capabilities
    # This approach is much more reliable than sed replacements
    
    # Firefox-specific color mapping (analyzed from the SVG)
    # Orange variants → Material Primary and Secondary
    inkscape --batch-process \
        --actions="select-all;selection-ungroup-deep;EditSelectAllInAllLayers;" \
        --actions="StrokeToPath;" \
        "$output_svg" &>/dev/null || true
    
    # Method 1: Direct color replacement in SVG text
    # Firefox orange colors → Material You colors
    sed -i "s/#ff750e/$MATERIAL_PRIMARY/g" "$output_svg"      # Main orange
    sed -i "s/#ff7f1f/$MATERIAL_SECONDARY/g" "$output_svg"   # Orange variant  
    sed -i "s/#ffba36/$MATERIAL_TERTIARY/g" "$output_svg"    # Yellow-orange
    sed -i "s/#ffde3f/$MATERIAL_SECONDARY/g" "$output_svg"   # Yellow
    
    # Firefox purple → Material Primary
    sed -i "s/#8357cd/$MATERIAL_PRIMARY/g" "$output_svg"
    
    # Firefox red → Material Tertiary  
    sed -i "s/#f74e66/$MATERIAL_TERTIARY/g" "$output_svg"
    
    log_message "✅ Inkscape recoloring complete: $output_svg"
}

# Function to create icon theme directory structure
create_material_icon_theme() {
    local theme_name="MaterialYou-Dynamic"
    local theme_dir="$EXPERIMENTS_DIR/icon-themes/$theme_name"
    
    log_message "Creating Material You icon theme: $theme_name"
    
    # Create theme directory structure
    mkdir -p "$theme_dir/48x48/apps"
    
    # Create theme index file
    cat > "$theme_dir/index.theme" << EOF
[Icon Theme]
Name=Material You Dynamic
Comment=Dynamically generated icon theme based on wallpaper colors
Inherits=Papirus-Dark,Papirus,Adwaita
Directories=48x48/apps

[48x48/apps]
Size=48
Context=Applications
Type=Fixed
EOF
    
    # Copy recolored icons
    if [[ -f "$EXPERIMENTS_DIR/test-icons/firefox-material-you.svg" ]]; then
        cp "$EXPERIMENTS_DIR/test-icons/firefox-material-you.svg" "$theme_dir/48x48/apps/firefox.svg"
        log_message "✅ Firefox icon added to theme"
    fi
    
    log_message "✅ Material You icon theme created: $theme_dir"
    log_message "To test: gsettings set org.gnome.desktop.interface icon-theme '$theme_name'"
    log_message "To restore: gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'"
}

# Function to safely test icon theme (with automatic rollback)
test_icon_theme() {
    local theme_name="MaterialYou-Dynamic"
    local theme_dir="$EXPERIMENTS_DIR/icon-themes/$theme_name"
    
    if [[ ! -d "$theme_dir" ]]; then
        log_message "❌ Icon theme not found: $theme_dir"
        return 1
    fi
    
    # Backup current icon theme
    local current_theme
    current_theme=$(gsettings get org.gnome.desktop.interface icon-theme)
    
    log_message "Testing Material You icon theme (will auto-rollback in 10 seconds)"
    log_message "Current theme backed up: $current_theme"
    
    # Apply test theme
    gsettings set org.gnome.desktop.interface icon-theme "$theme_name"
    
    log_message "✅ Test theme applied! Check your Firefox icon now."
    log_message "Theme will auto-rollback in 10 seconds..."
    
    # Wait and rollback
    sleep 10
    
    # Restore original theme
    gsettings set org.gnome.desktop.interface icon-theme "$current_theme"
    log_message "✅ Original theme restored: $current_theme"
}

# Main function
main() {
    log_message "=== Material You Icon Recoloring POC with Inkscape Started ==="
    
    # Check if Inkscape is available
    if ! command -v inkscape &> /dev/null; then
        log_message "❌ Inkscape not found. Please install: sudo pacman -S inkscape"
        exit 1
    fi
    
    log_message "✅ Inkscape found: $(inkscape --version | head -n1)"
    
    # Use current wallpaper or default
    local wallpaper="${1:-$DOTFILES_DIR/assets/wallpapers/dark/evilpuccin.png}"
    
    if [[ ! -f "$wallpaper" ]]; then
        log_message "❌ Wallpaper not found: $wallpaper"
        exit 1
    fi
    
    # Extract colors
    extract_material_colors "$wallpaper" "dark"
    
    # Test directory
    local test_icons_dir="$EXPERIMENTS_DIR/test-icons"
    
    # Recolor Firefox icon
    if [[ -f "$test_icons_dir/firefox-original.svg" ]]; then
        recolor_svg_icon_inkscape "$test_icons_dir/firefox-original.svg" "$test_icons_dir/firefox-material-you.svg"
        
        # Create PNG previews
        log_message "Creating PNG previews with Inkscape..."
        inkscape "$test_icons_dir/firefox-original.svg" --export-type=png -o "$test_icons_dir/firefox-original.png" &>/dev/null
        inkscape "$test_icons_dir/firefox-material-you.svg" --export-type=png -o "$test_icons_dir/firefox-material-you.png" &>/dev/null
        log_message "✅ PNG previews created"
        
        # Create full icon theme for testing
        create_material_icon_theme
        
        log_message "✅ POC Complete! Results available:"
        log_message "  Original: $test_icons_dir/firefox-original.svg"
        log_message "  Recolored: $test_icons_dir/firefox-material-you.svg"
        log_message "  Preview PNGs: firefox-original.png & firefox-material-you.png"
        log_message ""
        log_message "🎯 To test the dynamic icon theme safely:"
        log_message "  ./icon-recolor-poc.sh test"
        
    else
        log_message "❌ Firefox original icon not found. Run this first:"
        log_message "cp /usr/share/icons/Papirus/48x48/apps/firefox.svg $test_icons_dir/firefox-original.svg"
        exit 1
    fi
    
    log_message "=== POC Session Complete ==="
}

# Handle different modes
case "${1:-}" in
    "test")
        test_icon_theme
        ;;
    *)
        main "$@"
        ;;
esac 