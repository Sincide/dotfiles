import { Variable, bind } from "astal"

export default function Clock() {
  return (
    <box 
      className="clock-widget" 
      spacing={8}
      setup={self => {
        // Create local variables with proper cleanup
        const time = Variable("")
        const date = Variable("")

        // Setup polling with proper cleanup
        const timeTimer = time.poll(1000, () => 
          new Date().toLocaleTimeString("en-US", { 
            hour12: false,
            hour: "2-digit", 
            minute: "2-digit",
            second: "2-digit"
          })
        )

        const dateTimer = date.poll(60000, () =>
          new Date().toLocaleDateString("en-US", { 
            weekday: "short",
            year: "numeric", 
            month: "short", 
            day: "numeric"
          })
        )

        // Create widgets
        const iconWidget = <icon icon="appointment-soon-symbolic" />
        const timeLabel = (
          <label 
            label={bind(time)}
            className="clock-time" 
          />
        )

        // Add children
        self.add(iconWidget)
        self.add(timeLabel)
        self.tooltipText = bind(date)

        // Setup cleanup on widget destruction
        self.connect('destroy', () => {
          time.stopPoll()
          date.stopPoll()
        })
      }}
    />
  )
} 