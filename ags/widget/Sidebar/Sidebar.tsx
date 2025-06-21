import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { bind } from "astal"
import { SIDEBAR_CONFIG } from "../../config/monitors"
import VolumeControl from "./components/VolumeControl"
import { QuickSettings } from "./components/QuickSettings"
import SystemStats from "./components/SystemStats"
import BrightnessControl from "./components/BrightnessControl"
import { MediaPlayer } from "./components/MediaPlayer"
import Calendar from "./components/Calendar"
import { NetworkInfo } from "./components/NetworkInfo"

export function Sidebar(monitor: number = 0) {
    return <window
        className="sidebar"
        name={`sidebar-${monitor}`}
        anchor={Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM}
        exclusivity={Astal.Exclusivity.IGNORE}
        monitor={monitor}
        visible={false}
        keymode={Astal.Keymode.ON_DEMAND}
    >
        <box
            className="sidebar-container"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={16}
        >
            {/* Header */}
            <box className="sidebar-header" spacing={8}>
                <label
                    label="Control Center"
                    className="sidebar-title"
                    hexpand={true}
                    halign={Gtk.Align.START}
                />
                <button
                    className="sidebar-close"
                    onClick={self => {
                        const window = self.get_root() as Astal.Window
                        window.visible = false
                    }}
                >
                    <icon icon="window-close-symbolic" />
                </button>
            </box>

            {/* Volume Control */}
            <box className="control-section">
                <label label="Audio" className="section-title" />
                <VolumeControl />
            </box>

            {/* Quick Settings */}
            <box className="control-section">
                <label label="Quick Settings" className="section-title" />
                <QuickSettings />
            </box>

            {/* Brightness Control */}
            <box className="control-section">
                <label label="Display" className="section-title" />
                <BrightnessControl />
            </box>

            {/* System Stats */}
            <box className="control-section">
                <label label="System" className="section-title" />
                <SystemStats />
            </box>

            {/* Media Player */}
            <box className="control-section">
                <label label="Media" className="section-title" />
                <MediaPlayer />
            </box>

            {/* Calendar */}
            <box className="control-section">
                <label label="Calendar" className="section-title" />
                <Calendar />
            </box>

            {/* Network Info */}
            <box className="control-section">
                <label label="Network" className="section-title" />
                <NetworkInfo />
            </box>
        </box>
    </window>
} 