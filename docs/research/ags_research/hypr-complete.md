# Complete Hyprland Desktop Environment with AGS/Astal, Dual Bars, and AI Integration

This comprehensive guide provides practical implementation guidance for building a sophisticated Hyprland desktop environment featuring AGS/Astal widgets, dual bars across three monitors, dynamic theming, and local LLM integration on Arch Linux with AMD GPU optimization.

## Foundation: Hyprland on Arch Linux with AMD GPU

The foundation requires proper AMD GPU setup for optimal Wayland performance. **AMD GPUs generally provide superior Wayland compatibility compared to NVIDIA**, making them ideal for this configuration.

### Essential Installation

```bash
# Core Hyprland installation
sudo pacman -S hyprland wayland wlroots xdg-desktop-portal-hyprland
sudo pacman -S waybar wofi kitty polkit-kde-agent pipewire wireplumber

# AMD GPU drivers and acceleration
sudo pacman -S mesa xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau amdgpu_top
sudo pacman -S libva-utils ffmpeg opencl-mesa

# Advanced components
yay -S matugen-bin swww swaync ollama-bin
```

### AMD GPU Optimization Configuration

**Critical AMD environment variables for `~/.config/hypr/hyprland.conf`:**

```bash
# AMD VAAPI hardware acceleration
env = LIBVA_DRIVER_NAME,radeonsi
env = VDPAU_DRIVER,radeonsi
env = AMD_VULKAN_ICD,RADV

# Wayland optimization
env = XDG_SESSION_TYPE,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = MOZ_ENABLE_WAYLAND,1

# Performance optimizations for AMD
decoration {
    blur { enabled = false }  # Disable for better performance
    drop_shadow = false
}

misc {
    vfr = true  # Variable frame rate when idle
}
```

**For older AMD GPUs, force AMDGPU kernel module:**

```bash
# /etc/modprobe.d/amdgpu.conf
options amdgpu si_support=1
options amdgpu cik_support=1
options radeon si_support=0
options radeon cik_support=0
```

## AGS/Astal Widget System: The Modern Waybar Replacement

**AGS has evolved into an Astal-based architecture** with TypeScript/JSX support, providing superior customization compared to traditional bars.

### Current AGS/Astal Architecture

The ecosystem now centers around **Astal libraries** (written in Vala/C) with AGS serving as CLI scaffolding for TypeScript projects. **For new projects, use Astal with TypeScript/JSX rather than legacy AGS v1/v2**.

### Dual Bar Configuration Across Three Monitors

**Project structure for modular approach:**

```
~/.config/ags/
├── app.ts                 # Main entry point
├── widget/
│   ├── TopBar.tsx        # Top bar component
│   ├── BottomBar.tsx     # Bottom bar component
│   ├── Clock.tsx         # Clock widget
│   ├── Workspaces.tsx    # Workspace management
│   └── SystemTray.tsx    # System tray widget
├── service/
│   ├── hyprland.ts       # Hyprland integration
│   └── llm.ts            # Local LLM service
├── style/
│   ├── main.scss         # Main stylesheet
│   └── bars.scss         # Bar-specific styles
└── config/
    └── monitors.ts       # Monitor configuration
```

**Multi-monitor dual bar implementation:**

```typescript
// config/monitors.ts
export const MONITOR_CONFIG = {
    primary: 0,
    secondary: 1,
    tertiary: 2,
    layouts: {
        dual_bars: true,
        top_modules: ["workspaces", "window-title", "clock", "systray"],
        bottom_modules: ["media", "llm-chat", "system-info"]
    }
}

// widget/TopBar.tsx
function TopBar(monitor = 0) {
    return <window 
        className="TopBar" 
        name={`top-bar-${monitor}`}
        monitor={monitor}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
        <centerbox>
            <box halign="start">
                <Workspaces monitor={monitor} />
                <WindowTitle />
            </box>
            <box halign="center">
                <Clock />
            </box>
            <box halign="end">
                <SystemTray />
                <LLMWidget />
            </box>
        </centerbox>
    </window>
}

// widget/BottomBar.tsx  
function BottomBar(monitor = 0) {
    return <window 
        className="BottomBar" 
        name={`bottom-bar-${monitor}`}
        monitor={monitor}
        anchor={Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
        <centerbox>
            <box halign="start">
                <MediaPlayer />
            </box>
            <box halign="center">
                <TaskBar monitor={monitor} />
            </box>
            <box halign="end">
                <NetworkInfo />
                <SystemMetrics />
            </box>
        </centerbox>
    </window>
}

// app.ts - Main entry point
App.start({
    main() {
        // Create dual bars for each monitor
        for (let i = 0; i <= MONITOR_CONFIG.tertiary; i++) {
            TopBar(i)
            BottomBar(i)
        }
    },
})
```

### Workspace Management Across Monitors

**Advanced workspace widget with per-monitor groups:**

```typescript
// widget/Workspaces.tsx
function WorkspaceWidget({ monitor }: { monitor: number }) {
    return <box className="workspaces">
        {bind(Hyprland, "workspaces").as(workspaces =>
            workspaces
                .filter(ws => ws.monitor === `monitor ${monitor}`)
                .map(workspace => (
                    <button
                        className={workspace.id === Hyprland.active.workspace.id ? "focused" : ""}
                        onClicked={() => execAsync(`hyprctl dispatch workspace ${workspace.id}`)}
                    >
                        <label label={`${workspace.id}`} />
                    </button>
                ))
        )}
    </box>
}
```

## Integrated Notification and Launcher System

### Notification System: SwayNC Recommended

**SwayNC provides the most comprehensive notification center** with GUI controls and extensive customization options.

```bash
# Installation
sudo pacman -S swaync

# Configuration (~/.config/swaync/config.json)
{
  "positionX": "right",
  "positionY": "top",
  "control-center-width": 500,
  "control-center-height": 600,
  "notification-window-width": 500,
  "timeout": 10,
  "timeout-critical": 0,
  "fit-to-screen": true,
  "keyboard-shortcuts": true,
  "image-visibility": "when-available",
  "transition-time": 200,
  "widgets": ["inhibitors", "title", "dnd", "notifications"],
  "widget-config": {
    "title": {
      "text": "Notifications",
      "clear-all-button": true,
      "button-text": "Clear All"
    }
  }
}
```

### App Launcher: Rofi with Wayland

**Rofi provides the most feature-rich launching experience:**

```bash
# Installation  
yay -S rofi-wayland

# Configuration (~/.config/rofi/config.rasi)
configuration {
    modi: "window,drun,ssh,combi";
    width: 50;
    show-icons: true;
    terminal: "kitty";
    drun-display-format: "{icon} {name}";
    disable-history: false;
    sidebar-mode: false;
    matching: "normal";
    theme: "custom";
}
```

## Advanced Sidebar Implementation 

### AGS-Based Modular Sidebar

**Create a comprehensive sidebar with system controls and AI integration:**

```typescript
// widget/Sidebar.tsx
function SidebarContent() {
    return <box orientation={Gtk.Orientation.VERTICAL} className="sidebar-content">
        <box className="header">
            <label label="Control Panel" />
        </box>
        
        <box orientation={Gtk.Orientation.VERTICAL} className="system-controls">
            <label label="System Controls" />
            <button onClicked={() => execAsync("nmcli device wifi rescan")}>
                WiFi Scan
            </button>
            <button onClicked={() => execAsync("bluetoothctl power toggle")}>
                Toggle Bluetooth  
            </button>
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} className="ai-section">
            <label label="AI Assistant" />
            <LLMChatWidget />
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} className="quick-launch">
            <label label="Quick Launch" />
            <button onClicked={() => execAsync("kitty")}>Terminal</button>
            <button onClicked={() => execAsync("firefox")}>Browser</button>
        </box>
    </box>
}

const Sidebar = () => <window
    name="sidebar"
    anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
    visible={false}
>
    <SidebarContent />
</window>
```

## Dynamic Theming with Matugen Integration

### Complete Matugen Setup

**Matugen automatically generates Material Design 3 color schemes** from wallpapers and applies them across all components.

```bash
# Installation
yay -S matugen-bin

# Configuration (~/.config/matugen/config.toml)
[config]
set_wallpaper = true

[config.wallpaper]
command = "swww"
arguments = ["img", "--transition-type", "center"]

[templates.hyprland]
input_path = '~/.config/matugen/templates/hyprland-colors.conf'
output_path = '~/.config/hypr/colors.conf'
post_hook = 'hyprctl reload'

[templates.ags]
input_path = '~/.config/matugen/templates/colors.scss'
output_path = '~/.config/ags/style/colors.scss'

[templates.rofi]
input_path = '~/.config/matugen/templates/colors.rasi'
output_path = '~/.config/rofi/colors.rasi'

[templates.swaync]
input_path = '~/.config/matugen/templates/swaync.css'
output_path = '~/.config/swaync/style.css'
```

**Template examples for consistent theming:**

```scss
/* ~/.config/matugen/templates/colors.scss */
$primary: {{colors.primary.default.hex}};
$secondary: {{colors.secondary.default.hex}};
$surface: {{colors.surface.default.hex}};
$on_primary: {{colors.on_primary.default.hex}};
$on_surface: {{colors.on_surface.default.hex}};
```

**Automated wallpaper and theming script:**

```bash
#!/bin/bash
# ~/.config/hypr/scripts/wallpaper.sh
WALLPAPER_DIR="$HOME/.config/wallpapers"
SELECTED=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | rofi -dmenu -i -p "Select wallpaper")

if [ -n "$SELECTED" ]; then
    # Generate colors and apply
    matugen image "$SELECTED"
    
    # Set wallpaper
    swww img "$SELECTED" --transition-type wipe --transition-duration 2
    
    # Notify completion
    notify-send "Wallpaper Changed" "Colors updated automatically"
fi
```

## Local LLM Integration for Desktop AI

### Ollama Setup and Configuration

**Ollama provides the simplest local LLM deployment:**

```bash
# Installation and setup
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3:8b
ollama pull mistral:7b

# Service management
systemctl --user enable ollama
systemctl --user start ollama
```

### AGS LLM Widget Integration

**Create an interactive AI assistant widget:**

```typescript
// service/llm.ts
class LLMService extends Service {
    static {
        Service.register(this, {}, {
            'response': ['string'],
        })
    }

    #response = ''
    
    get response() { return this.#response }

    async query(prompt: string, model = 'llama3:8b') {
        try {
            const response = await fetch('http://localhost:11434/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: model,
                    prompt: prompt,
                    stream: false
                })
            })
            
            const data = await response.json()
            this.#response = data.response
            this.emit('response', data.response)
        } catch (error) {
            this.#response = `Error: ${error.message}`
            this.emit('response', this.#response)
        }
    }
}

export default new LLMService()

// widget/LLMWidget.tsx
function LLMWidget() {
    const [input, setInput] = useState('')
    const [isLoading, setIsLoading] = useState(false)
    
    const handleSubmit = async () => {
        if (!input.trim()) return
        
        setIsLoading(true)
        await LLMService.query(input)
        setInput('')
        setIsLoading(false)
    }

    return <box className="llm-widget" orientation={Gtk.Orientation.VERTICAL}>
        <scrolledwindow className="response-area">
            <label 
                label={bind(LLMService, 'response')} 
                wrap={true}
                selectable={true}
            />
        </scrolledwindow>
        
        <box className="input-area">
            <entry
                text={bind(Variable(input))}
                onChanged={({ text }) => setInput(text)}
                onActivate={handleSubmit}
                placeholderText="Ask AI..."
            />
            <button 
                onClicked={handleSubmit}
                sensitive={!isLoading}
            >
                {isLoading ? "..." : "Send"}
            </button>
        </box>
    </box>
}
```

## Modular Configuration Organization

### Best Practices Directory Structure

**Implement a maintainable modular structure:**

```
~/.config/hypr/
├── hyprland.conf              # Main configuration
├── configs/                   # Core modules
│   ├── monitor.conf          # Multi-monitor setup
│   ├── input.conf            # Input devices
│   ├── decorations.conf      # Visual settings
│   ├── animations.conf       # Animation configuration
│   └── rules.conf            # Window rules
├── UserConfigs/              # User customizations
│   ├── Startup_Apps.conf    # Autostart applications
│   ├── ENVariables.conf     # Environment variables
│   ├── UserKeybinds.conf    # Custom keybindings
│   └── UserSettings.conf    # Personal settings
├── Monitor_Profiles/         # Display profiles
│   ├── triple-monitor.conf  # 3-monitor setup
│   ├── dual-monitor.conf    # 2-monitor setup
│   └── laptop.conf          # Single display
├── scripts/                  # Automation scripts
│   ├── startup.sh           # System initialization
│   ├── wallpaper.sh         # Wallpaper management
│   └── backup_config.sh     # Configuration backup
└── backup/                   # Configuration backups
```

**Main configuration with modular imports:**

```bash
# ~/.config/hypr/hyprland.conf
# Modular Hyprland Configuration

# Load color scheme
source = colors.conf

# Core configuration modules
source = ~/.config/hypr/configs/monitor.conf
source = ~/.config/hypr/configs/input.conf
source = ~/.config/hypr/configs/decorations.conf
source = ~/.config/hypr/configs/animations.conf
source = ~/.config/hypr/configs/rules.conf

# User-specific configurations
source = ~/.config/hypr/UserConfigs/ENVariables.conf
source = ~/.config/hypr/UserConfigs/UserSettings.conf
source = ~/.config/hypr/UserConfigs/UserKeybinds.conf
source = ~/.config/hypr/UserConfigs/Startup_Apps.conf

# Monitor profile (uncomment appropriate profile)
source = ~/.config/hypr/Monitor_Profiles/triple-monitor.conf
# source = ~/.config/hypr/Monitor_Profiles/dual-monitor.conf
# source = ~/.config/hypr/Monitor_Profiles/laptop.conf
```

## Inspiration from Notable Configurations

### End-4 Dots: Advanced AI-Integrated Setup

**Repository**: https://github.com/end-4/dots-hyprland

**Key Features**: AI sidebar with Gemini and Ollama support, Material Design 3 theming, automatic color generation, advanced workspace management with unlimited scaling.

### ML4W Dotfiles: Comprehensive Cross-Platform

**Repository**: https://github.com/mylinuxforwork/dotfiles

**Key Features**: Installation scripts for Arch/Fedora, multiple waybar themes, extensive customization options, active community support.

### HyprPanel: Production-Ready Multi-Monitor

**Repository**: https://github.com/Jas-SinghFSU/HyprPanel

**Key Features**: Sophisticated multi-monitor support, modular widget architecture, comprehensive system integration.

## Performance Optimization and Troubleshooting

### Critical Performance Settings

**Essential optimizations for smooth operation:**

```bash
# ~/.config/hypr/configs/performance.conf
decoration {
    blur { enabled = false }    # Major performance gain
    shadow { enabled = false }  # Reduce GPU load
}

misc {
    vfr = true                 # Variable frame rate when idle
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

# Use integer scaling for best performance
monitor = ,preferred,auto,1
```

### Common Issues and Solutions

**AGS not starting**: Check if TypeScript is properly installed and configured
```bash
npm install -g typescript
ags --init
```

**LLM integration failing**: Verify Ollama service status
```bash
systemctl --user status ollama
curl http://localhost:11434/api/tags
```

**Performance issues with multiple bars**: Implement lazy loading and resource sharing
```typescript
// Share service instances across bars
const sharedHyprland = Hyprland.get_default()
const sharedAudio = Audio.get_default()
```

### Monitoring and Maintenance

**Performance monitoring script:**

```bash
#!/bin/bash
# ~/.config/hypr/scripts/performance_monitor.sh
echo "=== Hyprland Performance Monitor ==="
echo "Windows: $(hyprctl clients | grep -c "Window")"
echo "Workspaces: $(hyprctl workspaces | grep -c "workspace")"
echo "GPU Usage: $(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null || echo "N/A")"
echo "Memory: $(free -h | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
```

**Automated backup system:**

```bash
#!/bin/bash
# ~/.config/hypr/scripts/backup_config.sh
BACKUP_DIR="$HOME/.config/hypr/backup"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
    ~/.config/hypr \
    ~/.config/ags \
    ~/.config/waybar \
    ~/.config/rofi \
    ~/.config/swaync \
    ~/.config/matugen

# Keep only last 5 backups
ls -t "$BACKUP_DIR"/config_*.tar.gz | tail -n +6 | xargs -r rm
```

## Implementation Roadmap

### Phase 1: Foundation Setup
1. Install Hyprland with AMD GPU optimization
2. Configure basic three-monitor setup
3. Test hardware acceleration and performance

### Phase 2: Widget System
1. Install AGS/Astal and configure basic dual bars
2. Implement modular widget structure
3. Add essential widgets (workspaces, clock, system tray)

### Phase 3: Integration Layer
1. Setup notification system (SwayNC)
2. Configure app launcher (Rofi)
3. Implement basic sidebar functionality

### Phase 4: Advanced Features
1. Install and configure Matugen for dynamic theming
2. Setup Ollama and implement LLM integration
3. Create automated wallpaper and theming scripts

### Phase 5: Optimization and Polish
1. Implement performance optimizations
2. Create comprehensive backup and maintenance scripts
3. Document configuration and create restore procedures

This comprehensive system provides a modern, efficient, and highly customizable desktop environment that leverages the latest developments in Wayland desktop technology while maintaining excellent performance on AMD GPUs. The modular approach ensures maintainability and extensibility for future enhancements.