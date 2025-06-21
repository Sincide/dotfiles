import QtQuick
import QtQuick.Controls
import Quickshell

Rectangle {
    id: systemTray
    
    // Properties
    property int volume: 75
    property int brightness: 60
    property bool isWifiConnected: true
    property string networkName: "QuickShell-5G"
    property int batteryLevel: 85
    property bool isCharging: false
    
    width: 300
    height: 200
    radius: 20
    
    // Glass effect
    color: "#70181825"
    opacity: 0.95
    
    // Gradient overlay
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: parent.radius
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#50cdd6f4" }
            GradientStop { position: 1.0; color: "#30181825" }
        }
    }
    
    // Border glow
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#80cdd6f4"
        border.width: 1
        radius: parent.radius
    }
    
    // Content
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        // Header
        Text {
            text: "⚙️ System Controls"
            color: "#cdd6f4"
            font.pixelSize: 16
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // Volume control
        Row {
            width: parent.width
            spacing: 15
            
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: "#4089b4fa"
                
                Text {
                    anchors.centerIn: parent
                    text: volume > 0 ? "🔊" : "🔇"
                    font.pixelSize: 20
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: volume = volume > 0 ? 0 : 75
                }
            }
            
            Column {
                width: parent.width - 55
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                
                Text {
                    text: "Volume: " + volume + "%"
                    color: "#cdd6f4"
                    font.pixelSize: 12
                }
                
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#40cdd6f4"
                    
                    Rectangle {
                        width: parent.width * (volume / 100)
                        height: parent.height
                        radius: parent.radius
                        color: "#89b4fa"
                        
                        Behavior on width {
                            NumberAnimation { duration: 200 }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            volume = Math.round((mouse.x / width) * 100)
                        }
                    }
                }
            }
        }
        
        // Brightness control
        Row {
            width: parent.width
            spacing: 15
            
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: "#40f9e2af"
                
                Text {
                    anchors.centerIn: parent
                    text: "☀️"
                    font.pixelSize: 20
                }
            }
            
            Column {
                width: parent.width - 55
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                
                Text {
                    text: "Brightness: " + brightness + "%"
                    color: "#cdd6f4"
                    font.pixelSize: 12
                }
                
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#40cdd6f4"
                    
                    Rectangle {
                        width: parent.width * (brightness / 100)
                        height: parent.height
                        radius: parent.radius
                        color: "#f9e2af"
                        
                        Behavior on width {
                            NumberAnimation { duration: 200 }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            brightness = Math.round((mouse.x / width) * 100)
                        }
                    }
                }
            }
        }
        
        // Network & Battery status
        Row {
            width: parent.width
            spacing: 20
            
            // Network status
            Row {
                spacing: 8
                
                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: isWifiConnected ? "#40a6e3a1" : "#40f38ba8"
                    
                    Text {
                        anchors.centerIn: parent
                        text: isWifiConnected ? "📶" : "📶"
                        font.pixelSize: 16
                    }
                }
                
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    
                    Text {
                        text: isWifiConnected ? "Connected" : "Disconnected"
                        color: "#cdd6f4"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    
                    Text {
                        text: isWifiConnected ? networkName : "No Network"
                        color: "#a6adc8"
                        font.pixelSize: 9
                    }
                }
            }
            
            // Battery status
            Row {
                spacing: 8
                
                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: batteryLevel > 20 ? "#40a6e3a1" : "#40f38ba8"
                    
                    Text {
                        anchors.centerIn: parent  
                        text: isCharging ? "🔌" : (batteryLevel > 50 ? "🔋" : "🪫")
                        font.pixelSize: 16
                    }
                }
                
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    
                    Text {
                        text: batteryLevel + "%"
                        color: "#cdd6f4"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    
                    Text {
                        text: isCharging ? "Charging" : "Battery"
                        color: "#a6adc8"
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
    
    // Update timer for demo
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            // Simulate battery changes
            if (!isCharging) {
                batteryLevel = Math.max(20, batteryLevel - Math.floor(Math.random() * 3))
            } else {
                batteryLevel = Math.min(100, batteryLevel + Math.floor(Math.random() * 5))
            }
            
            // Randomly toggle charging
            if (Math.random() < 0.1) {
                isCharging = !isCharging
            }
        }
    }
    
    // Mouse interactions
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            parent.scale = 1.02
        }
        
        onExited: {
            parent.scale = 1.0
        }
    }
    
    // Smooth animations
    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }
} 