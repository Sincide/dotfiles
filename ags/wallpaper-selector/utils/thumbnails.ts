import GdkPixbuf from 'gi://GdkPixbuf'
import { Variable } from 'astal'

export class ThumbnailService {
  private cache = new Map<string, GdkPixbuf.Pixbuf>()
  private thumbnailSize: number
  private loadingSet = new Set<string>()

  constructor(thumbnailSize: number = 200) {
    this.thumbnailSize = thumbnailSize
  }

  async generateThumbnail(imagePath: string): Promise<GdkPixbuf.Pixbuf | null> {
    // Check cache first
    if (this.cache.has(imagePath)) {
      return this.cache.get(imagePath)!
    }

    // Prevent duplicate loading
    if (this.loadingSet.has(imagePath)) {
      return null
    }

    this.loadingSet.add(imagePath)

    try {
      // Load original image
      const originalPixbuf = GdkPixbuf.Pixbuf.new_from_file(imagePath)
      
      // Calculate scaling maintaining aspect ratio
      const originalWidth = originalPixbuf.get_width()
      const originalHeight = originalPixbuf.get_height()
      const aspectRatio = originalWidth / originalHeight
      
      let newWidth: number, newHeight: number
      if (aspectRatio > 1) {
        newWidth = this.thumbnailSize
        newHeight = Math.round(this.thumbnailSize / aspectRatio)
      } else {
        newHeight = this.thumbnailSize
        newWidth = Math.round(this.thumbnailSize * aspectRatio)
      }
      
      // Scale the image
      const thumbnail = originalPixbuf.scale_simple(
        newWidth,
        newHeight,
        GdkPixbuf.InterpType.BILINEAR
      )
      
      // Cache the result
      this.cache.set(imagePath, thumbnail)
      
      return thumbnail
    } catch (error) {
      console.error(`Failed to generate thumbnail for ${imagePath}:`, error)
      return null
    } finally {
      this.loadingSet.delete(imagePath)
    }
  }

  clearCache() {
    this.cache.clear()
  }
} 