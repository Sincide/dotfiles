import QtQuick
import Quickshell

Item {
    id: notificationSystem
    
    // Properties
    property var notifications: []
    property int maxNotifications: 5
    
    anchors.fill: parent
    
    // Notification container
    Column {
        id: notificationContainer
        anchors {
            top: parent.top
            right: parent.right
            margins: 20
        }
        spacing: 10
        
        // Notification items
        Repeater {
            model: notifications
            
            Rectangle {
                id: notification
                width: 350
                height: 100
                radius: 15
                
                // Glass effect
                color: "#60181825"
                opacity: 0.95
                
                // Gradient overlay
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: parent.radius
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#40cdd6f4" }
                        GradientStop { position: 1.0; color: "#20181825" }
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
                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    
                    // Icon
                    Rectangle {
                        width: 50
                        height: 50
                        radius: 25
                        color: "#89b4fa"
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon || "🔔"
                            font.pixelSize: 24
                        }
                    }
                    
                    // Text content
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 80
                        spacing: 5
                        
                        Text {
                            text: modelData.title || "Notification"
                            color: "#cdd6f4"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Text {
                            text: modelData.message || "Message"
                            color: "#a6adc8"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
                
                // Close button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: "#60f38ba8"
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 10
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "#cdd6f4"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: removeNotification(index)
                    }
                }
                
                // Entry animation
                NumberAnimation on x {
                    from: 400
                    to: 0
                    duration: 300
                    easing.type: Easing.OutBack
                    running: true
                }
                
                NumberAnimation on opacity {
                    from: 0
                    to: 0.95
                    duration: 300
                    running: true
                }
                
                // Auto-dismiss timer
                Timer {
                    interval: modelData.duration || 5000
                    running: true
                    onTriggered: removeNotification(index)
                }
            }
        }
    }
    
    // Functions
    function showNotification(title, message, icon, duration) {
        let notification = {
            title: title,
            message: message,
            icon: icon,
            duration: duration || 5000,
            timestamp: Date.now()
        }
        
        notifications.unshift(notification)
        
        // Limit notifications
        if (notifications.length > maxNotifications) {
            notifications = notifications.slice(0, maxNotifications)
        }
    }
    
    function removeNotification(index) {
        let newNotifications = [...notifications]
        newNotifications.splice(index, 1)
        notifications = newNotifications
    }
    
    // Demo notifications
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            let demoMessages = [
                { title: "System Update", message: "New updates available for installation", icon: "📦" },
                { title: "Weather Alert", message: "Sunny skies ahead! Perfect day for coding", icon: "☀️" },
                { title: "Task Complete", message: "Backup operation completed successfully", icon: "✅" },
                { title: "Network Status", message: "Connected to QuickShell-WiFi", icon: "📶" },
                { title: "Battery Status", message: "Battery at 85% - All systems optimal", icon: "🔋" }
            ]
            
            let randomMsg = demoMessages[Math.floor(Math.random() * demoMessages.length)]
            showNotification(randomMsg.title, randomMsg.message, randomMsg.icon)
        }
    }
} 