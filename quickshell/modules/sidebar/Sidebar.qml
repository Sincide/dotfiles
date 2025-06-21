import QtQuick
import QtQuick.Controls
import Quickshell

PanelWindow {
    id: sidebar
    
    // Properties
    property bool isVisible: false
    property int sidebarWidth: 350
    
    // Signals for communicating with main shell
    signal triggerAppLauncher()
    signal triggerWeather()
    signal triggerSystemTray()
    signal triggerTerminal()
    
    // Panel positioning
    anchors {
        right: true
        top: true
        bottom: true
    }
    
    implicitWidth: isVisible ? sidebarWidth : 0
    
    // Smooth width animation
    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }
    
    // Main content rectangle
    Rectangle {
        anchors.fill: parent
        
        // Glass effect styling
        color: "#80181825"
        
        // Gradient overlay
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#50cdd6f4" }
                GradientStop { position: 1.0; color: "#30181825" }
            }
        }
        
        // Border
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#60cdd6f4"
            border.width: 2
        }
        
        // Content
        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20
            
            // Header
            Row {
                width: parent.width
                spacing: 10
                
                Text {
                    text: "⚙️ Control Panel"
                    color: "#cdd6f4"
                    font.pixelSize: 20
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Item {
                    width: parent.width - 200
                    height: 1
                }
                
                // Close button
                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: "#f38ba8"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: sidebar.hide()
                    }
                }
            }
            
            // Quick Actions Section
            Rectangle {
                width: parent.width
                height: 160
                radius: 12
                color: "#40181825"
                border.color: "#60cdd6f4"
                border.width: 1
                
                Column {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    
                    Text {
                        text: "🚀 Quick Actions"
                        color: "#cdd6f4"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    
                    Grid {
                        columns: 2
                        spacing: 10
                        
                        // App Launcher Button
                        Rectangle {
                            width: 130
                            height: 40
                            radius: 8
                            color: "#a6e3a1"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "🚀 Apps"
                                color: "#1e1e2e"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.scale = 1.05
                                onExited: parent.scale = 1.0
                                onClicked: {
                                    console.log("Sidebar: Opening app launcher")
                                    sidebar.hide()
                                    sidebar.triggerAppLauncher()
                                }
                            }
                            
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                        
                        // Weather Toggle
                        Rectangle {
                            width: 130
                            height: 40
                            radius: 8
                            color: "#89b4fa"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "🌤️ Weather"
                                color: "white"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.scale = 1.05
                                onExited: parent.scale = 1.0
                                onClicked: {
                                    console.log("Sidebar: Toggling weather")
                                    sidebar.triggerWeather()
                                }
                            }
                            
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                        
                        // System Tray
                        Rectangle {
                            width: 130
                            height: 40
                            radius: 8
                            color: "#f9e2af"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⚙️ System"
                                color: "#1e1e2e"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.scale = 1.05
                                onExited: parent.scale = 1.0
                                onClicked: {
                                    console.log("Sidebar: Toggling system tray")
                                    sidebar.triggerSystemTray()
                                }
                            }
                            
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                        
                        // Terminal
                        Rectangle {
                            width: 130
                            height: 40
                            radius: 8
                            color: "#cba6f7"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⌨️ Terminal"
                                color: "white"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.scale = 1.05
                                onExited: parent.scale = 1.0
                                onClicked: {
                                    console.log("Sidebar: Opening terminal")
                                    sidebar.triggerTerminal()
                                }
                            }
                            
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                    }
                }
            }
            
            // System Status Section  
            Rectangle {
                width: parent.width
                height: 120
                radius: 12
                color: "#40181825"
                border.color: "#60cdd6f4"
                border.width: 1
                
                Column {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    Text {
                        text: "📊 System Status"
                        color: "#cdd6f4"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    
                    Row {
                        width: parent.width
                        spacing: 20
                        
                        Column {
                            spacing: 5
                            
                            Text {
                                text: "CPU"
                                color: "#89b4fa"
                                font.pixelSize: 12
                            }
                            
                            Rectangle {
                                width: 80
                                height: 8
                                radius: 4
                                color: "#45475a"
                                
                                Rectangle {
                                    width: parent.width * 0.45
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#a6e3a1"
                                }
                            }
                            
                            Text {
                                text: "45%"
                                color: "#cdd6f4"
                                font.pixelSize: 10
                            }
                        }
                        
                        Column {
                            spacing: 5
                            
                            Text {
                                text: "RAM"
                                color: "#89b4fa"
                                font.pixelSize: 12
                            }
                            
                            Rectangle {
                                width: 80
                                height: 8
                                radius: 4
                                color: "#45475a"
                                
                                Rectangle {
                                    width: parent.width * 0.62
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#f9e2af"
                                }
                            }
                            
                            Text {
                                text: "62%"
                                color: "#cdd6f4"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Functions
    function show() {
        isVisible = true
    }
    
    function hide() {
        isVisible = false
    }
    
    function toggle() {
        isVisible = !isVisible
    }
} 