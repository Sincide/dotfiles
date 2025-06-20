import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable } from "astal"

// Smart polling with different intervals based on importance and visibility
const time = Variable("--:--").poll(1000, ["bash", "-c", "date +%H:%M || echo '--:--'"])
const date = Variable("---").poll(60000, ["bash", "-c", "date '+%a %b %d' || echo '---'"])

// Optimized system monitoring with error handling and caching
const cpu = Variable("--").poll(2000, ["bash", "-c", `
    awk '/^cpu / {
        usage = ($2+$4)*100/($2+$3+$4+$5)
        printf "%.0f%%", usage
    }' /proc/stat || echo '--'
`])

const memory = Variable("--").poll(3000, ["bash", "-c", `
    free | awk 'NR==2 {
        used = $3/1024/1024
        total = $2/1024/1024
        printf "%.1fGB/%.1fGB", used, total
    }' || echo '--'
`])

const uptime = Variable("--").poll(30000, ["bash", "-c", `
    uptime -p | sed 's/up //' | sed 's/ hours/h/' | sed 's/ hour/h/' | sed 's/ minutes/m/' | sed 's/ minute/m/' || echo '--'
`])

// System load average (less frequent updates)
const loadavg = Variable("--").poll(5000, ["bash", "-c", `
    cat /proc/loadavg | awk '{printf "%.2f", $1}' || echo '--'
`])

// Sidebar visibility state
const sidebarVisible = Variable(false)

// Hover trigger component - always visible at screen edge
function HoverTrigger(gdkmonitor: Gdk.Monitor) {
    const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor

    return <window
        className="SidebarTrigger"
        name="sidebar-trigger"
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.NORMAL}
        anchor={TOP | BOTTOM | LEFT}
        application={App}
        keymode={Astal.Keymode.NONE}
        layer={Astal.Layer.TOP}
        margin_left={0}
        margin_top={0}
        margin_bottom={0}>
        
        <eventbox
            onHover={() => {
                sidebarVisible.set(true)
                App.get_window("sidebar")?.set_visible(true)
            }}
            className="trigger-area">
            <box className="trigger-tab" orientation={Gtk.Orientation.VERTICAL}>
                <label className="trigger-icon" label="📊" />
                <label className="trigger-text" label="S\nY\nS" />
            </box>
        </eventbox>
    </window>
}

// Main sidebar component - shows on hover
function MainSidebar(gdkmonitor: Gdk.Monitor) {
    const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor

    return <window
        className="Sidebar"
        name="sidebar"
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.NORMAL}  // Changed from EXCLUSIVE to NORMAL for overlay
        anchor={TOP | BOTTOM | LEFT}
        application={App}
        keymode={Astal.Keymode.NONE}
        layer={Astal.Layer.TOP}
        visible={sidebarVisible()}
        margin_left={0}>
        
        <eventbox
            onHover={() => sidebarVisible.set(true)}
            onHoverLost={() => {
                // Small delay before hiding to prevent flicker
                setTimeout(() => sidebarVisible.set(false), 300)
            }}
            className="sidebar-eventbox">
            
            <box orientation={Gtk.Orientation.VERTICAL} className="sidebar-container" spacing={20}>
                
                {/* Header Section with improved hierarchy */}
                <box className="sidebar-header" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                    <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8} className="header-content">
                        <label className="header-icon" label="📊" />
                        <label className="sidebar-title" label="System Monitor" />
                    </box>
                    <box className="separator" />
                </box>

                {/* Time & Date Section with better typography */}
                <box className="time-section" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                    <box orientation={Gtk.Orientation.HORIZONTAL} spacing={12} className="time-container">
                        <label className="time-icon" label="🕐" />
                        <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                            <label className="time" label={time()} />
                            <label className="date" label={date()} />
                        </box>
                    </box>
                </box>

                {/* System Stats with icons and improved layout */}
                <box className="stats-section" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                    
                    {/* CPU Usage */}
                    <box className="stat-item cpu-stat" orientation={Gtk.Orientation.HORIZONTAL} spacing={12}>
                        <label className="stat-icon" label="⚡" />
                        <box orientation={Gtk.Orientation.VERTICAL} className="stat-content" spacing={4}>
                            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
                                <label className="stat-label" label="CPU" />
                                <label className="stat-value" label={cpu()} />
                            </box>
                            <label className="stat-detail" label={loadavg().as(load => `Load: ${load}`)} />
                        </box>
                    </box>

                    {/* Memory Usage */}
                    <box className="stat-item memory-stat" orientation={Gtk.Orientation.HORIZONTAL} spacing={12}>
                        <label className="stat-icon" label="💾" />
                        <box orientation={Gtk.Orientation.VERTICAL} className="stat-content" spacing={4}>
                            <label className="stat-label" label="Memory" />
                            <label className="stat-value" label={memory()} />
                        </box>
                    </box>

                    {/* Uptime */}
                    <box className="stat-item uptime-stat" orientation={Gtk.Orientation.HORIZONTAL} spacing={12}>
                        <label className="stat-icon" label="⏱️" />
                        <box orientation={Gtk.Orientation.VERTICAL} className="stat-content" spacing={4}>
                            <label className="stat-label" label="Uptime" />
                            <label className="stat-value uptime" label={uptime()} />
                        </box>
                    </box>
                </box>

                {/* Quick Actions with better icons and layout */}
                <box className="actions-section" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                    <box className="separator" />
                    <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8} className="actions-header">
                        <label className="actions-icon" label="🚀" />
                        <label className="section-title" label="Quick Actions" />
                    </box>
                    
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={8} className="action-buttons">
                        <button 
                            className="action-button terminal-button"
                            onClicked="kitty"
                        >
                            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                                <label label="💻" />
                                <label label="Terminal" />
                            </box>
                        </button>
                        
                        <button 
                            className="action-button files-button"
                            onClicked="nautilus"
                        >
                            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                                <label label="📁" />
                                <label label="File Manager" />
                            </box>
                        </button>
                        
                        <button 
                            className="action-button settings-button"
                            onClicked="gnome-control-center"
                        >
                            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                                <label label="⚙️" />
                                <label label="Settings" />
                            </box>
                        </button>
                        
                        <button 
                            className="action-button pin-button"
                            onClicked={() => {
                                const currentState = sidebarVisible.get()
                                sidebarVisible.set(!currentState)
                            }}
                        >
                            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                                <label label="📌" />
                                <label label={sidebarVisible().as(visible => visible ? "Unpin" : "Pin")} />
                            </box>
                        </button>
                        
                        <button 
                            className="action-button close-button"
                            onClicked={() => sidebarVisible.set(false)}
                        >
                            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                                <label label="✕" />
                                <label label="Hide Sidebar" />
                            </box>
                        </button>
                    </box>
                </box>
            </box>
        </eventbox>
    </window>
}

// Main export function that creates both components
export default function Sidebar(gdkmonitor: Gdk.Monitor) {
    // Create both the trigger and main sidebar
    const trigger = HoverTrigger(gdkmonitor)
    const sidebar = MainSidebar(gdkmonitor)
    
    return sidebar // Return the main sidebar (trigger is created separately)
}

// Export the toggle function for external use
export function toggleSidebar() {
    const currentState = sidebarVisible.get()
    sidebarVisible.set(!currentState)
    App.get_window("sidebar")?.set_visible(!currentState)
}

// Export function to create trigger window
export function createTrigger(gdkmonitor: Gdk.Monitor) {
    return HoverTrigger(gdkmonitor)
} 