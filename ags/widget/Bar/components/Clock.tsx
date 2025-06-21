import { bind, Variable, GLib } from "astal"
import { Gtk } from "astal/gtk3"

const time = Variable("").poll(1000, () => 
    GLib.DateTime.new_now_local().format("%H:%M:%S") || ""
)

const date = Variable("").poll(60000, () => 
    GLib.DateTime.new_now_local().format("%a %b %d") || ""
)

export function Clock() {
    return <box className="clock-widget" spacing={8} tooltipText={bind(date)}>
        <icon icon="appointment-soon-symbolic" />
        <label
            className="clock-time"
            label={bind(time)}
        />
    </box>
} 