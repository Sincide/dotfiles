import { Variable, bind } from "astal"
import { Gtk } from "astal/gtk3"

export default function Calendar() {
    return (
        <box className="calendar-widget" orientation={Gtk.Orientation.VERTICAL} spacing={16} setup={self => {
            // Create local variables with proper cleanup
            const time = Variable("")
            const date = Variable("")
            const dayOfWeek = Variable("")
            const monthDay = Variable("")
            const month = Variable("")

            // Setup polling with proper cleanup
            const timeTimer = time.poll(1000, () => 
                new Date().toLocaleTimeString("en-US", { 
                    hour12: true,
                    hour: "numeric", 
                    minute: "2-digit"
                })
            )

            const dateTimer = date.poll(60000, () =>
                new Date().toLocaleDateString("en-US")
            )

            const dayTimer = dayOfWeek.poll(60000, () =>
                new Date().toLocaleDateString("en-US", { weekday: "long" })
            )

            const monthDayTimer = monthDay.poll(60000, () =>
                new Date().getDate().toString()
            )

            const monthTimer = month.poll(60000, () =>
                new Date().toLocaleDateString("en-US", { month: "long" })
            )

            // Create widgets
            const timeWidget = (
                <label 
                    label={bind(time)}
                    className="calendar-time"
                />
            )

            const dateWidget = (
                <label 
                    label={bind(date)}
                    className="calendar-date"
                />
            )

            const monthWidget = (
                <box spacing={8} className="month-display">
                    <label 
                        label={bind(month)}
                        className="calendar-month"
                    />
                    <label 
                        label={bind(monthDay)}
                        className="calendar-day-number"
                    />
                </box>
            )

            const dayWidget = (
                <label 
                    label={bind(dayOfWeek)}
                    className="calendar-day-name"
                />
            )

            // Add children
            self.add(timeWidget)
            self.add(dateWidget)
            self.add(monthWidget)
            self.add(dayWidget)

            // Setup cleanup on widget destruction
            self.connect('destroy', () => {
                time.stopPoll()
                date.stopPoll()
                dayOfWeek.stopPoll()
                monthDay.stopPoll()
                month.stopPoll()
            })
        }} />
    )
} 