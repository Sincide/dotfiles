import GLib from 'gi://GLib'
import Gio from 'gi://Gio'
import { Variable } from 'astal'

// Promisify Gio methods
Gio._promisify(Gio.File.prototype, 'enumerate_children_async')
Gio._promisify(Gio.FileEnumerator.prototype, 'next_files_async')

export interface WallpaperImage {
  name: string
  path: string
  category: string
  size: number
  contentType: string
}

export class FileSystemService {
  private basePath: string
  private images = Variable<WallpaperImage[]>([])
  private categories = Variable<string[]>([])

  constructor(basePath: string = "/home/martin/dotfiles/assets/wallpapers") {
    this.basePath = basePath
    this.scanWallpapers()
  }

  async scanWallpapers() {
    try {
      const allImages: WallpaperImage[] = []
      const categorySet = new Set<string>()

      // Scan each category directory
      const baseDir = Gio.File.new_for_path(this.basePath)
      const enumerator = await baseDir.enumerate_children_async(
        'standard::name,standard::type',
        Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
        GLib.PRIORITY_DEFAULT,
        null
      )

      for await (const fileInfo of enumerator) {
        if (fileInfo.get_file_type() === Gio.FileType.DIRECTORY) {
          const categoryName = fileInfo.get_name()
          categorySet.add(categoryName)
          
          const categoryImages = await this.scanCategoryDirectory(categoryName)
          allImages.push(...categoryImages)
        }
      }

      this.categories.set(Array.from(categorySet).sort())
      this.images.set(allImages)
      
      console.log(`Loaded ${allImages.length} wallpapers from ${categorySet.size} categories`)
    } catch (error) {
      console.error("Failed to scan wallpapers:", error)
    }
  }

  private async scanCategoryDirectory(category: string): Promise<WallpaperImage[]> {
    const categoryPath = GLib.build_filenamev([this.basePath, category])
    const categoryDir = Gio.File.new_for_path(categoryPath)
    const images: WallpaperImage[] = []

    try {
      const enumerator = await categoryDir.enumerate_children_async(
        'standard::name,standard::type,standard::content-type,standard::size',
        Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
        GLib.PRIORITY_DEFAULT,
        null
      )

      for await (const fileInfo of enumerator) {
        if (this.isImageFile(fileInfo)) {
          images.push({
            name: fileInfo.get_name(),
            path: GLib.build_filenamev([categoryPath, fileInfo.get_name()]),
            category: category,
            size: fileInfo.get_size(),
            contentType: fileInfo.get_content_type() || ''
          })
        }
      }
    } catch (error) {
      console.error(`Failed to scan category ${category}:`, error)
    }

    return images
  }

  private isImageFile(fileInfo: any): boolean {
    const fileName = fileInfo.get_name().toLowerCase()
    const contentType = fileInfo.get_content_type() || ''
    
    const imageExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif']
    const imageMimeTypes = ['image/png', 'image/jpeg', 'image/webp', 'image/gif']
    
    return imageExtensions.some(ext => fileName.endsWith(ext)) ||
           imageMimeTypes.some(type => contentType.startsWith(type))
  }

  getImages() { return this.images }
  getCategories() { return this.categories }
  getImagesByCategory(category: string) {
    return this.images.get().filter(img => img.category === category)
  }
} 