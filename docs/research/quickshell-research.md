# Complete Hyprland + QuickShell System Setup Guide

This comprehensive guide covers setting up a complete Hyprland desktop environment on Arch Linux with QuickShell replacing waybar, featuring dual bars across 3 monitors, integrated notifications, app launcher functionality, awesome sidebar implementation, and dynamic theming with Matugen.

## Foundation: Hyprland Installation and Setup

**Hyprland** serves as our Wayland compositor foundation, providing window management and multi-monitor support. The installation process requires specific dependencies and configuration for optimal QuickShell integration.

### Essential Installation Commands

```bash
# Install yay if not present
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si && cd .. && rm -rf yay

# Core Hyprland installation
sudo pacman -S hyprland  # Stable release
# OR for bleeding edge: yay -S hyprland-git

# Essential dependencies for complete system
sudo pacman -S kitty pipewire wireplumber pipewire-audio pipewire-pulse
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
sudo pacman -S brightnessctl pamixer playerctl grim slurp wl-clipboard
sudo pacman -S hyprpaper hyprlock network-manager-applet pavucontrol
sudo pacman -S noto-fonts ttf-jetbrains-mono-nerd otf-font-awesome

# QuickShell installation
yay -S quickshell-git  # Development version recommended
```

### Multi-Monitor Hyprland Configuration

The foundation configuration supports 3 monitors with workspace assignment and QuickShell integration. Create or modify `~/.config/hypr/hyprland.conf`:

```bash
# Monitor configuration for 3-monitor setup
monitor = DP-1, 2560x1440@144, 1920x0, 1       # Center (Primary)
monitor = DP-2, 1920x1080@60, 0x360, 1         # Left
monitor = HDMI-A-1, 1920x1080@60, 4480x360, 1  # Right

# Workspace assignment per monitor
workspace = 1, monitor:DP-2, default:true    # Left monitor
workspace = 2, monitor:DP-2
workspace = 3, monitor:DP-2
workspace = 4, monitor:DP-1, default:true    # Center monitor  
workspace = 5, monitor:DP-1
workspace = 6, monitor:DP-1
workspace = 7, monitor:DP-1
workspace = 8, monitor:HDMI-A-1, default:true  # Right monitor
workspace = 9, monitor:HDMI-A-1
workspace = 10, monitor:HDMI-A-1

# General settings optimized for QuickShell
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Enable features needed by QuickShell
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    enable_swallow = true
}

# Window rules for QuickShell components
windowrulev2 = float, class:^(quickshell)$
windowrulev2 = noborder, class:^(quickshell)$
windowrulev2 = noblur, class:^(quickshell)$
windowrulev2 = noshadow, class:^(quickshell)$
windowrulev2 = pin, class:^(quickshell)$

# Auto-start essential services
exec-once = quickshell &
exec-once = hyprpaper &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
```

## QuickShell: Dual Bars Across 3 Monitors

**QuickShell** provides our custom shell interface using QtQuick/QML. The configuration creates 6 total bars (2 per monitor) with different functions and monitor-specific content.

### Directory Structure Setup

```bash
mkdir -p ~/.config/quickshell/{components,styles,scripts}
```

### Main Shell Configuration

Create `~/.config/quickshell/shell.qml`:

```qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Scope {
    // Monitor-specific configurations
    property var monitorConfigs: ({
        "DP-1": { primary: true, workspaces: [4,5,6,7] },
        "DP-2": { primary: false, workspaces: [1,2,3] },
        "HDMI-A-1": { primary: false, workspaces: [8,9,10] }
    })
    
    // Top bars for all monitors
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: topBar
                property var modelData
                property var config: monitorConfigs[modelData.name] || {}
                
                screen: modelData
                anchors { top: true; left: true; right: true }
                implicitHeight: config.primary ? 36 : 32
                margins { top: 8; left: 8; right: 8 }
                
                color: "#1e1e2e"
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 12
                    
                    // Workspace indicators
                    Row {
                        spacing: 4
                        Repeater {
                            model: config.workspaces || []
                            delegate: Rectangle {
                                property bool isActive: {
                                    var activeWs = Hyprland.focusedMonitor?.activeWorkspace
                                    return activeWs && activeWs.id === modelData
                                }
                                property bool hasWindows: {
                                    return Hyprland.workspaces.some(ws => 
                                        ws.id === modelData && ws.windows > 0)
                                }
                                
                                width: 28
                                height: 24
                                radius: 12
                                color: isActive ? "#cba6f7" : 
                                       hasWindows ? "#585b70" : "#313244"
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 10
                                    color: isActive ? "#1e1e2e" : "#cdd6f4"
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Hyprland.dispatch("workspace", modelData.toString())
                                }
                            }
                        }
                    }
                    
                    // Window title
                    Text {
                        Layout.fillWidth: true
                        text: Hyprland.focusedMonitor?.activeWindow?.title ?? "Desktop"
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    
                    // System tray (primary monitor only)
                    Loader {
                        active: config.primary
                        sourceComponent: SystemTray {}
                    }
                    
                    // Clock
                    Rectangle {
                        width: 80
                        height: 24
                        color: "#313244"
                        radius: 12
                        
                        Text {
                            id: clockText
                            anchors.centerIn: parent
                            font.pixelSize: 11
                            color: "#cdd6f4"
                        }
                        
                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: {
                                clockText.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Bottom bars for system information
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: bottomBar
                property var modelData
                property var config: monitorConfigs[modelData.name] || {}
                
                screen: modelData
                anchors { bottom: true; left: true; right: true }
                implicitHeight: 28
                margins { bottom: 8; left: 8; right: 8 }
                
                color: "#181825"
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    // System resources
                    SystemMetrics {
                        showDetailed: config.primary
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Network status
                    Rectangle {
                        width: 100
                        height: 20
                        color: "#313244"
                        radius: 10
                        
                        Text {
                            anchors.centerIn: parent
                            text: "NET: Active"
                            font.pixelSize: 10
                            color: "#a6e3a1"
                        }
                    }
                }
            }
        }
    }
}
```

### System Metrics Component

Create `~/.config/quickshell/components/SystemMetrics.qml`:

```qml
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
    property bool showDetailed: false
    spacing: 12
    
    // CPU Usage
    Rectangle {
        width: showDetailed ? 80 : 60
        height: 20
        color: "#313244"
        radius: 10
        
        Text {
            id: cpuText
            anchors.centerIn: parent
            font.pixelSize: 9
            color: "#f9e2af"
        }
        
        Process {
            id: cpuProcess
            command: ["sh", "-c", "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4)} END {print int(usage)}'"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: cpuText.text = `CPU: ${text.trim()}%`
            }
        }
        
        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: cpuProcess.running = true
        }
    }
    
    // Memory Usage
    Rectangle {
        width: showDetailed ? 80 : 60
        height: 20
        color: "#313244"
        radius: 10
        
        Text {
            id: memText
            anchors.centerIn: parent
            font.pixelSize: 9
            color: "#fab387"
        }
        
        Process {
            id: memProcess
            command: ["sh", "-c", "free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100.0}'"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: memText.text = `MEM: ${text.trim()}%`
            }
        }
        
        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: memProcess.running = true
        }
    }
}
```

## Notification System Integration

**Both dunst and mako work excellently with Hyprland**, but **mako is recommended** for Wayland-native integration and simpler setup. QuickShell can integrate with either daemon or provide custom notification handling.

### Mako Installation and Configuration

```bash
# Install mako (recommended)
sudo pacman -S mako

# Configure mako
mkdir -p ~/.config/mako
```

Create `~/.config/mako/config`:

```ini
# Multi-monitor notification positioning
anchor=top-right
margin=20
padding=15
border-size=2
border-radius=8
font=Inter 12
max-visible=5

# Styling
background-color=#2e3440
text-color=#d8dee9
border-color=#81a1c1

# Urgency levels
[urgency=critical]
background-color=#bf616a
border-color=#d08770
text-color=#eceff4
default-timeout=0

[urgency=high]
background-color=#ebcb8b
text-color=#2e3440
border-color=#d08770

# Monitor-specific positioning
[output=DP-1]
anchor=top-right
margin=20,40,20,20

[output=DP-2]
anchor=top-left
margin=20,20,20,40

[output=HDMI-A-1]
anchor=top-right
margin=20,20,40,20
```

### Alternative: Dunst Configuration

For users preferring extensive customization, install dunst:

```bash
sudo pacman -S dunst
mkdir -p ~/.config/dunst
```

Create `~/.config/dunst/dunstrc`:

```ini
[global]
    monitor = 0
    follow = keyboard
    width = (0, 400)
    height = 300
    origin = top-right
    offset = 20x50
    
    font = Inter 11
    markup = full
    format = "<b>%s</b>\n%b"
    
    frame_width = 2
    frame_color = "#81a1c1"
    background = "#2e3440"
    foreground = "#d8dee9"
    
    mouse_left_click = close_current
    mouse_middle_click = do_action
    mouse_right_click = close_all

[urgency_critical]
    background = "#bf616a"
    foreground = "#eceff4"
    frame_color = "#d08770"
    timeout = 0
```

### QuickShell Notification Integration

Create `~/.config/quickshell/components/NotificationWidget.qml`:

```qml
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Rectangle {
    id: notificationArea
    width: 300
    height: childrenRect.height
    color: "transparent"
    
    Column {
        id: notificationList
        width: parent.width
        spacing: 8
        
        Repeater {
            model: NotificationServer.notifications
            
            Rectangle {
                width: notificationList.width
                height: 80
                radius: 8
                color: "#313244"
                border.color: getUrgencyColor(modelData.urgency)
                border.width: 2
                
                function getUrgencyColor(urgency) {
                    switch(urgency) {
                        case "critical": return "#f38ba8"
                        case "high": return "#fab387"
                        default: return "#89b4fa"
                    }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    
                    Image {
                        source: modelData.icon
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                    }
                    
                    Column {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text {
                            text: modelData.summary
                            font.bold: true
                            color: "#cdd6f4"
                            elide: Text.ElideRight
                        }
                        
                        Text {
                            text: modelData.body
                            color: "#a6adc8"
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                        }
                    }
                    
                    MouseArea {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        onClicked: modelData.dismiss()
                        
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "#cdd6f4"
                        }
                    }
                }
            }
        }
    }
}
```

## QuickShell App Launcher Implementation

**QuickShell's app launcher** provides a modern, customizable alternative to traditional launchers like rofi or wofi, with native desktop file parsing and launch capabilities.

### App Launcher Component

Create `~/.config/quickshell/components/AppLauncher.qml`:

```qml
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

FloatingWindow {
    id: launcherWindow
    
    property bool launcherVisible: false
    property var applications: []
    property string searchText: ""
    
    width: 600
    height: 500
    visible: launcherVisible
    
    // Center on screen
    x: (screen.width - width) / 2
    y: (screen.height - height) / 2
    
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        radius: 12
        border.color: "#313244"
        border.width: 2
        
        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // Search box
            Rectangle {
                width: parent.width
                height: 50
                color: "#313244"
                radius: 8
                
                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.margins: 15
                    color: "#cdd6f4"
                    font.pixelSize: 16
                    placeholderText: "Search applications..."
                    
                    onTextChanged: {
                        launcherWindow.searchText = text
                        filterApplications()
                    }
                    
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            launcherWindow.launcherVisible = false
                        }
                        if (event.key === Qt.Key_Return && appGrid.currentIndex >= 0) {
                            launchApplication(filteredApps[appGrid.currentIndex].exec)
                            launcherWindow.launcherVisible = false
                        }
                    }
                }
            }
            
            // Application grid
            GridView {
                id: appGrid
                width: parent.width
                height: parent.height - 65
                
                cellWidth: 120
                cellHeight: 120
                
                property var filteredApps: []
                model: filteredApps.length
                
                delegate: Rectangle {
                    width: appGrid.cellWidth - 10
                    height: appGrid.cellHeight - 10
                    color: mouseArea.containsMouse ? "#45475a" : "transparent"
                    radius: 8
                    
                    property var app: appGrid.filteredApps[index] || {}
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Image {
                            width: 48
                            height: 48
                            source: app.icon ? `image://theme/${app.icon}` : ""
                            anchors.horizontalCenter: parent.horizontalCenter
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        Text {
                            text: app.name || ""
                            color: "#cdd6f4"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            width: 100
                            elide: Text.ElideRight
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onClicked: {
                            launchApplication(app.exec)
                            launcherWindow.launcherVisible = false
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        discoverApplications()
    }
    
    function discoverApplications() {
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["find", "/usr/share/applications", "/home/" + Quickshell.env.USER + "/.local/share/applications", "-name", "*.desktop"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: parseDesktopFiles(text)
                }
            }
        `, launcherWindow)
    }
    
    function parseDesktopFiles(output) {
        var files = output.trim().split('\n')
        applications = []
        
        files.forEach(file => {
            if (file.trim()) {
                parseDesktopFile(file)
            }
        })
        
        filterApplications()
    }
    
    function parseDesktopFile(filePath) {
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["cat", "${filePath}"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: addApplication(text)
                }
            }
        `, launcherWindow)
        
        function addApplication(content) {
            var lines = content.split('\n')
            var app = {}
            var inDesktopEntry = false
            
            lines.forEach(line => {
                if (line === '[Desktop Entry]') {
                    inDesktopEntry = true
                    return
                }
                if (line.startsWith('[') && line !== '[Desktop Entry]') {
                    inDesktopEntry = false
                    return
                }
                if (!inDesktopEntry) return
                
                var parts = line.split('=')
                if (parts.length >= 2) {
                    var key = parts[0]
                    var value = parts.slice(1).join('=')
                    
                    switch(key) {
                        case 'Name':
                            app.name = value
                            break
                        case 'Exec':
                            app.exec = value
                            break
                        case 'Icon':
                            app.icon = value
                            break
                        case 'NoDisplay':
                            if (value === 'true') return
                            break
                        case 'Hidden':
                            if (value === 'true') return
                            break
                    }
                }
            })
            
            if (app.name && app.exec) {
                applications.push(app)
            }
        }
    }
    
    function filterApplications() {
        if (!searchText) {
            appGrid.filteredApps = applications
        } else {
            appGrid.filteredApps = applications.filter(app => 
                app.name.toLowerCase().includes(searchText.toLowerCase())
            )
        }
        appGrid.model = appGrid.filteredApps.length
    }
    
    function launchApplication(exec) {
        var cleanExec = exec.replace(/%[uUfF]/g, '').trim()
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ${JSON.stringify(cleanExec.split(' '))}
                running: true
            }
        `, launcherWindow)
    }
}
```

## Awesome Sidebar Implementation

**The sidebar provides system controls, media management, and quick access tools** in a unified interface. It demonstrates QuickShell's capability for creating complex, interactive desktop widgets.

### Complete Sidebar Component

Create `~/.config/quickshell/components/Sidebar.qml`:

```qml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: sidebar
    
    // Position on left side
    anchors {
        left: true
        top: true
        bottom: true
    }
    width: 320
    margins {
        left: 10
        top: 10
        bottom: 10
    }
    
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        opacity: 0.95
        radius: 12
        border.color: "#313244"
        border.width: 2
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 15
            
            Column {
                width: parent.width
                spacing: 15
                
                // Header section
                Rectangle {
                    width: parent.width
                    height: 60
                    color: "#313244"
                    radius: 8
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 15
                        
                        Text {
                            text: "QuickShell"
                            color: "#cdd6f4"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        
                        Text {
                            text: Qt.formatDateTime(new Date(), "MMM dd")
                            color: "#a6adc8"
                            font.pixelSize: 12
                        }
                    }
                }
                
                // Workspace management
                Rectangle {
                    width: parent.width
                    height: 120
                    color: "#313244"
                    radius: 8
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        Text {
                            text: "Workspaces"
                            color: "#cdd6f4"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Flow {
                            width: parent.width
                            spacing: 5
                            
                            Repeater {
                                model: 10
                                
                                Rectangle {
                                    width: 35
                                    height: 30
                                    radius: 6
                                    
                                    property bool isActive: {
                                        var activeWs = Hyprland.focusedMonitor?.activeWorkspace
                                        return activeWs && activeWs.id === (index + 1)
                                    }
                                    
                                    property bool hasWindows: {
                                        return Hyprland.workspaces.some(ws => 
                                            ws.id === (index + 1) && ws.windows > 0)
                                    }
                                    
                                    color: isActive ? "#cba6f7" : 
                                           hasWindows ? "#45475a" : "#1e1e2e"
                                    border.color: "#6c7086"
                                    border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: index + 1
                                        color: isActive ? "#1e1e2e" : "#cdd6f4"
                                        font.pixelSize: 11
                                        font.bold: isActive
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            Hyprland.dispatch("workspace", (index + 1).toString())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // System controls
                SystemControlsWidget {
                    width: parent.width
                }
                
                // Media controls
                MediaControlWidget {
                    width: parent.width
                }
                
                // Quick launch
                Rectangle {
                    width: parent.width
                    height: 150
                    color: "#313244"
                    radius: 8
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        Text {
                            text: "Quick Launch"
                            color: "#cdd6f4"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Flow {
                            width: parent.width
                            spacing: 8
                            
                            property var quickApps: [
                                {name: "Terminal", exec: "kitty", icon: "🖥️"},
                                {name: "Browser", exec: "firefox", icon: "🌐"},
                                {name: "Files", exec: "thunar", icon: "📁"},
                                {name: "Settings", exec: "pavucontrol", icon: "⚙️"}
                            ]
                            
                            Repeater {
                                model: parent.quickApps
                                
                                Rectangle {
                                    width: 60
                                    height: 50
                                    radius: 8
                                    color: mouseArea.containsMouse ? "#45475a" : "#1e1e2e"
                                    border.color: "#6c7086"
                                    border.width: 1
                                    
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        
                                        Text {
                                            text: modelData.icon
                                            font.pixelSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        
                                        Text {
                                            text: modelData.name
                                            color: "#cdd6f4"
                                            font.pixelSize: 8
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        onClicked: {
                                            var process = Qt.createQmlObject(`
                                                import Quickshell.Io
                                                Process {
                                                    command: ["${modelData.exec}"]
                                                    running: true
                                                }
                                            `, sidebar)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // System information
                Rectangle {
                    width: parent.width
                    height: 100
                    color: "#313244"
                    radius: 8
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 8
                        
                        Text {
                            text: "System Info"
                            color: "#cdd6f4"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Row {
                            spacing: 20
                            
                            Text {
                                id: uptimeText
                                color: "#a6adc8"
                                font.pixelSize: 10
                            }
                            
                            Text {
                                id: loadText
                                color: "#a6adc8"
                                font.pixelSize: 10
                            }
                        }
                        
                        Timer {
                            interval: 10000
                            running: true
                            repeat: true
                            onTriggered: updateSystemInfo()
                        }
                        
                        Component.onCompleted: updateSystemInfo()
                        
                        function updateSystemInfo() {
                            var uptimeProcess = Qt.createQmlObject(`
                                import Quickshell.Io
                                Process {
                                    command: ["uptime", "-p"]
                                    running: true
                                    stdout: StdioCollector {
                                        onStreamFinished: uptimeText.text = text.trim()
                                    }
                                }
                            `, parent)
                            
                            var loadProcess = Qt.createQmlObject(`
                                import Quickshell.Io
                                Process {
                                    command: ["cat", "/proc/loadavg"]
                                    running: true
                                    stdout: StdioCollector {
                                        onStreamFinished: loadText.text = "Load: " + text.split(' ')[0]
                                    }
                                }
                            `, parent)
                        }
                    }
                }
            }
        }
    }
}
```

### System Controls Component

Create `~/.config/quickshell/components/SystemControlsWidget.qml`:

```qml
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

Rectangle {
    height: 180
    color: "#313244"
    radius: 8
    
    property real volume: 50
    property real brightness: 70
    
    Column {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12
        
        Text {
            text: "System Controls"
            color: "#cdd6f4"
            font.pixelSize: 14
            font.bold: true
        }
        
        // Volume control
        Row {
            width: parent.width
            spacing: 10
            
            Text {
                text: "🔊"
                font.pixelSize: 14
                width: 25
            }
            
            Slider {
                id: volumeSlider
                width: parent.width - 35
                value: volume
                from: 0
                to: 100
                
                onValueChanged: {
                    volume = value
                    setVolume(value)
                }
                
                background: Rectangle {
                    width: volumeSlider.width
                    height: 6
                    color: "#45475a"
                    radius: 3
                    
                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        color: "#cba6f7"
                        radius: 3
                    }
                }
                
                handle: Rectangle {
                    x: volumeSlider.visualPosition * (volumeSlider.width - width)
                    y: (volumeSlider.height - height) / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: "#cdd6f4"
                }
            }
        }
        
        // Brightness control
        Row {
            width: parent.width
            spacing: 10
            
            Text {
                text: "☀️"
                font.pixelSize: 14
                width: 25
            }
            
            Slider {
                id: brightnessSlider
                width: parent.width - 35
                value: brightness
                from: 0
                to: 100
                
                onValueChanged: {
                    brightness = value
                    setBrightness(value)
                }
                
                background: Rectangle {
                    width: brightnessSlider.width
                    height: 6
                    color: "#45475a"
                    radius: 3
                    
                    Rectangle {
                        width: brightnessSlider.visualPosition * parent.width
                        height: parent.height
                        color: "#f9e2af"
                        radius: 3
                    }
                }
                
                handle: Rectangle {
                    x: brightnessSlider.visualPosition * (brightnessSlider.width - width)
                    y: (brightnessSlider.height - height) / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: "#cdd6f4"
                }
            }
        }
        
        // Power options
        Row {
            width: parent.width
            spacing: 10
            
            Rectangle {
                width: 45
                height: 30
                radius: 6
                color: mouseArea1.containsMouse ? "#585b70" : "#45475a"
                
                Text {
                    anchors.centerIn: parent
                    text: "🔒"
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: mouseArea1
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: lockScreen()
                }
            }
            
            Rectangle {
                width: 45
                height: 30
                radius: 6
                color: mouseArea2.containsMouse ? "#585b70" : "#45475a"
                
                Text {
                    anchors.centerIn: parent
                    text: "💤"
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: mouseArea2
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: suspend()
                }
            }
            
            Rectangle {
                width: 45
                height: 30
                radius: 6
                color: mouseArea3.containsMouse ? "#f38ba8" : "#45475a"
                
                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: mouseArea3
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: shutdown()
                }
            }
        }
    }
    
    function setVolume(level) {
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "${level}%"]
                running: true
            }
        `, parent)
    }
    
    function setBrightness(level) {
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["brightnessctl", "set", "${level}%"]
                running: true
            }
        `, parent)
    }
    
    function lockScreen() {
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["hyprlock"]
                running: true
            }
        `, parent)
    }
    
    function suspend() {
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["systemctl", "suspend"]
                running: true
            }
        `, parent)
    }
    
    function shutdown() {
        var process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["systemctl", "poweroff"]
                running: true
            }
        `, parent)
    }
}
```

## Comprehensive Matugen Dynamic Theming

**Matugen provides Material You dynamic theming** that extracts colors from wallpapers and applies them system-wide. This creates a cohesive visual experience across Hyprland, QuickShell, and notifications.

### Matugen Installation and Setup

```bash
# Install Matugen and dependencies
yay -S matugen-bin swww
sudo pacman -S imagemagick

# Create configuration directories
mkdir -p ~/.config/matugen/{templates,scripts}
```

### Core Matugen Configuration

Create `~/.config/matugen/config.toml`:

```toml
[config]
set_wallpaper = true
wallpaper_tool = 'Swww'
swww_options = ['--transition-type', 'center', '--transition-fps', '30']
scheme_type = 'scheme-content'
contrast = 0.0

# Hyprland color integration
[templates.hyprland]
input_path = '~/.config/matugen/templates/hyprland-colors.conf'
output_path = '~/.config/hypr/colors.conf'
post_hook = 'hyprctl reload'

# QuickShell color integration
[templates.quickshell_colors]
input_path = '~/.config/matugen/templates/quickshell-colors.qml'
output_path = '~/.config/quickshell/Colors.qml'
post_hook = 'pkill -SIGUSR1 quickshell || true'

# Notification daemon integration
[templates.mako]
input_path = '~/.config/matugen/templates/mako-config'
output_path = '~/.config/mako/config'
post_hook = 'makoctl reload'
```

### Hyprland Colors Template

Create `~/.config/matugen/templates/hyprland-colors.conf`:

```conf
# Matugen Generated Colors for Hyprland
$primary = rgb({{colors.primary.default.hex_stripped}})
$on_primary = rgb({{colors.on_primary.default.hex_stripped}})
$primary_container = rgb({{colors.primary_container.default.hex_stripped}})
$secondary = rgb({{colors.secondary.default.hex_stripped}})
$surface = rgb({{colors.surface.default.hex_stripped}})
$on_surface = rgb({{colors.on_surface.default.hex_stripped}})
$surface_container = rgb({{colors.surface_container.default.hex_stripped}})
$outline = rgb({{colors.outline.default.hex_stripped}})
$error = rgb({{colors.error.default.hex_stripped}})
$shadow = rgb({{colors.shadow.default.hex_stripped}})

# Wallpaper path
$wallpaper = {{image}}
```

### QuickShell Colors Template

Create `~/.config/matugen/templates/quickshell-colors.qml`:

```qml
pragma Singleton
import QtQuick

QtObject {
    // Material You Color Palette
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color onPrimary: "{{colors.on_primary.default.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color onPrimaryContainer: "{{colors.on_primary_container.default.hex}}"
    
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color onSecondary: "{{colors.on_secondary.default.hex}}"
    readonly property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property color onSecondaryContainer: "{{colors.on_secondary_container.default.hex}}"
    
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color onSurface: "{{colors.on_surface.default.hex}}"
    readonly property color surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property color surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color outlineVariant: "{{colors.outline_variant.default.hex}}"
    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color errorContainer: "{{colors.error_container.default.hex}}"
    readonly property color onErrorContainer: "{{colors.on_error_container.default.hex}}"
    
    // Wallpaper path
    readonly property string wallpaperPath: "{{image}}"
}
```

### Mako Notification Template

Create `~/.config/matugen/templates/mako-config`:

```ini
font = Inter 12
width = 400
height = 150
margin = 20
padding = 15
border-size = 2
border-radius = 8
max-visible = 5
layer = overlay
anchor = top-right

# Dynamic colors from Matugen
background-color = {{colors.surface_container.default.hex}}
text-color = {{colors.on_surface.default.hex}}
border-color = {{colors.primary.default.hex}}
progress-color = {{colors.primary.default.hex}}

[urgency=critical]
background-color = {{colors.error_container.default.hex}}
text-color = {{colors.on_error_container.default.hex}}
border-color = {{colors.error.default.hex}}

[urgency=high]
background-color = {{colors.primary_container.default.hex}}
text-color = {{colors.on_primary_container.default.hex}}
border-color = {{colors.primary.default.hex}}
```

### Updated Hyprland Configuration

Modify your `~/.config/hypr/hyprland.conf` to use dynamic colors:

```bash
# Source generated colors
source = ~/.config/hypr/colors.conf

# Use dynamic colors in configuration
general {
    col.active_border = $primary $secondary 45deg
    col.inactive_border = $outline
    gaps_in = 5
    gaps_out = 20
    border_size = 2
}

decoration {
    rounding = 8
    blur {
        enabled = true
        size = 8
        passes = 3
    }
    drop_shadow = true
    shadow_range = 15
    col.shadow = $shadow
}

# Set dynamic wallpaper
exec = swww img $wallpaper
```

### Theme Integration in QuickShell

Create `~/.config/quickshell/qmldir`:

```
singleton Colors Colors.qml
```

Update your QuickShell components to use dynamic colors:

```qml
import QtQuick
import "Colors.qml" as Colors

Rectangle {
    color: Colors.surfaceContainer
    border.color: Colors.outline
    
    Text {
        color: Colors.onSurface
        text: "Themed text"
    }
}
```

### Automation Scripts

Create `~/.config/matugen/scripts/theme-change.sh`:

```bash
#!/bin/bash

WALLPAPER_PATH="$1"

if [[ -z "$WALLPAPER_PATH" || ! -f "$WALLPAPER_PATH" ]]; then
    echo "Usage: $0 <wallpaper_path>"
    exit 1
fi

# Generate theme from wallpaper
echo "Generating theme from: $WALLPAPER_PATH"
matugen image "$WALLPAPER_PATH"

# Restart components
pkill -SIGUSR1 quickshell 2>/dev/null || true
hyprctl reload
makoctl reload

# Show notification
notify-send -i "$WALLPAPER_PATH" "Theme Updated" "Dynamic theme applied successfully"
```

Make it executable and add Hyprland keybinding:

```bash
chmod +x ~/.config/matugen/scripts/theme-change.sh

# Add to hyprland.conf
bind = SUPER_SHIFT, T, exec, ~/.config/matugen/scripts/theme-change.sh $(find ~/Pictures/Wallpapers -name "*.jpg" -o -name "*.png" | rofi -dmenu -p "Select Wallpaper")
```

## Final System Integration

### Complete Startup Configuration

Update your `~/.config/hypr/hyprland.conf` with the complete startup sequence:

```bash
# Essential services
exec-once = swww-daemon
exec-once = mako
exec-once = quickshell
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Initial theme setup
exec-once = matugen image ~/Pictures/Wallpapers/default.jpg

# Key bindings for QuickShell features
bind = SUPER, SPACE, exec, pkill -USR1 quickshell  # Toggle launcher
bind = SUPER, TAB, togglespecialworkspace, sidebar
bind = SUPER_SHIFT, N, exec, makoctl dismiss -a
bind = SUPER, N, exec, makoctl restore
```

### Performance Optimization

For smooth operation across all components:

```bash
# Add to hyprland.conf
misc {
    vfr = true
    vrr = 1
}

# Optimize QuickShell
env = QT_QUICK_CONTROLS_STYLE,Basic
env = QT_QPA_PLATFORM,wayland
```

## Conclusion

This complete setup provides a modern, cohesive desktop environment featuring **Hyprland's powerful window management**, **QuickShell's flexible interface system**, **integrated notifications**, **custom app launcher**, **comprehensive sidebar functionality**, and **dynamic Material You theming** that adapts to your wallpaper choices.

**Key achievements of this configuration:**

- **Six bars total** (dual bars on each of 3 monitors) with monitor-specific content
- **Native Wayland notification system** with mako integration
- **Custom app launcher** with desktop file parsing and fuzzy search
- **Interactive sidebar** with system controls, media management, and quick launch
- **Complete dynamic theming** that updates all components automatically
- **Seamless multi-monitor workflow** optimized for productivity

**The system automatically handles:**
- Color scheme generation from wallpapers
- Theme application across all components
- Multi-monitor workspace management
- System integration and automation
- Performance optimization for smooth operation

This setup demonstrates QuickShell's potential as a powerful waybar replacement while maintaining the performance and flexibility that makes Hyprland an excellent choice for advanced users seeking a customizable, modern desktop environment.