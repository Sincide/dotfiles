import QtQuick
import Quickshell

// System monitoring service - tracks CPU, RAM, and other system stats
QtObject {
    id: systemMonitor
    
    // System properties
    property real cpuUsage: 0.0
    property real memoryUsage: 0.0
    property string memoryUsageText: "0 MB"
    property real diskUsage: 0.0
    property string networkStatus: "📡"
    
    // Update timer - refresh every 3 seconds
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: updateSystemInfo()
    }
    
    // Update system information
    function updateSystemInfo() {
        updateCpuUsage()
        updateMemoryUsage()
        updateDiskUsage()
        updateNetworkStatus()
    }
    
    // Get CPU usage using top command
    function updateCpuUsage() {
        Process {
            id: cpuProcess
            command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1"]
            
            onFinished: function(exitCode, stdout, stderr) {
                if (exitCode === 0) {
                    const usage = parseFloat(stdout.trim())
                    if (!isNaN(usage)) {
                        systemMonitor.cpuUsage = usage
                    }
                }
            }
        }
        cpuProcess.start()
    }
    
    // Get memory usage
    function updateMemoryUsage() {
        Process {
            id: memProcess
            command: ["sh", "-c", "free -m | awk 'NR==2{printf \"%.1f %.0f\", $3*100/$2, $3}'"]
            
            onFinished: function(exitCode, stdout, stderr) {
                if (exitCode === 0) {
                    const parts = stdout.trim().split(' ')
                    if (parts.length >= 2) {
                        systemMonitor.memoryUsage = parseFloat(parts[0])
                        systemMonitor.memoryUsageText = parts[1] + " MB"
                    }
                }
            }
        }
        memProcess.start()
    }
    
    // Get disk usage for root partition
    function updateDiskUsage() {
        Process {
            id: diskProcess
            command: ["sh", "-c", "df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1"]
            
            onFinished: function(exitCode, stdout, stderr) {
                if (exitCode === 0) {
                    const usage = parseFloat(stdout.trim())
                    if (!isNaN(usage)) {
                        systemMonitor.diskUsage = usage
                    }
                }
            }
        }
        diskProcess.start()
    }
    
    // Simple network status check
    function updateNetworkStatus() {
        Process {
            id: networkProcess
            command: ["sh", "-c", "ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo 'connected' || echo 'disconnected'"]
            
            onFinished: function(exitCode, stdout, stderr) {
                const status = stdout.trim()
                if (status === "connected") {
                    systemMonitor.networkStatus = "🌐"
                } else {
                    systemMonitor.networkStatus = "📡"
                }
            }
        }
        networkProcess.start()
    }
    
    // Initialize on startup
    Component.onCompleted: {
        updateSystemInfo()
    }
} 