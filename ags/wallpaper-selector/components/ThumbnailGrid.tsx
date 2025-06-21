import { Gtk } from "astal/gtk3"
import { Variable } from "astal"

interface ThumbnailGridProps {
    wallpapers: Variable<string[]>
    onWallpaperSelect: (wallpaper: string) => void
}

export default function ThumbnailGrid({ wallpapers, onWallpaperSelect }: ThumbnailGridProps) {
    return <scrollable 
        className="thumbnail-grid-container"
        vexpand
        hscrollPolicy={Gtk.PolicyType.NEVER}
        vscrollPolicy={Gtk.PolicyType.AUTOMATIC}
    >
        <flowbox 
            className="thumbnail-grid"
            selectionMode={Gtk.SelectionMode.NONE}
            homogeneous
            maxChildrenPerLine={4}
            minChildrenPerLine={2}
            columnSpacing={12}
            rowSpacing={12}
        >
            {wallpapers().map(wallpaper => (
                <button
                    key={wallpaper}
                    className="thumbnail-button"
                    onClicked={() => onWallpaperSelect(wallpaper)}
                >
                    <box 
                        className="thumbnail-container"
                        orientation={Gtk.Orientation.VERTICAL}
                        spacing={8}
                    >
                        <box 
                            className="thumbnail-image"
                            widthRequest={200}
                            heightRequest={120}
                            css={`background-image: url('${wallpaper}'); background-size: cover; background-position: center;`}
                        />
                        <label 
                            className="thumbnail-label"
                            label={wallpaper.split('/').pop()?.replace(/\.[^/.]+$/, '') || ''}
                            ellipsize={3}
                            maxWidthChars={20}
                        />
                    </box>
                </button>
            ))}
        </flowbox>
    </scrollable>
} 