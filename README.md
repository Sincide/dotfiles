# AI-Enhanced Linux Desktop + Web Theming System 🧠🎨

*The world's first AI-enhanced Linux desktop with real-time web browser theming*

![Version](https://img.shields.io/badge/version-2.1-blue)
![Firefox](https://img.shields.io/badge/Firefox-Theme%20API-orange)
![AI](https://img.shields.io/badge/AI-Phi4%20Vision-green)
![Performance](https://img.shields.io/badge/performance-%3C3s-brightgreen)

## 🎯 What This Does

Your **wallpaper changes** → **AI analyzes colors** → **Entire computing environment updates**:
- 🖥️ **Desktop applications** (Hyprland, Waybar, Kitty, etc.)
- 🌐 **Firefox browser interface** (toolbar, tabs, address bar)
- 📄 **Website content** (GitHub, Reddit, any site)

**Result:** Everything matches your wallpaper in real-time with AI-optimized colors.

## ⚡ Quick Start

### Fresh Arch Linux Installation
```bash
git clone https://github.com/your-username/dotfiles
cd dotfiles
chmod +x install.sh
./install.sh
```

### Existing System
```bash
# See COMPLETE_SYSTEM_GUIDE.md for detailed instructions
```

## 📖 Documentation

**👉 [COMPLETE_SYSTEM_GUIDE.md](COMPLETE_SYSTEM_GUIDE.md) - Full documentation, setup, and usage**

## 🌟 Key Features

### v2.1 - Complete Firefox Integration ⭐ NEW
- **Firefox Theme API**: Browser interface theming (toolbar, tabs, address bar)
- **Website Content Theming**: Real-time website color updates
- **Fuzzel Cache Fix**: Preserved application usage statistics
- **Auto-start Integration**: Color server launches automatically

### v2.0 - AI Enhancement & Web Theming
- **AI Color Pipeline**: Phi4 vision + mathematical harmony analysis
- **Firefox AI Extension**: Real-time website theming
- **Performance Optimization**: Sub-2 second theme changes
- **Material You Icons**: Dynamic icon theming

### v1.0 - Desktop Foundation
- **Hyprland Environment**: Complete tiling WM setup
- **Dynamic Theming**: Wallpaper-driven color schemes
- **Application Integration**: Waybar, Dunst, Kitty, Fuzzel theming

## 🚀 Usage Examples

```bash
# Change wallpaper with AI-enhanced theming
./scripts/wallpaper-theme-changer-optimized.sh /path/to/wallpaper.jpg

# Interactive wallpaper selector
./scripts/wallpaper-selector.sh

# Force regeneration (bypass cache)
./scripts/wallpaper-theme-changer-optimized.sh wallpaper.jpg force

# Standard mode (no AI)
ENABLE_AI_OPTIMIZATION=false ./scripts/wallpaper-theme-changer-optimized.sh wallpaper.jpg
```

## 📊 Performance

- **Wallpaper Change**: <2 seconds
- **Firefox Update**: <1 second
- **Total End-to-End**: <3 seconds
- **AI Enhancement**: +2-4 seconds (optional)

## 🧠 AI Features

- **Vision Analysis**: Phi4 model analyzes wallpaper composition
- **Color Harmony**: Mathematical color wheel analysis
- **Accessibility**: WCAG AA/AAA compliance
- **Fallback**: Matugen integration for reliability

## 🌐 Firefox Integration

### What Gets Themed
- ✅ **Browser Interface**: Toolbar, address bar, tabs, buttons
- ✅ **Website Content**: Text, backgrounds, links, forms
- ✅ **Real-time**: Updates instantly with wallpaper changes

### Components
- **AI Extension**: `firefox-ai-extension/` - Complete browser + web theming
- **Color Server**: `local-color-server.py` - HTTP API for color delivery
- **Auto-start**: Launches with Hyprland automatically

## 🛠️ Architecture

```
Wallpaper → AI Analysis → Color Server → Firefox Extension → Browser + Websites
                      ↘ Matugen → Desktop Applications
```

## 📁 Quick Directory Reference

```
dotfiles/
├── COMPLETE_SYSTEM_GUIDE.md     # 📖 Full documentation
├── config/                      # Application configs
├── scripts/                     # Automation scripts
├── firefox-ai-extension/        # Firefox AI extension
├── assets/wallpapers/           # Wallpaper collection
└── install.sh                   # System installer
```

## 🐛 Quick Troubleshooting

```bash
# Check system status
curl http://localhost:8080/ai-colors    # Color server
ollama ps                               # AI models
tail -f /tmp/wallpaper-theme-optimized.log  # Logs

# Firefox extension issues
# Firefox → about:addons → AI Dynamic Colors → Details
```

## 🤝 Support

- 📖 **Full Documentation**: [COMPLETE_SYSTEM_GUIDE.md](COMPLETE_SYSTEM_GUIDE.md)
- 🐛 **Issues**: Check logs and troubleshooting section
- 💡 **Contributing**: Add wallpapers, themes, or features

---

**This system represents the world's first complete AI-enhanced desktop + web theming ecosystem with real-time synchronization across desktop environment, browser interface, and website content.**

**Installation:** ~35-45 minutes | **Disk Usage:** ~6.5GB | **Performance:** <3s theme updates 