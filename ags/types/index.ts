// Type definitions for AGS Wallpaper Selector

export interface WallpaperImage {
  name: string
  path: string
  category: string
  size: number
  contentType: string
}

export interface MatugenColors {
  background: { default: { hex: string } }
  primary: { default: { hex: string } }
  secondary: { default: { hex: string } }
  surface: { default: { hex: string } }
}

export interface CategorySidebarProps {
  categories: import('astal').Variable<string[]>
  selectedCategory: import('astal').Variable<string>
  onCategorySelect: (category: string) => void
}

export interface ThumbnailGridProps {
  images: import('astal').Variable<WallpaperImage[]>
  onImageSelect: (image: WallpaperImage) => void
  thumbnailService: import('../wallpaper-selector/utils/thumbnails').ThumbnailService
}

export interface ImagePreviewProps {
  selectedImage: import('astal').Variable<WallpaperImage | null>
  onApply: (image: WallpaperImage) => void
  onClose: () => void
} 