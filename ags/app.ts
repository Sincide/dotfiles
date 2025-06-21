import { App } from "astal/gtk3"
import { TopBar } from "./widget/Bar/TopBar"
import { BottomBar } from "./widget/Bar/BottomBar"
import { Sidebar } from "./widget/Sidebar/Sidebar"
import { NotificationCenter } from "./widget/Notifications/NotificationCenter"
import { AppLauncher } from "./widget/Launcher/AppLauncher"
import { MONITOR_CONFIG } from "./config/monitors"
import "./style/main.scss"

App.start({
    css: "./style/main.scss",
    main() {
        // Create bars for each monitor
        for (let i = 0; i <= MONITOR_CONFIG.tertiary; i++) {
            TopBar(i)
            BottomBar(i)
        }
        
        // Create sidebar (only on primary monitor)
        Sidebar(MONITOR_CONFIG.primary)
        
        // Create notification center
        NotificationCenter()
        
        // Create application launcher
        AppLauncher()
    },
    
    requestHandler(request: string, res: (response: any) => void) {
        const parts = request.split(" ")
        const command = parts[0]
        
        switch (command) {
            case "toggle-sidebar":
                App.get_window("sidebar")?.set_visible(!App.get_window("sidebar")?.visible)
                res("ok")
                break
                
            case "toggle-launcher":
                App.get_window("launcher")?.set_visible(!App.get_window("launcher")?.visible)
                res("ok")
                break
                
            case "toggle-notifications":
                App.get_window("notifications")?.set_visible(!App.get_window("notifications")?.visible)
                res("ok")
                break
                
            default:
                res("unknown command")
        }
    }
}) 