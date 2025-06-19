#!/usr/bin/env bash

# Manual script to restart themed applications
# Run this when you're in a Hyprland session to apply theme changes

echo "🔄 Manually restarting themed applications..."

# Check if we're in Hyprland
if [[ ! "$WAYLAND_DISPLAY" ]] || ! pgrep -x Hyprland > /dev/null; then
    echo "❌ Error: This script must be run within a Hyprland session"
    exit 1
fi

echo "  • Reloading Hyprland configuration..."
hyprctl reload
sleep 1

echo "  • Restarting Waybar..."
pkill waybar 2>/dev/null
sleep 1
waybar &
sleep 1

echo "  • Restarting Dunst..."
pkill dunst 2>/dev/null
sleep 1
dunst &
sleep 1

# Check if applications started successfully
waybar_pid=$(pgrep waybar)
dunst_pid=$(pgrep dunst)

echo ""
echo "✅ Restart complete!"
echo "Status:"
if [[ "$waybar_pid" ]]; then
    echo "  • Waybar: Running (PID: $waybar_pid)"
else
    echo "  • Waybar: ❌ Failed to start"
fi

if [[ "$dunst_pid" ]]; then
    echo "  • Dunst: Running (PID: $dunst_pid)"
else
    echo "  • Dunst: ❌ Failed to start"
fi

# Show current theme info
primary_color=$(grep 'primary' ~/dotfiles/waybar/colors.css | head -1 | cut -d'#' -f2 | cut -d';' -f1)
echo ""
echo "🎨 Current theme primary color: #$primary_color" 