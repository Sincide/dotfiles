# 🔍 AGS/Astal - Complete Research & Implementation Guide

*Comprehensive research findings on AGS/Astal for sidebar implementation*

---

## 📋 Executive Summary

Based on extensive research, **AGS v2/Astal** is the optimal choice for implementing a smart sidebar system in your dotfiles. This document contains all the essential information needed for successful implementation.

### 🎯 Key Findings
- **AGS v2** is actually a scaffolding CLI tool for **Astal** projects
- **Astal** is the core library suite (Vala/C) that provides desktop shell functionality
- **AGS CLI** helps initialize, bundle, and run TypeScript/JavaScript Astal projects
- Perfect integration with Hyprland via layer-shell protocol

---

## 🏗️ Architecture Overview

### Core Components
1. **Astal Core Libraries** (`libastal-*`)
   - Written in Vala/C for performance
   - Provides widgets, services, and system integrations
   - Uses GObject Introspection for language bindings

2. **AGS CLI Tool**
   - Go-based scaffolding tool
   - Handles project initialization, bundling, and execution
   - TypeScript support with automatic type generation

3. **JavaScript Runtime**
   - Runs on GJS (GNOME JavaScript)
   - Same runtime that GNOME Shell uses
   - Firefox SpiderMonkey engine + GNOME platform libraries

---

## 📦 Installation Guide

### Arch Linux Installation

#### Option 1: AUR Packages (Recommended)
```bash
# Install AGS CLI + dependencies
yay -S aylurs-gtk-shell

# This installs:
# - ags (CLI tool)
# - libastal-meta (all Astal libraries)
# - libastal-gjs (JavaScript bindings)
# - All necessary dependencies
```

#### Option 2: Git Versions (Latest Features)
```bash
# For bleeding edge
yay -S aylurs-gtk-shell-git
```

### Dependencies Breakdown
```bash
# Core dependencies (auto-installed)
blueprint-compiler    # UI file compilation
dart-sass             # SCSS compilation  
gjs                   # JavaScript runtime
gobject-introspection # Language bindings
libastal-meta         # All Astal libraries
npm                   # Node package manager
go                    # For building AGS CLI
```

### Post-Installation Verification
```bash
# Check AGS version
ags --version

# Check available libraries
ls /usr/lib/girepository-1.0/ | grep -i astal

# Test basic functionality
ags init test-project
cd test-project
ags run
```

---

## 🚀 Development Workflow

### Project Initialization
```bash
# Create new project
ags init sidebar-project
cd sidebar-project

# Project structure created:
# ├── app.ts          # Main application file
# ├── style.scss      # Styling
# ├── tsconfig.json   # TypeScript configuration
# └── node_modules/   # Dependencies
```

### Development Commands
```bash
# Run development server (with hot reload)
ags run

# Bundle for production
ags bundle

# Generate TypeScript types for libraries
ags types

# Run bundled application
ags run ./dist/main.js
```

### Configuration Structure
```typescript
// app.ts - Main configuration file
import { App, Window, Widget } from "astal/gtk3"
import { Variable, bind } from "astal"

// Create a variable for dynamic content
const time = Variable("").poll(1000, "date")

// Define a window (your sidebar)
function Sidebar() {
    return <Window
        name="sidebar"
        namespace="sidebar"
        anchor={Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        application={App}>
        <Box vertical>
            <Label label={bind(time)} />
            {/* Your widgets here */}
        </Box>
    </Window>
}

// Start the application
App.start({
    css: "./style.scss",
    main() {
        Sidebar()
    }
})
```

---

## 🎛️ Available Libraries & Services

### System Information Libraries
```typescript
// System stats
import Battery from "gi://AstalBattery"
import Network from "gi://AstalNetwork" 
import Apps from "gi://AstalApps"

// Hardware monitoring  
import Cava from "gi://AstalCava"        // Audio visualization
import WirePlumber from "gi://AstalWp"   // Audio control

// Desktop integration
import Hyprland from "gi://AstalHyprland"  // Hyprland integration
import Tray from "gi://AstalTray"          // System tray
import Mpris from "gi://AstalMpris"        // Media player control
```

### Core Widgets
```typescript
import { Widget } from "astal/gtk3"

// Basic widgets
Widget.Box()           // Container
Widget.Label()         // Text display
Widget.Button()        // Clickable button
Widget.ProgressBar()   // Progress indicator
Widget.Slider()        // Value slider
Widget.Entry()         // Text input
Widget.Image()         // Image display

// Layout widgets  
Widget.CenterBox()     // Three-section layout
Widget.Overlay()       // Layered widgets
Widget.Revealer()      // Animated show/hide
Widget.Stack()         // Switching between widgets
```

---

## 🎨 Styling System

### SCSS Support
```scss
// style.scss - Built-in SCSS compilation
.sidebar {
    background: rgba(0, 0, 0, 0.8);
    border-radius: 10px;
    margin: 10px;
    padding: 20px;
    
    .system-info {
        font-size: 14px;
        color: #ffffff;
        
        .cpu-usage {
            color: #ff6b6b;
        }
        
        .memory-usage {
            color: #4ecdc4;
        }
    }
}

// Variables and mixins supported
$primary-color: #7c3aed;
$border-radius: 8px;

@mixin glass-effect {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
}
```

### Dynamic Styling
```typescript
// CSS can be updated at runtime
App.apply_css(`
    .sidebar {
        background: ${currentTheme.background};
    }
`)
```

---

## 🔗 Hyprland Integration

### Layer Shell Configuration
```typescript
// Sidebar window configuration for Hyprland
function Sidebar() {
    return <Window
        name="sidebar"
        namespace="sidebar"
        layer={Astal.Layer.OVERLAY}
        anchor={Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        keymode={Astal.Keymode.ON_DEMAND}
        visible={false}
        application={App}>
        {/* Content */}
    </Window>
}
```

### Hyprland Window Rules
```ini
# In hyprland.conf
layerrule = blur, sidebar
layerrule = blurpopups, sidebar  
layerrule = ignorealpha 0.2, sidebar

# Animation for sidebar
animation = slide, 1, 6, default, slide
```

### Keybind Integration
```ini
# In hyprland.conf - Toggle sidebar
bind = SUPER, grave, exec, ags toggle-window sidebar

# Or using hyprctl
bind = SUPER, grave, exec, hyprctl dispatch exec "ags toggle-window sidebar"
```

---

## 💡 Best Practices & Patterns

### Variable Management
```typescript
// Reactive variables for dynamic content
const cpuUsage = Variable(0).poll(1000, ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1"])
const memoryUsage = Variable(0).poll(1000, "free | grep Mem | awk '{print ($3/$2) * 100.0}'")

// Bind to widgets
<Label label={bind(cpuUsage).as(cpu => `CPU: ${cpu}%`)} />
```

### Service Integration  
```typescript
// Battery service example
const battery = Battery.get_default()

<Box>
    <Icon icon={bind(battery, "iconName")} />
    <Label label={bind(battery, "percentage").as(p => `${p}%`)} />
    <ProgressBar value={bind(battery, "percentage").as(p => p / 100)} />
</Box>
```

### Performance Optimization
```typescript
// Use polling sparingly - prefer signals when available
const battery = Battery.get_default()

// Good: Uses GObject signals
battery.connect("notify", () => {
    // React to battery changes
})

// Avoid: Unnecessary polling when signals exist
// Variable(0).poll(1000, "cat /sys/class/power_supply/BAT0/capacity")
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "Typelib file not found"
**Problem**: AGS v2 missing typelib files
**Solution**: 
```bash
# Install git version which includes typelibs
yay -S aylurs-gtk-shell-git
# Or install individual astal libraries
yay -S libastal-meta
```

### Issue 2: "Cannot find module" errors
**Problem**: Missing JavaScript bindings
**Solution**:
```bash
# Ensure GJS bindings are installed
yay -S libastal-gjs-git

# Generate types
ags types
```

### Issue 3: Hot reload not working
**Problem**: Changes not reflected in running application
**Solution**:
```bash
# Kill existing instance
pkill ags

# Restart with run command
ags run
```

### Issue 4: Sidebar not appearing
**Problem**: Layer shell or window rules issues
**Solution**:
```ini
# Check hyprland layer rules
layerrule = noanim, sidebar   # Disable if animations cause issues

# Verify window shows in hyprctl
hyprctl layers
```

---

## 🔧 Example Implementations

### Basic System Monitor Sidebar
```typescript
import { App, Window, Widget } from "astal/gtk3"
import { Variable, bind } from "astal"
import Battery from "gi://AstalBattery"
import Wp from "gi://AstalWp"

const cpu = Variable("").poll(1000, "grep 'cpu ' /proc/stat | awk '{print ($2+$4)*100/($2+$3+$4+$5)}'")
const memory = Variable("").poll(2000, "free | grep Mem | awk '{print ($3/$2) * 100.0}'")

function SystemStats() {
    return <Box vertical className="system-stats">
        <Label label="System Monitor" className="title" />
        
        <Box className="stat-row">
            <Label label="CPU:" />
            <ProgressBar value={bind(cpu).as(c => parseFloat(c) / 100)} />
            <Label label={bind(cpu).as(c => `${Math.round(parseFloat(c))}%`)} />
        </Box>
        
        <Box className="stat-row">
            <Label label="RAM:" />
            <ProgressBar value={bind(memory).as(m => parseFloat(m) / 100)} />
            <Label label={bind(memory).as(m => `${Math.round(parseFloat(m))}%`)} />
        </Box>
    </Box>
}

function QuickSettings() {
    const audio = Wp.get_default()?.audio
    
    return <Box vertical className="quick-settings">
        <Label label="Quick Settings" className="title" />
        
        <Box className="setting-row">
            <Icon icon="audio-volume-high" />
            <Slider 
                value={bind(audio.defaultSpeaker, "volume")}
                onDragged={({ value }) => audio.defaultSpeaker.volume = value}
            />
        </Box>
    </Box>
}

function Sidebar() {
    return <Window
        name="sidebar"
        namespace="sidebar"
        anchor={Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        visible={false}
        application={App}>
        <Box vertical className="sidebar" spacing={20}>
            <SystemStats />
            <QuickSettings />
        </Box>
    </Window>
}

App.start({
    css: "./style.scss",
    main() {
        Sidebar()
    }
})
```

---

## 🎯 Next Steps for Implementation

### Phase 1: Basic Setup (Week 1)
1. **Install AGS/Astal**
   ```bash
   yay -S aylurs-gtk-shell
   ```

2. **Create sidebar project**
   ```bash
   ags init evil-space-sidebar
   cd evil-space-sidebar
   ```

3. **Basic sidebar window**
   - Create toggleable sidebar
   - Add to Hyprland keybinds
   - Basic styling

### Phase 2: Core Features (Week 2)
1. **System monitoring**
   - CPU, RAM, GPU usage
   - Temperature monitoring
   - Network status

2. **Quick settings**
   - Volume control
   - Brightness control
   - WiFi/Bluetooth toggles

### Phase 3: Advanced Features (Week 3-4)
1. **AI integration**
   - LLM status display
   - Ollama model switching
   - AI insights panel

2. **Theme integration**
   - Dynamic theme previews
   - Wallpaper gallery
   - Color scheme switching

3. **Performance optimization**
   - Lazy loading
   - Efficient polling
   - Memory management

---

## 📚 Additional Resources

### Official Documentation
- [AGS v2 Documentation](https://aylur.github.io/ags/)
- [Astal Library Reference](https://aylur.github.io/astal/)
- [AGS GitHub Repository](https://github.com/Aylur/ags)
- [Astal GitHub Repository](https://github.com/Aylur/astal)

### Community Examples
- [HyprPanel v2](https://hyprpanel.com/) - AGS-based panel
- [AGS Examples Directory](https://github.com/Aylur/astal/tree/main/examples)
- [Community Dotfiles](https://github.com/topics/ags-v2)

### Related Tools
- [Hyprland Wiki - Status Bars](https://wiki.hyprland.org/Useful-Utilities/Status-Bars/)
- [GTK4 Documentation](https://docs.gtk.org/gtk4/)
- [GJS Guide](https://gjs.guide/)

---

*This document provides all the essential information needed to successfully implement AGS/Astal in your dotfiles system. The research shows that AGS v2/Astal is mature, well-supported, and perfect for your sidebar implementation needs.* 