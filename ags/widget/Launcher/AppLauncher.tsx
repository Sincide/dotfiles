import { App, Astal, Gtk } from "astal/gtk3"
import { bind, Variable } from "astal"
import { exec, execAsync } from "astal/process"
import Apps from "gi://AstalApps"

const apps = new Apps.Apps()

const searchQuery = Variable("")
const selectedIndex = Variable(0)

function fuzzyMatch(str: string, pattern: string): boolean {
    const regex = new RegExp(pattern.split('').join('.*'), 'i')
    return regex.test(str)
}

export function AppLauncher() {
    const filteredApps = Variable.derive([searchQuery], (query) => {
        const filtered = apps.get_list().filter(app => {
            const name = app.name.toLowerCase()
            const exec = app.executable?.toLowerCase() || ""
            const description = app.description?.toLowerCase() || ""
            const q = query.toLowerCase()
            
            return name.includes(q) || 
                   exec.includes(q) || 
                   description.includes(q) ||
                   fuzzyMatch(name, q)
        })
        
        // Sort by relevance
        return filtered.sort((a, b) => {
            const aName = a.name.toLowerCase()
            const bName = b.name.toLowerCase()
            const q = query.toLowerCase()
            
            if (aName.startsWith(q) && !bName.startsWith(q)) return -1
            if (!aName.startsWith(q) && bName.startsWith(q)) return 1
            
            return aName.localeCompare(bName)
        })
    })

    return <window
        className="launcher"
        name="launcher"
        anchor={Astal.WindowAnchor.TOP}
        layer={Astal.Layer.OVERLAY}
        exclusivity={Astal.Exclusivity.IGNORE}
        visible={false}
        keymode={Astal.Keymode.EXCLUSIVE}
        onKeyPressed={(self, keyval, keycode, state) => {
            const key = keyval
            
            if (key === 65307) { // Escape
                App.get_window("launcher")?.set_visible(false)
                return true
            }
            
            if (key === 65293) { // Enter
                const apps = filteredApps.get()
                const selected = apps[selectedIndex.get()]
                if (selected) {
                    selected.launch()
                    App.get_window("launcher")?.set_visible(false)
                    searchQuery.set("")
                    selectedIndex.set(0)
                }
                return true
            }
            
            if (key === 65362) { // Up arrow
                const apps = filteredApps.get()
                selectedIndex.set(Math.max(0, selectedIndex.get() - 1))
                return true
            }
            
            if (key === 65364) { // Down arrow
                const apps = filteredApps.get()
                selectedIndex.set(Math.min(apps.length - 1, selectedIndex.get() + 1))
                return true
            }
            
            return false
        }}
        application={App}
    >
        <box
            className="launcher-container"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={12}
        >
            {/* Search Input */}
            <entry
                className="launcher-search"
                placeholderText="Search applications..."
                text={bind(searchQuery)}
                onChanged={(self) => {
                    searchQuery.set(self.text)
                    selectedIndex.set(0)
                }}
                onActivate={() => {
                    const apps = filteredApps.get()
                    const selected = apps[selectedIndex.get()]
                    if (selected) {
                        selected.launch()
                        App.get_window("launcher")?.set_visible(false)
                        searchQuery.set("")
                        selectedIndex.set(0)
                    }
                }}
            />

            {/* App List */}
            <scrolled
                className="launcher-list"
                hscroll={Gtk.PolicyType.NEVER}
                vscroll={Gtk.PolicyType.AUTOMATIC}
            >
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    {bind(filteredApps).as(apps => 
                        apps.slice(0, 10).map((app, index) => (
                            <button
                                key={app.name}
                                className={bind(selectedIndex).as(i => 
                                    `launcher-app ${i === index ? 'selected' : ''}`
                                )}
                                onClicked={() => {
                                    app.launch()
                                    App.get_window("launcher")?.set_visible(false)
                                    searchQuery.set("")
                                    selectedIndex.set(0)
                                }}
                            >
                                <box spacing={12}>
                                    <icon
                                        icon={app.iconName || "application-x-executable"}
                                        css="min-width: 32px; min-height: 32px;"
                                    />
                                    <box
                                        orientation={Gtk.Orientation.VERTICAL}
                                        halign={Gtk.Align.START}
                                        spacing={2}
                                    >
                                        <label
                                            label={app.name}
                                            halign={Gtk.Align.START}
                                            className="app-name"
                                        />
                                        <label
                                            label={app.description || app.executable || ""}
                                            halign={Gtk.Align.START}
                                            className="app-description"
                                        />
                                    </box>
                                </box>
                            </button>
                        ))
                    )}
                </box>
            </scrolled>
        </box>
    </window>
} 