import { bind, Variable } from "astal"
import { Gtk } from "astal/gtk3"
import { exec, execAsync } from "astal/process"

const brightness = Variable(50).poll(1000, () => {
    try {
        const output = exec("brightnessctl get")
        const max = exec("brightnessctl max")
        return Math.round((parseInt(output) / parseInt(max)) * 100)
    } catch {
        return 50
    }
})

export function BrightnessControl() {
    return <box className="brightness-control" spacing={8}>
        <button
            className="brightness-icon"
            onClicked={() => {
                const current = brightness.get()
                const newBrightness = current === 0 ? 50 : 0
                execAsync(`brightnessctl set ${newBrightness}%`)
            }}
        >
            <icon 
                icon={bind(brightness).as(b => 
                    b === 0 ? "display-brightness-off-symbolic" : 
                    b < 30 ? "display-brightness-low-symbolic" :
                    b < 70 ? "display-brightness-medium-symbolic" :
                    "display-brightness-high-symbolic"
                )}
            />
        </button>
        
        <scale
            className="brightness-slider"
            hexpand={true}
            drawValue={false}
            min={0}
            max={100}
            step={5}
            value={bind(brightness)}
            onDragged={({ value }) => {
                execAsync(`brightnessctl set ${Math.round(value)}%`)
            }}
        />
        
        <label
            className="brightness-percentage"
            label={bind(brightness).as(b => `${b}%`)}
        />
    </box>
} 