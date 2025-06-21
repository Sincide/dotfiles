import { Variable, bind, exec } from "astal"
import { Gtk } from "astal/gtk3"

export default function BrightnessControl() {
  return (
    <box
      className="brightness-control"
      spacing={8}
      setup={self => {
        // Create local variable with proper cleanup
        const brightness = Variable(50)

        // Setup polling with proper cleanup
        const brightnessTimer = brightness.poll(1000, () => {
          try {
            const output = exec("brightnessctl get")
            const max = exec("brightnessctl max")
            return Math.round((parseInt(output) / parseInt(max)) * 100)
          } catch (e) {
            console.warn("Could not get brightness:", e)
            return 50
          }
        })

        const setBrightness = (value: number) => {
          try {
            exec(`brightnessctl set ${value}%`)
          } catch (e) {
            console.warn("Could not set brightness:", e)
          }
        }

        // Create widgets
        const iconWidget = (
          <icon 
            icon={bind(brightness).as(b =>
              b > 66 ? "brightness-high-symbolic" :
              b > 33 ? "brightness-medium-symbolic" :
              "brightness-low-symbolic"
            )}
          />
        )

        const sliderWidget = (
          <slider
            className="brightness-slider"
            hexpand={true}
            value={bind(brightness)}
            onDragged={({ value }) => setBrightness(Math.round(value))}
            min={1}
            max={100}
          />
        )

        const labelWidget = (
          <label 
            label={bind(brightness).as(b => `${b}%`)}
            className="brightness-percentage"
          />
        )

        // Add children
        self.add(iconWidget)
        self.add(sliderWidget)
        self.add(labelWidget)

        // Setup cleanup on widget destruction
        self.connect('destroy', () => {
          brightness.stopPoll()
        })
      }}
    />
  )
} 