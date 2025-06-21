import { bind } from "astal"
import { Gtk } from "astal/gtk3"
import Tray from "gi://AstalTray"

const tray = Tray.get_default()

export function SystemTray() {
    return <box className="system-tray" spacing={4}>
        {bind(tray, "items").as(items =>
            items.map(item => (
                <button
                    key={item.itemId}
                    className="tray-item"
                    tooltipMarkup={bind(item, "tooltipMarkup")}
                    onClicked={(self, event) => item.activate(event.button)}
                    onClickedSecondary={(self, event) => item.secondaryActivate(event.button)}
                >
                    <icon gIcon={bind(item, "gicon")} />
                </button>
            ))
        )}
    </box>
} 