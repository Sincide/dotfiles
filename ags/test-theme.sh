#!/bin/bash

# AGS Matugen Integration Test Script
echo "🎨 Testing AGS Matugen Integration"

# Check if matugen is installed
if ! command -v matugen &> /dev/null; then
    echo "❌ Matugen not found. Install with: yay -S matugen-bin"
    exit 1
fi

# Check if AGS is installed
if ! command -v ags &> /dev/null; then
    echo "❌ AGS not found. Install with: yay -S aylurs-gtk-shell"
    exit 1
fi

# Test wallpaper path
WALLPAPER="${1:-$HOME/dotfiles/assets/wallpapers/space/galaxy.jpg}"

if [[ ! -f "$WALLPAPER" ]]; then
    echo "❌ Wallpaper not found: $WALLPAPER"
    echo "Usage: $0 [wallpaper_path]"
    exit 1
fi

echo "🖼️  Using wallpaper: $WALLPAPER"

# Generate theme with matugen
echo "🎨 Generating theme with matugen..."
cd ~/dotfiles
matugen image "$WALLPAPER"

if [[ $? -eq 0 ]]; then
    echo "✅ Matugen theme generated successfully"
else
    echo "❌ Matugen theme generation failed"
    exit 1
fi

# Check if AGS theme file was created
AGS_THEME_FILE="$HOME/dotfiles/ags/style/theme.scss"
if [[ -f "$AGS_THEME_FILE" ]]; then
    echo "✅ AGS theme file created: $AGS_THEME_FILE"
    echo "📝 First few lines of generated theme:"
    head -n 10 "$AGS_THEME_FILE"
else
    echo "⚠️  AGS theme file not found. Matugen may not have generated it."
fi

# Test AGS
echo "🚀 Testing AGS with new theme..."
cd ~/.config/ags
ags run &
AGS_PID=$!

sleep 3

if ps -p $AGS_PID > /dev/null; then
    echo "✅ AGS running successfully with new theme!"
    echo "🎯 Check your sidebar (Super+S), launcher (Super+D), and bars"
    echo "🔥 Theme should match your wallpaper colors"
else
    echo "❌ AGS failed to start"
fi

echo "🏁 Test complete! AGS PID: $AGS_PID" 