import { Gtk } from "astal/gtk3"
import { Variable } from "astal"

interface ImagePreviewProps {
    selectedImage: Variable<string | null>
    onClose: () => void
    onSetWallpaper: (imagePath: string) => void
}

export default function ImagePreview({ selectedImage, onClose, onSetWallpaper }: ImagePreviewProps) {
    return <revealer 
        className="preview-overlay"
        revealChild={selectedImage() !== null}
        transitionType={Gtk.RevealerTransitionType.CROSSFADE}
        transitionDuration={200}
    >
        <eventbox 
            onButtonPressEvent={onClose}
            className="preview-background"
        >
            <box 
                className="preview-container"
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
            >
                <box 
                    className="preview-content"
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={16}
                >
                    <box 
                        className="preview-header"
                        orientation={Gtk.Orientation.HORIZONTAL}
                        spacing={12}
                    >
                        <label 
                            className="preview-title"
                            label={selectedImage() ? selectedImage()!.split('/').pop()?.replace(/\.[^/.]+$/, '') || 'Preview' : 'Preview'}
                            halign={Gtk.Align.START}
                            hexpand
                        />
                        <button 
                            className="close-button"
                            onClicked={onClose}
                        >
                            <label label="✕" />
                        </button>
                    </box>

                    <box 
                        className="preview-image-container"
                        widthRequest={600}
                        heightRequest={400}
                    >
                        <box 
                            className="preview-image"
                            css={selectedImage() ? `background-image: url('${selectedImage()}'); background-size: contain; background-repeat: no-repeat; background-position: center;` : ''}
                            widthRequest={600}
                            heightRequest={400}
                        />
                    </box>

                    <box 
                        className="preview-actions"
                        orientation={Gtk.Orientation.HORIZONTAL}
                        spacing={12}
                        halign={Gtk.Align.CENTER}
                    >
                        <button 
                            className="set-wallpaper-button primary"
                            onClicked={() => {
                                const img = selectedImage()
                                if (img) {
                                    onSetWallpaper(img)
                                    onClose()
                                }
                            }}
                        >
                            <label label="Set as Wallpaper" />
                        </button>
                        <button 
                            className="cancel-button"
                            onClicked={onClose}
                        >
                            <label label="Cancel" />
                        </button>
                    </box>
                </box>
            </box>
        </eventbox>
    </revealer>
} 