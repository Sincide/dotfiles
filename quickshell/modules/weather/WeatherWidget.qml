import QtQuick
import QtQuick.Controls
import Quickshell

Rectangle {
    id: weatherWidget
    
    // Properties
    property string location: "San Francisco"
    property string temperature: "22°C"
    property string condition: "Partly Cloudy"
    property string icon: "⛅"
    property var forecast: [
        { day: "Today", high: "24°", low: "18°", icon: "⛅" },
        { day: "Tomorrow", high: "26°", low: "20°", icon: "☀️" },
        { day: "Thursday", high: "23°", low: "17°", icon: "🌧️" },
        { day: "Friday", high: "25°", low: "19°", icon: "☀️" },
        { day: "Saturday", high: "21°", low: "16°", icon: "☁️" }
    ]
    
    width: 350
    height: 250
    radius: 20
    
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
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        // Header
        Row {
            width: parent.width
            spacing: 10
            
            Text {
                text: "🌍"
                font.pixelSize: 20
                color: "#cdd6f4"
            }
            
            Text {
                text: location
                color: "#cdd6f4"
                font.pixelSize: 16
                font.bold: true
            }
        }
        
        // Current weather
        Row {
            width: parent.width
            spacing: 20
            
            // Weather icon
            Rectangle {
                width: 80
                height: 80
                radius: 40
                color: "#4089b4fa"
                
                Text {
                    anchors.centerIn: parent
                    text: icon
                    font.pixelSize: 40
                }
            }
            
            // Weather info
            Column {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                
                Text {
                    text: temperature
                    color: "#cdd6f4"
                    font.pixelSize: 32
                    font.bold: true
                }
                
                Text {
                    text: condition
                    color: "#a6adc8"
                    font.pixelSize: 14
                }
            }
        }
        
        // Forecast
        Column {
            width: parent.width
            spacing: 8
            
            Text {
                text: "5-Day Forecast"
                color: "#cdd6f4"
                font.pixelSize: 14
                font.bold: true
            }
            
            ListView {
                width: parent.width
                height: 100
                model: forecast
                spacing: 5
                
                delegate: Rectangle {
                    width: parent.width
                    height: 18
                    color: "transparent"
                    
                    Row {
                        anchors.fill: parent
                        spacing: 15
                        
                        Text {
                            text: modelData.day
                            color: "#a6adc8"
                            font.pixelSize: 12
                            width: 70
                        }
                        
                        Text {
                            text: modelData.icon
                            font.pixelSize: 16
                            width: 25
                        }
                        
                        Text {
                            text: modelData.high + " / " + modelData.low
                            color: "#cdd6f4"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
    
    // Update timer
    Timer {
        interval: 30000 // 30 seconds for demo
        running: true
        repeat: true
        onTriggered: updateWeather()
    }
    
    // Functions
    function updateWeather() {
        // Simulate weather changes
        let conditions = [
            { temp: "22°C", condition: "Partly Cloudy", icon: "⛅" },
            { temp: "25°C", condition: "Sunny", icon: "☀️" },
            { temp: "19°C", condition: "Rainy", icon: "🌧️" },
            { temp: "23°C", condition: "Cloudy", icon: "☁️" },
            { temp: "21°C", condition: "Clear", icon: "🌤️" }
        ]
        
        let randomWeather = conditions[Math.floor(Math.random() * conditions.length)]
        temperature = randomWeather.temp
        condition = randomWeather.condition
        icon = randomWeather.icon
        
        console.log("Weather updated:", condition, temperature)
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
        
        onClicked: {
            updateWeather()
        }
    }
    
    // Smooth animations
    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }
    
    // Initialize
    Component.onCompleted: {
        updateWeather()
    }
} 