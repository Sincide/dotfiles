import { bind } from "astal"
import { Gtk } from "astal/gtk3"
import Network from "gi://AstalNetwork"

const network = Network.get_default()

export function NetworkInfo() {
    return <box className="network-info" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        {/* WiFi Info */}
        <box className="network-item" spacing={8}>
            <icon 
                icon={bind(network, "wifi").as(wifi => 
                    wifi?.enabled ? (
                        wifi.strength > 75 ? "network-wireless-signal-excellent-symbolic" :
                        wifi.strength > 50 ? "network-wireless-signal-good-symbolic" :
                        wifi.strength > 25 ? "network-wireless-signal-ok-symbolic" :
                        "network-wireless-signal-weak-symbolic"
                    ) : "network-wireless-disabled-symbolic"
                )}
            />
            <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand={true}>
                <label
                    className="network-name"
                    label={bind(network, "wifi").as(wifi => 
                        wifi?.ssid || (wifi?.enabled ? "Not Connected" : "WiFi Disabled")
                    )}
                    halign={Gtk.Align.START}
                />
                <label
                    className="network-status"
                    label={bind(network, "wifi").as(wifi => 
                        wifi?.enabled ? `Signal: ${wifi.strength || 0}%` : "Disabled"
                    )}
                    halign={Gtk.Align.START}
                />
            </box>
        </box>

        {/* Wired Info */}
        <box className="network-item" spacing={8}>
            <icon 
                icon={bind(network, "wired").as(wired => 
                    wired?.state === 1 ? "network-wired-symbolic" : "network-wired-disconnected-symbolic"
                )}
            />
            <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand={true}>
                <label
                    className="network-name"
                    label="Ethernet"
                    halign={Gtk.Align.START}
                />
                <label
                    className="network-status"
                    label={bind(network, "wired").as(wired => 
                        wired?.state === 1 ? "Connected" : "Disconnected"
                    )}
                    halign={Gtk.Align.START}
                />
            </box>
        </box>

        {/* Connectivity Status */}
        <box className="connectivity-status" spacing={8}>
            <icon 
                icon={bind(network, "connectivity").as(conn => 
                    conn === 4 ? "network-transmit-receive-symbolic" : 
                    conn === 3 ? "network-transmit-symbolic" : 
                    "network-offline-symbolic"
                )}
            />
            <label
                className="connectivity-label"
                label={bind(network, "connectivity").as(conn => 
                    conn === 4 ? "Full Connectivity" :
                    conn === 3 ? "Limited Connectivity" :
                    conn === 2 ? "Portal Required" :
                    conn === 1 ? "Local Only" :
                    "No Connectivity"
                )}
                halign={Gtk.Align.START}
            />
        </box>
    </box>
} 