import { App, Astal, Gtk } from "astal/gtk3"
import { bind, Variable } from "astal"
import Notifd from "gi://AstalNotifd"

const notifd = Notifd.get_default()

export function NotificationCenter() {
    return <window
        className="notifications"
        name="notifications"
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
        layer={Astal.Layer.OVERLAY}
        exclusivity={Astal.Exclusivity.IGNORE}
        visible={false}
        application={App}
    >
        <box
            className="notification-center"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={8}
        >
            {/* Header */}
            <box className="notification-header" spacing={8}>
                <label 
                    className="notification-title"
                    label="Notifications"
                    halign={Gtk.Align.START}
                />
                <button
                    className="clear-all"
                    label="Clear All"
                    halign={Gtk.Align.END}
                    hexpand={true}
                    onClicked={() => {
                        notifd.get_notifications().forEach(n => n.dismiss())
                    }}
                />
            </box>

            {/* Notification List */}
            <scrolled
                className="notification-list"
                hscroll={Gtk.PolicyType.NEVER}
                vscroll={Gtk.PolicyType.AUTOMATIC}
            >
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    {bind(notifd, "notifications").as(notifications =>
                        notifications.length === 0 ? (
                            <box className="no-notifications">
                                <icon icon="notification-symbolic" />
                                <label label="No notifications" />
                            </box>
                        ) : notifications.map(notification => (
                            <box
                                key={notification.id}
                                className={`notification-item ${notification.urgency}`}
                                orientation={Gtk.Orientation.VERTICAL}
                                spacing={8}
                            >
                                <box className="notification-header" spacing={8}>
                                    <icon 
                                        icon={notification.appIcon || notification.desktopEntry || "dialog-information"}
                                    />
                                    <box 
                                        orientation={Gtk.Orientation.VERTICAL}
                                        spacing={2}
                                        hexpand={true}
                                    >
                                        <label
                                            className="notification-title"
                                            label={notification.summary}
                                            halign={Gtk.Align.START}
                                        />
                                        <label
                                            className="notification-time"
                                            label={new Date(notification.time * 1000).toLocaleTimeString()}
                                            halign={Gtk.Align.START}
                                        />
                                    </box>
                                    <button
                                        className="notification-close"
                                        onClicked={() => notification.dismiss()}
                                    >
                                        <icon icon="window-close-symbolic" />
                                    </button>
                                </box>

                                {notification.body && (
                                    <label
                                        className="notification-body"
                                        label={notification.body}
                                        halign={Gtk.Align.START}
                                        wrap={true}
                                    />
                                )}

                                {notification.actions.length > 0 && (
                                    <box className="notification-actions" spacing={4}>
                                        {notification.actions.map(action => (
                                            <button
                                                key={action.id}
                                                label={action.label}
                                                onClicked={() => notification.invoke(action.id)}
                                            />
                                        ))}
                                    </box>
                                )}
                            </box>
                        ))
                    )}
                </box>
            </scrolled>
        </box>
    </window>
} 