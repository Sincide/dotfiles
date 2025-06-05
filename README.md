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

### v2.1 - Complete Firefox Integration + Performance Dashboard ⭐ NEW
- **Firefox Theme API**: Browser interface theming (toolbar, tabs, address bar)
- **Website Content Theming**: Real-time website color updates
- **Go Performance Dashboard**: Professional htop-style monitoring (`ai-perf` command)
- **Miniprogram Hub**: Modern web-based utility launcher with AI theming
- **Waybar Integration**: Live AI status in bottom bar with rich tooltips
- **Gaming Optimized**: Freed 18GB+ RAM by optimizing AI models (llava-llama3:8b + phi4)
- **Fuzzel Cache Fix**: Application usage statistics fully preserved (separate cache files for wallpaper vs app selection)
- **Smart Error Handling**: Comprehensive error states with visual indicators
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

# Launch utility hub (NEW!)
mini-hub                                   # AI-themed utility launcher
video-dl                                   # Video downloader via hub


# Monitor system performance (NEW!)
ai-perf                                    # Full dashboard interface
scripts/ai/dashboard --waybar            # Waybar JSON output

# Force regeneration (bypass cache)
./scripts/wallpaper-theme-changer-optimized.sh wallpaper.jpg force

# Standard mode (no AI)
ENABLE_AI_OPTIMIZATION=false ./scripts/wallpaper-theme-changer-optimized.sh wallpaper.jpg
```

## 📊 Performance

- **Boot Time Optimization**: ~55% faster boot (26s → ~12s)
- **Wallpaper Change**: <2 seconds
- **Firefox Update**: <1 second
- **Total End-to-End**: <3 seconds
- **AI Enhancement**: +2-4 seconds (optional)

## 🧠 AI Features

- **Vision Analysis**: Phi4 model analyzes wallpaper composition
- **Color Harmony**: Mathematical color wheel analysis
- **Accessibility**: WCAG AA/AAA compliance
- **Fallback**: Matugen integration for reliability

## 🌐 **Firefox Web Theming Extension**

**Real-time AI-optimized color themes from your wallpaper!**

### **Features:**
- 🎨 **Subtle Professional Theming**: Neutral base colors with tiny wallpaper color hints (1.5-3% intensity)
- 🔄 **Real-time Updates**: No Firefox restart needed
- 🤖 **AI Harmony Analysis**: Mathematically optimized colors
- ♿ **WCAG AAA Compliance**: Perfect accessibility
- 🎯 **Site-Specific Rules**: Enhanced styling for popular sites
- 📊 **Performance Monitoring**: Built-in metrics

### **Installation:**
```bash
# Install the extension
firefox firefox-ai-extension.xpi

# Start color server (auto-starts with Hyprland)
python3 local-color-server.py
```

### **Color Moderation:**
The extension uses an advanced **neutral tint approach**:
- **Base**: Professional neutral grays (#3c3c3c, #2a2a2a, #4a4a4a)
- **Tinting**: Only 1.5-3% of wallpaper colors mixed in
- **Result**: Subtle, cohesive theming that's never overwhelming

### **Usage:**
1. Change wallpaper with `Super + B`
2. AI analyzes colors (~2s)
3. Firefox updates automatically (5s polling)
4. All websites get subtle new theme

## 🛠️ Architecture

```
Wallpaper → AI Analysis → Color Server → Firefox Extension → Browser + Websites
                      ↘ Matugen → Desktop Applications
                      ↘ Dashboard → Waybar Integration → Status Monitoring
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
ai-perf                                 # Full dashboard with all metrics
curl http://localhost:8080/ai-colors    # Color server
ollama ps                               # AI models
tail -f /tmp/wallpaper-theme-optimized.log  # Logs

# Waybar integration
config/waybar/scripts/ai-dashboard.sh   # Test waybar output

# Firefox extension issues
# Firefox → about:addons → AI Dynamic Colors → Details
```

## 🧠 AI-Powered Development Workflow

### **Smart Dotfiles Management**
This repository includes an AI-enhanced development workflow for managing dotfiles changes:

```bash
# Quick dotfiles sync with AI-generated commit messages
dots                    # Alias for intelligent sync workflow

# Manual options
./scripts/dotfiles.sh sync              # AI commit messages
./scripts/dotfiles.sh sync "custom msg" # Manual commit message  
./scripts/dotfiles.sh status            # Check sync status
./scripts/dotfiles.sh diff              # View changes
```

### **AI Commit Message Generation**
- 🧠 **Local LLM Integration**: Uses your Ollama models (phi4, llama, etc.)
- 📏 **Platform Compliance**: Adheres to GitHub/GitLab 50-72 character limits
- 🎯 **Context Aware**: Analyzes changed files and git diff for intelligent messages
- 🔄 **Graceful Fallback**: Falls back to rule-based messages if AI unavailable
- ⚡ **Fast Generation**: 8-10 second timeout for responsive experience

### **Example AI Messages:**
```bash
# Instead of: "Updated waybar, hypr configs. Modified ai scripts."
# AI generates: "config: enhance waybar AI module and hypr scripts"

# Instead of: "Updated fish configuration files"  
# AI generates: "feat: add SSH agent auto-loading to fish shell"
```

### **Features:**
- ✅ **Conventional Commits**: Follows standard format (feat:, fix:, config:)
- ✅ **Smart Analysis**: Understands dotfiles context and component relationships
- ✅ **Multi-Model Support**: Tries phi4 → llama → mistral → fallback logic
- ✅ **Message Validation**: Ensures proper length and format
- ✅ **SSH Integration**: Works seamlessly with SSH key authentication

## 🤝 Support

- 📖 **Full Documentation**: [COMPLETE_SYSTEM_GUIDE.md](COMPLETE_SYSTEM_GUIDE.md)
- 🐛 **Issues**: Check logs and troubleshooting section
- 💡 **Contributing**: Add wallpapers, themes, or features

---

**This system represents the world's first complete AI-enhanced desktop + web theming ecosystem with real-time synchronization across desktop environment, browser interface, and website content.**

**Installation:** ~35-45 minutes | **Disk Usage:** ~6.5GB | **Performance:** <3s theme updates 

## 🚀 **Key Features**

- 🎨 **Dynamic Wallpaper Theming**: Real-time color extraction and application  
- 🤖 **AI-Enhanced Color Optimization**: Smart contrast, accessibility, and harmony
- 🧠 **Ollama Vision Integration**: Advanced wallpaper analysis and color suggestions
- 🦊 **Firefox Real-time Theming**: Browser colors sync instantly with wallpaper
- 📊 **Performance Dashboard**: Monitor AI theming system with rich terminal interface
- 🎯 **Cache-Preserving Updates**: Fuzzel launcher maintains app rankings across theme changes
- ⚡ **Optimized Performance**: Parallel processing, intelligent caching, startup restoration 

# AI System Dashboard 🧠📊

A beautiful, real-time terminal dashboard for monitoring AI-enhanced Linux system health with interactive 3-column layout.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)
![TUI](https://img.shields.io/badge/TUI-Bubbletea-ff69b4)

## 🎯 What This Does

**Real-time system monitoring** with beautiful terminal UI:
- 📊 **Component Health Scores** (CPU, Memory, Boot, Disk, GPU, Packages)
- 🔧 **Optimization Opportunities** (Available fixes and applied optimizations)  
- 🧠 **AI System Status** (Ollama models, theming, color server)
- ⚡ **Interactive Navigation** (3-column layout with live updates)

## 🚀 Features

### **3-Column Layout**
```
┌─────────────────┬─────────────────┬─────────────────┐
│  📊 HEALTH      │  🔧 OPTIMIZE    │  🧠 AI STATUS   │
│                 │                 │                 │
│ CPU: 100/100 ✅ │ Boot Fix: Done  │ Ollama: Online  │
│ Memory: 100/100 │ Cache: 3 items  │ Models: 5       │
│ Boot: 115/100 🚀│ Orphans: None   │ Theming: Active │
│ Disk: 100/100   │                 │ Server: Running │
│ GPU: 100/100    │ Status: Perfect │ Last: 2min ago  │
│ Packages: 97/100│                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

### **Real-time Updates**
- ⚡ **Live scoring** from system health analyzer
- 🔄 **Auto-refresh** every 30 seconds
- 📈 **Performance metrics** with color coding
- 🎨 **Beautiful styling** with Lipgloss

### **Interactive Controls**
- `r` - Refresh data manually
- `q` - Quit application
- `↑/↓` - Navigate between sections
- `Enter` - View detailed information

## 📁 Project Structure

```
ai-system-dashboard/
├── cmd/ai-system/           # Main application entry point
├── internal/
│   ├── ui/                  # Bubbletea UI components
│   ├── system/              # System analysis logic
│   └── config/              # Configuration management
├── pkg/
│   ├── models/              # Data structures
│   └── utils/               # Utility functions
├── docs/                    # Documentation
├── go.mod                   # Go module definition
└── README.md               # This file
```

## 🛠️ Installation

### **Build from Source**
```bash
cd ai-system-dashboard
go mod tidy
go build -o ai-system cmd/ai-system/main.go
```

### **Install System-wide**
```bash
# Build and install
go build -o ai-system cmd/ai-system/main.go
sudo cp ai-system /usr/local/bin/
chmod +x /usr/local/bin/ai-system

# Add to fish shell (optional)
echo 'alias sys="ai-system"' >> ~/.config/fish/config.fish
```

## 🎮 Usage

### **Basic Usage**
```bash
# Run the dashboard
./ai-system

# Or if installed system-wide
ai-system
```

### **Command Line Options**
```bash
ai-system --help              # Show help
ai-system --refresh-rate 10   # Set refresh rate (seconds)
ai-system --no-color          # Disable colors
ai-system --debug             # Enable debug logging
```

## 🏗️ Architecture

### **Data Flow**
```
System Health Analyzer (JSON) → Models → UI Components → Terminal Display
                ↓
    /tmp/system-health-analysis.json
                ↓
    Real-time parsing and display
```

### **Key Components**

#### **1. System Analyzer (`internal/system/`)**
- Parses existing health analysis JSON
- Extracts component scores and details
- Monitors optimization status
- Tracks AI system health

#### **2. UI Layer (`internal/ui/`)**
- Bubbletea-based terminal interface
- 3-column responsive layout
- Color-coded health indicators
- Interactive navigation

#### **3. Models (`pkg/models/`)**
- Structured data types
- JSON parsing logic
- Health score calculations
- Status representations

## 🎨 Styling Guide

### **Color Scheme**
- 🟢 **Green**: Excellent (90-100+ score)
- 🟡 **Yellow**: Good (70-89 score)  
- 🔴 **Red**: Needs Attention (<70 score)
- 🔵 **Blue**: Information/Status
- ⚪ **Gray**: Disabled/Unknown

### **Icons & Indicators**
- ✅ **Optimized**: Score ≥ 100
- 🚀 **Excellent**: Score 90-99
- ⚠️ **Warning**: Score 70-89
- ❌ **Critical**: Score < 70
- 🔄 **Processing**: Live updates

## 🔧 Configuration

### **Default Settings**
```go
RefreshRate: 30 * time.Second
AnalysisCache: "/tmp/system-health-analysis.json"
ColorEnabled: true
DebugMode: false
```

### **Environment Variables**
```bash
export AI_SYSTEM_REFRESH_RATE=30    # Refresh interval (seconds)
export AI_SYSTEM_DEBUG=true         # Enable debug logging
export AI_SYSTEM_NO_COLOR=false     # Disable colors
```

## 🧪 Development

### **Running Tests**
```bash
go test ./...
go test -v ./internal/ui/
go test -cover ./pkg/models/
```

### **Building for Development**
```bash
# Build with debug info
go build -ldflags "-X main.version=dev" -o ai-system-dev cmd/ai-system/main.go

# Run with live reload (requires air)
air
```

### **Adding New Components**
1. Define data structure in `pkg/models/`
2. Add parsing logic in `internal/system/`
3. Create UI component in `internal/ui/`
4. Update main layout in `cmd/ai-system/`

## 🤝 Integration

### **With Existing AI Scripts**
- Reads from same JSON cache as shell scripts
- Compatible with `config-system-health-analyzer.sh`
- Works alongside `ai-config-hub.sh`
- Integrates with `config-smart-optimizer.sh`

### **Fish Shell Integration**
```fish
# Add to ~/.config/fish/config.fish
alias sys='ai-system'
alias health='ai-system --refresh-rate 5'
```

## 📊 Performance

- **Startup Time**: <100ms
- **Memory Usage**: ~10MB
- **CPU Impact**: <1% (during updates)
- **Refresh Overhead**: ~50ms per cycle

## 🐛 Troubleshooting

### **Common Issues**

**Dashboard shows "No Data"**
```bash
# Ensure health analyzer has run recently
scripts/ai/config-system-health-analyzer.sh
```

**Colors not working**
```bash
# Check terminal color support
echo $COLORTERM
export TERM=xterm-256color
```

**Permission errors**
```bash
# Ensure cache file is readable
ls -la /tmp/system-health-analysis.json
```

## 🚀 Development Planning

**See ROADMAP.md for all planned features and development priorities.**

## 📝 License

Part of the AI-Enhanced Linux Desktop ecosystem.
See main project LICENSE for details.

---

**Built with ❤️ using Go + Bubbletea for the AI-Enhanced Linux Desktop project** 