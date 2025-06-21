pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    // Expose config properties as aliases for easy access
    property alias theme: config.theme
    property alias barHeight: config.barHeight
    property alias showSeconds: config.showSeconds
    property alias enabledModules: config.enabledModules
    property alias transparency: config.transparency
    
    FileView {
        id: configFile
        path: `${Quickshell.env.HOME}/.config/quickshell/config.json`
        
        // Enable file watching for live reloading
        watchChanges: true
        onFileChanged: reload()
        
        // When changes are made to properties in the adapter, save them
        onAdapterUpdated: writeAdapter()
        
        JsonAdapter {
            id: config
            
            // Theme and appearance
            property string theme: "dark"
            property int barHeight: 32
            property real transparency: 0.9
            
            // Feature toggles
            property bool showSeconds: true
            property bool showDate: true
            property bool showWorkspaces: true
            property bool showSystemTray: true
            property bool showMediaControls: true
            property bool showSystemResources: true
            
            // Module configuration
            property list<string> enabledModules: [
                "clock", 
                "workspaces", 
                "tray", 
                "media", 
                "system"
            ]
            
            // Layout configuration
            property string primaryMonitor: "auto"
            property bool mirrorToAllMonitors: true
            property bool topBar: true
            property bool bottomBar: false
            
            // Color overrides (for when not using matugen)
            property var colorOverrides: ({})
            
            // Debug settings
            property bool debugMode: false
            property bool verboseLogging: false
        }
    }
    
    // Utility methods
    function saveConfig() {
        console.log("ConfigManager: Saving configuration")
        configFile.writeAdapter()
    }
    
    function resetConfig() {
        console.log("ConfigManager: Resetting to defaults")
        config.theme = "dark"
        config.barHeight = 32
        config.transparency = 0.9
        config.showSeconds = true
        config.showDate = true
        config.showWorkspaces = true
        config.showSystemTray = true
        config.showMediaControls = true
        config.showSystemResources = true
        config.enabledModules = ["clock", "workspaces", "tray", "media", "system"]
        config.primaryMonitor = "auto"
        config.mirrorToAllMonitors = true
        config.topBar = true
        config.bottomBar = false
        config.colorOverrides = ({})
        config.debugMode = false
        config.verboseLogging = false
    }
    
    function toggleModule(moduleName) {
        const modules = [...config.enabledModules]
        const index = modules.indexOf(moduleName)
        
        if (index >= 0) {
            modules.splice(index, 1)
        } else {
            modules.push(moduleName)
        }
        
        config.enabledModules = modules
        console.log(`ConfigManager: Toggled module ${moduleName}, enabled:`, modules)
    }
    
    function isModuleEnabled(moduleName) {
        return config.enabledModules.includes(moduleName)
    }
    
    // Debug logging
    Component.onCompleted: {
        console.log("ConfigManager: Initialized with config:", JSON.stringify({
            theme: config.theme,
            barHeight: config.barHeight,
            transparency: config.transparency,
            enabledModules: config.enabledModules
        }, null, 2))
    }
    
    // Log config changes in debug mode
    Connections {
        target: config
        function onThemeChanged() {
            if (config.debugMode) console.log("ConfigManager: Theme changed to:", config.theme)
        }
        function onBarHeightChanged() {
            if (config.debugMode) console.log("ConfigManager: Bar height changed to:", config.barHeight)
        }
        function onEnabledModulesChanged() {
            if (config.debugMode) console.log("ConfigManager: Enabled modules changed to:", config.enabledModules)
        }
    }
} 