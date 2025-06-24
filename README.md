# 🌌 Evil Space Dotfiles

**Transform your Arch Linux into a beautiful, intelligent desktop experience**

A complete Hyprland + Material Design 3 setup with dynamic theming, real-time GPU monitoring, and AI integration. Everything works out of the box with one simple command.

![Desktop Preview](assets/screenshots/desktop-preview.png)

## ✨ What You Get

🎨 **Dynamic Theming** - Colors change instantly based on your wallpaper  
📊 **Dual Status Bars** - Clean controls + comprehensive AMD GPU monitoring  
🤖 **AI Integration** - Local AI models with Ollama  
🌌 **Space Theme** - Beautiful cosmic aesthetic with glassmorphism effects  
⚡ **High Performance** - Optimized for AMD GPUs with real-time monitoring  
🚀 **One-Click Setup** - Complete installation in 45-90 minutes  

## 🚀 Quick Start

### Prerequisites
- Fresh Arch Linux installation
- Internet connection  
- AMD GPU (recommended for full monitoring features)

### Installation
```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

That's it! The installer will:
- Install 397 packages across 6 categories
- Set up Hyprland with beautiful animations
- Configure dynamic theming system
- Set up dual Waybar with GPU monitoring
- Install and configure AI integration
- Apply space-themed styling throughout

### After Installation
1. **Reboot** your system
2. **Log in** to Hyprland
3. **Change wallpaper** to see theming in action
4. **Enjoy your new desktop!** 🌌

## 📱 Main Features

### 🎨 Dynamic Material Design 3 Theming
- **Instant color adaptation** from any wallpaper
- **System-wide consistency** across all applications
- **Intelligent color harmony** with Material You algorithms
- **6 theme categories** with optimized presets

### 📊 Professional Status Bars

**Top Bar:**
- 🚀 App launcher and workspace indicators
- 🎵 Media controls with album art
- 🌐 Network info with speeds
- 🗓️ Date/time with calendar

**Bottom Bar (AMD GPU Focus):**
- 🌡️ GPU temperature with color-coded warnings
- 🌪️ Fan speed monitoring with visual indicators  
- ⚡ GPU usage with performance metrics
- 🧠 VRAM usage tracking
- 🔋 Power consumption monitoring

### 🤖 AI Integration
- **Local AI models** with Ollama
- **Privacy-focused** - no data leaves your machine
- **Interactive model selection** during setup
- **Smart theming assistance** for color harmony

### 🖥️ Desktop Environment
- **Hyprland** - Modern Wayland compositor
- **Dynamic workspaces** with smooth animations
- **Intelligent window tiling** with floating support
- **Cosmic visual effects** and space theming

## 🛠️ What's Included

### Core Applications
| Category | Count | Examples |
|----------|-------|----------|
| **Essential** | 89 | System tools, drivers, basics |
| **Development** | 67 | VS Code, Git, programming tools |
| **Multimedia** | 45 | OBS, GIMP, audio/video tools |
| **Gaming** | 23 | Steam, Lutris, compatibility |
| **Theming** | 18 | Icons, cursors, GTK themes |
| **Optional** | 15 | Extra utilities and tools |

### Key Components
- **Hyprland** - Wayland compositor
- **Waybar** - Status bars with monitoring
- **Kitty** - GPU-accelerated terminal
- **Fish Shell** - Smart command line
- **Matugen** - Material Design 3 colors
- **Ollama** - Local AI platform
- **Dunst** - Smart notifications

## 🎛️ Customization

### Change Wallpaper and Theme
```bash
# Use the wallpaper manager (includes theme switching)
~/dotfiles/scripts/theming/wallpaper_manager.sh

# Or directly change wallpaper (auto-themes)
~/dotfiles/scripts/theming/set_wallpaper.sh /path/to/image.jpg
```

### Customize Colors
```bash
# Generate theme from specific image
matugen image /path/to/wallpaper.jpg

# Apply changes
~/dotfiles/scripts/theming/apply_theme.sh
```

### GPU Monitoring Thresholds
Edit temperature warnings in `scripts/theming/gpu_temp_monitor.sh`:
```bash
TEMP_WARNING=85     # Warning threshold (°C)
TEMP_CRITICAL=100   # Critical threshold (°C)
```

### Add Custom Waybar Modules
1. Edit `waybar/config` or `waybar/config-bottom`
2. Add your module configuration
3. Style it in the corresponding CSS file
4. Restart: `pkill waybar && waybar &`

## 🔧 Post-Installation Features

The installer is **safe to rerun** and includes maintenance modes:

```bash
./install.sh  # Shows different menu after installation
```

**Maintenance Options:**
- 🔄 **Reinstall Dependencies** - Safely update all packages
- 🗄️ **Setup External Drives** - Mount drives to `/mnt` and add to fstab
- 🎯 **Custom Phases** - Rerun specific installation phases
- 🧪 **Dry-Run Testing** - Test changes without applying them

### External Drive Management
All external drives are automatically mounted to `/mnt/[drive-label]` and added to fstab for permanent mounting. No more `/run/media` issues!

## 🌡️ GPU Monitoring

### Supported Hardware
- **AMD RX 7000 Series** - Full monitoring (temp, fan, usage, VRAM, power)
- **AMD RX 6000 Series** - Complete monitoring support
- **AMD RX 5000 Series** - Temperature, fan, and usage monitoring
- **Other AMD GPUs** - Basic monitoring available

### Visual Indicators
- **Temperature**: ❄️ Cool → 🌡️ Normal → 🔥 Warning → 💀 Critical
- **Fan Speed**: 😴 Idle → 🌬️ Low → 💨 Medium → 🌪️ High  
- **GPU Usage**: 💤 Low → 🔋 Medium → ⚡ High → 🚀 Maximum
- **VRAM**: 🟢 Plenty → 🟡 Medium → 🟠 High → 🔴 Critical

## 💡 Tips and Tricks

### Keyboard Shortcuts
- `Super + Return` - Open terminal
- `Super + D` - Application launcher
- `Super + E` - File manager
- `Super + W` - Wallpaper selector
- `Super + L` - Lock screen

### Useful Commands
```bash
# Check installation status
./install.sh --status

# Test GPU monitoring
~/dotfiles/scripts/theming/test_amdgpu_sensors.sh

# Update AI models
ollama pull codellama:latest

# Restart theming system
~/dotfiles/scripts/theming/restart_theming.sh
```

## 🚨 Troubleshooting

### Installation Issues
```bash
# Update system first
sudo pacman -Syu

# Clear cache and retry
yay -Sc
./install.sh
```

### Theming Not Working
```bash
# Regenerate theme
matugen image ~/dotfiles/assets/wallpapers/space/nebula.jpg
~/dotfiles/scripts/theming/apply_theme.sh
```

### GPU Monitoring Not Working
```bash
# Test AMDGPU detection
~/dotfiles/scripts/theming/amdgpu_check.sh

# Check sensor paths
ls /sys/class/drm/card*/device/hwmon/
```

### Get Help
- **Logs**: Check `~/dotfiles/logs/` for installation logs
- **System**: Use `journalctl --user -f` for service logs
- **GPU**: Run `~/dotfiles/scripts/theming/test_amdgpu_sensors.sh`

## 🌟 What Makes This Special

### 🎨 **2025-Ready Theming**
Uses the latest theming technologies optimized for Hyprland and Wayland:
- **Hyprcursor** for modern cursor theming
- **nwg-look** for Wayland GTK management  
- **Material You** algorithms for intelligent color extraction

### 📊 **Professional Monitoring**
- Real-time AMD GPU metrics with visual feedback
- Dynamic threshold alerts with color-coded warnings
- Performance tracking optimized for gaming and content creation

### 🤖 **Privacy-First AI**
- All AI processing happens locally on your machine
- No data sent to external servers
- Choose from 14+ specialized models for different tasks

### 🚀 **Production Ready**
- Thoroughly tested on fresh Arch installations
- Idempotent scripts safe to run multiple times
- Comprehensive error handling and recovery
- Professional documentation and support

## 🤝 Contributing

We welcome contributions! Areas where you can help:

- 🐛 **Bug Reports** - Found an issue? Let us know!
- 🎨 **New Themes** - Create templates for other applications
- 📊 **Monitoring** - Add support for NVIDIA/Intel GPUs
- 📚 **Documentation** - Improve guides and tutorials
- ✨ **Features** - Suggest and implement new functionality

### Development Setup
1. Fork the repository
2. Create feature branch: `git checkout -b feature/awesome-feature`
3. Test on clean Arch Linux VM
4. Submit pull request with clear description

## 📄 License

MIT License - feel free to use, modify, and share!

## 🙏 Thanks

Built with amazing open-source projects:
- [Hyprland](https://hyprland.org/) - Modern Wayland compositor
- [Waybar](https://github.com/Alexays/Waybar) - Customizable status bar
- [Matugen](https://github.com/InioX/matugen) - Material Design 3 theming
- [Ollama](https://ollama.ai/) - Local AI platform

---

<div align="center">

### 🌌 **Ready to transform your desktop?** 🚀

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
```

**⭐ Star this repo if it helped you create an awesome desktop!**

</div>