import { Variable, bind } from 'astal'
import { Widget } from 'astal/gtk3'
import Gtk from 'gi://Gtk'
import type { WallpaperImage } from '../services/filesystem'

interface ImagePreviewProps {
  selectedImage: Variable<WallpaperImage | null>
  onApply: (image: WallpaperImage) => void
  onClose: () => void
}

export function ImagePreview({ selectedImage, onApply, onClose }: ImagePreviewProps) {
  return (
    <overlay>
      <eventbox 
        className="preview-backdrop"
        onButtonPressEvent={onClose}
      />
      
      <box className="preview-dialog" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        {bind(selectedImage).as(image => 
          image ? (
            <box orientation={Gtk.Orientation.VERTICAL} className="preview-content">
              <box className="preview-header">
                <label 
                  label={image.name.replace(/\.[^/.]+$/, "")} 
                  className="preview-title"
                />
                <button className="close-button" onClicked={onClose}>
                  <label label="×" />
                </button>
              </box>
              
              <image
                file={image.path}
                className="preview-image"
                widthRequest={600}
                heightRequest={400}
              />
              
              <box className="preview-controls">
                <button className="cancel-button" onClicked={onClose}>
                  <label label="Cancel" />
                </button>
                <button 
                  className="apply-button" 
                  onClicked={() => onApply(image)}
                >
                  <label label="Apply Wallpaper" />
                </button>
              </box>
            </box>
          ) : null
        )}
      </box>
    </overlay>
  )
} 