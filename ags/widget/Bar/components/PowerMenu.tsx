import { Variable, bind, exec } from "astal"
import { Gtk } from "astal/gtk3"

export default function PowerMenu() {
  return (
    <box
      className="power-menu"
      setup={self => {
        // Create local variable with proper cleanup
        const showMenu = Variable(false)

        const powerButton = (
          <button
            className="power-button"
            onClick={() => showMenu.set(!showMenu.get())}
            child={
              <icon icon="system-shutdown-symbolic" />
            }
          />
        )

        const menuBox = bind(showMenu).as(show => show ? (
          <box className="power-menu-options" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            <button
              className="power-option"
              onClick={() => {
                exec("systemctl poweroff")
                showMenu.set(false) 
              }}
              child={
                <box spacing={8}>
                  <icon icon="system-shutdown-symbolic" />
                  <label label="Power Off" />
                </box>
              }
            />
            <button
              className="power-option"
              onClick={() => {
                exec("systemctl reboot")
                showMenu.set(false)
              }}
              child={
                <box spacing={8}>
                  <icon icon="system-reboot-symbolic" />
                  <label label="Restart" />
                </box>
              }
            />
            <button
              className="power-option"
              onClick={() => {
                exec("systemctl suspend")
                showMenu.set(false)
              }}
              child={
                <box spacing={8}>
                  <icon icon="system-suspend-symbolic" />
                  <label label="Sleep" />
                </box>
              }
            />
            <button
              className="power-option"
              onClick={() => {
                exec("loginctl lock-session")
                showMenu.set(false)
              }}
              child={
                <box spacing={8}>
                  <icon icon="system-lock-screen-symbolic" />
                  <label label="Lock" />
                </box>
              }
            />
          </box>
        ) : null)

        // Add children
        self.add(powerButton)
        if (menuBox) self.add(menuBox)

        // Setup cleanup on widget destruction
        self.connect('destroy', () => {
          showMenu.destroy()
        })
      }}
    />
  )
} 