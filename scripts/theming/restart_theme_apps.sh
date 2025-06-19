#!/usr/bin/env bash

# Restart Theme Applications Script
# Reloads all theming-related applications after matugen color changes

echo "🔄 Restarting theme applications..."

# Check if we're running under Wayland/Hyprland
if [[ "$WAYLAND_DISPLAY" ]] && pgrep -x Hyprland > /dev/null; then
    echo "  • Reloading Hyprland configuration..."
    hyprctl reload
    
    # Restart Waybar (dual bars: top + bottom)
    if pgrep -x waybar > /dev/null; then
        echo "  • Restarting Waybar instances..."
        pkill waybar
        sleep 0.5
    fi
    echo "  • Starting top Waybar..."
    waybar > /dev/null 2>&1 &
    echo "  • Starting bottom Waybar (AMDGPU monitoring)..."
    waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom.css > /dev/null 2>&1 &
    
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
    
    # Refresh GTK applications
    echo "  • Refreshing GTK theme cache..."
    
    # Update GTK icon cache if possible
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f "$HOME/.icons/Papirus-Dark" 2>/dev/null || true
        gtk-update-icon-cache -f "/usr/share/icons/Papirus-Dark" 2>/dev/null || true
    fi
    
    # Signal GTK applications to reload themes
    if command -v gsettings >/dev/null 2>&1; then
        # Get current theme
        current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'Adwaita-dark'")
        # Toggle to force refresh
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
        sleep 0.1
        gsettings set org.gnome.desktop.interface gtk-theme "${current_theme//\'}" 2>/dev/null || true
        echo "    ✓ GTK theme refreshed"
    fi
    
    # Refresh icon theme as well
    if command -v gsettings >/dev/null 2>&1; then
        current_icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "'Papirus-Dark'")
        gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
        sleep 0.1
        gsettings set org.gnome.desktop.interface icon-theme "${current_icons//\'}" 2>/dev/null || true
        echo "    ✓ Icon theme refreshed"
    fi
    
    echo ""
    echo "✨ All theme applications restarted successfully!"
    echo "   🌈 Active theme components:"
    echo "      • Hyprland window manager"
    echo "      • Waybar dual bars (top + bottom with AMDGPU)"
    echo "      • Kitty terminal"
    echo "      • Dunst notifications"
    echo "      • GTK3/GTK4 applications"
    echo ""
    echo "   💡 Some GTK applications may need to be restarted to fully see theme changes"
    
    # Send notification if dunst is running
    sleep 1
    if pgrep -x dunst > /dev/null; then
        notify-send "🎨 Theme Updated" "All applications reloaded with new colors" --urgency=low 2>/dev/null || true
    fi
    
else
    echo "  ⚠️  Not running under Hyprland"
    echo "     This script is designed for Hyprland/Wayland environments"
    echo ""
    echo "  • GTK theme refresh still available..."
    
    # Still try to refresh GTK themes even outside Hyprland
    if command -v gsettings >/dev/null 2>&1; then
        current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'Adwaita-dark'")
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
        sleep 0.1
        gsettings set org.gnome.desktop.interface gtk-theme "${current_theme//\'}" 2>/dev/null || true
        echo "    ✓ GTK theme refreshed"
        
        current_icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "'Papirus-Dark'")
        gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
        sleep 0.1
        gsettings set org.gnome.desktop.interface icon-theme "${current_icons//\'}" 2>/dev/null || true
        echo "    ✓ Icon theme refreshed"
    fi
fi 