#!/bin/bash
timeout 20 sh -c "while true; do hyprctl dispatch dpms off HDMI-A-1; sleep 1; done" 

# Wait a moment, then restart waybar to ensure proper workspace display
sleep 3
killall waybar
sleep 0.5
waybar &
waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom.css & 