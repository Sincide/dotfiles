import { bind } from "astal"
import { Gtk } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland"
import { execAsync } from "astal/process"

const hyprland = Hyprland.get_default()

export function Workspaces({ monitor = 0 }: { monitor?: number }) {
    return <box className="workspaces" spacing={4}>
        {bind(hyprland, "workspaces").as(workspaces =>
            workspaces
                .filter(ws => ws.monitor?.id === monitor)
                .sort((a, b) => a.id - b.id)
                .map(workspace => (
                    <button
                        key={workspace.id}
                        className={bind(hyprland, "focusedWorkspace").as(focused => 
                            `workspace ${focused?.id === workspace.id ? 'active' : ''} ${
                                workspace.clients && workspace.clients.length > 0 ? 'occupied' : ''
                            }`
                        )}
                        onClicked={() => workspace.focus()}
                        tooltipText={`Workspace ${workspace.id}`}
                    >
                        <label label={`${workspace.id}`} />
                    </button>
                ))
        )}
    </box>
} 