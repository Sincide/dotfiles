# Dynamic Theming System

A complete wallpaper-based dynamic theming system for Hyprland that automatically adapts your entire desktop theme to match your wallpaper colors.

## ✨ Features

- **Simple Selection**: Use fuzzel to choose wallpapers from a clean menu
- **Automatic Theming**: Extracts colors from wallpapers and applies them across all applications
- **Smooth Transitions**: Beautiful wallpaper transitions with swww
- **Complete Integration**: Updates Hyprland, Waybar (dual bars), Kitty, Dunst, and Fuzzel
- **One Keybind**: Press `Super+B` for instant wallpaper + theme changes

## 🎯 How It Works

1. **Press Super+B** → Opens fuzzel with your wallpaper collection
2. **Select wallpaper** → Sets wallpaper with swww (smooth wipe transition)
3. **Automatic magic** → Extracts colors with matugen and updates all applications
4. **Live updates** → Waybar, terminal, notifications instantly reflect new colors

## 📦 Installation

### Required Packages

```bash
# Core packages (add to install.sh)
sudo pacman -S swww matugen fuzzel

# Additional dependencies
cargo install matugen  # If not in repos
```

### File Structure

```
dotfiles/
├── assets/wallpapers/          # Your wallpaper collection
├── config/matugen/
│   ├── config.toml            # Matugen configuration
│   └── templates/             # Color templates for each app
│       ├── hyprland-colors.conf
│       ├── waybar-style.css
│       ├── waybar-style-bottom.css
│       ├── kitty.conf
│       ├── dunst.conf
│       └── fuzzel.ini
├── scripts/
│   ├── wallpaper-selector.sh  # Main wallpaper picker (Super+B)
│   └── wallpaper-theme-changer.sh  # Theme application logic
└── config/
    ├── hypr/conf/
    │   ├── keybinds.conf      # Super+B keybinding
    │   └── startup.conf       # swww auto-start
    ├── waybar/
    │   ├── style-dynamic.css  # Generated top bar theme
    │   └── style-bottom-dynamic.css  # Generated bottom bar theme
    ├── kitty/
    │   └── theme-dynamic.conf # Generated terminal colors
    ├── dunst/
    │   └── dunstrc-dynamic    # Generated notification theme
    └── fuzzel/
        └── fuzzel-dynamic.ini # Generated launcher theme
```

## ⚙️ Configuration

### Matugen Setup (`config/matugen/config.toml`)

```toml
[config]
reload_apps = true
set_wallpaper = false  # swww handles wallpaper setting
prefix = ""

[templates.hyprland]
input_path = "~/.config/matugen/templates/hyprland-colors.conf"
output_path = "~/.config/hypr/conf/colors.conf"

[templates.waybar]
input_path = "~/.config/matugen/templates/waybar-style.css"  
output_path = "~/.config/waybar/style-dynamic.css"

[templates.waybar-bottom]
input_path = "~/.config/matugen/templates/waybar-style-bottom.css"  
output_path = "~/.config/waybar/style-bottom-dynamic.css"

[templates.kitty]
input_path = "~/.config/matugen/templates/kitty.conf"
output_path = "~/.config/kitty/theme-dynamic.conf"

[templates.dunst]
input_path = "~/.config/matugen/templates/dunst.conf"
output_path = "~/.config/dunst/dunstrc-dynamic"

[templates.fuzzel]
input_path = "~/.config/matugen/templates/fuzzel.ini"
output_path = "~/.config/fuzzel/fuzzel-dynamic.ini"
```

### Hyprland Integration

**Keybinding** (`config/hypr/conf/keybinds.conf`):
```bash
bind = $mainMod, B, exec, ~/dotfiles/scripts/wallpaper-selector.sh
```

**Startup** (`config/hypr/conf/startup.conf`):
```bash
exec-once = waybar -s ~/.config/waybar/style-dynamic.css
exec-once = waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css
exec-once = swww init && swww img ~/dotfiles/assets/wallpapers/evilpuccin.png
exec-once = dunst
```

## 🚀 Usage

### Basic Usage
- **Super+B**: Open wallpaper selector
- **Select wallpaper**: Choose from fuzzel menu
- **Automatic**: Theme applies instantly

### Advanced Usage
```bash
# Manual wallpaper change with theming
./scripts/wallpaper-selector.sh

# Apply theme to current wallpaper
./scripts/wallpaper-theme-changer.sh

# Apply theme to specific wallpaper
./scripts/wallpaper-theme-changer.sh /path/to/wallpaper.png

# Set wallpaper only (no theming)
swww img ~/dotfiles/assets/wallpapers/image.png
```

## 🎨 Color Variables

Templates use Material Design 3 color tokens:

### Primary Colors
- `{{colors.primary.dark.hex}}` - Main accent color
- `{{colors.primary.dark.rgba}}` - With transparency
- `{{colors.on_primary.dark.hex}}` - Text on primary

### Surface Colors  
- `{{colors.surface.dark.rgba}}` - Background surfaces
- `{{colors.surface_variant.dark.rgba}}` - Secondary surfaces
- `{{colors.on_surface.dark.hex}}` - Text on surfaces

### Semantic Colors
- `{{colors.error.dark.hex}}` - Error states
- `{{colors.tertiary.dark.hex}}` - Tertiary accent
- `{{colors.outline.dark.hex}}` - Borders and dividers

## 📝 Template Examples

### Waybar Module Styling
```css
#cpu {
    color: {{colors.primary.dark.hex}};
    background: {{colors.surface_variant.dark.rgba}};
    border-radius: 10px;
    min-width: 70px;
}

#cpu:hover {
    background: {{colors.primary_container.dark.rgba}};
    box-shadow: inset 0 0 0 1px {{colors.primary.dark.hex}};
}
```

### Hyprland Window Borders
```bash
decoration {
    col.active_border = {{colors.primary.dark.hex}}
    col.inactive_border = {{colors.outline.dark.hex}}
}
```

## 🔧 Scripts Overview

### `wallpaper-selector.sh`
- Main interface triggered by Super+B
- Shows fuzzel menu with wallpaper names
- Sets wallpaper with swww transitions
- Calls theme script automatically
- Provides user notifications

### `wallpaper-theme-changer.sh`
- Generates colors with matugen
- Restarts applications with new themes
- Handles both manual and automatic calls
- Comprehensive error handling and logging

## 📊 Supported Applications

| Application | Dynamic Component | Template |
|-------------|------------------|----------|
| **Hyprland** | Window borders, workspace colors | `hyprland-colors.conf` |
| **Waybar Top** | Status bar, modules, backgrounds | `waybar-style.css` |
| **Waybar Bottom** | GPU info bar, system stats | `waybar-style-bottom.css` |
| **Kitty** | Terminal colors, backgrounds | `kitty.conf` |
| **Dunst** | Notification styling | `dunst.conf` |
| **Fuzzel** | Application launcher | `fuzzel.ini` |

## 📁 Wallpaper Management

### Supported Formats
- PNG, JPG, JPEG, WEBP
- Any resolution (swww handles scaling)
- Stored in `~/dotfiles/assets/wallpapers/`

### Adding Wallpapers
```bash
# Copy new wallpapers
cp new-wallpaper.png ~/dotfiles/assets/wallpapers/

# They'll appear automatically in fuzzel menu
```

## 🐛 Troubleshooting

### Common Issues

**Fuzzel doesn't show wallpapers:**
```bash
ls ~/dotfiles/assets/wallpapers/  # Check wallpapers exist
echo $XDG_CURRENT_DESKTOP         # Should be "Hyprland"
```

**swww daemon not running:**
```bash
pkill swww-daemon
swww init
```

**Theme not applying:**
```bash
# Check logs
tail -f /tmp/wallpaper-selector.log
tail -f /tmp/wallpaper-theme.log

# Test matugen manually
matugen image ~/dotfiles/assets/wallpapers/test.png --mode dark
```

**Waybar not restarting:**
```bash
# Check if waybar is running
pgrep waybar

# Restart manually
pkill waybar
waybar -s ~/.config/waybar/style-dynamic.css &
waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css &
```

### Log Files
- `/tmp/wallpaper-selector.log` - Main selector activity
- `/tmp/wallpaper-theme.log` - Theme application details
- `/tmp/matugen.log` - Color generation output

### Debug Commands
```bash
# Test wallpaper selection
./scripts/wallpaper-selector.sh

# Test theme application
./scripts/wallpaper-theme-changer.sh ~/dotfiles/assets/wallpapers/test.png

# Check current wallpaper
swww query

# Verify dynamic CSS generation
ls -la ~/.config/waybar/style-dynamic.css
head -20 ~/.config/waybar/style-dynamic.css
```

## 🎯 Performance

- **Color extraction**: ~1-2 seconds per wallpaper
- **Application restart**: ~2-3 seconds total
- **Memory usage**: Minimal overhead
- **Transitions**: Smooth 2-second wipe effect

## 🔮 Future Enhancements

- [ ] **Preview mode**: Show color preview before applying
- [ ] **Wallpaper categories**: Organize by mood/time/season
- [ ] **Transition effects**: More swww transition options
- [ ] **Auto-theming**: Time-based or automatic wallpaper rotation
- [ ] **Theme presets**: Save and restore favorite combinations

---

**Enjoy your beautiful, dynamically themed desktop! 🌈** 