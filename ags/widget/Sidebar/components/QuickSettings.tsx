import { bind } from "astal"
import { Gtk } from "astal/gtk3"
import { execAsync } from "astal/process"

export function QuickSettings() {
    return <box className="quick-settings" spacing={8}>
        <button 
            className="quick-toggle wifi"
            tooltipText="Toggle WiFi"
            onClicked={() => execAsync("nmcli radio wifi toggle")}
        >
            <icon icon="network-wireless-symbolic" />
        </button>
        
        <button 
            className="quick-toggle bluetooth"
            tooltipText="Toggle Bluetooth"
            onClicked={() => execAsync("bluetoothctl power toggle")}
        >
            <icon icon="bluetooth-symbolic" />
        </button>
        
        <button 
            className="quick-toggle dnd"
            tooltipText="Toggle Do Not Disturb"
            onClicked={() => execAsync("makoctl mode -t do-not-disturb")}
        >
            <icon icon="notification-disabled-symbolic" />
        </button>
        
        <button 
            className="quick-toggle nightlight"
            tooltipText="Toggle Night Light"
            onClicked={() => execAsync("gammastep -O 4000")}
        >
            <icon icon="night-light-symbolic" />
        </button>
    </box>
} 