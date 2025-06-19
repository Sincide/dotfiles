# Dynamic Theme Switching System

A revolutionary approach to desktop theming that automatically switches GTK themes, icons, and cursors based on your wallpaper category.

## 🎯 Why Dynamic Themes?

After extensive research into GTK theming in 2025, we discovered that:
- **libadwaita actively blocks custom theming** 
- **Gradience is archived** (July 2024)
- **matugen + GTK CSS approach is unreliable**

The solution? **Dynamic theme switching** - change entire theme packages based on wallpaper aesthetics.

## 🎨 Theme Categories & Mappings

### 🌌 Space Wallpapers
- **GTK Theme**: Nordic (Dark, futuristic)
- **Icons**: Papirus-Dark (Colorful, space-like)
- **Cursor**: Bibata-Modern-Ice (Clean, white)

### 🌿 Nature Wallpapers  
- **GTK Theme**: Orchis-Green-Dark (Organic, natural)
- **Icons**: Tela-circle-green (Nature-inspired)
- **Cursor**: Bibata-Modern-Amber (Warm, earthy)

### 🎮 Gaming Wallpapers
- **GTK Theme**: Ultimate-Dark (High contrast)
- **Icons**: Papirus (Vibrant, colorful)
- **Cursor**: Bibata-Modern-Classic (Sharp, precise)

### 🎯 Minimal Wallpapers
- **GTK Theme**: WhiteSur-Light (Clean, macOS-like)
- **Icons**: WhiteSur (Minimalist, elegant)
- **Cursor**: Capitaine-Cursors (Simple, refined)

### 🌑 Dark Wallpapers
- **GTK Theme**: Graphite-Dark (Pure dark)
- **Icons**: Qogir-dark (Subtle, dark)
- **Cursor**: Bibata-Modern-Classic (Professional)

### 🎨 Abstract Wallpapers
- **GTK Theme**: Yaru-Colors (Colorful, artistic)
- **Icons**: Numix-Circle (Creative, circular)
- **Cursor**: Bibata-Modern-Amber (Artistic, warm)

## 🚀 Installation

### 1. Automatic Installation (Recommended)
```bash
cd ~/dotfiles
./scripts/setup/dotfiles-installer.sh
```

During installation, you'll be prompted to:
- Pre-cache themes to avoid re-downloading
- Install dynamic themes
- Configure theme mappings  
- Test the system

### 2. Manual Installation
```bash
cd ~/dotfiles
./scripts/theming/dynamic_theme_switcher.sh install
```

This will:
- Create configuration file at `~/.config/dynamic-themes.conf`
- Install all required themes, icons, and cursors
- Set up automatic theme switching

## 📦 Theme Cache System

The system includes a smart caching mechanism that stores themes locally in your dotfiles directory:

**Cache Location**: `~/dotfiles/themes/cached/`

**Benefits**:
- ✅ No re-downloading themes on fresh installs
- ✅ Faster theme installation (cached themes install in seconds)
- ✅ Offline installation capability for git-based themes
- ✅ Backup of theme sources in your dotfiles

**Cache Management**:
```bash
# Cache all git-based themes
./scripts/theming/theme_cache_manager.sh cache-all

# List cached themes
./scripts/theming/theme_cache_manager.sh list

# Install specific theme (from cache if available)
./scripts/theming/theme_cache_manager.sh install Nordic

# Clean cache
./scripts/theming/theme_cache_manager.sh clean

# Show available themes
./scripts/theming/theme_cache_manager.sh list-available
```

### 3. Test Theme Switching
```bash
# Apply space theme
./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/space/dark_space.jpg

# Apply nature theme  
./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/nature/gradiant_sky.png

# Apply gaming theme
./scripts/theming/dynamic_theme_switcher.sh apply assets/wallpapers/gaming/sudo-linux_5120.png
```

### 4. Integration with Wallpaper Manager
The system automatically integrates with your existing wallpaper manager:

```bash
# This now applies dynamic themes automatically
./scripts/theming/wallpaper_manager.sh select
```

## 🛠️ Commands

### View Available Themes
```bash
./scripts/theming/dynamic_theme_switcher.sh list
```

### Customize Configuration
```bash
./scripts/theming/dynamic_theme_switcher.sh config
# Edit ~/.config/dynamic-themes.conf to customize mappings
```

### Manual Theme Application
```bash
./scripts/theming/dynamic_theme_switcher.sh apply <wallpaper_path>
```

## 📋 Theme Installation Details

### GTK Themes
- **Nordic**: Dark theme with blue accents
- **Orchis-Green-Dark**: Nature-inspired green theme
- **Ultimate-Dark**: High-contrast dark theme
- **WhiteSur-Light**: macOS Big Sur inspired light theme
- **Graphite-Dark**: Material Design dark theme
- **Yaru-Colors**: Ubuntu's colorful theme variants

### Icon Themes
- **Papirus/Papirus-Dark**: Most popular Linux icon theme
- **Tela-circle-green**: Circular nature-themed icons
- **WhiteSur**: macOS-style icons
- **Qogir-dark**: Flat, minimalist dark icons
- **Numix-Circle**: Circular, colorful icons

### Cursor Themes
- **Bibata-Modern-Ice**: White, modern cursors
- **Bibata-Modern-Amber**: Warm, amber cursors
- **Bibata-Modern-Classic**: Black, professional cursors
- **Capitaine-Cursors**: macOS-inspired cursors

## 🔧 Customization

Edit `~/.config/dynamic-themes.conf` to customize theme mappings:

```ini
[space]
gtk=Nordic
icons=Papirus-Dark
cursor=Bibata-Modern-Ice

[nature]
gtk=Orchis-Green-Dark
icons=Tela-circle-green
cursor=Bibata-Modern-Amber
# ... etc
```

## 🎯 Benefits

1. **Reliable**: No fighting with libadwaita's anti-theming
2. **Comprehensive**: Themes everything (GTK, icons, cursors)
3. **Automatic**: Changes based on wallpaper category
4. **Customizable**: Easy to modify theme mappings
5. **Modern**: Uses 2025's best available themes

## 🔄 Migration from matugen

The system maintains backward compatibility:
- If dynamic theme switcher is missing, falls back to matugen
- Existing wallpaper manager commands work unchanged
- GTK configurations preserved for manual overrides

## 🎨 Result

Each wallpaper category now gets a **complete aesthetic transformation**:
- Space wallpapers → Futuristic, dark UI
- Nature wallpapers → Organic, green UI  
- Gaming wallpapers → High-contrast, RGB UI
- Minimal wallpapers → Clean, light UI
- Dark wallpapers → Pure dark UI
- Abstract wallpapers → Colorful, artistic UI

This creates a **cohesive visual experience** where your entire desktop adapts to match your wallpaper's mood and aesthetic. 