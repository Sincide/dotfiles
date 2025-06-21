import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable } from "astal"
import CategorySidebar from "./components/CategorySidebar"
import ThumbnailGrid from "./components/ThumbnailGrid"
import ImagePreview from "./components/ImagePreview"
import { FileSystemService } from "./services/filesystem"
import { WallpaperService } from "./services/wallpaper"
import { MatugenService } from "./services/matugen"

// Initialize services
const fileSystemService = new FileSystemService()
const wallpaperService = new WallpaperService()
const matugenService = new MatugenService()

// State variables
const selectedCategory = Variable<string>("all")
const selectedImage = Variable<string | null>(null)
const categories = Variable<string[]>([])
const wallpapers = Variable<string[]>([])
const allWallpapers = Variable<Record<string, string[]>>({})

// Initialize data
async function initializeData() {
    try {
        const wallpaperData = await fileSystemService.scanWallpapers()
        const categoryList = Object.keys(wallpaperData)
        
        allWallpapers.set(wallpaperData)
        categories.set(["all", ...categoryList])
        
        // Set initial wallpapers to all
        const allPapers = Object.values(wallpaperData).flat()
        wallpapers.set(allPapers)
        
        console.log(`Loaded ${allPapers.length} wallpapers from ${categoryList.length} categories`)
    } catch (error) {
        console.error("Failed to initialize wallpaper data:", error)
    }
}

// Handle category selection
function handleCategorySelect(category: string) {
    selectedCategory.set(category)
    
    const allData = allWallpapers.get()
    if (category === "all") {
        const allPapers = Object.values(allData).flat()
        wallpapers.set(allPapers)
    } else {
        wallpapers.set(allData[category] || [])
    }
}

// Handle wallpaper selection
function handleWallpaperSelect(wallpaper: string) {
    selectedImage.set(wallpaper)
}

// Handle setting wallpaper
async function handleSetWallpaper(imagePath: string) {
    try {
        console.log(`Setting wallpaper: ${imagePath}`)
        
        // Set the wallpaper
        await wallpaperService.setWallpaper(imagePath)
        
        // Generate and apply colors
        await matugenService.generateColors(imagePath)
        
        console.log("Wallpaper and colors applied successfully")
    } catch (error) {
        console.error("Failed to set wallpaper:", error)
    }
}

// Handle preview close
function handlePreviewClose() {
    selectedImage.set(null)
}

export default function WallpaperSelector(gdkmonitor: Gdk.Monitor) {
    const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
    
    // Initialize data when component mounts
    initializeData()
    
    return <window
        className="WallpaperSelector"
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.NORMAL}
        anchor={TOP | LEFT | RIGHT | BOTTOM}
        application={App}
        keymode={Astal.Keymode.EXCLUSIVE}
        onKeyPressEvent={(self, event) => {
            if (event.get_keyval()[1] === Gdk.KEY_Escape) {
                App.quit()
            }
        }}
    >
        <box 
            className="main-container"
            orientation={Gtk.Orientation.HORIZONTAL}
        >
            <CategorySidebar
                categories={categories.get()}
                selectedCategory={selectedCategory}
                onCategorySelect={handleCategorySelect}
            />
            
            <box 
                className="content-area"
                orientation={Gtk.Orientation.VERTICAL}
                hexpand
            >
                <box 
                    className="header"
                    orientation={Gtk.Orientation.HORIZONTAL}
                    spacing={12}
                >
                    <label 
                        className="title"
                        label="Wallpaper Selector"
                        halign={Gtk.Align.START}
                        hexpand
                    />
                    <button 
                        className="close-button"
                        onClicked={() => App.quit()}
                    >
                        <label label="✕" />
                    </button>
                </box>
                
                <ThumbnailGrid
                    wallpapers={wallpapers}
                    onWallpaperSelect={handleWallpaperSelect}
                />
            </box>
        </box>
        
        <ImagePreview
            selectedImage={selectedImage}
            onClose={handlePreviewClose}
            onSetWallpaper={handleSetWallpaper}
        />
    </window>
} 