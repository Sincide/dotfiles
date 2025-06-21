import { Variable, bind } from 'astal'
import { Widget } from 'astal/gtk3'
import Gtk from 'gi://Gtk'
import { FileSystemService, type WallpaperImage } from './services/filesystem'
import { WallpaperService } from './services/wallpaper'
import { ThumbnailService } from './utils/thumbnails'
import { CategorySidebar } from './components/CategorySidebar'
import { ThumbnailGrid } from './components/ThumbnailGrid'
import { ImagePreview } from './components/ImagePreview'

export function WallpaperSelector() {
  // Services
  const fileSystemService = new FileSystemService()
  const wallpaperService = new WallpaperService()
  const thumbnailService = new ThumbnailService(180)

  // State
  const selectedCategory = Variable<string>("abstract")
  const selectedImage = Variable<WallpaperImage | null>(null)
  const showPreview = Variable<boolean>(false)
  const filteredImages = Variable<WallpaperImage[]>([])

  // Update filtered images when category changes
  selectedCategory.subscribe(category => {
    const images = fileSystemService.getImagesByCategory(category)
    filteredImages.set(images)
  })

  // Initialize with first category
  fileSystemService.getCategories().subscribe(categories => {
    if (categories.length > 0 && !selectedCategory.get()) {
      selectedCategory.set(categories[0])
    }
  })

  function handleCategorySelect(category: string) {
    selectedCategory.set(category)
  }

  function handleImageSelect(image: WallpaperImage) {
    selectedImage.set(image)
    showPreview.set(true)
  }

  function handleClosePreview() {
    showPreview.set(false)
    selectedImage.set(null)
  }

  async function handleApplyWallpaper(image: WallpaperImage) {
    try {
      const success = await wallpaperService.setWallpaper(image.path, true)
      if (success) {
        console.log(`Applied wallpaper: ${image.name}`)
        handleClosePreview()
      } else {
        console.error("Failed to apply wallpaper")
      }
    } catch (error) {
      console.error("Error applying wallpaper:", error)
    }
  }

  const mainWindow = (
    <window
      className="wallpaper-selector"
      name="wallpaper-selector"
      title="Wallpaper Selector"
      defaultWidth={1200}
      defaultHeight={800}
      resizable={true}
    >
      <overlay>
        <box orientation={Gtk.Orientation.HORIZONTAL}>
          <CategorySidebar
            categories={fileSystemService.getCategories()}
            selectedCategory={selectedCategory}
            onCategorySelect={handleCategorySelect}
          />
          
          <separator orientation={Gtk.Orientation.VERTICAL} />
          
          <box className="main-content" hexpand>
            <box className="content-header">
              <label 
                label={bind(selectedCategory).as(cat => 
                  `${cat.charAt(0).toUpperCase() + cat.slice(1)} Wallpapers`
                )}
                className="content-title"
              />
            </box>
            
            <ThumbnailGrid
              images={filteredImages}
              onImageSelect={handleImageSelect}
              thumbnailService={thumbnailService}
            />
          </box>
        </box>
        
        {bind(showPreview).as(show => 
          show ? (
            <ImagePreview
              selectedImage={selectedImage}
              onApply={handleApplyWallpaper}
              onClose={handleClosePreview}
            />
          ) : null
        )}
      </overlay>
    </window>
  )

  return mainWindow
} 