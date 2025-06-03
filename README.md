# 🚀 AI-Enhanced Arch Linux Dotfiles

**World's first production-ready AI-powered dynamic theming system** for Linux desktop environments.

## ✨ Key Features

### 🧠 AI-Enhanced Dynamic Theming *(Default Enabled)*
- **Content-Aware Intelligence**: Ollama vision AI analyzes wallpaper content 
- **Mathematical Color Harmony**: AI-powered color wheel analysis ensuring perfect relationships
- **WCAG AAA Accessibility**: Automated compliance for universal design
- **Lightning Performance**: Complete AI analysis in <2.5s
- **Material You Icons**: Real-time icon color adaptation from wallpaper

### 🖥️ Desktop Environment
- **Compositor**: Hyprland (Wayland)
- **Status Bar**: Waybar with system monitoring & theming integration
- **Terminal**: Kitty with AI-optimized colors
- **Shell**: Fish with smart aliases and completions
- **Launcher**: Fuzzel
- **File Manager**: lf (terminal) + Thunar (GUI)
- **Theme**: Catppuccin Mocha with AI color injection

### ⚡ Smart Installation
- **One-Command Setup**: `./install.sh` installs ~50 packages automatically
- **Safe & Re-runnable**: Automatic backups, incremental installation
- **AI System Integration**: Ollama setup, model download, configuration
- **Global AI Access**: `ai-config` command available system-wide
- **Progress Tracking**: Real-time progress bars with ETA

## 🎯 Quick Start

   ```bash
git clone <repository-url> dotfiles
cd dotfiles
   ./install.sh
   ```

**That's it!** The script handles everything:
- Package installation (yay, Hyprland, AI tools, etc.)
- Configuration backup & symlinking  
- AI system setup (Ollama, vision models)
- Fish shell configuration
- Desktop environment setup

## 🎮 Usage

### AI Theming
```bash
Super + B                 # Select wallpaper → AI optimizes colors
ai-config config          # Configure AI settings
ai-config status          # Check AI system status
```

### Essential Shortcuts
```bash
Super + Enter             # Terminal
Super + D                 # Launcher
Super + W                 # Firefox
Super + E                 # File manager
Super + L                 # Lock screen
Print                     # Screenshot with editor
```

## 🤖 How AI Theming Works

1. **Press Super+B** → Wallpaper selection opens
2. **Select wallpaper** → AI analyzes content (nature, abstract, gaming, etc.)
3. **Color optimization** → Mathematical harmony + accessibility compliance  
4. **Instant application** → Entire desktop updates in ~2s
5. **Dynamic icons** → Material You icons adapt to new colors

**Result**: Perfect color schemes with 100/100 harmony scores and WCAG AAA compliance.

## 📊 Performance Metrics

- **Installation Time**: 5-10 minutes
- **AI Analysis**: <2.5s average
- **Package Count**: ~50 applications
- **AI Model Size**: ~4GB (one-time download)
- **Theme Application**: <2s complete desktop update

## 🛠️ System Requirements

- **OS**: Arch Linux
- **GPU**: AMD recommended (optimized drivers included)
- **Storage**: ~6GB total (including AI models)
- **Memory**: 4GB+ recommended for AI processing

## 📁 Key Directories

```
├── config/                 # Application configurations
│   ├── hypr/              # Hyprland compositor
│   ├── waybar/            # Status bar
│   ├── dynamic-theming/   # AI configuration
│   └── ...                # Other app configs
├── scripts/ai/            # AI theming system
├── assets/wallpapers/     # Wallpaper collection
├── install.sh            # Automated installer
└── *_EXPLAINED*.md       # Documentation
```

## 🌍 Documentation

- **[INSTALL_SCRIPT_EXPLAINED.md](INSTALL_SCRIPT_EXPLAINED.md)** - Detailed install process (English)
- **[INSTALL_SCRIPT_EXPLAINED_SV.md](INSTALL_SCRIPT_EXPLAINED_SV.md)** - Detailed install process (Swedish)
- **[AI_IMPLEMENTATION_GUIDE.md](AI_IMPLEMENTATION_GUIDE.md)** - Complete AI system documentation
- **[DYNAMIC_THEMING_GUIDE.md](DYNAMIC_THEMING_GUIDE.md)** - Theming system technical details

## 🔧 Advanced Configuration

### AI Settings
```bash
ai-config config          # Interactive configuration menu
```
**Available modes**: Enhanced, Vision-only, Mathematical-only, Disabled

### GTK/Qt Theming
- **GTK**: Use `nwg-look` for GUI theme management
- **Qt**: Use `qt5ct`/`qt6ct` with Kvantum integration
- **Icons**: Papirus with Material You dynamic coloring

### Monitor Setup
- **Physical**: Auto-detects multi-monitor setup
- **VM**: Configures single virtual display
- **DDC/CI**: Hardware brightness control support

## 🛡️ Safety Features

- **Automatic backups** before any changes
- **Idempotent installation** - safe to re-run
- **Comprehensive logging** in `install.log`
- **Graceful AI fallbacks** if models unavailable
- **Configuration restoration** from timestamped backups

## 🎉 Result

Transform a basic Arch Linux installation into a **professional-grade, AI-enhanced workstation** that automatically adapts its entire visual appearance based on wallpaper content while maintaining perfect color harmony and accessibility compliance.

**Total setup time**: ~10 minutes  
**Your effort**: Answer a few prompts  
**Outcome**: The most advanced Linux desktop experience available 🚀 