import { execAsync } from 'astal'
import { Variable } from 'astal'
import { detectDesktopEnvironment } from '../utils/desktop-env'
import { MatugenService } from './matugen'

export class WallpaperService {
  private currentWallpaper = Variable<string>("")
  private matugenService = new MatugenService()
  private desktopEnv: string

  constructor() {
    this.desktopEnv = detectDesktopEnvironment()
  }

  async setWallpaper(imagePath: string, generateColors: boolean = true): Promise<boolean> {
    try {
      // Set wallpaper based on desktop environment
      await this.setWallpaperByDE(imagePath)
      
      // Generate and apply colors if requested
      if (generateColors) {
        const colors = await this.matugenService.generateAndApplyColors(imagePath)
        if (colors) {
          console.log("Generated colors:", colors)
        }
      }
      
      this.currentWallpaper.set(imagePath)
      return true
    } catch (error) {
      console.error("Failed to set wallpaper:", error)
      return false
    }
  }

  private async setWallpaperByDE(imagePath: string) {
    const methods: Record<string, () => Promise<void>> = {
      gnome: () => execAsync(`gsettings set org.gnome.desktop.background picture-uri "file://${imagePath}"`),
      kde: () => this.setKdeWallpaper(imagePath),
      xfce: () => execAsync(`xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/workspace0/last-image -s "${imagePath}"`),
      mate: () => execAsync(`gsettings set org.mate.desktop.background picture-uri "file://${imagePath}"`),
      unknown: () => execAsync(`feh --bg-scale "${imagePath}"`)
    }

    const method = methods[this.desktopEnv] || methods.unknown
    await method()
  }

  private async setKdeWallpaper(imagePath: string) {
    const script = `
    var Desktops = desktops();
    for (i=0;i<Desktops.length;i++) {
        d = Desktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
        d.writeConfig('Image', 'file://${imagePath}')
    }`
    
    await execAsync(`qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${script}"`)
  }

  getCurrentWallpaper() { return this.currentWallpaper }
} 