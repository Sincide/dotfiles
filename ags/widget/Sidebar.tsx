import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable } from "astal"

// System monitoring variables with error handling
const time = Variable("--:--").poll(1000, ["bash", "-c", "date +%H:%M || echo '--:--'"])
const date = Variable("---").poll(60000, ["bash", "-c", "date '+%a %b %d' || echo '---'"])
const cpu = Variable("--").poll(3000, ["bash", "-c", "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {printf \"%.1f%%\", usage}' || echo '--'"])
const memory = Variable("--").poll(5000, ["bash", "-c", "free | awk 'NR==2{printf \"%.1f%%\", $3*100/$2}' || echo '--'"])
const uptime = Variable("--").poll(60000, ["bash", "-c", "uptime -p || echo '--'"])

export default function Sidebar(gdkmonitor: Gdk.Monitor) {
    const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor

    return <window
        className="Sidebar"
        name="sidebar"
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={TOP | BOTTOM | LEFT}
        application={App}>
        
        <box orientation={Gtk.Orientation.VERTICAL} spacing={20}>
            
            {/* Header Section */}
            <box className="sidebar-header" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
                <label className="sidebar-title" label="System Info" />
                <box className="separator" />
            </box>

            {/* Time & Date */}
            <box className="time-section" orientation={Gtk.Orientation.VERTICAL} spacing={5}>
                <label className="time" label={time()} />
                <label className="date" label={date()} />
            </box>

            {/* System Stats */}
            <box className="stats-section" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
                
                {/* CPU Usage */}
                <box className="stat-item" orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                    <label className="stat-label" label="CPU:" />
                    <label className="stat-value" label={cpu()} />
                </box>

                {/* Memory Usage */}
                <box className="stat-item" orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
                    <label className="stat-label" label="RAM:" />
                    <label className="stat-value" label={memory()} />
                </box>

                {/* Uptime */}
                <box className="stat-item" orientation={Gtk.Orientation.VERTICAL} spacing={5}>
                    <label className="stat-label" label="Uptime:" />
                    <label className="stat-value uptime" label={uptime()} />
                </box>
            </box>

            {/* Quick Actions */}
            <box className="actions-section" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
                <box className="separator" />
                <label className="section-title" label="Quick Actions" />
                
                <button 
                    className="action-button"
                    onClicked="kitty"
                >
                    🖥️ Terminal
                </button>
                
                <button 
                    className="action-button"
                    onClicked="nautilus"
                >
                    📁 Files
                </button>
                
                <button 
                    className="action-button close-button"
                    onClicked={() => App.quit()}
                >
                    ✕ Close
                </button>
            </box>
        </box>
    </window>
}

// Export the toggle function for external use
export function toggleSidebar() {
    App.toggle_window("sidebar")
} 