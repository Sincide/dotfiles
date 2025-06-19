# Modern Cursor Theming Guide (2025)

## Overview: Hyprcursor + nwg-look Solution

This dotfiles setup uses **modern hyprcursor** technology with **nwg-look** automation for reliable cursor theming on Hyprland/Wayland systems.

## Architecture

### ✅ **Primary System: Hyprcursor**
- **Native Hyprland support** with server-side cursors
- **Better performance** than traditional xcursor
- **Wide app compatibility**: Qt, Chromium, Electron, Hypr Ecosystem

### ✅ **Fallback System: XCursor**
- **Legacy app support** for GTK and older applications
- **Automatic fallback** when hyprcursor isn't supported
- **Seamless integration** with the primary system

### ✅ **Automation: nwg-look**
- **Dynamic theme switching** based on wallpaper categories
- **Wayland-optimized** GTK theme management
- **Configuration export** to all relevant config files

## How It Works

### 1. Dynamic Cursor Configuration
The `dynamic_theme_switcher.sh` automatically:
- Sets both `HYPRCURSOR_THEME` and `XCURSOR_THEME` environment variables
- Generates `~/.config/hypr/cursor-theme.conf` with current theme
- Uses `hyprctl setcursor` for immediate application
- Reloads Hyprland configuration for system-wide changes

### 2. Theme Categories
Each wallpaper category has a specific cursor theme:
- **Space**: `Bibata-Modern-Ice` (futuristic, blue-white)
- **Nature**: `Bibata-Modern-Amber` (warm, earthy)
- **Gaming**: `Bibata-Modern-Classic` (professional, precise)
- **Dark**: `Bibata-Modern-Classic` (sleek, dark)
- **Abstract**: `Bibata-Modern-Amber` (artistic, warm)
- **Minimal**: `Capitaine-Cursors` (clean, macOS-like)

### 3. Application Compatibility

✅ **Immediate hyprcursor support**:
- Hyprland compositor
- Waybar modules
- Qt applications (most modern apps)
- Chromium/Electron apps
- Terminal applications

✅ **XCursor fallback (may need restart)**:
- GTK applications
- Firefox/older browsers
- Some legacy applications

## Configuration Files

### Current Dynamic Configuration
```bash
# Generated automatically by theme switcher
# ~/.config/hypr/cursor-theme.conf

env = HYPRCURSOR_THEME,Bibata-Modern-Ice
env = HYPRCURSOR_SIZE,24

# Fallback for apps that don't support hyprcursor
env = XCURSOR_THEME,Bibata-Modern-Ice
env = XCURSOR_SIZE,24
```

### Manual Override (if needed)
```bash
# Set cursor manually
hyprctl setcursor Bibata-Modern-Amber 24

# Check current themes
echo "HYPRCURSOR_THEME: $HYPRCURSOR_THEME"
echo "XCURSOR_THEME: $XCURSOR_THEME"
```

## Troubleshooting

### Theme Not Applying
1. **Check if hyprcursor theme is installed**:
   ```bash
   find /usr/share/icons -name "manifest.hl" | grep Bibata
   ```

2. **Verify dynamic theme switcher**:
   ```bash
   ./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/space/dark_space.jpg
   cat ~/.config/hypr/cursor-theme.conf
   ```

3. **Force reload**:
   ```bash
   hyprctl reload
   hyprctl setcursor Bibata-Modern-Ice 24
   ```

### Restart Applications
For stubborn applications that don't pick up cursor changes:
```bash
# Restart cursor-sensitive applications
./scripts/theming/restart_cursor_apps.sh

# Manual browser restart
pkill brave && brave > /dev/null 2>&1 &
```

### Check Installation
```bash
# Verify hyprcursor package
pacman -Q hyprcursor

# Check available themes
ls /usr/share/icons/Bibata*/

# Verify nwg-look integration
nwg-look -a
```

## Installation Requirements

### Required Packages
```bash
# Core hyprcursor system
pacman -S hyprcursor

# Cursor themes with hyprcursor support
yay -S bibata-cursor-git

# GTK theme management for Wayland
pacman -S nwg-look
```

### Theme Switching Commands
```bash
# Apply space theme (sets Bibata-Modern-Ice)
./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/space/dark_space.jpg

# Apply nature theme (sets Bibata-Modern-Amber)  
./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/nature/gradiant_sky.png

# Manual cursor change
hyprctl setcursor Bibata-Modern-Classic 24
```

## Benefits of This System

### 🚀 **Performance**
- Server-side cursors reduce client load
- Native Wayland support (no X11 compatibility layer)
- Faster cursor rendering and responsiveness

### 🎨 **Automation**
- Automatic theme switching based on wallpapers
- No manual configuration required
- Consistent theming across all applications

### 🔄 **Reliability**  
- Dual system (hyprcursor + xcursor) ensures compatibility
- nwg-look handles Wayland-specific edge cases
- Immediate application via hyprctl

### 🛠️ **Maintainability**
- Single configuration point in dynamic theme switcher
- Centralized cursor management
- Easy debugging and troubleshooting

This modern system ensures consistent, beautiful cursor theming across your entire Hyprland desktop environment! 