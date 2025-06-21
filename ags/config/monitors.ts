export const MONITOR_CONFIG = {
    primary: 0,
    secondary: 1,
    tertiary: 2,
    layouts: {
        dual_bars: true,
        sidebar_monitor: 0,
        top_modules: ["workspaces", "window-title", "clock", "systray"],
        bottom_modules: ["media", "system-info", "network"]
    }
}

export const SIDEBAR_CONFIG = {
    width: 350,
    height: "100%",
    position: "left",
    anchor: ["left", "top", "bottom"],
    exclusive: false, // Overlay mode
    layer: "overlay"
}

export const BAR_CONFIG = {
    height: 32,
    exclusive: true,
    layer: "top"
} 