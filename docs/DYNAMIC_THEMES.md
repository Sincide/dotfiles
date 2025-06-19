# Dynamic Theming System (2025)

## Overview

This dotfiles setup features a **comprehensive dynamic theming system** that automatically adapts your entire desktop environment based on wallpaper categories. The system uses modern 2025 technologies for optimal Hyprland/Wayland compatibility.

## System Architecture

### 🎨 **Core Components**

1. **Dynamic Theme Switcher** (`scripts/theming/dynamic_theme_switcher.sh`)
   - Wallpaper category detection
   - Automatic theme application
   - Cross-application theming coordination

2. **Modern Cursor System** (Hyprcursor + XCursor fallback)
   - Native Hyprland server-side cursors
   - Automatic fallback for legacy applications
   - Instant theme switching

3. **GTK Theme Management** (nwg-look integration)
   - Wayland-optimized theme application
   - Configuration export to all GTK versions
   - Reliable theme persistence

4. **Material You Color Generation** (matugen)
   - Wallpaper-based color palette extraction
   - Application-specific color configuration
   - Dynamic color coordination

## Theme Categories & Mappings

### 🌌 **Space** (Futuristic, Dark)
- **GTK**: Graphite-Dark (sleek, modern dark theme)
- **Icons**: Papirus-Dark (clean, professional icons)
- **Cursor**: Bibata-Modern-Ice (blue-white, futuristic)
- **Colors**: Deep blues, purples, space-inspired palette

### 🌿 **Nature** (Organic, Earth-toned)
- **GTK**: Orchis-Green-Dark (natural, organic appearance)
- **Icons**: Tela-circle-green (rounded, earth-friendly)
- **Cursor**: Bibata-Modern-Amber (warm, earthy tones)
- **Colors**: Greens, browns, natural color harmony

### 🎮 **Gaming** (High-contrast, Performance)
- **GTK**: Graphite-Dark (clean, distraction-free)
- **Icons**: Papirus (high-contrast, clear visibility)
- **Cursor**: Bibata-Modern-Classic (precise, professional)
- **Colors**: High contrast for optimal gaming visibility

### ⭕ **Minimal** (Clean, Simple)
- **GTK**: WhiteSur-Light (macOS-inspired, clean)
- **Icons**: WhiteSur (minimal, elegant)
- **Cursor**: Capitaine-Cursors (macOS-like, clean)
- **Colors**: Minimal palette, focus on usability

### 🌑 **Dark** (Pure Dark Mode)
- **GTK**: Graphite-Dark (professional dark theme)
- **Icons**: Papirus-Dark (consistent dark iconography)
- **Cursor**: Bibata-Modern-Classic (professional appearance)
- **Colors**: Deep blacks, dark grays, minimal color

### 🎨 **Abstract** (Artistic, Colorful)
- **GTK**: Graphite (balanced light/dark elements)
- **Icons**: Papirus (colorful, artistic expression)
- **Cursor**: Bibata-Modern-Amber (warm, creative tones)
- **Colors**: Vibrant, artistic color coordination

## Technical Implementation

### Automatic Wallpaper Detection
```bash
detect_category() {
    local wallpaper_path="$1"
    
    if [[ "$wallpaper_path" =~ space ]]; then
        echo "space"
    elif [[ "$wallpaper_path" =~ nature ]]; then
        echo "nature"
    elif [[ "$wallpaper_path" =~ gaming ]]; then
        echo "gaming"
    # ... additional categories
    else
        echo "minimal"  # Default fallback
    fi
}
```

### Theme Application Process
1. **Category Detection**: Analyze wallpaper path/filename
2. **Theme Mapping**: Select appropriate theme combination
3. **GTK Application**: Use nwg-look for reliable Wayland theming
4. **Cursor Setup**: Apply both hyprcursor and xcursor themes
5. **Color Generation**: Extract Material You colors with matugen
6. **System Reload**: Refresh Hyprland and applications

### Modern Cursor Implementation
```bash
# Hyprcursor (primary) + XCursor (fallback)
env = HYPRCURSOR_THEME,Bibata-Modern-Ice
env = HYPRCURSOR_SIZE,24
env = XCURSOR_THEME,Bibata-Modern-Ice
env = XCURSOR_SIZE,24
```

### nwg-look Integration
```bash
# Set themes via gsettings
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

# Export and apply with nwg-look for Wayland compatibility
nwg-look -x  # Export to config files
nwg-look -a  # Apply configurations
```

## Supported Applications

### ✅ **Immediate Theme Application**
- **Hyprland**: Window manager, decorations, borders
- **Waybar**: Status bars, modules, styling
- **Kitty**: Terminal colors and themes
- **Dunst**: Notification appearance
- **Fuzzel**: Application launcher styling

### ✅ **GTK Applications** (via nwg-look)
- **File Managers**: Nemo, Nautilus, Thunar
- **Settings Apps**: Gnome Settings, system preferences
- **Text Editors**: Gedit, GTK-based editors
- **Browsers**: GTK-based browser elements

### ✅ **Qt Applications** (via hyprcursor)
- **Modern Apps**: Most contemporary Qt applications
- **Development Tools**: Qt-based IDEs and tools
- **Media Players**: Qt-based media applications

### ⚠️ **May Need Application Restart**
- **Browsers**: Firefox, Chrome (for full theme application)
- **IDEs**: VS Code, Cursor (for complete theming)
- **Legacy Apps**: Older applications without live theming

## Usage Commands

### Automatic Theme Switching
```bash
# Apply based on wallpaper category
./scripts/theming/dynamic_theme_switcher.sh apply /path/to/wallpaper.jpg

# Examples for specific categories
./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/space/dark_space.jpg
./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/nature/gradiant_sky.png
```

### Manual Theme Application
```bash
# Force specific cursor theme
hyprctl setcursor Bibata-Modern-Amber 24

# Reload all theming
hyprctl reload

# Restart theme-sensitive applications
./scripts/theming/restart_cursor_apps.sh
```

### Debug and Status
```bash
# Check current themes
echo "GTK: $(gsettings get org.gnome.desktop.interface gtk-theme)"
echo "Cursor: $HYPRCURSOR_THEME / $XCURSOR_THEME"

# Verify hyprcursor installation
find /usr/share/icons -name "manifest.hl" | grep Bibata

# Test nwg-look functionality
nwg-look -a
```

## Configuration Files

### Dynamic Generated Configs
- `~/.config/hypr/cursor-theme.conf` - Hyprcursor environment variables
- `~/.config/gtk-3.0/colors.css` - Material You colors for GTK3
- `~/.config/gtk-4.0/colors.css` - Material You colors for GTK4
- `~/.config/waybar/colors.css` - Status bar color scheme
- `~/.config/kitty/theme-dynamic.conf` - Terminal color scheme

### Static Configuration
- `~/.config/gtk-3.0/settings.ini` - GTK3 theme preferences
- `~/.config/gtk-4.0/settings.ini` - GTK4 theme preferences
- `~/.config/matugen/config.toml` - Color generation settings

## Requirements

### Essential Packages
```bash
# Modern cursor system
pacman -S hyprcursor
yay -S bibata-cursor-git

# GTK theme management
pacman -S nwg-look

# Material You color generation
yay -S matugen

# Theme packages
# (Graphite, Orchis, WhiteSur themes as needed)
```

### Optional Enhancements
```bash
# Additional cursor themes
yay -S capitaine-cursors

# Icon theme variety
pacman -S papirus-icon-theme
yay -S tela-icon-theme

# Additional GTK themes
# (Install themes as needed for customization)
```

## Benefits

### 🚀 **Performance**
- Server-side cursors (hyprcursor) for better performance
- Native Wayland support without X11 compatibility layers
- Efficient color generation and caching

### 🎨 **Consistency**
- Unified theming across all application types
- Coordinated color schemes based on wallpapers
- Professional appearance with minimal manual configuration

### 🔄 **Automation**
- Wallpaper changes automatically trigger theme updates
- No manual theme selection required
- Intelligent category detection and theme mapping

### 🛠️ **Reliability**
- Fallback systems ensure compatibility with all applications
- nwg-look handles Wayland-specific configuration challenges
- Robust error handling and graceful degradation

This dynamic theming system provides a seamless, beautiful, and highly automated desktop experience that adapts to your wallpaper choices while maintaining excellent performance and compatibility across the Hyprland ecosystem. 