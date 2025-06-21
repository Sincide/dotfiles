import { Apps } from "astal/apps"
import { Variable, bind } from "astal"
import { Gtk } from "astal/gtk3"

export default function AppLauncher() {
  return (
    <window
      name="launcher"
      className="launcher-window"
      visible={false}
      keymode={Astal.Keymode.ON_DEMAND}
      application={App}
      layer={Astal.Layer.TOP}
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM}
      setup={self => {
        // Create local variables with proper cleanup
        const searchQuery = Variable("")
        const selectedIndex = Variable(0)
        const apps = new Apps.Apps()
        
        const filteredApps = Variable.derive([searchQuery], ([query]) => {
          if (!query) return apps.get_list().slice(0, 10)
          
          return apps.get_list()
            .filter(app => 
              app.name.toLowerCase().includes(query.toLowerCase()) ||
              app.description?.toLowerCase().includes(query.toLowerCase()) ||
              app.executable.toLowerCase().includes(query.toLowerCase())
            )
            .slice(0, 10)
        })

        const launchApp = (app: any) => {
          app.launch()
          self.visible = false
          searchQuery.set("")
          selectedIndex.set(0)
        }

        const handleKeyPress = (self: any, event: any) => {
          const keyval = event.get_keyval()[1]
          const apps = filteredApps.get()
          
          switch (keyval) {
            case Gdk.KEY_Escape:
              self.visible = false
              searchQuery.set("")
              selectedIndex.set(0)
              return true
              
            case Gdk.KEY_Return:
              const selected = apps[selectedIndex.get()]
              if (selected) {
                launchApp(selected)
              }
              return true
              
            case Gdk.KEY_Down:
              selectedIndex.set(Math.min(selectedIndex.get() + 1, apps.length - 1))
              return true
              
            case Gdk.KEY_Up:
              selectedIndex.set(Math.max(selectedIndex.get() - 1, 0))
              return true
          }
          return false
        }

        // Create widgets
        const searchEntry = (
          <entry
            className="launcher-search"
            placeholderText="Search applications..."
            text={bind(searchQuery)}
            onChanged={self => {
              searchQuery.set(self.text)
              selectedIndex.set(0)
            }}
            onActivate={() => {
              const apps = filteredApps.get()
              const selected = apps[selectedIndex.get()]
              if (selected) {
                launchApp(selected)
              }
            }}
          />
        )

        const appsList = (
          <scrolled
            className="launcher-apps"
            vscroll={Gtk.PolicyType.AUTOMATIC}
            hscroll={Gtk.PolicyType.NEVER}
            minContentHeight={400}
            child={
              <box orientation={Gtk.Orientation.VERTICAL}>
                {bind(filteredApps).as(apps =>
                  apps.map((app, index) => (
                    <button
                      key={app.name}
                      className={bind(selectedIndex).as(i =>
                        i === index ? "launcher-app-item selected" : "launcher-app-item"
                      )}
                      onClick={() => launchApp(app)}
                      child={
                        <box spacing={12}>
                          <icon
                            icon={app.iconName || "application-x-executable"}
                            size={32}
                          />
                          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                            <label
                              label={app.name}
                              halign={Gtk.Align.START}
                              className="app-name"
                            />
                            <label
                              label={app.description || ""}
                              halign={Gtk.Align.START}
                              className="app-description"
                              ellipsize={Pango.EllipsizeMode.END}
                            />
                          </box>
                        </box>
                      }
                    />
                  ))
                )}
              </box>
            }
          />
        )

        const mainBox = (
          <box
            orientation={Gtk.Orientation.VERTICAL}
            spacing={12}
            className="launcher-content"
          >
            {searchEntry}
            {appsList}
          </box>
        )

        // Add main content
        self.child = mainBox

        // Connect key press handler
        self.connect("key-press-event", handleKeyPress)

        // Setup cleanup on widget destruction
        self.connect('destroy', () => {
          searchQuery.destroy()
          selectedIndex.destroy()
          filteredApps.destroy()
        })
      }}
    />
  )
} 