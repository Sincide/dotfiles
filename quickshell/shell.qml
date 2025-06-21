import QtQuick
import QtQuick.Controls
import Quickshell
import "./modules/notifications"
import "./modules/bar"
import "./modules/weather"
import "./modules/sidebar"

ShellRoot {
    // Our shell - tutorial approach with simple system info
    
    // System monitoring properties (back to simulated for now)
    property real cpuUsage: 25.0
    property real memoryUsage: 45.0
    property string uptime: "2h 15m"
    
    // Workspace properties
    property int currentWorkspace: 1
    property int totalWorkspaces: 5
    
    // Dock state properties
    property var activeApps: [false, false, false, false, false]  // Track which apps are "running"
    
    // Overlay control properties
    property bool weatherVisible: false
    property bool systemTrayVisible: false
    property bool sidebarVisible: false
    property bool appLauncherVisible: false
    
    // Timer to simulate changing system stats
    Timer {
        interval: 3000  // Update every 3 seconds
        running: true
        repeat: true
        onTriggered: {
            // Simulate realistic fluctuations
            cpuUsage = Math.random() * 60 + 15  // 15-75%
            memoryUsage = Math.random() * 30 + 35  // 35-65%
        }
    }
    
    // Timer to occasionally simulate workspace switching (demo purposes)
    Timer {
        interval: 8000  // Every 8 seconds
        running: true
        repeat: true
        onTriggered: {
            // Occasionally switch workspaces to show the animation
            if (Math.random() < 0.3) {  // 30% chance
                currentWorkspace = (currentWorkspace % totalWorkspaces) + 1
            }
        }
    }
    
    // Function to toggle app state
    function launchApp(appIcon) {
        console.log("Toggling app:", appIcon)
        
        // Find the index of the clicked app
        const appIcons = ["🌐", "📁", "⌨️", "🎵", "⚙️"]
        const appIndex = appIcons.indexOf(appIcon)
        
        if (appIndex !== -1) {
            // Toggle the active state
            let newActiveApps = [...activeApps]  // Create a copy
            newActiveApps[appIndex] = !newActiveApps[appIndex]
            activeApps = newActiveApps
            
            console.log("App", appIcon, newActiveApps[appIndex] ? "launched" : "closed")
        }
    }
    
    // Function to show app launcher
    function showAppLauncher() {
        console.log("Opening app launcher")
        appLauncherVisible = true
    }
    
    // Function to launch terminal
    function launchTerminal() {
        console.log("Launching terminal: kitty")
        // In a real implementation, you'd use Process or similar
    }
    
    // Top bar
    PanelWindow {
        id: topBar
        
        anchors {
            top: true
            left: true
            right: true
        }
        
        implicitHeight: 40
        
        Rectangle {
            anchors.fill: parent
            
            // Premium glass effect
            color: "#40000000"  // Semi-transparent black
            opacity: 0.95
            
            // Glass blur background
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#403D3D3D" }
                    GradientStop { position: 1.0; color: "#402D2D2D" }
                }
                radius: 8
            }
            
            // Left side - system info
            Row {
                anchors {
                    left: parent.left
                    leftMargin: 15
                    verticalCenter: parent.verticalCenter
                }
                spacing: 20
                
                Text {
                    text: "💻 CPU: " + Math.round(cpuUsage) + "%"
                    color: cpuUsage > 70 ? "#f38ba8" : cpuUsage > 50 ? "#f9e2af" : "#89b4fa"
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Text {
                    text: "🧠 RAM: " + Math.round(memoryUsage) + "%"
                    color: memoryUsage > 70 ? "#f38ba8" : memoryUsage > 50 ? "#f9e2af" : "#a6e3a1"
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Text {
                    text: "⏱️ " + uptime
                    color: "#cba6f7"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
            
            // Center - workspace indicators
            Row {
                anchors.centerIn: parent
                spacing: 8
                
                Repeater {
                    model: totalWorkspaces
                    
                    Rectangle {
                        width: 30
                        height: 20
                        radius: 4
                        color: (index + 1) === currentWorkspace ? "#89b4fa" : "#45475a"
                        border.width: 1
                        border.color: (index + 1) === currentWorkspace ? "#b4befe" : "#6c7086"
                        
                        // Smooth transitions
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            color: (index + 1) === currentWorkspace ? "#1e1e2e" : "#cdd6f4"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            
                            onEntered: {
                                if ((index + 1) !== currentWorkspace) {
                                    parent.color = "#585b70"
                                }
                            }
                            
                            onExited: {
                                if ((index + 1) !== currentWorkspace) {
                                    parent.color = "#45475a"
                                }
                            }
                            
                            onClicked: {
                                currentWorkspace = index + 1
                                console.log("Switched to workspace:", currentWorkspace)
                            }
                        }
                    }
                }
            }
            
            // Right side - clickable controls and time
            Row {
                anchors {
                    right: parent.right
                    rightMargin: 15
                    verticalCenter: parent.verticalCenter
                }
                spacing: 15
                
                // Weather toggle button
                Rectangle {
                    width: 60
                    height: 25
                    radius: 12
                    color: weatherVisible ? "#89b4fa" : "#45475a"
                    border.width: 1
                    border.color: weatherVisible ? "#b4befe" : "#6c7086"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🌤️"
                        font.pixelSize: 12
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.scale = 1.05
                        onExited: parent.scale = 1.0
                        onClicked: weatherVisible = !weatherVisible
                    }
                    
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                // System tray toggle button
                Rectangle {
                    width: 60
                    height: 25
                    radius: 12
                    color: systemTrayVisible ? "#89b4fa" : "#45475a"
                    border.width: 1
                    border.color: systemTrayVisible ? "#b4befe" : "#6c7086"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "⚙️"
                        font.pixelSize: 12
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.scale = 1.05
                        onExited: parent.scale = 1.0
                        onClicked: systemTrayVisible = !systemTrayVisible
                    }
                    
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                // App launcher button
                Rectangle {
                    width: 60
                    height: 25
                    radius: 12
                    color: "#a6e3a1"
                    border.width: 1
                    border.color: "#b4befe"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🚀"
                        font.pixelSize: 12
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.scale = 1.05
                        onExited: parent.scale = 1.0
                        onClicked: showAppLauncher()
                    }
                    
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
                
                // Sidebar toggle button
                Rectangle {
                    width: 60
                    height: 25
                    radius: 12
                    color: sidebarVisible ? "#cba6f7" : "#45475a"
                    border.width: 1
                    border.color: sidebarVisible ? "#b4befe" : "#6c7086"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "📋"
                        font.pixelSize: 12
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.scale = 1.05
                        onExited: parent.scale = 1.0
                        onClicked: sidebar.toggle()
                    }
                    
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                // Clock
                Text {
                    id: clockText
                    text: Qt.formatDateTime(new Date(), "hh:mm:ss")
                    color: "white"
                    font.pixelSize: 14
                    
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            clockText.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: notifications.showNotification(
                            "Time Check", 
                            "Current time: " + clockText.text, 
                            "⏰"
                        )
                    }
                }
            }
        }
    }
    
    // Bottom dock - inline for now
    PanelWindow {
        id: dock
        
        anchors {
            bottom: true
            left: true
            right: true
        }
        
        implicitHeight: 60
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            
            // Premium glass dock effect
            color: "#60181825"
            opacity: 0.95
            radius: 20
            
            // Subtle gradient overlay
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: parent.radius
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#30cdd6f4" }
                    GradientStop { position: 1.0; color: "#20181825" }
                }
            }
            
            // Elegant border glow
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "#60cdd6f4"
                border.width: 1
                radius: parent.radius
            }
            
            Row {
                anchors.centerIn: parent
                spacing: 15
                
                Repeater {
                    model: ["🌐", "📁", "⌨️", "🎵", "⚙️"]
                    
                    Rectangle {
                        width: 45
                        height: 45
                        radius: 8
                        color: activeApps[index] ? "#585b70" : "#3D3D3D"
                        border.width: activeApps[index] ? 2 : 0
                        border.color: "#89b4fa"
                        
                        // Smooth transitions for active state
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        Behavior on border.width {
                            NumberAnimation { duration: 200 }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.scale = 1.1
                            onExited: parent.scale = 1.0
                            onClicked: {
                                launchApp(modelData)
                            }
                        }
                        
                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 24
                        }
                    }
                }
            }
        }
    }
    
    // === OVERLAY SYSTEM ===
    
    // Notification system
    NotificationSystem {
        id: notifications
        anchors.fill: parent
    }
    
    // App launcher overlay - using Loader for proper component loading
    Loader {
        id: appLauncherLoader
        anchors.fill: parent
        active: appLauncherVisible
        
        sourceComponent: Component {
            AppLauncher {
                id: appLauncher
                isVisible: appLauncherVisible
                
                // Close when visibility changes
                onIsVisibleChanged: {
                    if (!isVisible) {
                        appLauncherVisible = false
                    }
                }
            }
        }
    }
    
    // Weather widget overlay (simplified following tutorial pattern)
    WeatherWidget {
        id: weatherWidget
        x: 20
        y: 50
        opacity: weatherVisible ? 1 : 0
        visible: opacity > 0
        
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }
    
    // System tray overlay - using Loader for proper component loading
    Loader {
        id: systemTrayLoader
        active: systemTrayVisible
        
        sourceComponent: Component {
            SystemTray {
                id: systemTray
                x: 800  // Fixed position, tutorial style
                y: 50
                opacity: systemTrayVisible ? 1 : 0
                visible: opacity > 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }
        }
    }
    
    // Sidebar panel
    Sidebar {
        id: sidebar
        isVisible: sidebarVisible
        
        // Connect sidebar visibility to shell property
        onIsVisibleChanged: sidebarVisible = isVisible
        
        // Connect sidebar actions to shell functions
        onTriggerAppLauncher: showAppLauncher()
        onTriggerWeather: weatherVisible = !weatherVisible
        onTriggerSystemTray: systemTrayVisible = !systemTrayVisible
        onTriggerTerminal: launchTerminal()
    }
    
    // === INTERACTION SYSTEM ===
    // TODO: Research QuickShell's proper keyboard/IPC integration methods
    
    // === ENHANCED INTERACTIONS ===
    // Note: Mouse areas removed to avoid conflicts with PanelWindows
    // Will integrate these interactions directly into the panel components
    
    // Quick actions menu
    Menu {
        id: quickActionsMenu
        
        MenuItem {
            text: "🚀 App Launcher"
            onTriggered: showAppLauncher()
        }
        
        MenuSeparator {}
        
        MenuItem {
            text: "🌤️ Weather"
            checkable: true
            checked: weatherVisible
            onTriggered: weatherVisible = !weatherVisible
        }
        
        MenuItem {
            text: "⚙️ System Tray"
            checkable: true
            checked: systemTrayVisible
            onTriggered: systemTrayVisible = !systemTrayVisible
        }
        
        MenuSeparator {}
        
        MenuItem {
            text: "🔔 Test Notification"
            onTriggered: notifications.showNotification(
                "Menu Action", 
                "Notification triggered from right-click menu!", 
                "🖱️"
            )
        }
    }
    
    // === FUTURE: EXTERNAL CONTROL SYSTEM ===
    // TODO: Implement proper IPC when QuickShell APIs are determined
} 