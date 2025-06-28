# 🌌 Evil Space Dotfiles - System Architecture

**Complete technical overview of the fuzzel-based dynamic theming system**

## 🏗️ Architecture Overview

The Evil Space dotfiles implement a sophisticated dynamic theming system built around fuzzel launcher and Material Design 3 color generation. The system automatically adapts the entire desktop environment based on wallpaper selection, providing a cohesive and beautiful user experience.

## 🚀 Core Components

### Application Launcher - Fuzzel
- **Primary Launcher**: `Super + D` → Fuzzel application launcher
- **Fast & Lightweight**: Native Wayland application launcher
- **Dynamic Theming**: Colors automatically match current theme
- **Fuzzy Search**: Intelligent application matching

### Wallpaper & Theme System
- **Wallpaper Manager**: `Super + W` → `~/dotfiles/scripts/theming/wallpaper_manager.sh`
- **Category Detection**: Automatic categorization based on wallpaper path/name
- **Dynamic Color Generation**: Matugen + Material Design 3 algorithms
- **System-wide Application**: All applications receive new theme instantly

### Hyprland Window Manager
- **Wayland Compositor**: Modern, performant window management
- **Dynamic Workspaces**: Smooth animations and transitions  
- **Multi-monitor Support**: Intelligent display management
- **Floating & Tiling**: Flexible window layouts

## 🎨 Dynamic Theming Pipeline

### 1. Wallpaper Selection
```bash
~/dotfiles/scripts/theming/wallpaper_manager.sh select
```

### 2. Category Detection
The system automatically detects wallpaper category:
- **Space**: Dark cosmic themes with vibrant accent colors
- **Nature**: Organic green themes with natural palettes
- **Gaming**: High-contrast RGB themes for gaming
- **Minimal**: Clean light themes with subtle colors
- **Dark**: Professional dark themes  
- **Abstract**: Artistic themes with bold colors

### 3. Color Generation (Matugen)
```bash
matugen image /path/to/wallpaper.jpg
```
- **Material Design 3**: Official Google algorithms
- **HCT Color Space**: Perceptually accurate colors
- **53 Color Variables**: Complete Material You palette
- **Light/Dark Modes**: Automatic mode selection per category

### 4. Template Application
Templates automatically generate themed configurations:
- **GTK 3/4**: `~/.config/gtk-3.0/colors.css` & `~/.config/gtk-4.0/colors.css`
- **Waybar**: `~/.config/waybar/colors.css`
- **Kitty**: `~/.config/kitty/theme-dynamic.conf`
- **Dunst**: `~/.config/dunst/dunstrc`
- **Fish Shell**: `~/.config/fish/theme-dynamic.fish`
- **Starship**: `~/.config/starship/starship-dynamic.toml`
- **Fuzzel**: `~/.config/fuzzel/fuzzel.ini`
- **Hyprland**: `~/.config/hypr/conf/colors.conf`

### 5. Application Refresh
Automatic application reload without restart:
- **GTK Applications**: Theme toggle sequence
- **Waybar**: Process restart with new config
- **Kitty**: Signal-based reload (`SIGUSR1`)
- **Hyprland**: `hyprctl reload`
- **Other Apps**: Smart restart mechanisms

## 📊 Status Bar System (Waybar)

### Top Bar - System Controls
- **Workspaces**: Dynamic workspace indicators
- **Media Controls**: Play/pause, track info, volume
- **System Info**: CPU, memory, network status
- **Date/Time**: Calendar integration
- **Notifications**: Dunst integration

### Bottom Bar - AMD GPU Monitoring
- **Temperature Monitoring**: Real-time GPU temperature with color coding
- **Fan Speed**: Current fan RPM with visual indicators
- **GPU Usage**: Real-time usage percentage
- **VRAM Usage**: Memory consumption tracking  
- **Power Draw**: Current power consumption

#### Color-Coded Alerts
- 🟢 **Normal**: < 80°C temperature
- 🟡 **Warning**: 80-90°C temperature  
- 🔴 **Critical**: > 90°C temperature

## 🤖 AI Integration (Ollama)

### Local AI Processing
- **Privacy-First**: All AI processing happens locally
- **No External Calls**: Zero data transmission to external servers
- **Model Selection**: Choose from 14+ specialized models

### AI-Powered Features
- **Git Automation**: Intelligent commit message generation
- **Log Analysis**: Real-time system log analysis with pattern detection
- **System Health**: Performance monitoring and recommendations
- **Chat Interface**: TUI-based AI assistant for system tasks

### Supported Models
- **Code Analysis**: `codegemma:7b`, `deepseek-coder:6.7b`
- **General Purpose**: `llama3.2:3b`, `qwen2.5:7b`
- **Fast Response**: `llama3.2:1b`, `phi3.5:3.8b`

## 🖥️ Desktop Environment Stack

### Core Applications
| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **Hyprland** | Window Manager | `~/.config/hypr/` |
| **Waybar** | Status Bars | `~/.config/waybar/` |
| **Kitty** | Terminal | `~/.config/kitty/` |
| **Fish** | Shell | `~/.config/fish/` |
| **Fuzzel** | App Launcher | `~/.config/fuzzel/` |
| **Dunst** | Notifications | `~/.config/dunst/` |
| **Nemo** | File Manager | GTK-themed |

### Theming Applications
| Tool | Purpose | Templates |
|------|---------|-----------|
| **Matugen** | Color Generation | `~/dotfiles/matugen/templates/` |
| **nwg-look** | GTK Management | System integration |
| **Hyprcursor** | Cursor Theming | Dynamic cursor themes |

## 🔧 System Monitoring & Management

### Dashboard (Web Interface)
- **Real-time Monitoring**: CPU, GPU, memory, network
- **Log Management**: System, application, and journal logs
- **Theme Control**: Live wallpaper and theme switching
- **Script Execution**: Safe execution of dotfiles scripts
- **AI Integration**: Chat interface for system analysis

Access: `http://localhost:8080` via `fish ~/dotfiles/dashboard/start_dashboard.fish`

### TUI Applications
- **Log Analyzer**: `log-analyzer-tui` - Interactive log analysis with AI
- **System Monitor**: Real-time system statistics
- **Theme Manager**: Terminal-based theme switching

### CLI Tools
- **GPU Monitoring**: `~/dotfiles/scripts/theming/amdgpu_check.sh`
- **Theme Switching**: `~/dotfiles/scripts/theming/apply_theme.sh`
- **System Health**: `~/dotfiles/scripts/ai/ai-health.fish`

## 🛡️ Security & Performance

### Security Features
- **Local AI Processing**: No external data transmission
- **Privilege Separation**: User-level permissions only
- **Safe Script Execution**: Comprehensive error handling
- **Input Validation**: Sanitized user inputs throughout

### Performance Optimization
- **GPU Acceleration**: Hardware-accelerated terminal and compositor
- **Efficient Theming**: Optimized template generation
- **Resource Monitoring**: Real-time performance tracking
- **Intelligent Caching**: Reduced redundant operations

## 📁 Directory Structure

```
~/dotfiles/
├── hypr/                    # Hyprland configuration
│   ├── conf/               # Modular config files
│   │   ├── keybinds.conf   # Keyboard shortcuts
│   │   ├── colors.conf     # Dynamic color variables
│   │   └── windowrules.conf # Window management rules
│   └── scripts/            # Hyprland-specific scripts
├── waybar/                 # Status bar configuration
│   ├── config              # Top bar config
│   ├── config-bottom       # Bottom bar (GPU monitoring)
│   ├── colors.css          # Dynamic color variables
│   └── scripts/            # Waybar custom modules
├── matugen/                # Theme generation
│   ├── config.toml         # Matugen configuration
│   └── templates/          # App-specific templates
├── scripts/                # Automation scripts
│   ├── theming/            # Theme management
│   ├── ai/                 # AI integration tools
│   ├── setup/              # Installation scripts
│   └── monitoring/         # System monitoring
├── dashboard/              # Web dashboard
│   ├── app/                # Flask application
│   ├── data/               # SQLite database
│   └── static/             # Web assets
└── assets/                 # Wallpapers and resources
    └── wallpapers/         # Categorized wallpapers
        ├── space/          # Space category
        ├── nature/         # Nature category
        ├── gaming/         # Gaming category
        ├── minimal/        # Minimal category
        ├── dark/           # Dark category
        └── abstract/       # Abstract category
```

## 🚀 Key User Workflows

### Daily Usage
1. **Launch Applications**: `Super + D` → Type app name → Enter
2. **Change Theme**: `Super + W` → Select wallpaper → Automatic theming
3. **Monitor System**: Check bottom Waybar for GPU metrics
4. **Terminal Work**: `Super + Return` → Themed Kitty terminal
5. **File Management**: `Super + E` → Themed Nemo file manager

### Theme Customization
1. **Add Wallpapers**: Place in appropriate `~/dotfiles/assets/wallpapers/category/`
2. **Adjust Colors**: Modify `~/dotfiles/matugen/templates/` files
3. **Custom Categories**: Edit detection logic in wallpaper manager
4. **GPU Alerts**: Adjust thresholds in monitoring scripts

### System Management
1. **View Logs**: Use dashboard web interface or `log-analyzer-tui`
2. **Monitor Performance**: Bottom Waybar + dashboard
3. **AI Analysis**: Chat with local models for system insights
4. **Script Execution**: Dashboard interface for safe script running

## 🔄 System Integration Points

### Theme Propagation
1. **Wallpaper Selection** → **Category Detection** → **Matugen Generation**
2. **Template Processing** → **Config Generation** → **Application Refresh**
3. **Visual Updates** → **Consistent Experience**

### Monitoring Chain
1. **Hardware Sensors** → **Script Collection** → **Waybar Display**
2. **Performance Data** → **Dashboard API** → **Web Interface**
3. **AI Analysis** → **Pattern Detection** → **User Notifications**

### AI Workflow
1. **Local Models** → **Context Processing** → **Intelligent Responses**
2. **System Events** → **Log Analysis** → **Proactive Suggestions**
3. **User Queries** → **Contextual Understanding** → **Actionable Insights**

---

This architecture provides a robust, performant, and beautiful desktop environment that automatically adapts to user preferences while maintaining system performance and security. 