import { Variable, bind, exec } from "astal"
import { Gtk } from "astal/gtk3"

export default function SystemStats() {
    // Remove the global variables that cause memory leaks
    return (
        <box
            className="system-stats"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={16}
            setup={self => {
                // Create local variables with proper cleanup
                const cpuUsage = Variable(0)
                const memoryUsage = Variable({ used: 0, total: 0 })
                const temperature = Variable(0)

                // Setup polling with proper cleanup
                const cpuTimer = cpuUsage.poll(2000, () => {
                    try {
                        const cpuInfo = exec("grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage}'")
                        return parseFloat(cpuInfo) || 0
                    } catch (e) {
                        return 0
                    }
                })

                const memTimer = memoryUsage.poll(2000, () => {
                    try {
                        const memInfo = exec('free -m | grep "^Mem:" | awk \'{print $3 " " $2}\'')
                        const [used, total] = memInfo.split(' ').map(Number)
                        return { used: used / 1024, total: total / 1024 }
                    } catch (e) {
                        return { used: 0, total: 0 }
                    }
                })

                const tempTimer = temperature.poll(5000, () => {
                    try {
                        const temp = exec("sensors | grep 'Package id 0:' | awk '{print $4}' | tr -d '+°C'")
                        return parseFloat(temp) || 0
                    } catch (e) {
                        return 0
                    }
                })

                // Create child widgets with proper binding
                const cpuWidget = (
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                        <box spacing={8}>
                            <icon icon="cpu-symbolic" />
                            <label label="CPU Usage" />
                            <label 
                                label={bind(cpuUsage).as(v => `${v.toFixed(1)}%`)}
                                className="stat-value"
                            />
                        </box>
                        <levelbar
                            value={bind(cpuUsage).as(v => v / 100)}
                            className="cpu-bar"
                        />
                    </box>
                )

                const memoryWidget = (
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                        <box spacing={8}>
                            <icon icon="memory-symbolic" />
                            <label label="Memory" />
                            <label 
                                label={bind(memoryUsage).as(m => `${m.used.toFixed(1)}G / ${m.total.toFixed(1)}G`)}
                                className="stat-value"
                            />
                        </box>
                        <levelbar
                            value={bind(memoryUsage).as(m => m.total > 0 ? m.used / m.total : 0)}
                            className="memory-bar"
                        />
                    </box>
                )

                const tempWidget = (
                    <box spacing={8}>
                        <icon icon="temperature-symbolic" />
                        <label label="Temperature" />
                        <label 
                            label={bind(temperature).as(t => t > 0 ? `${t.toFixed(1)}°C` : "N/A")}
                            className="stat-value"
                        />
                    </box>
                )

                // Add children to the main container
                self.add(cpuWidget)
                self.add(memoryWidget) 
                self.add(tempWidget)

                // Setup cleanup on widget destruction
                self.connect('destroy', () => {
                    cpuUsage.stopPoll()
                    memoryUsage.stopPoll()
                    temperature.stopPoll()
                })
            }}
        />
    )
} 