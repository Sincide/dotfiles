# AI-Enhanced Linux Desktop + Web Theming System
## Complete Setup & Usage Guide v2.1

*The world's first AI-enhanced Linux desktop with real-time web browser theming*

---

## 🎯 What This System Does

**Desktop + Web AI Theming Pipeline:**
1. **Wallpaper Change** → **AI Color Analysis** → **Desktop Theme** + **Firefox Browser Theme** + **Website Colors**
2. **Real-time synchronization** across desktop environment AND web browser interface AND website content
3. **AI-optimized colors** with mathematical harmony analysis and accessibility compliance

**Result:** Your entire computing environment (desktop + browser + websites) changes color in real-time based on your wallpaper.

---

## 📦 Quick Installation

### Option 1: Fresh Arch Linux System (Recommended)
```bash
git clone https://github.com/your-username/dotfiles
cd dotfiles
chmod +x install.sh
./install.sh
```

**What gets installed:**
- Hyprland desktop environment (12 packages)
- Audio system with pipewire (5 packages) 
- AI tools (Ollama, matugen, Python dependencies)
- Firefox Developer Edition + AI extension
- Complete theming stack
- ~6.5GB total, ~35-45 minutes install time

### Option 2: Existing System
```bash
# Install core dependencies manually
sudo pacman -S hyprland waybar dunst kitty fuzzel swww matugen python python-requests

# Clone and run selective setup
git clone https://github.com/your-username/dotfiles
cd dotfiles
./install.sh --existing-system
```

---

## 🧠 AI Enhancement System

### Core AI Pipeline
**Location:** `scripts/ai/ai-color-pipeline.sh`

**Process:**
1. **Vision Analysis**: Ollama + phi4 vision model analyzes wallpaper composition
2. **Mathematical Harmony**: Color wheel analysis, golden ratio calculations  
3. **Accessibility Check**: WCAG AA/AAA compliance validation
4. **Matugen Integration**: AI-optimized colors fed into theme generator

### Enable/Disable AI
```bash
# Enable AI enhancement (default)
export ENABLE_AI_OPTIMIZATION=true

# Use standard matugen only
export ENABLE_AI_OPTIMIZATION=false
```

---

## 🌈 Theme Components

### Desktop Environment
- **Hyprland**: Window manager theming
- **Waybar**: Top and bottom bars with AI colors
- **Dunst**: Notification theming
- **Kitty**: Terminal color schemes
- **Fuzzel**: Application launcher theming
- **GTK/Qt**: Application theming

### Firefox Integration ⭐ NEW IN v2.1
**Complete browser theming with Theme API:**

**What's themed:**
- ✅ **Browser Interface**: Toolbar, address bar, tabs, buttons
- ✅ **Website Content**: Text, backgrounds, links, forms
- ✅ **Real-time Updates**: Changes with wallpaper instantly

**Components:**
1. **AI Extension**: `firefox-ai-extension/` - handles both website content AND browser interface
2. **Color Server**: `local-color-server.py` - serves AI colors to browser
3. **Auto-start**: Color server launches with Hyprland automatically

---

## 🚀 Usage

### Basic Wallpaper Change
```bash
# Quick change with AI enhancement
./scripts/wallpaper-theme-changer-optimized.sh /path/to/wallpaper.jpg

# Force regeneration (bypass cache)  
./scripts/wallpaper-theme-changer-optimized.sh /path/to/wallpaper.jpg force

# Interactive wallpaper selector
./scripts/wallpaper-selector.sh
```

### Advanced Usage
```bash
# Pure AI mode (no matugen fallback)
ENABLE_AI_OPTIMIZATION=true ./scripts/wallpaper-theme-changer-optimized.sh wallpaper.jpg

# Performance testing
time ./scripts/wallpaper-theme-changer-optimized.sh wallpaper.jpg

# Check logs
tail -f /tmp/wallpaper-theme-optimized.log
tail -f /tmp/ai-pipeline-output.log
```

---

## 🔧 Configuration

### Hyprland Config
**Location:** `config/hypr/hyprland.conf`

**Key bindings:**
- `SUPER + W`: Wallpaper selector
- `SUPER + T`: Terminal
- `SUPER + D`: Application launcher (fuzzel)

### AI Configuration  
**Location:** `config/dynamic-theming/ai-config.conf`

```bash
# AI Model Configuration
AI_MODEL="phi4"
AI_PROVIDER="ollama"

# Color Analysis Settings
ENABLE_VISION_ANALYSIS=true
ENABLE_HARMONY_ANALYSIS=true  
ENABLE_ACCESSIBILITY_CHECK=true

# Performance Settings
COLOR_CACHE_ENABLED=true
MATUGEN_FALLBACK=true
```

### Firefox Extension Settings
**Access:** Firefox → Extensions → AI Dynamic Colors → Options

**Features:**
- ✅ Enable/disable real-time theming
- ✅ Website content theming toggle
- ✅ Browser interface theming toggle
- ✅ Color server connection status
- ✅ Force refresh colors

---

## 📁 Directory Structure

```
dotfiles/
├── config/                    # Application configurations
│   ├── hypr/                 # Hyprland WM config
│   ├── waybar/               # Status bars
│   ├── kitty/                # Terminal
│   ├── fuzzel/               # App launcher
│   └── matugen/              # Theme generator templates
├── scripts/                   # Automation scripts
│   ├── wallpaper-theme-changer-optimized.sh  # Main wallpaper script
│   ├── wallpaper-selector.sh                 # Interactive selector
│   └── ai/                                    # AI pipeline scripts
├── firefox-ai-extension/     # Firefox AI extension
├── assets/wallpapers/        # Wallpaper collection
└── install.sh               # Complete system installer
```

---

## 🐛 Troubleshooting

### Firefox Extension Issues
```bash
# Check if color server is running
curl http://localhost:8080/ai-colors

# Restart color server
pkill -f local-color-server.py
python3 local-color-server.py &

# Check Firefox extension status
# Firefox → about:addons → AI Dynamic Colors → Details
```

### AI Pipeline Issues  
```bash
# Check Ollama status
ollama list
ollama ps

# Test AI pipeline manually
./scripts/ai/ai-color-pipeline.sh /path/to/wallpaper.jpg

# Check logs
cat /tmp/ai-pipeline-error.log
cat /tmp/vision-analysis-enhanced.json
```

### Performance Issues
```bash
# Check system resources
htop

# Clear caches if needed
rm -rf ~/.cache/dynamic-theming/
rm -rf /tmp/ai-*.json

# Test without AI
ENABLE_AI_OPTIMIZATION=false ./scripts/wallpaper-theme-changer-optimized.sh wallpaper.jpg
```

### Fuzzel Cache Issues
```bash
# Fuzzel cache is FULLY preserved across wallpaper changes (v2.1.1 fix)

# App launcher cache (preserved across theme changes)
cat ~/.config/fuzzel/fuzzel.ini | grep cache
# Should show: cache=/home/martin/.cache/fuzzel/cache

# Solution: Separate cache files prevent corruption
# - App launcher: ~/.cache/fuzzel/cache (preserves usage stats)
# - Wallpaper selector: /tmp/fuzzel-wallpaper-cache (temporary)

# Manual cache reset (if needed)
rm ~/.cache/fuzzel/cache
```

---

## 📊 Performance Monitoring ⭐ NEW IN v2.1

### **AI Performance Dashboard**
Real-time terminal-based monitoring interface for your AI theming system:

```bash
# Launch dashboard (from dotfiles directory)
bash scripts/ai/performance-dashboard.sh

# System-wide access (after fish shell restart)
ai-perf
# or shorthand
perf
dashboard
```

### **Dashboard Features:**
- **🧠 AI System Status**: Ollama service, model states, color server, Firefox extension
- **⚡ Performance Metrics**: Real-time timing analysis, throughput statistics
- **💾 System Resources**: Memory, CPU, disk usage monitoring  
- **🎨 Wallpaper History**: Recent theme changes and activity log
- **📊 AI Statistics**: Success rates, cache hit ratios, average processing times

### **Interactive Controls:**
- **`q`** - Quit dashboard cleanly
- **`r`** / **`Space`** - Force refresh display
- **`c`** - Clear all performance logs
- **`t`** - Test AI pipeline with sample wallpaper
- **`h`** - Show help and documentation

### **Dashboard Options:**
```bash
ai-perf -i 5         # Update every 5 seconds (default: 2s)
ai-perf --clear      # Clear all logs and start fresh
ai-perf --help       # Show usage information and examples
```

### **Performance Log Files:**
- `/tmp/ai-pipeline-output.log` - AI processing and error logs
- `/tmp/vision-analyzer.log` - Vision model analysis logs
- `/tmp/wallpaper-theme-optimized.log` - Theme change activity logs
- `/tmp/ai-performance-dashboard.log` - Dashboard monitoring logs

### **Example Dashboard View:**
```
╔══════════════════════════════════════════════════════════════════════════════╗
║  🧠 AI-Enhanced Desktop Performance Dashboard                           ║
║  Uptime: 15:23 | 14:42:18 2025-06-03                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

🧠 AI System Status:
  Ollama Service:    ✅ Running
  llava-llama3:8b:   🟡 Available
  phi4:              🟡 Available  
  Color Server:      ✅ Active
  Firefox Ext:       ✅ Connected

⚡ Performance Metrics:
  Last Total Time:   2.4s
  Last AI Time:      4.1s
  Last Vision Time:  3.2s
  Themes Today:      7

💾 System Resources:
  Memory Usage:      8.2GB/32GB
  CPU Usage:         12.3%
  Disk Usage:        45%
  Ollama Memory:     127.4MB

🎨 Recent Wallpaper Changes:
  Current: numbers.jpg
  Recent changes:
    2025-06-03 14:39 → sunset-valley.jpg
    2025-06-03 14:41 → abstract-blue.jpg
    2025-06-03 14:42 → numbers.jpg

📊 AI Model Statistics:
  Vision Analyses:   23 total, 96% success
  Average Time:      3.8s
  Cache Hit Rate:    68% (15/22)

────────────────────────────────────────────────────────────────────────────────
Controls: [q]uit | [r]efresh | [c]lear logs | [t]est pipeline | [h]elp
Press any key to continue... (auto-refresh every 2s)
```

---

## ⚡ Performance Metrics

**Target Performance (v2.1):**
- **Wallpaper + Desktop Theme**: <2 seconds
- **Firefox Update**: <1 second after desktop
- **Total End-to-End**: <3 seconds
- **AI Enhancement Overhead**: +2-4 seconds (optional)

**Optimizations:**
- ✅ Parallel application reloads
- ✅ Intelligent caching system
- ✅ Fuzzel cache preservation
- ✅ AI pipeline error handling with matugen fallback

---

## 🎨 Theming Examples

### AI vs Standard Comparison
```bash
# Standard matugen extraction
ENABLE_AI_OPTIMIZATION=false ./scripts/wallpaper-theme-changer-optimized.sh sunset.jpg

# AI-enhanced with harmony analysis  
ENABLE_AI_OPTIMIZATION=true ./scripts/wallpaper-theme-changer-optimized.sh sunset.jpg
```

**AI Enhancement Benefits:**
- 🎨 **Color Harmony**: Mathematical color wheel analysis
- ♿ **Accessibility**: WCAG AA/AAA compliance checking
- 🧠 **Context Awareness**: Vision model understands image composition
- 🔬 **Scientific**: Golden ratio and color theory application

---

## 🌟 Features Overview

### Desktop Features
- [x] **Real-time wallpaper theming** with sub-2 second updates
- [x] **AI-enhanced color analysis** with vision models
- [x] **Parallel application reloads** for maximum performance
- [x] **Intelligent caching** system to avoid redundant processing
- [x] **Material You dynamic icons** with wallpaper synchronization
- [x] **Dual waybar setup** (top + bottom) with dynamic themes
- [x] **Preserved fuzzel usage cache** across theme changes (separate cache files solution)

### Firefox Features ⭐ NEW
- [x] **Complete browser interface theming** (toolbar, tabs, address bar)
- [x] **Real-time website content theming** (text, backgrounds, forms)
- [x] **Auto-start color server** with Hyprland integration
- [x] **Firefox Theme API integration** for native browser theming
- [x] **Extension popup** with controls and status
- [x] **Permanent installation** options with troubleshooting scripts

### AI Features
- [x] **Ollama phi4 vision analysis** for intelligent color extraction
- [x] **Color harmony mathematical analysis** with color wheel theory
- [x] **WCAG accessibility compliance** checking and optimization
- [x] **Matugen fallback** for reliability when AI is unavailable
- [x] **Performance monitoring** with detailed logging and timing

---

## 📖 Version History

### v2.1 (Current) - Complete Firefox Integration
- ✅ **Firefox Theme API**: Complete browser interface theming
- ✅ **Extension Enhancement**: Both website + browser theming
- ✅ **Fuzzel Cache Fix**: Preserved application usage statistics
- ✅ **Auto-start Integration**: Color server launches with Hyprland
- ✅ **Documentation Consolidation**: Single comprehensive guide

### v2.0 - AI Enhancement & Web Theming
- ✅ **Firefox AI Extension**: Real-time website theming
- ✅ **AI Color Pipeline**: Vision + mathematical analysis  
- ✅ **Local Color Server**: HTTP API for web integration
- ✅ **Performance Optimization**: Sub-2 second theme changes
- ✅ **Material You Icons**: Dynamic icon theming

### v1.0 - Desktop Foundation
- ✅ **Hyprland Setup**: Complete desktop environment
- ✅ **Matugen Integration**: Basic wallpaper theming
- ✅ **Application Support**: Waybar, Dunst, Kitty, Fuzzel
- ✅ **Wallpaper Management**: Collection and selection tools

---

## 🤝 Support & Development

### Getting Help
1. **Check logs**: `/tmp/wallpaper-theme-optimized.log`
2. **Test components**: Individual script testing  
3. **Reset to defaults**: Run install.sh with --reset flag

### Contributing
- 📁 **Wallpapers**: Add to `assets/wallpapers/`
- 🎨 **Themes**: Modify templates in `config/matugen/templates/`
- 🧠 **AI Models**: Update model configurations in `scripts/ai/`
- 🌐 **Web Integration**: Enhance Firefox extension features

### Architecture
This system represents the **world's first complete AI-enhanced desktop + web theming ecosystem** with:
- 🖥️ **Desktop Environment**: Hyprland + AI color analysis
- 🌐 **Web Browser**: Firefox with Theme API integration  
- 🎨 **Real-time Sync**: Wallpaper → Desktop + Browser + Websites
- 🧠 **AI Enhancement**: Vision models + mathematical analysis
- ⚡ **Performance**: Sub-3 second complete system updates

---

**Installation Time:** ~35-45 minutes  
**Disk Usage:** ~6.5GB  
**Memory Usage:** ~2-4GB (including AI models)  
**Performance:** <3 seconds end-to-end theme updates

**This system transforms your Linux desktop into an intelligent, AI-enhanced environment where your wallpaper drives the visual experience across desktop applications, browser interface, and website content in real-time.**

# AI-Enhanced Desktop Environment Guide
*Complete Guide to Arch Linux + Hyprland + AI Theming System*

## 🎯 Overview
This system provides AI-powered dynamic theming that analyzes wallpapers and automatically generates beautiful, cohesive color schemes for your entire desktop environment including browser interfaces.

**Key Features:**
- 🧠 **AI Vision Analysis** - Ollama llava-llama3:8b analyzes images for dominant colors
- 🎨 **Dynamic Theming** - Real-time color generation and application
- 🦊 **Browser Integration** - Firefox Theme API for complete theming
- 📊 **Performance Dashboard** - Go-powered monitoring with htop-style interface
- ⚡ **Gaming Optimized** - Efficient memory usage (freed 18GB+ RAM)

## 🏗️ System Requirements

### Core Dependencies
```bash
# System packages (install via pacman)
sudo pacman -S hyprland waybar kitty fuzzel
sudo pacman -S python python-pip python-rich
sudo pacman -S go                           # For performance dashboard
sudo pacman -S matugen                      # Material You color generation
sudo pacman -S lf nano                      # File management and editing
sudo pacman -S ttf-jetbrains-mono-nerd     # Nerd font
sudo pacman -S otf-font-awesome             # Icon font
sudo pacman -S dunst                        # Notifications
sudo pacman -S swappy grim slurp            # Screenshots
sudo pacman -S qt5ct qt6ct                  # Qt theming
sudo pacman -S gtk3 gtk4                    # GTK theming
sudo pacman -S pipewire pipewire-pulse      # Audio
sudo pacman -S curl wget git                # Network tools

# AUR packages (install via yay)
yay -S ollama-bin                           # AI backend
```

### AI Models
```bash
# Install vision model (5.5GB)
ollama pull llava-llama3:8b

# Install text model (2.8GB) 
ollama pull phi4
```

## 📊 Performance Dashboard

### New Go + Bubbletea Dashboard
Professional htop-style monitoring interface:

```bash
ai-perf                    # Launch dashboard
ai-perf --waybar           # JSON output for waybar integration
```

**Features:**
- 🎨 **Smooth Terminal UI** - No flickering, proper terminal control
- 🧠 **AI System Status** - Ollama service, models, color server
- ⚡ **Performance Metrics** - Timing data, themes per day
- 💾 **System Resources** - Memory, CPU, disk usage  
- 🎨 **Wallpaper History** - Recent theme changes
- 📊 **AI Statistics** - Success rates, cache hits

**Controls:**
- `q` or `Ctrl+C` - Quit dashboard
- `w` - Toggle waybar JSON mode
- Automatic 2-second refresh

### Building the Dashboard
The Go dashboard auto-builds on first run:
```bash
cd ~/dotfiles/scripts/ai
go mod tidy              # Install dependencies
go build -o dashboard dashboard.go
```

## 🚀 Quick Start

### Installation
```bash
git clone <your-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Basic Usage
```bash
# Change wallpaper and theme
bash scripts/wallpaper-theme-changer-optimized.sh ~/path/to/image.jpg

# Monitor system performance  
ai-perf

# Start color server (automatic with install)
python3 local-color-server.py &

# Install Firefox extension
./install-firefox-ai-extension.sh
```

## 🧠 AI System Architecture

### Vision Analysis Pipeline
1. **Image Input** → User selects wallpaper
2. **AI Processing** → llava-llama3:8b analyzes image content  
3. **Color Extraction** → Generates 5 dominant colors
4. **Theme Generation** → matugen creates Material You palette
5. **System Application** → Updates all components simultaneously

### Performance Optimizations
- **Caching System** - Avoids re-analyzing identical images
- **Parallel Processing** - Concurrent theme application
- **Memory Efficient** - Gaming-optimized model selection
- **Fast Startup** - Pre-loaded models and services

## 🎨 Theme Components

### Desktop Environment
- **Hyprland** - Window manager colors and borders
- **Waybar** - Status bar styling  
- **Kitty** - Terminal colors and transparency
- **Fuzzel** - Application launcher theming
- **Dunst** - Notification colors

### Applications  
- **GTK3/4** - System application theming
- **Qt5/6** - Qt application colors
- **Firefox** - Complete browser interface theming via Theme API

## 🔧 Configuration Files

### Core Scripts
```
scripts/
├── ai/
│   ├── dashboard.go                    # Go performance monitor
│   ├── go.mod                         # Go dependencies  
│   └── vision-analyzer.sh             # AI vision processing
├── wallpaper-theme-changer-optimized.sh   # Main theming script
└── install-firefox-ai-extension.sh        # Browser integration
```

### Config Locations
```
config/
├── hypr/                              # Hyprland WM config
├── waybar/                            # Status bar config
├── kitty/                             # Terminal config
├── fuzzel/                            # Launcher config
├── dunst/                             # Notifications
├── fish/conf.d/ai-performance.fish    # Dashboard command
└── dynamic-theming/                   # AI theme storage
```

## 📈 Performance Monitoring

### System Metrics
- **AI Status** - Model loading, service health
- **Performance** - Theme generation timing
- **Resources** - Memory, CPU, disk usage
- **Activity** - Wallpaper changes, success rates

### Log Files
```
/tmp/ai-pipeline-output.log            # AI processing logs
/tmp/vision-analyzer.log               # Vision model logs  
/tmp/wallpaper-theme-optimized.log     # Main system logs
/tmp/ai-performance-dashboard.log      # Dashboard logs
```

## 🎮 Gaming Considerations

### Optimized Configuration
- **Reduced Models** - Removed 32B monster (19GB → 8B efficient)
- **Smart Caching** - Minimize AI calls during gaming
- **Resource Monitoring** - Real-time memory/CPU tracking
- **Quick Disable** - Fast system suspend if needed

### Memory Usage
- **Ollama Base** - ~230MB resident
- **llava-llama3:8b** - ~5.5GB when loaded
- **phi4** - ~2.8GB when loaded
- **Total Maximum** - ~8.5GB (vs previous 27GB+)

## 🌐 Browser Integration

### Firefox Theme API
Complete browser theming via Theme API:
- **Toolbar Colors** - Dynamic background/text
- **Tab Styling** - Active/inactive tab colors  
- **Address Bar** - URL bar and button colors
- **Popup Menus** - Context menu theming
- **Real-time Updates** - Instant color changes

### Extension Features
- Connects to local color server (port 8080)
- Applies themes immediately on wallpaper change
- Preserves user preferences and bookmarks
- No performance impact on browsing

## 🚀 Waybar Integration (Future)

### Dashboard Widget
```json
{
    "custom/ai-dashboard": {
        "exec": "~/dotfiles/scripts/ai/dashboard --waybar",
        "format": "{}",
        "return-type": "json",
        "interval": 5
    }
}
```

### Status Display
- AI system health indicator
- Performance percentage
- Hover tooltip with details
- Click actions for full dashboard

## 🔍 Troubleshooting

### Common Issues
1. **Ollama Not Starting** - Check `systemctl status ollama`
2. **Models Not Loading** - Verify disk space and memory
3. **Firefox Not Theming** - Check color server status
4. **Dashboard Build Fails** - Ensure Go is installed

### Debug Commands
```bash
# Check AI system status
ollama ps
curl http://localhost:8080/ai-colors

# View recent logs
tail -f /tmp/ai-pipeline-output.log

# Test vision analysis
bash scripts/ai/vision-analyzer.sh /path/to/test-image.jpg

# Monitor system resources
ai-perf
```

## 📋 Version History

### v2.1 - Performance & Monitoring
- ✅ Go dashboard with htop-style interface
- ✅ Gaming-optimized AI models (freed 18GB RAM)
- ✅ Firefox Theme API integration
- ✅ Consolidated documentation
- ✅ Fuzzel cache preservation

### v2.0 - AI Integration
- 🧠 Ollama vision analysis
- 🎨 Dynamic theme generation
- 🦊 Browser theming
- 📊 Performance monitoring

---

**🎯 Result:** World's first AI-enhanced desktop + browser theming system with professional monitoring and gaming-optimized performance. 