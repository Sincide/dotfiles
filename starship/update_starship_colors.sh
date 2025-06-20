#!/bin/bash

# Update Starship Colors Script
# This script updates starship colors to match the current dynamic theme
# Can be called by the dynamic theme switcher

# Get the current theme colors from waybar colors.css
COLORS_FILE="$HOME/.config/waybar/colors.css"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
STARSHIP_TEMPLATE="$HOME/dotfiles/starship/starship.toml"

if [[ ! -f "$COLORS_FILE" ]]; then
    echo "Colors file not found: $COLORS_FILE"
    exit 1
fi

if [[ ! -f "$STARSHIP_TEMPLATE" ]]; then
    echo "Starship template not found: $STARSHIP_TEMPLATE"
    exit 1
fi

# Extract colors from the CSS file
PRIMARY=$(grep "primary " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
ON_PRIMARY=$(grep "onPrimary " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
SECONDARY=$(grep "secondary " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
ON_SECONDARY=$(grep "onSecondary " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
TERTIARY=$(grep "tertiary " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
ON_TERTIARY=$(grep "onTertiary " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
SURFACE_VARIANT=$(grep "surfaceVariant " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
ON_SURFACE_VARIANT=$(grep "onSurfaceVariant " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
BACKGROUND=$(grep "background " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
ON_BACKGROUND=$(grep "onBackground " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
INVERSE_ON_SURFACE=$(grep "inverseOnSurface " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')
ERROR=$(grep "error " "$COLORS_FILE" | head -1 | sed 's/.*#\([^;]*\);.*/\1/')

# Update the starship config with new colors
cp "$STARSHIP_TEMPLATE" "$STARSHIP_CONFIG"

# Replace color values in the config
sed -i "s/#ffb3b5/#$PRIMARY/g" "$STARSHIP_CONFIG"
sed -i "s/#561d23/#$ON_PRIMARY/g" "$STARSHIP_CONFIG"
sed -i "s/#e6bdbd/#$SECONDARY/g" "$STARSHIP_CONFIG"
sed -i "s/#44292a/#$ON_SECONDARY/g" "$STARSHIP_CONFIG"
sed -i "s/#e6c08d/#$TERTIARY/g" "$STARSHIP_CONFIG"
sed -i "s/#432c05/#$ON_TERTIARY/g" "$STARSHIP_CONFIG"
sed -i "s/#d7c1c1/#$ON_SURFACE_VARIANT/g" "$STARSHIP_CONFIG"
sed -i "s/#524343/#$SURFACE_VARIANT/g" "$STARSHIP_CONFIG"
sed -i "s/#f0dede/#$ON_BACKGROUND/g" "$STARSHIP_CONFIG"
sed -i "s/#1a1111/#$BACKGROUND/g" "$STARSHIP_CONFIG"
sed -i "s/#382e2e/#$INVERSE_ON_SURFACE/g" "$STARSHIP_CONFIG"
sed -i "s/#ffb4ab/#$ERROR/g" "$STARSHIP_CONFIG"

echo "✨ Starship colors updated to match current theme!"
echo "🎨 Primary: #$PRIMARY"
echo "🎨 Secondary: #$SECONDARY" 
echo "🎨 Tertiary: #$TERTIARY"
echo "💫 Restart your terminal to see the changes" 