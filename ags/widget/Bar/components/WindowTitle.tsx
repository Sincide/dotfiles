import { bind } from "astal"
import { Gtk } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland"

const hyprland = Hyprland.get_default()

export function WindowTitle() {
    return <label
        className="window-title"
        label={bind(hyprland, "focusedClient").as(client => 
            client ? client.title || client.class || "Desktop" : "Desktop"
        )}
        maxWidthChars={50}
        ellipsize={3} // PANGO_ELLIPSIZE_END
        halign={Gtk.Align.CENTER}
    />
} 