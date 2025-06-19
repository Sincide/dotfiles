# Evil Space Dotfiles - System Overview (2025)

## 🌌 Complete Modern Desktop Environment

This repository contains a **production-ready Arch Linux + Hyprland configuration** featuring cutting-edge 2025 technologies for reliable, beautiful, and automated desktop theming.

## 🚀 Modern Technology Stack

### **Core Desktop Environment**
- **Hyprland**: Wayland compositor with advanced features
- **Waybar**: Dual-bar system (controls + GPU monitoring)
- **Dunst**: Dynamic notifications with cosmic theming
- **Fuzzel**: Fast application launcher
- **Kitty**: High-performance terminal with dynamic theming

### **Advanced Theming Technologies**
- **Hyprcursor**: Server-side cursor system (2025 standard)
- **nwg-look**: Wayland-optimized GTK theme management
- **Matugen**: AI-powered Material You color extraction
- **Dynamic Theme Switching**: Category-based complete theme packages

### **AI & Automation**
- **Ollama**: Local AI models with interactive selection
- **Intelligent Theming**: Automatic color harmony analysis
- **Dynamic Adaptation**: Real-time system responses to changes

## 🎨 Theming Architecture

### **Three-Layer System**

#### 1. **Primary Layer: Hyprcursor**
- Native Hyprland server-side cursors
- Instant theme switching with `hyprctl setcursor`
- Better performance than traditional xcursor
- Wide compatibility (Qt, Chromium, Electron, Hypr Ecosystem)

#### 2. **Application Layer: nwg-look**
- Wayland-optimized GTK theme management
- Exports configurations to all GTK versions (3.0, 4.0)
- Handles libadwaita and modern GTK applications
- Resolves Wayland-specific theming challenges

#### 3. **Color Layer: Material You**
- AI-powered color extraction from wallpapers
- Dynamic palette generation for all applications
- Consistent color harmony across the desktop
- Template-based configuration system

### **Wallpaper-Driven Categories**

Each category provides a complete aesthetic transformation:

| Category | GTK Theme | Icons | Cursor | Aesthetic |
|----------|-----------|-------|--------|-----------|
| 🌌 **Space** | Graphite-Dark | Papirus-Dark | Bibata-Modern-Ice | Futuristic, dark |
| 🌿 **Nature** | Orchis-Green-Dark | Tela-circle-green | Bibata-Modern-Amber | Organic, earthy |
| 🎮 **Gaming** | Graphite-Dark | Papirus | Bibata-Modern-Classic | High-contrast |
| ⭕ **Minimal** | WhiteSur-Light | WhiteSur | Capitaine-Cursors | Clean, simple |
| 🌑 **Dark** | Graphite-Dark | Papirus-Dark | Bibata-Modern-Classic | Professional |
| 🎨 **Abstract** | Graphite | Papirus | Bibata-Modern-Amber | Artistic, colorful |

## 🛠️ System Components

### **Theming Scripts**
- `dynamic_theme_switcher.sh` - Main theming orchestrator with nwg-look integration
- `wallpaper_manager.sh` - Wallpaper selection with automatic theme triggering
- `restart_cursor_apps.sh` - Application restart for immediate theme application

### **Configuration Files**
- `~/.config/hypr/cursor-theme.conf` - Dynamic hyprcursor + xcursor variables
- `~/.config/gtk-3.0/settings.ini` - GTK3 theme preferences (auto-updated)
- `~/.config/gtk-4.0/settings.ini` - GTK4 theme preferences (auto-updated)
- `matugen/config.toml` - Material You color generation settings
- `matugen/templates/` - Application-specific color templates

### **Monitoring & Performance**
- Real-time AMDGPU monitoring (temperature, fan, usage, VRAM, power)
- Intelligent visual indicators with performance-based styling
- Dual Waybar system for comprehensive system overview

## 🔧 Installation & Setup

### **Automatic Installation**
```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### **Required Packages (Auto-installed)**
```bash
# Core theming system
pacman -S hyprcursor nwg-look
yay -S bibata-cursor-git matugen

# Theme packages
# Graphite, Orchis, WhiteSur themes
# Papirus, Tela icons
# Complete package management in installer
```

### **Post-Installation**
1. Reboot to activate all services
2. Select Ollama AI models during first startup
3. Change wallpaper to test dynamic theming
4. Enjoy the modern evil space desktop experience

## 🎯 Key Benefits

### **🚀 Performance**
- Server-side cursors reduce client load
- Native Wayland support (no X11 compatibility layers)
- Efficient color generation and template caching

### **🎨 Reliability**
- Proven theme packages that actually work in 2025
- Dual-system approach (hyprcursor + xcursor fallback)
- nwg-look handles all Wayland edge cases

### **🔄 Automation**
- Zero manual theme configuration required
- Intelligent wallpaper category detection
- Instant desktop-wide theme coordination

### **🛠️ Maintainability**
- Centralized theme management
- Clean, documented configuration files
- Easy customization and debugging

## 📚 Documentation

### **User Guides**
- `docs/CURSOR_TROUBLESHOOTING.md` - Modern cursor theming guide
- `docs/DYNAMIC_THEMES.md` - Complete theming system documentation
- `docs/MIGRATION_TO_DYNAMIC_THEMES.md` - Migration from older systems

### **Development**
- All scripts include comprehensive comments
- Template system for easy customization
- Modular architecture for easy extension

## 🌟 Advanced Features

### **AI Integration**
- Local Ollama models for enhanced system intelligence
- Smart color harmony analysis
- Intelligent theme recommendations

### **Real-time Monitoring**
- GPU performance tracking with visual feedback
- System health indicators
- Dynamic performance-based theming adjustments

### **Professional Appearance**
- Glassmorphism design elements
- Cosmic space aesthetic
- Professional animations and transitions

## 🔮 Future-Proof Design

This system is built for 2025 and beyond:
- Uses cutting-edge Wayland technologies
- Bypasses deprecated theming methods
- Embraces modern design standards
- Ready for future Hyprland developments

The result is a **cohesive, beautiful, and highly functional desktop environment** that automatically adapts to your aesthetic preferences while maintaining excellent performance and reliability.

---

*For detailed component documentation, see the specific guides in the `docs/` directory.* 