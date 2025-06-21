import { bind } from "astal"
import { Gtk } from "astal/gtk3"
import Mpris from "gi://AstalMpris"

const mpris = Mpris.get_default()

export function MediaPlayer() {
    return <box className="media-player" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        {bind(mpris, "players").as(players => 
            players.length === 0 ? (
                <box className="no-media">
                    <icon icon="audio-x-generic-symbolic" />
                    <label label="No media playing" />
                </box>
            ) : players[0] ? (
                <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                    {/* Track Info */}
                    <box spacing={8}>
                        <icon
                            className="media-icon"
                            icon={bind(players[0], "entry").as(e => e?.iconName || "audio-x-generic-symbolic")}
                        />
                        <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand={true}>
                            <label
                                className="media-title"
                                label={bind(players[0], "title").as(t => t || "Unknown")}
                                halign={Gtk.Align.START}
                                ellipsize={3}
                            />
                            <label
                                className="media-artist"
                                label={bind(players[0], "artist").as(a => a || "Unknown Artist")}
                                halign={Gtk.Align.START}
                                ellipsize={3}
                            />
                        </box>
                    </box>

                    {/* Controls */}
                    <box className="media-controls" spacing={8} halign={Gtk.Align.CENTER}>
                        <button
                            className="media-button"
                            onClicked={() => players[0].previous()}
                            sensitive={bind(players[0], "canGoPrevious")}
                        >
                            <icon icon="media-skip-backward-symbolic" />
                        </button>
                        
                        <button
                            className="media-button play-pause"
                            onClicked={() => players[0].playPause()}
                            sensitive={bind(players[0], "canPlay").as(p => 
                                p || players[0].canPause
                            )}
                        >
                            <icon 
                                icon={bind(players[0], "playbackStatus").as(s => 
                                    s === "Playing" ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                                )}
                            />
                        </button>
                        
                        <button
                            className="media-button"
                            onClicked={() => players[0].next()}
                            sensitive={bind(players[0], "canGoNext")}
                        >
                            <icon icon="media-skip-forward-symbolic" />
                        </button>
                    </box>

                    {/* Progress Bar */}
                    {bind(players[0], "length").as(length => length > 0 ? (
                        <scale
                            className="media-progress"
                            drawValue={false}
                            min={0}
                            max={length}
                            value={bind(players[0], "position")}
                            onDragged={({ value }) => {
                                players[0].position = value
                            }}
                        />
                    ) : null)}
                </box>
            ) : null
        )}
    </box>
} 