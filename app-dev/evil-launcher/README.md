# Evil Launcher

A minimalist, self-contained TUI application launcher and wallpaper selector for Hyprland, written in Go. Features live wallpaper previews with `chafa` and integrated dynamic theming with [matugen](https://github.com/InioX/matugen).

## 🚀 Features

### Application Launcher (`./launcher launch`)
- **Fast Desktop File Scanning**: Parses `.desktop` files from standard directories
- **Real-time Fuzzy Search**: Instant filtering as you type
- **Clean Process Management**: Proper process isolation with `setpgid`
- **Smart Desktop File Parsing**: Removes command arguments (`%U`, `%F`) automatically
- **No External Dependencies**: Self-contained with minimal system requirements

### Wallpaper Selector (`./launcher wall`)
- **Category-Based Organization**: Automatically detects wallpaper categories
- **Live Previews**: Real-time wallpaper previews using `chafa` (when available)
- **Random Selection**: Built-in random wallpaper option
- **`swww` Integration**: Seamless wallpaper setting with transition effects
- **🎨 Dynamic Theming**: **[NEW]** Automatic theme switching based on wallpaper category

## 🎨 Dynamic Theming Integration

Evil Launcher integrates with the dotfiles' comprehensive dynamic theming system, automatically applying themes based on wallpaper categories:

### Theme Categories
- **🌌 Space**: Futuristic dark themes (Graphite-Dark + Papirus-Dark + Bibata-Modern-Ice)
- **🌿 Nature**: Organic earth-toned themes (Orchis-Green-Dark + Tela-circle-green + Bibata-Modern-Amber)
- **🎮 Gaming**: High-contrast performance themes (Graphite-Dark + Papirus + Bibata-Modern-Classic)
- **⭕ Minimal**: Clean simple themes (WhiteSur-Light + WhiteSur + Capitaine-Cursors)
- **🌑 Dark**: Pure dark mode themes (Graphite-Dark + Papirus-Dark + Bibata-Modern-Classic)
- **🎨 Abstract**: Artistic colorful themes (Graphite + Papirus + Bibata-Modern-Amber)

### What Gets Themed
When you select a wallpaper, the system automatically updates:
- **GTK Themes**: Window decorations, buttons, menus
- **Icon Themes**: Application and system icons
- **Cursor Themes**: Mouse cursor appearance
- **Material You Colors**: Generated from wallpaper for Waybar, Kitty, Dunst, Fuzzel
- **Application Configs**: Hyprland, Waybar, Starship prompt colors

## 🏗️ Architecture

### Core Components
- **TUI Rendering**: Custom ANSI escape code implementation
- **Raw Terminal Input**: Direct `stty` integration for responsive controls
- **Desktop File Parser**: Manual `.desktop` file parsing (no external libraries)
- **Image Preview System**: Optional `chafa` integration with error handling
- **Theme Integration**: Calls existing dynamic theme switcher system

### Dependencies
- **Required**: Go 1.24.4+, `swww`, `stty` (standard on Linux)
- **Optional**: `chafa` (for wallpaper previews)
- **Theme System**: `dynamic_theme_switcher.sh`, `matugen`, `nwg-look`

## 📦 Installation & Usage

### Build
```bash
cd app-dev/evil-launcher
go build -o launcher .
```

### Usage
```bash
# Launch applications
./launcher launch

# Select wallpapers (with dynamic theming)
./launcher wall
```

### Controls
- **Arrow Keys**: Navigate up/down
- **Type**: Real-time fuzzy search
- **Enter**: Select and execute
- **Backspace**: Delete search characters  
- **Ctrl+C / Escape**: Exit

## 🔧 Configuration

### Wallpaper Directory
```go
wallpaperDir = "/dotfiles/assets/wallpapers"
```

### Application Directories
```go
appDirs = []string{"/usr/share/applications", "/.local/share/applications"}
```

### Theme Integration
The launcher automatically detects wallpaper categories from directory structure:
```
~/dotfiles/assets/wallpapers/
├── space/     → Space theme
├── nature/    → Nature theme
├── gaming/    → Gaming theme
├── minimal/   → Minimal theme
├── dark/      → Dark theme
└── abstract/  → Abstract theme
```

## 🚧 Development Status

### ✅ Completed (Phase 1)
- Core TUI application launcher
- Wallpaper selection with live previews
- Integration with `swww` wallpaper daemon
- Basic category detection from file paths

### 🔄 In Progress (Phase 2)
- **Dynamic Theme Integration**: Automatic theme switching on wallpaper change
- **Enhanced Error Handling**: Graceful degradation when theme system unavailable
- **Progress Feedback**: User feedback during theme application
- **Category Display**: Show wallpaper categories in selection interface

### 📋 Planned (Phase 3)
- **Theme-Only Mode**: `./launcher theme` for theme switching without wallpaper change
- **Configuration File**: External config for paths and theme mappings
- **Icon Support**: Display application icons in launcher
- **Extended File Formats**: Support for more image formats

## 🔗 Integration with Dotfiles

### Replaces Fuzzel Workflow
Evil Launcher serves as a **drop-in replacement** for the current fuzzel-based wallpaper selection:

**Before**: `wallpaper_manager.sh select` → fuzzel (category) → fuzzel (wallpaper) → theme
**After**: `./launcher wall` → TUI selection → automatic theming

### Maintains Compatibility
- ✅ Same wallpaper directory structure
- ✅ Same `swww` commands and transitions
- ✅ Same theme switching logic via `dynamic_theme_switcher.sh`
- ✅ Same Material You color generation with `matugen`
- ✅ Same application restart workflow

### Enhanced User Experience
- **Single Interface**: One tool for apps and wallpapers
- **Live Previews**: See wallpapers before selection
- **Better Performance**: Go's speed vs bash script overhead
- **Unified Navigation**: Consistent keyboard controls

## 🐛 Known Issues

1. **Theme Application Delay**: Theme switching takes 2-3 seconds, no progress indicator yet
2. **Error Propagation**: Theme system errors not yet displayed to user
3. **Preview Sizing**: `chafa` preview dimensions could be better optimized
4. **Hard-coded Paths**: Configuration should be externalized

## 📚 Related Documentation

- `CHANGE_PLAN.md`: Detailed implementation roadmap
- `DEVLOG.md`: Development progress and decisions
- `../../../docs/DYNAMIC_THEMES.md`: Complete theming system documentation
- `../../../scripts/theming/`: Theme switching scripts and configuration

## 🤝 Contributing

This is part of a comprehensive dotfiles system focusing on:
- **Performance**: Fast, responsive user interfaces
- **Integration**: Seamless workflow between components  
- **Theming**: Automated, beautiful dynamic themes
- **Reliability**: Robust error handling and fallbacks

For development guidelines, see `DEVLOG.md` and the project's change plan. 