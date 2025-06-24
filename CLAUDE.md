# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **comprehensive, production-ready Arch Linux + Hyprland dotfiles configuration** featuring:
- **Dynamic Material Design 3 theming** that adapts entire system to wallpapers
- **Dual Waybar monitoring** (top controls + bottom AMD GPU monitoring)
- **Complete system automation** with 25+ scripts and 397 packages
- **AI integration** with Ollama for automated git commits and health monitoring
- **Web-based dashboard** for real-time system oversight
- **Zero-intervention setup** from fresh Arch installation to complete desktop

This represents one of the most sophisticated dotfiles automation systems available, with enterprise-level logging, error handling, and user experience optimization.

## Architecture Overview

### Core Desktop Environment

**Window Manager & Compositor:**
- **Hyprland**: Wayland compositor with 10+ modular config files in `hypr/conf/`
- **Waybar**: Sophisticated dual-bar system with real-time monitoring
  - **Top Bar**: Application launcher, workspaces, window titles, system controls
  - **Bottom Bar**: AMD GPU monitoring (temp, fan, usage, VRAM, power)
- **Dynamic Theming**: Matugen-powered Material Design 3 system
- **AI Integration**: Ollama with 14 specialized models for various tasks

**Key Architecture Components:**
- `hypr/`: Modular Hyprland configuration (animations, keybinds, monitors, etc.)
- `waybar/`: Dual-bar configuration with 170+ lines of sophisticated modules
- `scripts/`: 25+ automation scripts totaling 8,000+ lines of code
- `matugen/`: Dynamic theming engine with 15 application templates
- `dashboard/`: Python web dashboard with REST API and real-time monitoring
- `fish/`: Advanced shell configuration with 500+ lines of aliases and functions

### System Architecture Patterns

**Modular Configuration:**
- **Hyprland**: `hyprland.conf` sources 10 specialized config modules
- **Theming**: Template-based system affecting 15+ applications simultaneously
- **Scripts**: Organized by function (`setup/`, `theming/`, `git/`, `ai/`, `backup/`)
- **Logging**: Centralized system in `logs/` with consistent naming patterns

**Automation Layers:**
1. **Installation Layer**: 11-phase setup with package categorization and conflict resolution
2. **Theming Layer**: Wallpaper-triggered system-wide color coordination
3. **AI Layer**: Local LLM integration for git automation and system diagnostics
4. **Monitoring Layer**: Real-time GPU monitoring and web dashboard
5. **Service Layer**: Background process management and systemd integration

## Development Commands

### Essential Development Commands

**System Monitoring & Diagnostics:**
```bash
# Web Dashboard
dashboard                               # Launch comprehensive web dashboard (port 8080)
cd ~/dotfiles && fish dashboard/start_dashboard.fish

# AI & System Health
scripts/ai/ai-health.fish              # Comprehensive Ollama/GPU diagnostics
scripts/ai/ai-health.fish gpu          # GPU-specific health check
scripts/ai/ai-health.fish models       # AI model management
scripts/theming/test_amdgpu_sensors.sh  # AMD GPU sensor validation
```

**Theme Development & Management:**
```bash
# Dynamic Theming System
scripts/theming/wallpaper_manager.sh           # Interactive wallpaper selection
scripts/theming/wallpaper_manager.sh select    # Fuzzel-based wallpaper picker
matugen image /path/to/wallpaper.jpg           # Generate Material Design 3 colors
scripts/theming/dynamic_theme_switcher.sh      # Apply category-based themes
scripts/theming/restart_cursor_apps.sh         # Restart all themed applications

# Theme Development
scripts/theming/theme_cache_manager.sh         # Manage theme downloads/cache
matugen image wallpaper.jpg --dry-run          # Preview color generation
```

**Git Automation with AI:**
```bash
# AI-Powered Git Workflow
scripts/git/dotfiles.fish sync                 # Smart sync with AI commit messages
scripts/git/dotfiles.fish                      # Interactive git management menu
scripts/git/dotfiles.fish ai-test             # Test AI commit generation
scripts/git/dotfiles.fish status              # Enhanced repository status
```

**Package & System Management:**
```bash
# Installation & Setup
scripts/setup/02-install-packages.sh           # Install 397 packages (6 categories)
scripts/setup/07-setup-ollama.sh               # AI platform with model selection
scripts/setup/08-setup-virt-manager.sh         # Virtualization setup
scripts/setup/03-deploy-dotfiles.sh            # Symlink deployment

# Service Management
sudo systemctl --user status qbittorrent-nox   # Check torrent service
sudo systemctl status ollama                    # Check AI service
```

### Advanced Development Workflow

**1. Configuration Development:**
```bash
# Hyprland Development
vim hypr/conf/keybinds.conf                    # Edit keybindings
hyprctl reload                                  # Test changes immediately
hyprctl keyword animations:enabled false       # Debug performance

# Waybar Development
vim waybar/config                               # Edit top bar
vim waybar/config-bottom                        # Edit GPU monitoring bar
waybar --config ~/.config/waybar/config --dry-run  # Validate syntax
pkill waybar && waybar &                        # Restart both bars
```

**2. Theme Development Pipeline:**
```bash
# Create new application template
cp matugen/templates/waybar.template matugen/templates/new-app.template
vim matugen/templates/new-app.template          # Edit template
vim matugen/config.toml                         # Add template config
matugen image ~/wallpaper.jpg                   # Generate and test
```

**3. Script Development:**
```bash
# Create new automation script
vim scripts/theming/new_script.sh               # Create script
chmod +x scripts/theming/new_script.sh          # Make executable
./scripts/theming/new_script.sh --dry-run       # Test safely
```

**4. AI Integration Development:**
```bash
# Test AI models
ollama list                                     # Show installed models
ollama run qwen2.5-coder:latest                # Test coding model
scripts/git/dotfiles.fish ai-test              # Test commit generation
```

### Testing & Validation Framework

**Configuration Validation:**
```bash
# Hyprland Configuration
hyprctl reload                                  # Test full config
hyprctl monitors                                # Verify monitor setup
hyprctl workspaces                              # Check workspace config

# Waybar Configuration
waybar --config ~/.config/waybar/config --dry-run
waybar --config ~/.config/waybar/config-bottom --dry-run
journalctl --user -u waybar -f                 # Monitor waybar logs

# GPU Monitoring
scripts/theming/gpu_temp_monitor.sh            # Test temperature monitoring
scripts/theming/gpu_usage_monitor.sh           # Test usage monitoring
scripts/theming/amdgpu_check.sh                # Validate GPU detection
```

**System Integration Testing:**
```bash
# Theme System Testing
scripts/theming/wallpaper_manager.sh ~/dotfiles/assets/wallpapers/space/dark_space.jpg
ls ~/.config/waybar/colors.css                 # Verify color generation
ls ~/.config/gtk-3.0/colors.css                # Check GTK theming

# AI System Testing
ollama list                                     # Verify model availability
scripts/ai/ai-health.fish                      # Full system diagnostics
echo "test change" >> README.md && scripts/git/dotfiles.fish sync  # Test AI commits
```

**Dashboard Development:**
```bash
# Test dashboard components
curl http://localhost:8080/api/system          # Test system API
curl http://localhost:8080/api/gpu             # Test GPU API
curl http://localhost:8080/api/logs            # Test logging API
```

## Advanced System Architecture

### Dynamic Theming System (Material Design 3)

The theming system represents a **sophisticated color coordination architecture**:

**Core Engine: Matugen**
- **Input**: Any wallpaper image → **Output**: Complete Material Design 3 color palette
- **Templates**: 15 application templates in `matugen/templates/`
- **Configuration**: `matugen/config.toml` with 15 template mappings
- **Coverage**: Hyprland, Waybar (dual), GTK3/4, Kitty, Dunst, Fish, Starship, and more

**Template Architecture:**
```
matugen/templates/
├── hyprland.template       → hypr/conf/colors.conf
├── waybar.template         → waybar/colors.css
├── waybar-bottom-style.template → waybar/style-bottom.css
├── gtk3.template           → gtk-3.0/colors.css
├── gtk4.template           → gtk-4.0/colors.css
├── kitty.template          → kitty/theme-dynamic.conf
├── dunst.template          → dunst/dunstrc
└── [8 more templates]
```

**Automation Pipeline:**
1. **Wallpaper Selection** → `wallpaper_manager.sh`
2. **Category Detection** → `dynamic_theme_switcher.sh` (space, nature, gaming, etc.)
3. **Color Generation** → `matugen image wallpaper.jpg`
4. **Template Processing** → 15 configuration files updated simultaneously
5. **Application Restart** → `restart_cursor_apps.sh` (Waybar, Dunst, GTK apps)
6. **Theme Coordination** → Complete system color harmony

### GPU Monitoring Architecture (AMD-Specific)

**Real-time Monitoring Pipeline:**
- **Hardware Access**: Direct `/sys/class/drm/card1/device/hwmon/` reading
- **Metrics Collected**: Temperature, fan speed, GPU usage, VRAM, power consumption
- **Update Frequency**: 2-second intervals for responsive monitoring
- **Visual Indicators**: Dynamic icons that change based on performance thresholds

**Waybar Integration:**
```
Bottom Bar Modules:
├── AMDGPU Temperature (❄️🌡️🔥💀 icons based on temp ranges)
├── Fan Speed (😴🌬️💨🌪️ icons based on RPM percentage)
├── GPU Usage (💤🔋⚡🚀 icons based on utilization)
├── VRAM Usage (🟢🟡🟠🔴 color coding based on memory pressure)
└── Power Draw (🔋⚡🔥💥 icons based on wattage consumption)
```

**Performance Thresholds:**
- **Temperature**: <70°C (cool) → 70-84°C (normal) → 85-99°C (warning) → 100°C+ (critical)
- **Fan Speed**: <20% (idle) → 20-49% (quiet) → 50-79% (active) → 80%+ (maximum)
- **GPU Usage**: <30% (low) → 30-69% (moderate) → 70-89% (heavy) → 90%+ (peak)

### AI-Powered Automation (Ollama Integration)

**Local LLM Infrastructure:**
- **14 Specialized Models**: Coding (qwen2.5-coder, codellama), general (llama3.2, phi4), embedding (nomic-embed)
- **Smart Model Selection**: Automatic detection of best available model for task
- **ROCm Acceleration**: Hardware-accelerated inference on AMD GPUs
- **Service Management**: Systemd integration with auto-restart

**Git Automation Features:**
```
AI Commit Generation Pipeline:
1. File Change Analysis → Categorize by type (scripts, configs, docs)
2. Context Generation → Create descriptive prompts for AI
3. Model Selection → Choose best coding model (priority: qwen2.5-coder)
4. Commit Generation → AI generates conventional commit format
5. Fallback System → Rule-based commits if AI fails
6. User Interaction → Preview, edit, approve workflow
```

**Health Monitoring System:**
- **System Diagnostics**: RAM, disk, CPU monitoring with intelligent warnings
- **GPU Integration**: ROCm detection, temperature monitoring, performance analysis
- **AI Model Management**: Model listing, performance benchmarking, recommendation system
- **Interactive Interface**: Color-coded status reporting with actionable recommendations

### Package Management Architecture

**Sophisticated Package System (397 Packages):**
- **6 Main Categories**: Essential (122), Development (96), Theming (72), Multimedia (42), Gaming (28), Optional (15)
- **Advanced Installation**: yay + Chaotic-AUR for faster AUR package installation
- **Error Handling**: Failed package tracking, conflict resolution, retry mechanisms
- **Modular Selection**: Category-based installation with CLI flag control

**Installation Pipeline:**
```
Phased Installation:
1. Prerequisites → System validation, yay installation
2. Repository Setup → Chaotic-AUR configuration
3. Package Installation → Batched category installation
4. Dotfiles Deployment → Intelligent symlink management
5. Service Configuration → Systemd service setup
6. User Environment → Shell and environment finalization
```

### Logging & Monitoring Infrastructure

**Centralized Logging System:**
- **Location**: `~/dotfiles/logs/`
- **Format**: `{script-name}_{YYYYMMDD}_{HHMMSS}.log`
- **Log Levels**: [INFO], [SUCCESS], [ERROR], [WARNING], [SECTION]
- **Retention**: Manual cleanup with provided commands
- **Integration**: All 25+ scripts use consistent logging patterns

**Dashboard Architecture (Python Web Interface):**
- **Backend**: Custom HTTP server with REST API
- **Frontend**: Real-time updating HTML dashboard
- **Features**: System monitoring, log management, script execution, theme switching
- **APIs**: `/api/system`, `/api/gpu`, `/api/logs`, `/api/themes`, `/api/scripts`
- **Port Management**: Intelligent port cleanup and process management

## Advanced Development Tasks

### Theme System Development

**Add New Application Theming:**
```bash
# 1. Create template with Material Design 3 variables
cp matugen/templates/waybar.template matugen/templates/your-app.template
vim matugen/templates/your-app.template
# Use variables like {{colors.primary.default.hex}} for dynamic colors

# 2. Add template to matugen configuration
vim matugen/config.toml
# Add: [templates.your-app]
#      input_path = "~/dotfiles/matugen/templates/your-app.template"
#      output_path = "~/.config/your-app/colors.conf"

# 3. Test theme generation
matugen image ~/dotfiles/assets/wallpapers/space/dark_space.jpg
ls ~/.config/your-app/colors.conf  # Verify generation

# 4. Add application restart logic
vim scripts/theming/restart_cursor_apps.sh
# Add: pkill your-app && your-app & || true

# 5. Test complete pipeline
scripts/theming/wallpaper_manager.sh ~/dotfiles/assets/wallpapers/nature/gradiant_sky.png
```

**Create Custom Theme Categories:**
```bash
# 1. Add new category to theme switcher
vim scripts/theming/dynamic_theme_switcher.sh
# Add to THEMES array:
# ["yourcategory_gtk"]="Your-GTK-Theme"
# ["yourcategory_icons"]="Your-Icon-Theme"
# ["yourcategory_cursor"]="Your-Cursor-Theme"

# 2. Add detection logic
# Add to detect_category(): elif [[ "$wallpaper_path" =~ yourcategory ]]; then echo "yourcategory"

# 3. Create wallpaper directory
mkdir -p ~/dotfiles/assets/wallpapers/yourcategory/

# 4. Test category detection
scripts/theming/dynamic_theme_switcher.sh apply yourcategory /path/to/wallpaper
```

### Waybar Module Development

**Add Custom Monitoring Module:**
```bash
# 1. Create monitoring script
vim scripts/theming/custom_monitor.sh
#!/bin/bash
# Your monitoring logic here
echo "📊 Your-Data: $(your-command)"

# 2. Add to Waybar configuration
vim waybar/config-bottom
# Add to modules-left/center/right:
"custom/your-monitor": {
    "format": "{}",
    "interval": 5,
    "exec": "~/dotfiles/scripts/theming/custom_monitor.sh",
    "tooltip": true,
    "tooltip-format": "📊 Your Custom Monitor\n💀 Evil Monitoring"
}

# 3. Add styling
vim waybar/style-bottom.css
#custom-your-monitor {
    background: @tertiaryContainer;
    color: @onTertiaryContainer;
    border: 1px solid @tertiary;
}

# 4. Test module
waybar --config ~/.config/waybar/config-bottom --dry-run
pkill waybar && waybar &
```

**Advanced GPU Monitoring:**
```bash
# 1. Extend GPU monitoring script
vim scripts/theming/gpu_advanced_monitor.sh
# Add custom metrics (GPU clocks, memory bandwidth, etc.)

# 2. Integration with Waybar
# Follow existing gpu_*_monitor.sh patterns
# Use dynamic icons and thresholds

# 3. Test with live GPU load
# Run stress test: stress-ng --cpu 4 --gpu 1 --timeout 60s
# Monitor: watch -n 1 'scripts/theming/gpu_temp_monitor.sh'
```

### AI Integration Development

**Add Custom AI Models:**
```bash
# 1. Install new model
ollama pull your-model:latest

# 2. Add to model detection
vim scripts/git/dotfiles.fish
# Add to detect_ollama_model(): else if ollama list | grep -q "your-model"
#     set OLLAMA_MODEL "your-model:latest"

# 3. Test model performance
scripts/ai/ai-health.fish models
ollama run your-model:latest "Write a commit message for config changes"
```

**Custom AI Health Checks:**
```bash
# 1. Extend health monitoring
vim scripts/ai/ai-health.fish
# Add custom check functions following existing patterns
# Use success/warn/error/neutral for consistent output

# 2. Add to main health check menu
# Integrate with interactive menu system
```

### Automation Script Development

**Create New Setup Script:**
```bash
# 1. Create script following naming convention
vim scripts/setup/12-setup-your-feature.sh

# 2. Use standard logging pattern
#!/bin/bash
set -euo pipefail
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/your-feature_$(date +%Y%m%d_%H%M%S).log"

# 3. Implement standard functions
source "${DOTFILES_DIR}/scripts/setup/common/logging.sh"  # If available
# Or implement: log_info, log_success, log_error, log_warning, log_section

# 4. Add CLI argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --yes) SKIP_CONFIRMATION=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# 5. Test script
./scripts/setup/12-setup-your-feature.sh --dry-run
```

**Dashboard API Development:**
```bash
# 1. Add new API endpoint
vim dashboard/app/api/your_module.py
# Follow patterns from system.py, logs.py, etc.

# 2. Register endpoint in server
vim dashboard/app/server.py
# Add to handle_api_request(): elif endpoint == 'your-endpoint':

# 3. Test API
curl http://localhost:8080/api/your-endpoint

# 4. Add frontend integration
vim dashboard/app/frontend/html_generator.py
# Add JavaScript fetch() calls and UI updates
```

### Multi-Monitor Configuration

**Advanced Monitor Setup:**
```bash
# 1. Configure complex layouts
vim hypr/conf/monitors.conf
# Example 3-monitor setup:
# monitor = DP-1,5120x1440@165,0x1440,1     # Ultrawide center
# monitor = DP-3,2560x1440@120,2560x0,1     # Right portrait
# monitor = HDMI-A-1,2560x1440@120,0x0,1    # Top landscape

# 2. Workspace assignment
vim hypr/conf/workspaces.conf
# wsbind = 1,DP-1    # Main workspace on ultrawide
# wsbind = 2,DP-3    # Code workspace on right
# wsbind = 3,HDMI-A-1 # Monitoring on top

# 3. Waybar per-monitor configuration
vim waybar/config
# Add: "output": ["DP-1", "DP-3"]  # Specific monitor targeting

# 4. Test configuration
hyprctl reload
hyprctl monitors  # Verify layout
```

## Repository Structure & File Organization

### Configuration Architecture
```
~/dotfiles/
├── hypr/                    # Hyprland window manager
│   ├── hyprland.conf       # Main config (sources others)
│   ├── cursor-theme.conf   # Dynamic cursor configuration
│   ├── conf/               # Modular configuration
│   │   ├── animations.conf # Animation definitions
│   │   ├── colors.conf     # Dynamic Material You colors
│   │   ├── decoration.conf # Visual effects & bezier curves
│   │   ├── env.conf        # Environment variables (100 lines)
│   │   ├── general.conf    # Basic window manager settings
│   │   ├── input.conf      # Keyboard/mouse configuration
│   │   ├── keybinds.conf   # Keyboard shortcuts (63 bindings)
│   │   ├── monitors.conf   # Multi-monitor setup
│   │   ├── startup.conf    # Autostart applications
│   │   ├── system.conf     # Advanced system settings
│   │   ├── windowrules.conf# Application-specific rules
│   │   └── workspaces.conf # Workspace assignments
│   └── scripts/            # Hyprland utilities
│
├── waybar/                  # Status bar configuration
│   ├── config              # Top bar (162 lines, 13 modules)
│   ├── config-bottom       # Bottom bar (170 lines, 11 modules)
│   ├── style.css           # Top bar styling (235 lines)
│   ├── style-bottom.css    # Bottom bar styling
│   ├── colors.css          # Dynamic color definitions
│   └── scripts/            # Waybar-specific scripts
│
├── scripts/                 # Automation backbone (8,000+ lines)
│   ├── setup/              # Installation automation (11 scripts)
│   ├── theming/            # Dynamic theme system (12 scripts)
│   ├── git/                # AI-powered git automation
│   ├── ai/                 # Ollama integration & health
│   ├── backup/             # Backup & restore systems
│   └── media/              # Media organization
│
├── matugen/                 # Dynamic theming engine
│   ├── config.toml         # Template definitions (15 apps)
│   └── templates/          # Color templates
│       ├── hyprland.template
│       ├── waybar.template
│       ├── gtk3.template
│       ├── gtk4.template
│       └── [11 more templates]
│
├── dashboard/               # Web monitoring interface
│   ├── evil_space_dashboard.py # Main entry point
│   ├── start_dashboard.fish    # Launch script
│   ├── app/                    # Dashboard application
│   │   ├── core/              # Core logic
│   │   ├── api/               # REST API endpoints
│   │   ├── frontend/          # HTML generation
│   │   └── server.py          # HTTP server
│   └── data/                  # SQLite database
│
├── fish/                    # Advanced shell configuration
│   ├── config.fish         # Main config (268 lines)
│   ├── functions/          # Custom functions
│   │   ├── aliases.fish    # System aliases (115 lines)
│   │   ├── dashboard.fish  # Dashboard launcher
│   │   └── [20+ more functions]
│   ├── completions/        # Tab completions
│   └── themes/             # Color schemes
│
├── assets/                  # Static resources
│   └── wallpapers/         # Categorized wallpapers
│       ├── space/          # Dark, cosmic themes
│       ├── nature/         # Organic, natural themes
│       ├── gaming/         # RGB, high-contrast themes
│       ├── minimal/        # Clean, simple themes
│       ├── dark/           # OLED-optimized themes
│       └── abstract/       # Artistic, colorful themes
│
├── logs/                    # Centralized logging
│   ├── packages_*.log      # Installation logs (largest)
│   ├── theming-setup_*.log # Theme system logs
│   ├── ollama-setup_*.log  # AI setup logs
│   └── [script-name]_[timestamp].log
│
└── [app-configs]/          # Application configurations
    ├── kitty/              # Terminal emulator
    ├── fuzzel/             # Application launcher  
    ├── dunst/              # Notification daemon
    ├── gtk-3.0/            # GTK3 theming
    ├── gtk-4.0/            # GTK4/libadwaita theming
    └── [15+ more apps]
```

### Key Architecture Insights

**Modular Design Philosophy:**
- **Hyprland**: 10+ config modules for maintainability
- **Waybar**: Dual-bar architecture (controls + monitoring)
- **Scripts**: Organized by function, not just alphabetically
- **Theming**: Template-based system affecting entire desktop
- **Logging**: Consistent patterns across all automation

**Scale & Complexity:**
- **Configuration Files**: 100+ configuration files
- **Automation Scripts**: 25+ scripts, 8,000+ lines of code
- **Package Management**: 397 packages across 6 categories
- **Theming Templates**: 15 applications with dynamic colors
- **Multi-Monitor**: Support for complex 3-display setups

**Production-Ready Features:**
- **Error Handling**: Comprehensive error checking and recovery
- **Logging**: Enterprise-level logging with timestamps
- **Backup Safety**: Automatic backups before modifications
- **Dry-Run Support**: Test mode for all major operations
- **User Experience**: Interactive menus and clear feedback
- **Documentation**: Extensive inline comments and guides

## Advanced Architecture Summary

This dotfiles repository represents a **sophisticated desktop environment automation system** that goes far beyond typical configuration management:

### Technical Excellence
- **Multi-Layered Architecture**: Installation → Theming → AI → Monitoring
- **Enterprise Logging**: Centralized, timestamped, searchable logs
- **AI Integration**: Local LLM automation for git workflows
- **Real-Time Monitoring**: GPU monitoring, system diagnostics, web dashboard
- **Template-Based Theming**: Material Design 3 coordination across 15+ applications
- **Service Integration**: Systemd services, background processes, automation triggers

### Operational Maturity
- **Zero-Intervention Setup**: Complete desktop from fresh Arch installation
- **Intelligent Error Handling**: Graceful failures, retry mechanisms, user guidance
- **Modular Component Design**: Independent, testable, maintainable scripts
- **Production Monitoring**: Real-time system oversight via web dashboard
- **Advanced Configuration Management**: Template-based, version-controlled, automated

### Innovation & Sophistication
- **Dynamic Theming Pipeline**: Wallpaper → AI Color Analysis → System-Wide Updates
- **AI-Powered Git Automation**: Local LLM commit generation with fallback systems
- **Real-Time GPU Monitoring**: AMD-specific hardware integration with visual indicators
- **Multi-Monitor Optimization**: Complex display configurations with workspace management
- **Comprehensive Package Management**: 6-category system with conflict resolution

This system demonstrates **enterprise-level Linux desktop automation** suitable for power users, developers, and system administrators who require both aesthetic excellence and operational reliability.

## Development Philosophy & Best Practices

**When working with this codebase:**
1. **Follow the modular patterns** - each component has a specific purpose
2. **Use the established logging system** - maintain traceability
3. **Test with dry-run modes** - validate before applying changes
4. **Leverage the AI integration** - use `dotfiles.fish sync` for commits
5. **Monitor via dashboard** - use the web interface for system oversight
6. **Respect the template system** - maintain Material Design 3 consistency
7. **Document changes** - update comments and documentation
8. **Test across the automation pipeline** - verify theming, monitoring, and services