# 🌌 Evil Space Dotfiles - Arch Linux + Hyprland

*A comprehensive, production-ready dotfiles configuration featuring dynamic Material Design 3 theming, dual Waybar monitoring, and complete system automation*

<div align="center">

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00D9FF?style=for-the-badge&logo=wayland&logoColor=white)
![Material Design](https://img.shields.io/badge/Material_Design_3-757575?style=for-the-badge&logo=material-design&logoColor=white)
![GPU Monitoring](https://img.shields.io/badge/AMDGPU-ED1C24?style=for-the-badge&logo=amd&logoColor=white)
![AI Integration](https://img.shields.io/badge/AI_Powered-FF6B6B?style=for-the-badge&logo=openai&logoColor=white)

</div>

---

## 🚀 Features Overview

### 🌌 **Evil Space Desktop Environment**
- **Dual Waybar System**: Professional top bar + comprehensive AMDGPU monitoring bottom bar
- **Dynamic Material Design 3 Theming**: Entire system adapts colors instantly to any wallpaper
- **Real-time GPU Monitoring**: Temperature, fan speed, usage, VRAM, and power consumption with visual indicators
- **System-wide GTK Integration**: Complete theming consistency across all desktop applications
- **Cosmic Visual Design**: Space-themed aesthetic with glassmorphism styling and professional animations

### 🤖 **AI-Enhanced Experience**
- **Ollama Integration**: Local AI models with interactive selection and boot-time activation
- **Intelligent Theming**: Automatic color harmony analysis and Material Design 3 palette generation
- **Smart Monitoring**: Dynamic visual indicators that adapt based on system performance

### 📦 **Zero-Intervention Setup**
- **Comprehensive Installer**: Beautiful gum-powered TUI with complete automation
- **Fresh Install Ready**: Everything works perfectly on clean Arch installations
- **Intelligent Package Management**: 6 organized categories with robust error handling
- **Complete Environment Setup**: From bare Arch to full desktop in one command

---

## 📋 Table of Contents

- [🎯 Quick Start](#-quick-start)
- [🌟 System Components](#-system-components)
- [🎨 Theming System](#-theming-system)
- [🚀 Waybar Configuration](#-waybar-configuration)
- [🌡️ GPU Monitoring](#️-gpu-monitoring)
- [🛠️ Customization](#️-customization)
- [📖 Detailed Setup](#-detailed-setup)
- [🔧 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)

---

## 🎯 Quick Start

### Prerequisites
- Fresh Arch Linux installation
- Internet connection
- Basic familiarity with terminal

### One-Command Installation
```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

**That's it!** The installer will:
- ✅ Install all required packages (600+ packages across 6 categories)
- ✅ Configure Hyprland with evil space theming
- ✅ Set up dual Waybar with GPU monitoring
- ✅ Configure AI integration with Ollama
- ✅ Apply system-wide GTK theming
- ✅ Configure all applications with dynamic theming
- ✅ Set up development environment
- ✅ Create necessary directories and symlinks

### Post-Installation
1. **Reboot** to activate all services
2. **Select AI models** during first Ollama startup
3. **Change wallpaper** to see dynamic theming in action
4. **Enjoy your evil space desktop!** 🌌

---

## 🌟 System Components

### 🖥️ **Desktop Environment**
| Component | Purpose | Features |
|-----------|---------|----------|
| **Hyprland** | Wayland Compositor | Dynamic workspaces, animations, tiling |
| **Waybar** | Status Bars | Dual bars: controls + GPU monitoring |
| **Dunst** | Notifications | Mouse-following, cosmic styling |
| **Fuzzel** | Application Launcher | Fast, themed, keyboard-driven |

### 🎨 **Theming & Visual**
| Component | Purpose | Features |
|-----------|---------|----------|
| **Matugen** | Color Generation | Material Design 3 from wallpapers |
| **GTK 3/4** | Application Theming | System-wide consistency |
| **Kitty** | Terminal | Dynamic theming, performance |
| **Custom CSS** | Styling | Glassmorphism, space aesthetics |

### 🔧 **System Tools**
| Component | Purpose | Features |
|-----------|---------|----------|
| **Fish Shell** | Command Line | Intelligent completions, theming |
| **Git** | Version Control | Enhanced configuration |
| **Ollama** | AI Integration | Local language models |
| **GPU Scripts** | Monitoring | Real-time AMDGPU metrics |

### 📦 **Package Categories**
- **Essential** (89 packages): Core system functionality
- **Development** (67 packages): Programming tools and environments
- **Multimedia** (45 packages): Audio, video, graphics tools
- **Gaming** (23 packages): Steam, compatibility layers
- **Theming** (18 packages): Visual customization tools
- **Optional** (15 packages): Additional utilities

---

## 🎨 Theming System

### 🌈 **Modern Dynamic Theming System (2025)**

Advanced theming system using modern technologies for optimal Hyprland/Wayland compatibility:

```
Wallpaper Category → Hyprcursor + nwg-look + Material You → Complete Desktop Transformation
```

**Core Technologies:**
- **Hyprcursor**: Modern server-side cursor system for Hyprland
- **nwg-look**: Wayland-optimized GTK theme management
- **Material You**: AI-powered color extraction from wallpapers
- **Dynamic Theme Packages**: Proven, reliable theme combinations

#### **Theme Categories & Mappings**

🌌 **Space Wallpapers** → Graphite-Dark + Papirus-Dark + Bibata-Modern-Ice (Hyprcursor)
🌿 **Nature Wallpapers** → Orchis-Green-Dark + Tela-circle-green + Bibata-Modern-Amber  
🎮 **Gaming Wallpapers** → Graphite-Dark + Papirus + Bibata-Modern-Classic
🎯 **Minimal Wallpapers** → WhiteSur-Light + WhiteSur + Capitaine-Cursors
🌑 **Dark Wallpapers** → Graphite-Dark + Papirus-Dark + Bibata-Modern-Classic
🎨 **Abstract Wallpapers** → Graphite + Papirus + Bibata-Modern-Amber

#### **Dynamic Adaptation**
- **Instant Switching**: Change wallpaper, entire theme ecosystem changes
- **Complete Coverage**: GTK themes, icon themes, and cursor themes
- **Category Detection**: Automatic wallpaper category recognition
- **Proven Reliability**: Uses 2025's most popular and stable themes

### 🖼️ **Wallpaper Collection**

Organized by themes in `assets/wallpapers/`:
- **Space**: Cosmic scenes, nebulae, galaxies
- **Abstract**: Geometric patterns, digital art
- **Nature**: Landscapes, natural beauty
- **Dark**: High contrast, OLED-optimized
- **Minimal**: Clean, simple designs
- **Gaming**: Gaming-themed artwork

### 🎛️ **Template System**

All theming handled through Matugen templates:
- `matugen/templates/hyprland.template` - Window manager colors
- `matugen/templates/waybar.template` - Top bar styling
- `matugen/templates/waybar-bottom-style.template` - Bottom bar styling
- `matugen/templates/gtk3.template` - GTK3 application theming
- `matugen/templates/gtk4.template` - GTK4/libadwaita theming
- `matugen/templates/kitty.template` - Terminal colors
- `matugen/templates/dunst.template` - Notification styling
- `matugen/templates/fuzzel.template` - Launcher theming

---

## 🚀 Waybar Configuration

### 📊 **Dual Bar System**

#### **Top Bar** (`waybar/config`)
**Left Side:**
- 🚀 Application launcher
- 🌌 Workspace indicators with cosmic icons
- 🪟 Window title

**Center:**
- 🎵 Media player controls
- 🔊 Audio controls

**Right Side:**
- 🌐 Network (IP + bandwidth: `🌐 192.168.1.100 ↑1.2MB ↓5.4MB`)
- 🗓️ Clock with calendar (`🗓️ Wednesday, December 19, 2024 - 14:32:45 - W51`)
- 🔋 System controls

#### **Bottom Bar** (`waybar/config-bottom`)
**Left Side - AMDGPU Monitoring:**
- 🌡️ GPU Temperature with dynamic icons
- 🌪️ Fan Speed with visual indicators
- ⚡ GPU Usage with performance icons
- 🟢 VRAM Usage with color coding
- 🔋 Power Consumption monitoring

**Center - System Monitoring:**
- 💻 CPU usage and temperature
- 🧠 Memory usage and availability
- 💾 Disk usage and I/O
- 📦 Available system updates

**Right Side - System Info:**
- 🌡️ System temperature
- ⚖️ Load average
- ⏱️ System uptime
- ℹ️ System information

### 🎨 **Visual Design**
- **Glassmorphism**: Translucent backgrounds with blur effects
- **Rounded Corners**: 12px main window, 6px modules
- **Dynamic Colors**: All colors adapt to current wallpaper
- **Smooth Animations**: Hover effects and transitions
- **Professional Spacing**: Optimized padding and margins
- **Evil Space Theme**: Cosmic icons and space aesthetics

### ⚙️ **Configuration Files**
- `waybar/config` - Top bar module configuration
- `waybar/config-bottom` - Bottom bar module configuration
- `waybar/style.css` - Top bar styling
- `waybar/style-bottom.css` - Bottom bar styling
- `waybar/colors.css` - Dynamic color variables (generated by matugen)

---

## 🌡️ GPU Monitoring

### 🔥 **AMDGPU Integration**

Our system provides comprehensive real-time GPU monitoring for AMD graphics cards:

#### **Monitored Metrics**
- **🌡️ Temperature**: Real-time thermal monitoring
- **🌪️ Fan Speed**: RPM and percentage monitoring
- **⚡ GPU Usage**: Real-time utilization percentage
- **🧠 VRAM Usage**: Memory consumption tracking
- **🔋 Power Consumption**: Wattage monitoring

#### **Dynamic Visual Indicators**

**Temperature Monitoring:**
- ❄️ **Cool** (< 70°C): Optimal operating temperature
- 🌡️ **Medium** (70-84°C): Normal operating range
- 🔥 **Warning** (85-99°C): Elevated temperature
- 💀 **Critical** (≥ 100°C): Dangerous temperature

**Fan Speed Indicators:**
- 😴 **Idle** (< 20%): Silent operation
- 🌬️ **Low** (20-49%): Quiet cooling
- 💨 **Medium** (50-79%): Active cooling
- 🌪️ **High** (≥ 80%): Maximum cooling

**GPU Usage Display:**
- 💤 **Low** (< 30%): Minimal usage
- 🔋 **Medium** (30-69%): Moderate usage
- ⚡ **High** (70-89%): Heavy usage
- 🚀 **Maximum** (≥ 90%): Peak performance

**VRAM Monitoring:**
- 🟢 **Low** (< 8GB): Plenty available
- 🟡 **Medium** (8-14GB): Moderate usage
- 🟠 **High** (15-19GB): Heavy usage
- 🔴 **Critical** (≥ 20GB): Near capacity

**Power Consumption:**
- 🔋 **Efficient** (< 100W): Low power mode
- ⚡ **Medium** (100-199W): Normal operation
- 🔥 **High** (200-299W): Performance mode
- 💥 **Maximum** (≥ 300W): Peak power draw

### 🛠️ **Monitoring Scripts**

Located in `scripts/theming/`:
- `gpu_temp_monitor.sh` - Temperature monitoring with thresholds
- `gpu_fan_monitor.sh` - Fan speed with RPM and percentage
- `gpu_usage_monitor.sh` - GPU utilization tracking
- `gpu_vram_monitor.sh` - VRAM usage with color coding
- `gpu_power_monitor.sh` - Power consumption monitoring
- `amdgpu_check.sh` - GPU detection and verification
- `test_amdgpu_sensors.sh` - Sensor testing and validation

### 🎯 **Supported Hardware**
- **AMD RX 7000 Series**: Full support with all metrics
- **AMD RX 6000 Series**: Complete monitoring capability
- **AMD RX 5000 Series**: Temperature, fan, usage monitoring
- **Other AMD GPUs**: Basic monitoring (temperature, usage)

---

## 🛠️ Customization

### 🎨 **Changing Themes**

#### **Wallpaper-Based Theming**
```bash
# Change wallpaper and update entire system theme
~/dotfiles/scripts/theming/wallpaper_manager.sh /path/to/your/wallpaper.jpg
```

#### **Manual Theme Generation**
```bash
# Generate theme from specific wallpaper
cd ~/dotfiles
matugen image /path/to/wallpaper.jpg

# Restart themed applications
~/dotfiles/scripts/theming/restart_theme_apps.sh
```

### 🔧 **Waybar Customization**

#### **Adding New Modules**
1. Edit `waybar/config` or `waybar/config-bottom`
2. Add module configuration
3. Update corresponding CSS file
4. Restart Waybar: `pkill waybar && waybar &`

#### **Modifying GPU Monitoring**
```bash
# Edit thresholds in monitoring scripts
vim ~/dotfiles/scripts/theming/gpu_temp_monitor.sh

# Modify temperature thresholds:
# TEMP_WARNING=85    # Warning threshold
# TEMP_CRITICAL=100  # Critical threshold
```

#### **Custom Module Example**
```json
"custom/weather": {
    "exec": "curl 'wttr.in/YourCity?format=1'",
    "interval": 3600,
    "format": "🌤️ {}",
    "tooltip": false
}
```

### 🎛️ **Hyprland Customization**

#### **Window Rules**
Edit `hypr/conf/windowrules.conf`:
```conf
# Float specific applications
windowrule = float, ^(calculator)$
windowrule = center, ^(calculator)$

# Workspace assignments
windowrule = workspace 2, ^(firefox)$
windowrule = workspace 3, ^(code)$
```

#### **Keybindings**
Edit `hypr/conf/keybinds.conf`:
```conf
# Application launches
bind = SUPER, Return, exec, kitty          # Terminal
bind = SUPER, E, exec, nemo                # File manager
bind = SUPER, D, exec, fuzzel              # Application launcher
bind = SUPER, W, exec, wallpaper_manager.sh select  # Wallpaper selector

# Window management
bind = SUPER, C, killactive                # Close window
bind = SUPER, F, fullscreen                # Toggle fullscreen
bind = SUPER, V, togglefloating            # Toggle floating
bind = SUPER SHIFT, Q, exit                # Exit Hyprland

# System controls
bind = SUPER, L, exec, screen lock         # Lock screen
bind = SUPER SHIFT, L, exec, unlock screen # Unlock screen
bind = SUPER SHIFT, W, exec, restart_theme_apps.sh  # Restart theme
```

### 🌈 **Color Customization**

#### **Override Specific Colors**
Edit `matugen/config.toml`:
```toml
[colors.custom]
primary = "#FF6B6B"          # Custom primary color
secondary = "#4ECDC4"        # Custom secondary color
accent = "#45B7D1"           # Custom accent color
```

#### **Create Custom Templates**
```bash
# Create new template
cp matugen/templates/waybar.template matugen/templates/my-app.template

# Edit template with your application's config format
vim matugen/templates/my-app.template

# Add to matugen config
vim matugen/config.toml
```

### 🖥️ **Multi-Monitor Setup**

#### **Hyprland Monitor Configuration**
Edit `hypr/conf/monitors.conf`:
```conf
# Primary monitor
monitor = DP-1, 3440x1440@144, 0x0, 1

# Secondary monitor
monitor = HDMI-A-1, 1920x1080@60, 3440x0, 1

# Waybar per monitor
exec-once = waybar -c ~/.config/waybar/config &
exec-once = waybar -c ~/.config/waybar/config-bottom &
```

---

## 📖 Detailed Setup

### 🔧 **Manual Installation Steps**

If you prefer manual installation or need to troubleshoot:

#### **1. Clone Repository**
```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

#### **2. Install Dependencies**
```bash
# Install yay (AUR helper)
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si

# Install gum (TUI framework)
yay -S gum

# Return to dotfiles
cd ~/dotfiles
```

#### **3. Run Installer**
```bash
./install.sh
```

#### **4. Package Categories**
The installer will prompt for each category:
- **Essential**: Core system packages (required)
- **Development**: Programming tools and environments
- **Multimedia**: Audio, video, graphics software
- **Gaming**: Steam, Lutris, gaming tools
- **Theming**: Visual customization tools
- **Optional**: Additional utilities

#### **5. Post-Installation Setup**
```bash
# Enable services
sudo systemctl enable ly.service          # Display manager
sudo systemctl enable ollama.service      # AI integration

# Set up user environment
chsh -s /usr/bin/fish                     # Set Fish as default shell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Reboot to activate everything
sudo reboot
```

### 🎯 **Configuration Verification**

#### **Check Installation Status**
```bash
# Verify Hyprland installation
hyprctl version

# Check Waybar configuration
waybar --config ~/.config/waybar/config --dry-run

# Test GPU monitoring
~/dotfiles/scripts/theming/test_amdgpu_sensors.sh

# Verify AI integration
ollama list
```

#### **Test Dynamic Theming**
```bash
# Test wallpaper change
~/dotfiles/scripts/theming/wallpaper_manager.sh ~/dotfiles/assets/wallpapers/space/dark_space.jpg

# Verify theme generation
ls ~/.config/waybar/colors.css
ls ~/.config/gtk-3.0/colors.css
```

### 🔍 **System Requirements**

#### **Minimum Requirements**
- **CPU**: Modern x86_64 processor
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB free space
- **GPU**: AMD graphics card for full GPU monitoring
- **Display**: 1920x1080 minimum resolution

#### **Recommended Hardware**
- **CPU**: AMD Ryzen 5/7 or Intel i5/i7 (2020+)
- **RAM**: 16GB+ DDR4/DDR5
- **Storage**: NVMe SSD for optimal performance
- **GPU**: AMD RX 6000/7000 series for complete monitoring
- **Display**: 2560x1440+ with high refresh rate

---

## 🔧 Troubleshooting

### 🚨 **Common Issues**

#### **Installation Problems**

**Package Installation Fails**
```bash
# Update system first
sudo pacman -Syu

# Clear package cache
yay -Sc

# Retry installation
./install.sh
```

**Permission Errors**
```bash
# Fix ownership
sudo chown -R $USER:$USER ~/dotfiles

# Fix permissions
chmod +x ~/dotfiles/scripts/theming/*.sh
chmod +x ~/dotfiles/install.sh
```

#### **Theming Issues**

**Colors Not Updating**
```bash
# Regenerate theme
cd ~/dotfiles
matugen image ~/dotfiles/assets/wallpapers/space/dark_space.jpg

# Restart applications
~/dotfiles/scripts/theming/restart_theme_apps.sh
```

**GTK Applications Not Themed**
```bash
# Verify GTK configuration
ls -la ~/.config/gtk-3.0/
ls -la ~/.config/gtk-4.0/

# Restart GTK applications
pkill -f gtk
```

#### **Waybar Problems**

**Waybar Not Starting**
```bash
# Check configuration syntax
waybar --config ~/.config/waybar/config --dry-run
waybar --config ~/.config/waybar/config-bottom --dry-run

# Check logs
journalctl --user -u waybar -f
```

**GPU Monitoring Not Working**
```bash
# Test AMDGPU sensors
~/dotfiles/scripts/theming/test_amdgpu_sensors.sh

# Check GPU detection
~/dotfiles/scripts/theming/amdgpu_check.sh

# Verify hwmon path
ls /sys/class/drm/card*/device/hwmon/
```

#### **AI Integration Issues**

**Ollama Not Starting**
```bash
# Check service status
sudo systemctl status ollama

# Start manually
sudo systemctl start ollama

# Check logs
journalctl -u ollama -f
```

**No AI Models Available**
```bash
# List available models
ollama list

# Install recommended models
ollama pull phi4:latest
ollama pull llava:latest
```

### 🛠️ **Advanced Troubleshooting**

#### **Performance Issues**

**High CPU Usage**
```bash
# Check running processes
htop

# Disable animations temporarily
hyprctl keyword animations:enabled false

# Check GPU monitoring frequency
# Edit update intervals in waybar configs
```

**Memory Usage**
```bash
# Check memory usage
free -h

# Clear system cache
sudo sync && sudo sysctl vm.drop_caches=3

# Restart memory-intensive applications
pkill waybar && waybar &
```

#### **Display Issues**

**Multi-Monitor Problems**
```bash
# List available outputs
hyprctl monitors

# Reconfigure monitors
vim ~/.config/hypr/conf/monitors.conf

# Reload Hyprland configuration
hyprctl reload
```

**Scaling Issues**
```bash
# Check current scaling
hyprctl monitors

# Adjust scaling in monitors.conf
# monitor = DP-1, 3440x1440@144, 0x0, 1.25
```

### 📞 **Getting Help**

#### **Log Files**
- **Hyprland**: `~/.cache/hyprland/hyprland.log`
- **Waybar**: `journalctl --user -u waybar`
- **Installation**: `~/dotfiles/install.log`
- **Theme Generation**: `~/.cache/matugen/`

#### **Debug Commands**
```bash
# System information
neofetch
inxi -Fxz

# GPU information
lspci | grep VGA
lshw -c display

# Service status
systemctl --user status
systemctl status ollama
```

---

## 🤝 Contributing

### 🌟 **How to Contribute**

We welcome contributions! Here's how you can help:

#### **Reporting Issues**
1. Check existing issues first
2. Provide detailed system information
3. Include relevant log files
4. Describe steps to reproduce

#### **Submitting Changes**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Submit a pull request

#### **Areas for Contribution**
- **New Templates**: Additional application theming
- **GPU Support**: Monitoring for other GPU vendors
- **Monitoring Modules**: System monitoring enhancements
- **Documentation**: Guides, tutorials, translations
- **Bug Fixes**: Issue resolution and improvements
- **Performance**: Optimization and efficiency improvements

### 📝 **Development Guidelines**

#### **Code Style**
- **Shell Scripts**: Follow POSIX standards where possible
- **Configuration Files**: Use consistent indentation
- **Comments**: Document complex logic
- **Error Handling**: Always include error checking

#### **Testing**
- Test on clean Arch Linux installation
- Verify all package categories install correctly
- Test theming with multiple wallpapers
- Validate GPU monitoring on different hardware

#### **Documentation**
- Update README for new features
- Add inline comments for complex configurations
- Include troubleshooting steps for new components
- Update roadmap with completed features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

### 🌟 **Special Thanks**
- **Hyprland Team** - Amazing Wayland compositor
- **Material Design Team** - Beautiful design system
- **Arch Linux Community** - Incredible distribution and support
- **Open Source Contributors** - All the amazing tools that make this possible

### 🛠️ **Built With**
- [Hyprland](https://hyprland.org/) - Dynamic tiling Wayland compositor
- [Waybar](https://github.com/Alexays/Waybar) - Highly customizable status bar
- [Matugen](https://github.com/InioX/matugen) - Material Design 3 color generation
- [Ollama](https://ollama.ai/) - Local AI model management
- [Fish Shell](https://fishshell.com/) - Smart and user-friendly command line shell
- [Kitty](https://sw.kovidgoyal.net/kitty/) - Fast, feature-rich terminal emulator

---

<div align="center">

### 🌌 **Welcome to the Evil Space Desktop Experience** 🚀

*Transform your Arch Linux system into a beautiful, intelligent, and highly functional desktop environment*

**[⭐ Star this repository](https://github.com/yourusername/dotfiles)** if you found it helpful!

</div>