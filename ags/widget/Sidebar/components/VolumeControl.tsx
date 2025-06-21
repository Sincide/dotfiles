import { bind } from "astal"
import { Gtk } from "astal/gtk3"
import Wp from "gi://AstalWp"

export default function VolumeControl() {
    const audio = Wp.get_default()
    const speaker = audio?.audio?.defaultSpeaker

    if (!speaker) {
        return <label label="No audio device" className="error-label" />
    }

    return (
        <box className="volume-control" spacing={8}>
            <button
                className="volume-icon"
                onClicked={() => {
                    try {
                        if (speaker) {
                            speaker.mute = !speaker.mute
                        }
                    } catch (e) {
                        console.warn("Failed to toggle mute:", e)
                    }
                }}
            >
                <icon 
                    icon={bind(speaker, "volumeIcon").as(icon => icon || "audio-volume-muted-symbolic")} 
                    tooltipText={bind(speaker, "description").as(desc => desc || "Audio Device")}
                />
            </button>
            
            <scale
                className="volume-slider"
                hexpand={true}
                drawValue={false}
                min={0}
                max={1}
                step={0.05}
                value={bind(speaker, "volume").as(v => v || 0)}
                onDragged={({ value }) => {
                    try {
                        if (speaker && typeof value === 'number') {
                            speaker.volume = value
                        }
                    } catch (e) {
                        console.warn("Failed to set volume:", e)
                    }
                }}
            />
            
            <label
                className="volume-percentage"
                label={bind(speaker, "volume").as(v => `${Math.round((v || 0) * 100)}%`)}
            />
        </box>
    )
} 