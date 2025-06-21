import { Variable, bind } from 'astal'
import { Widget } from 'astal/gtk3'
import Gtk from 'gi://Gtk'
import type { WallpaperImage } from '../services/filesystem'
import { ThumbnailService } from '../utils/thumbnails'

interface ThumbnailGridProps {
  images: Variable<WallpaperImage[]>
  onImageSelect: (image: WallpaperImage) => void
  thumbnailService: ThumbnailService
}

export function ThumbnailGrid({ images, onImageSelect, thumbnailService }: ThumbnailGridProps) {
  function createThumbnailItem(image: WallpaperImage) {
    return (
      <eventbox
        className="thumbnail-container"
        onButtonPressEvent={() => onImageSelect(image)}
      >
        <box orientation={Gtk.Orientation.VERTICAL} className="thumbnail-item">
          <image
            className="thumbnail-image"
            widthRequest={180}
            heightRequest={135}
            setup={async (self) => {
              try {
                const thumbnail = await thumbnailService.generateThumbnail(image.path)
                if (thumbnail) {
                  self.pixbuf = thumbnail
                } else {
                  self.iconName = "image-missing"
                  self.iconSize = Gtk.IconSize.DIALOG
                }
              } catch (error) {
                console.error(`Failed to load thumbnail for ${image.path}:`, error)
                self.iconName = "image-missing"
                self.iconSize = Gtk.IconSize.DIALOG
              }
            }}
          />
          <label 
            label={image.name.replace(/\.[^/.]+$/, "")} 
            maxWidthChars={20}
            ellipsize={3} // PANGO_ELLIPSIZE_END
            className="thumbnail-label"
          />
        </box>
      </eventbox>
    )
  }

  return (
    <scrollable className="thumbnail-grid-container" vexpand>
      <box className="thumbnail-grid">
        {bind(images).as(imgs => 
          imgs.map(image => createThumbnailItem(image))
        )}
      </box>
    </scrollable>
  )
} 