import { App } from "astal/gtk3"
import { WallpaperSelector } from "./wallpaper-selector/main"

App.start({
  main() {
    WallpaperSelector()
  }
}) 