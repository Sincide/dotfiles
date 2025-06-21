import { App, Astal, Gtk } from "astal/gtk3"
import { bind } from "astal"
import Hyprland from "gi://AstalHyprland"
import Tray from "gi://AstalTray"
import { BAR_CONFIG } from "../../config/monitors"
import { Workspaces } from "./components/Workspaces"
import { WindowTitle } from "./components/WindowTitle"
import Clock from "./components/Clock"
import { SystemTray } from "./components/SystemTray"
import PowerMenu from "./components/PowerMenu"

const hyprland = Hyprland.get_default()
const tray = Tray.get_default()

export function TopBar(monitor: number = 0) {
    return <window
        className="top-bar"
        name={`bar-${monitor}`}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        monitor={monitor}
    >
        <centerbox className="bar-container">
            {/* Left Section */}
            <box className="bar-left" halign={Gtk.Align.START} spacing={8}>
                <button
                    className="menu-button"
                    onClick={() => {
                        const launcher = App.get_window("launcher")
                        if (launcher) {
                            launcher.visible = !launcher.visible
                        }
                    }}
                >
                    <icon icon="view-app-grid-symbolic" />
                </button>
                <Workspaces />
                <button
                    className="sidebar-toggle"
                    onClick={() => {
                        const sidebar = App.get_window("sidebar")
                        if (sidebar) {
                            sidebar.visible = !sidebar.visible
                        }
                    }}
                >
                    <icon icon="sidebar-show-symbolic" />
                </button>
            </box>

            {/* Center Section */}
            <box className="bar-center" halign={Gtk.Align.CENTER}>
                <WindowTitle />
            </box>

            {/* Right Section */}
            <box className="bar-right" halign={Gtk.Align.END} spacing={8}>
                <SystemTray />
                <Clock />
                <button
                    className="notifications-button"
                    onClick={() => {
                        const notifications = App.get_window("notifications")
                        if (notifications) {
                            notifications.visible = !notifications.visible
                        }
                    }}
                >
                    <icon icon="notification-symbolic" />
                </button>
                <PowerMenu />
            </box>
        </centerbox>
    </window>
} 