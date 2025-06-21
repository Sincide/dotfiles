import QtQuick
import Quickshell

// Simple dock component - our first module!
PanelWindow {
    id: dock
    
    // Position at bottom of screen
    anchors {
        bottom: true
        left: true
        right: true
    }
    
    implicitHeight: 60
    
    // Dock background
    Rectangle {
        anchors.fill: parent
        
        // Nice gradient similar to top bar
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2D2D2D" }
            GradientStop { position: 1.0; color: "#1D1D1D" }
        }
        
        // Rounded top corners
        radius: 10
        
        // Dock content - centered row of "apps"
        Row {
            anchors.centerIn: parent
            spacing: 15
            
            // Simulated app icons (we'll make these functional later)
            Repeater {
                model: ["🌐", "📁", "⌨️", "🎵", "⚙️"]
                
                Rectangle {
                    width: 45
                    height: 45
                    radius: 8
                    color: "#3D3D3D"
                    
                    // Hover effect
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onEntered: parent.scale = 1.1
                        onExited: parent.scale = 1.0
                        onClicked: console.log("Clicked app:", modelData)
                    }
                    
                    // Smooth scaling animation
                    Behavior on scale {
                        NumberAnimation { duration: 100 }
                    }
                    
                    // App "icon"
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