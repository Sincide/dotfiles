import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Scope {
    id: shell
    
    // Simple configuration - back to basics
    property var config: ({
        "bars": {"height": 36},
        "material3": {
            "spacing": {"space8": 8, "space12": 12},
            "typography": {"labelLarge": 14}
        }
    })
    
    // Screen configuration - focusing on primary ultrawide for now
    property var primaryScreen: Quickshell.screens.find(s => s.width === 5120) ?? Quickshell.screens[0]
    
    // Basic top bar for primary monitor
    PanelWindow {
        id: topBar
        screen: primaryScreen
        
        anchors {
            top: true
            left: true  
            right: true
        }
        
        implicitHeight: config.bars.height || 36
        exclusiveZone: implicitHeight
        
        // Use configuration for transparency and colors
        color: Qt.rgba(0.11, 0.11, 0.12, 0.95) // Material 3 dark
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: config.material3.spacing.space8
                spacing: config.material3.spacing.space12
                
                // Simple workspace indicator placeholder
                Rectangle {
                    width: 100
                    height: 24
                    color: "#49454F"
                    radius: config.material3.spacing.space12
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Workspaces"
                        color: "#E6E0E9"
                        font.pixelSize: config.material3.typography.labelLarge
                    }
                }
                
                // Window title or placeholder
                Text {
                    Layout.fillWidth: true
                    text: Hyprland.focusedMonitor?.activeWindow?.title ?? "QuickShell Custom Build"
                    color: "#E6E0E9"
                    font.pixelSize: config.material3.typography.labelLarge
                    elide: Text.ElideRight
                }
                
                // Simple clock placeholder
                Rectangle {
                    width: 80
                    height: 24
                    color: "#49454F"
                    radius: config.material3.spacing.space12
                    
                    Text {
                        id: clockText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(new Date(), "hh:mm")
                        color: "#E6E0E9"
                        font.pixelSize: config.material3.typography.labelLarge
                    }
                    
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "hh:mm")
                    }
                }
            }
        }
    }
} 