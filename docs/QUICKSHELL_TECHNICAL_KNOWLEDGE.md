# QuickShell Technical Knowledge Base

## Overview
This document captures all technical knowledge gained during the QuickShell integration project. Use this as reference when building custom QuickShell configurations.

---

## 🔧 **API Compatibility & Breaking Changes**

### Critical API Changes
QuickShell has breaking changes from older configurations found online:

#### 1. **Process Execution**
```qml
// ❌ OLD (doesn't work)
Quickshell.execDetached(["command", "arg1", "arg2"])

// ✅ NEW (correct way)
Process {
    id: myProcess
    // Set command and start
    onSomeEvent: {
        myProcess.command = ["command", "arg1", "arg2"]
        myProcess.startDetached()
    }
}
```

#### 2. **QML ID Naming**
```qml
// ❌ OLD (case sensitive issues)
Utils { id: Utils }

// ✅ NEW (lowercase required)
Utils { id: utils }
```

#### 3. **Import Requirements**
```qml
// Always include these imports for process management
import Quickshell
import Quickshell.Io
```

---

## 🎨 **Theming & Color Integration**

### Matugen Integration
QuickShell can integrate with matugen for dynamic theming:

#### Template Format
```json
// quickshell.template - Use this exact format
{
  "primary": "{{colors.primary.default.hex}}",
  "onPrimary": "{{colors.on_primary.default.hex}}",
  "background": "{{colors.background.default.hex}}"
}
```

#### Key Points:
- Use `{{colors.color_name.default.hex}}` format
- Snake_case in template becomes camelCase in QML
- Output to `~/.local/state/quickshell/user/generated/colors.json`

#### Color Loading in QML
```qml
// MaterialThemeLoader.qml pattern
FileView {
    id: colorFile
    path: `${Directories.userState}/generated/colors.json`
    
    property var colors: ({})
    
    onContentChanged: {
        try {
            colors = JSON.parse(content || "{}")
        } catch (e) {
            console.error("Failed to parse colors:", e)
        }
    }
}
```

---

## 🏗️ **Project Structure Best Practices**

### Directory Organization
```
quickshell/
├── config/
│   └── config.json          # Main configuration
├── modules/
│   ├── bar/                 # Top bar components
│   ├── common/              # Shared utilities
│   ├── sidebars/           # Left/right sidebars
│   └── widgets/            # Reusable UI components
├── services/               # Background services
├── assets/                 # Icons, images, etc.
└── shell.qml              # Main entry point
```

### Configuration Management
```qml
// Use custom config paths
property string configPath: `${Directories.config}/quickshell/config/config.json`

// Load with FileView for hot reloading
FileView {
    id: configFile
    path: configPath
    
    property var config: ({})
    
    onContentChanged: {
        try {
            config = JSON.parse(content || "{}")
        } catch (e) {
            console.error("Config parse error:", e)
            config = {}
        }
    }
}
```

---

## 🖥️ **Multi-Monitor Support**

### Monitor Detection
```qml
// Access all monitors
Hyprland.monitors.values

// Get specific monitor
property var primaryMonitor: Hyprland.monitors.values.find(m => m.name === "DP-1")

// Monitor properties available:
// - name (e.g., "DP-1")
// - width, height
// - x, y (position)
// - scale
// - focused
```

### Window Positioning
```qml
PanelWindow {
    monitor: targetMonitor
    anchors {
        top: true
        left: true
        right: true
    }
    height: 40
    exclusiveZone: height  // Reserve space
}
```

---

## 🎵 **Audio & Media Integration**

### PipeWire/PulseAudio
```qml
// Audio service access
property var audioService: Audio.defaultSink

// Volume control
onVolumeChange: {
    audioService.volume = newVolume
}

// Mute toggle
onMuteToggle: {
    audioService.muted = !audioService.muted
}
```

### MPRIS Media Control
```qml
// Media players
property var players: Mpris.players

// Control playback
onPlayPause: {
    if (players.length > 0) {
        players[0].togglePlayPause()
    }
}
```

---

## 🔔 **Notification System**

### Custom Notification Service
```qml
// Basic notification
Notifications.notify("Title", "Body", "icon-name")

// Advanced notification with actions
Notifications.notify("Title", "Body", "icon", {
    actions: ["action1", "Action 1", "action2", "Action 2"],
    timeout: 5000,
    urgency: "normal"
})
```

### Notification History
```qml
// Access notification history
property var notifications: Notifications.notifications

// Clear all notifications
Notifications.clearAll()
```

---

## ⌨️ **Input & Shortcuts**

### Global Shortcuts
```qml
GlobalShortcut {
    name: "myShortcut"
    description: "My custom shortcut"
    
    onPressed: {
        // Handle shortcut
    }
}
```

### Hyprland Integration
```qml
// Dispatch Hyprland commands
Hyprland.dispatch("workspace", "1")
Hyprland.dispatch("killactive")

// Global dispatch (for IPC)
Hyprland.dispatch("global", "quickshell:myAction")
```

---

## 🎯 **Performance Optimization**

### Lazy Loading
```qml
Loader {
    id: heavyComponent
    active: shouldLoad
    sourceComponent: Component {
        // Heavy component here
    }
}
```

### Efficient Updates
```qml
// Use property bindings for reactive updates
property bool isActive: someService.active

// Avoid frequent property changes
Timer {
    interval: 100  // Throttle updates
    running: true
    repeat: true
    onTriggered: updateUI()
}
```

---

## 🐛 **Common Issues & Solutions**

### 1. **Zero Width/Height Warnings**
```qml
// Problem: Layout items with no size
Item {
    // ❌ This causes warnings
    visible: true
    // No width/height set
}

// Solution: Always set explicit sizes
Item {
    visible: true
    implicitWidth: 100
    implicitHeight: 30
}
```

### 2. **Icon Loading Issues**
```qml
// Use fallback icons
Icon {
    source: "my-icon"
    fallback: "image-missing"
}

// Or custom icon component with error handling
CustomIcon {
    source: iconExists ? "custom-icon" : "fallback-icon"
}
```

### 3. **Service Dependencies**
```qml
// Check service availability
Component.onCompleted: {
    if (typeof SomeService !== 'undefined') {
        // Service available
    } else {
        console.warn("SomeService not available")
    }
}
```

---

## 📦 **Dependencies & Requirements**

### Core Requirements
- QuickShell v0.1.0+
- Qt 6.5+
- Hyprland (for Wayland integration)

### Optional Dependencies
```bash
# Clipboard management
sudo pacman -S cliphist

# External monitor brightness
sudo pacman -S ddcutil

# Translation services
yay -S translate-shell

# Video wallpapers
yay -S mpvpaper

# System monitoring
sudo pacman -S btop htop
```

### System Integration
```bash
# Ensure these are available for full functionality
which hyprctl     # Hyprland control
which notify-send # Notifications
which nmcli       # Network management
which bluetoothctl # Bluetooth
which pactl       # Audio control
```

---

## 🎨 **Material Design 3 Guidelines**

### Color System
- Use Material 3 color roles (primary, secondary, tertiary)
- Implement proper contrast ratios (4.5:1 minimum)
- Support both light and dark themes

### Typography
```qml
// Font hierarchy
property int displayLarge: 57
property int headlineLarge: 32
property int titleLarge: 22
property int bodyLarge: 16
property int labelLarge: 14
```

### Spacing
```qml
// Material 3 spacing scale
property int space4: 4
property int space8: 8
property int space12: 12
property int space16: 16
property int space24: 24
property int space32: 32
```

### Animations
```qml
// Material motion curves
property var standardCurve: [0.2, 0.0, 0, 1.0]
property var decelerateCurve: [0.0, 0.0, 0.2, 1.0]
property var accelerateCurve: [0.3, 0.0, 1.0, 1.0]
```

---

## 🔄 **State Management**

### Global State
```qml
// GlobalStates.qml pattern
QtObject {
    id: globalStates
    
    property bool sidebarOpen: false
    property string currentTheme: "dark"
    property var activeNotifications: []
    
    signal stateChanged(string stateName, var newValue)
}
```

### Persistent State
```qml
// Save state to file
function saveState() {
    const state = {
        sidebarOpen: GlobalStates.sidebarOpen,
        theme: GlobalStates.currentTheme
    }
    
    FileUtils.writeFile(
        `${Directories.userState}/app-state.json`,
        JSON.stringify(state, null, 2)
    )
}
```

---

## 🚀 **Development Workflow**

### Hot Reloading
```bash
# Reload QuickShell configuration
quickshell --reload

# Or use the reload button in UI
# Or Hyprland shortcut: Super+R
```

### Debugging
```qml
// Enable debug output
console.log("Debug info:", someVariable)
console.warn("Warning:", warningMessage)
console.error("Error:", errorDetails)

// Check QuickShell logs
tail -f ~/.local/state/quickshell/logs/quickshell.log
```

### Testing
```bash
# Test configuration syntax
quickshell --check

# Test specific component
quickshell --component MyComponent.qml
```

---

## 📝 **Best Practices Summary**

1. **Always use Process objects** instead of execDetached
2. **Implement proper error handling** for all external dependencies
3. **Use FileView for configuration** to enable hot reloading
4. **Follow Material 3 design principles** for consistent UI
5. **Test on actual hardware** - multi-monitor setups behave differently
6. **Implement graceful degradation** when optional services unavailable
7. **Use proper QML naming conventions** - lowercase IDs, PascalCase types
8. **Structure code modularly** - separate concerns into different files
9. **Document configuration options** - make it easy to customize
10. **Test with different themes** - ensure compatibility with light/dark modes

---

## 🎓 **Key Learnings**

### What Works Well
- QuickShell's modular architecture
- Material 3 theming integration
- Hyprland integration for window management
- FileView for hot-reloadable configuration
- Multi-monitor support with proper positioning

### Common Pitfalls
- API compatibility issues with older examples
- Case sensitivity in QML IDs
- Missing error handling for external dependencies
- Layout sizing issues without explicit dimensions
- Process execution patterns changed significantly

### Development Tips
- Start simple and build incrementally
- Test each component individually
- Use the devlog approach for complex integrations
- Keep configuration separate from implementation
- Always implement fallbacks for missing dependencies

---

*This knowledge base should be updated as new QuickShell features and patterns are discovered.* 