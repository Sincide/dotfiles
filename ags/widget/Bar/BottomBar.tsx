import { App, Astal, Gtk } from "astal/gtk3"
import { bind } from "astal"

export function BottomBar(monitor = 0) {
    return <window
        className="bottom-bar"
        name={`bottom-bar-${monitor}`}
        monitor={monitor}
        anchor={Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        layer={Astal.Layer.TOP}
        application={App}
    >
        <centerbox className="bar-container">
            {/* Left Section */}
            <box className="bar-left" halign={Gtk.Align.START} spacing={8}>
                <label label="System Info" className="bottom-label" />
            </box>

            {/* Center Section */}
            <box className="bar-center" halign={Gtk.Align.CENTER}>
                <label label="Media Controls" className="bottom-label" />
            </box>

            {/* Right Section */}
            <box className="bar-right" halign={Gtk.Align.END} spacing={8}>
                <label label="Network" className="bottom-label" />
            </box>
        </centerbox>
    </window>
} 