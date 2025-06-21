import { App } from "astal/gtk3"
import style from "./style/wallpaper-selector.scss"
import WallpaperSelector from "./wallpaper-selector/main"

App.start({
    css: style,
    main() {
        App.get_monitors().map(WallpaperSelector)
    },
}) 