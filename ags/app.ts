import { App } from "astal/gtk3"
import style from "./style.scss"
import Sidebar, { createTrigger } from "./widget/Sidebar"

App.start({
    css: style,
    main() {
        // Create sidebar and trigger for each monitor
        App.get_monitors().map(monitor => {
            // Create the hover trigger (always visible)
            createTrigger(monitor)
            
            // Create the main sidebar (shows on hover)
            Sidebar(monitor)
        })
    },
})
