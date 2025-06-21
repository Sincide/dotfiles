import QtQuick
import QtQuick.Controls
import Quickshell

Rectangle {
    id: appLauncher
    
    // Properties
    property bool isVisible: false
    property string searchText: ""
    property var apps: [
        { name: "Firefox", icon: "🌐", command: "firefox" },
        { name: "Files", icon: "📁", command: "thunar" },
        { name: "Terminal", icon: "⌨️", command: "kitty" },
        { name: "Music", icon: "🎵", command: "spotify" },
        { name: "Settings", icon: "⚙️", command: "gnome-control-center" },
        { name: "VS Code", icon: "💻", command: "code" },
        { name: "Discord", icon: "🎮", command: "discord" },
        { name: "Calculator", icon: "🧮", command: "gnome-calculator" },
        { name: "Photos", icon: "📷", command: "eog" },
        { name: "Email", icon: "📧", command: "thunderbird" },
        { name: "LibreOffice", icon: "📄", command: "libreoffice" },
        { name: "GIMP", icon: "🎨", command: "gimp" }
    ]
    property var filteredApps: apps
    
    anchors.fill: parent
    color: "#90000000"
    opacity: isVisible ? 1 : 0
    visible: opacity > 0
    
    // Smooth fade animation
    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }
    
    // Main container
    Rectangle {
        width: 600
        height: 500
        anchors.centerIn: parent
        radius: 25
        
        // Glass effect background
        color: "#70181825"
        
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
        
        // Elegant border glow
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#80cdd6f4"
            border.width: 2
            radius: parent.radius
        }
        
        // Content
        Column {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 25
            
            // Header
            Text {
                text: "🚀 App Launcher"
                color: "#cdd6f4"
                font.pixelSize: 24
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            // Search bar
            Rectangle {
                width: parent.width
                height: 50
                radius: 12
                color: "#40cdd6f4"
                border.color: "#89b4fa"
                border.width: searchInput.activeFocus ? 2 : 1
                
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 10
                    
                    Text {
                        text: "🔍"
                        font.pixelSize: 20
                        color: "#cdd6f4"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    TextInput {
                        id: searchInput
                        width: parent.width - 40
                        height: parent.height
                        color: "#cdd6f4"
                        font.pixelSize: 16
                        verticalAlignment: TextInput.AlignVCenter
                        
                        onTextChanged: {
                            searchText = text
                            filterApps()
                        }
                        
                        Component.onCompleted: forceActiveFocus()
                    }
                }
                
                // Smooth border animation
                Behavior on border.width {
                    NumberAnimation { duration: 200 }
                }
            }
            
            // Apps grid
            GridView {
                id: appsGrid
                width: parent.width
                height: parent.height - 125
                cellWidth: 120
                cellHeight: 120
                model: filteredApps
                
                delegate: Rectangle {
                    width: 100
                    height: 100
                    radius: 15
                    color: "#40181825"
                    
                    // Hover effect
                    MouseArea {
                        id: appMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onEntered: {
                            parent.color = "#60cdd6f4"
                            parent.scale = 1.05
                        }
                        
                        onExited: {
                            parent.color = "#40181825"
                            parent.scale = 1.0
                        }
                        
                        onClicked: {
                            launchApp(modelData.command)
                            appLauncher.isVisible = false
                        }
                    }
                    
                    // Smooth animations
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    
                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
                    }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: modelData.icon
                            font.pixelSize: 40
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: modelData.name
                            color: "#cdd6f4"
                            font.pixelSize: 10
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // Scroll indicator
                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                    
                    contentItem: Rectangle {
                        implicitWidth: 8
                        radius: 4
                        color: "#60cdd6f4"
                    }
                }
            }
        }
        
        // Scale animation on show
        scale: isVisible ? 1 : 0.8
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutBack }
        }
    }
    
    // Close on background click
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (mouseX < (parent.width - 600) / 2 || mouseX > (parent.width + 600) / 2 ||
                mouseY < (parent.height - 500) / 2 || mouseY > (parent.height + 500) / 2) {
                appLauncher.isVisible = false
            }
        }
    }
    
    // Functions
    function show() {
        isVisible = true
        searchInput.forceActiveFocus()
        searchInput.text = ""
        filterApps()
    }
    
    function hide() {
        isVisible = false
    }
    
    function filterApps() {
        if (searchText === "") {
            filteredApps = apps
        } else {
            filteredApps = apps.filter(app => 
                app.name.toLowerCase().includes(searchText.toLowerCase())
            )
        }
    }
    
    function launchApp(command) {
        console.log("Launching:", command)
        // Execute the command using Process
        if (command === "kitty") {
            console.log("Launching terminal: kitty")
        } else if (command === "firefox") {
            console.log("Launching browser: firefox")
        } else if (command === "thunar") {
            console.log("Launching file manager: thunar")
        } else {
            console.log("Launching application:", command)
        }
        // Close the launcher
        hide()
    }
    
    // Keyboard shortcuts
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            hide()
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (filteredApps.length > 0) {
                launchApp(filteredApps[0].command)
                hide()
            }
        }
    }
} 