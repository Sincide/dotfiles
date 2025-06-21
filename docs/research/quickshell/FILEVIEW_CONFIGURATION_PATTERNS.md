# QuickShell FileView Configuration Patterns

## Research Summary
Date: 2025-01-27
Status: ✅ SOLVED - Correct API patterns identified

## The Problem
Initial attempts to use FileView for configuration loading failed because:
1. Used non-existent `onContentChanged` property 
2. Attempted to parse JSON manually with `JSON.parse()`
3. Tried to create Singleton registration patterns that don't exist

## The Correct Solution: FileView + JsonAdapter

### Basic Pattern
```qml
import Quickshell.Io

FileView {
    path: "/path/to/config.json"
    
    // Enable file watching for live reloading
    watchChanges: true
    onFileChanged: reload()
    
    // When changes are made to properties in the adapter, save them
    onAdapterUpdated: writeAdapter()
    
    JsonAdapter {
        property string someConfigValue: "default"
        property bool someToggle: false
        property list<string> someList: ["default", "values"]
        property var complexObject: { "key": "value" }
        
        // Property change handlers work normally
        onSomeConfigValueChanged: {
            console.log("Config value changed:", someConfigValue)
        }
    }
}
```

### Key FileView Properties & Signals
- `path: string` - Path to the JSON file
- `watchChanges: bool` - Enable file system watching
- `onFileChanged` - Signal when file changes on disk
- `onAdapterUpdated` - Signal when JsonAdapter properties change
- `reload()` - Method to reload file content
- `writeAdapter()` - Method to save adapter state to file

### Key JsonAdapter Features
- Properties automatically sync with JSON file structure
- Supports primitives: `int`, `bool`, `string`, `real`
- Supports lists: `list<string>`, `list<int>`, etc.
- Supports sub-objects via `JsonObject` type
- Supports raw JSON via `var` type
- Property change signals work normally (`onPropertyChanged`)

### JSON File Structure
The JsonAdapter creates this structure automatically:
```json
{
   "someConfigValue": "default",
   "someToggle": false,
   "someList": ["default", "values"],
   "complexObject": {
     "key": "value"
   }
}
```

## Working Configuration System Example

### services/ConfigManager.qml
```qml
pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    property alias theme: config.theme
    property alias barHeight: config.barHeight
    property alias showSeconds: config.showSeconds
    
    FileView {
        id: configFile
        path: `${Quickshell.env.HOME}/.config/quickshell/config.json`
        
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        
        JsonAdapter {
            id: config
            property string theme: "dark"
            property int barHeight: 32
            property bool showSeconds: true
            property list<string> enabledModules: ["clock", "workspaces", "tray"]
        }
    }
    
    // Expose methods
    function saveConfig() {
        configFile.writeAdapter()
    }
    
    function resetConfig() {
        config.theme = "dark"
        config.barHeight = 32
        config.showSeconds = true
        config.enabledModules = ["clock", "workspaces", "tray"]
    }
}
```

### Usage in Components
```qml
import Quickshell

Text {
    text: ConfigManager.showSeconds ? 
          Qt.formatDateTime(new Date(), "hh:mm:ss") :
          Qt.formatDateTime(new Date(), "hh:mm")
    
    // React to config changes
    Connections {
        target: ConfigManager
        function onShowSecondsChanged() {
            console.log("Seconds display toggled:", ConfigManager.showSeconds)
        }
    }
}
```

## Why Previous Attempts Failed

### ❌ Wrong: Manual JSON Parsing
```qml
FileView {
    property var config: ({})
    onContentChanged: {  // This property doesn't exist!
        try {
            config = JSON.parse(content || "{}")
        } catch (e) {
            console.error("Config parse error:", e)
        }
    }
}
```

### ❌ Wrong: Singleton Registration
```qml
// qmldir file attempts - this pattern doesn't work in QuickShell
singleton ConfigLoader 1.0 ConfigLoader.qml
```

### ✅ Correct: JsonAdapter Pattern
```qml
FileView {
    JsonAdapter {
        property string value: "default"
        // Properties automatically sync with JSON
    }
}
```

## Benefits of Correct Pattern
1. **Automatic JSON handling** - No manual parsing needed
2. **Reactive properties** - Changes automatically propagate
3. **File watching** - Live reloads when config file changes
4. **Two-way sync** - Can save changes back to file
5. **Type safety** - Properties have defined types
6. **Default values** - Built-in fallback system

## Best Practices
1. Always use `watchChanges: true` for live config reloading
2. Define sensible default values for all properties
3. Use specific types instead of `var` when possible
4. Handle file write permissions gracefully
5. Use Singleton pattern for global configuration access

## Integration with Existing Systems
- Works perfectly with existing matugen color pipeline
- Can load colors from `~/.local/state/quickshell/user/generated/colors.json`
- Supports complex nested configuration structures
- Compatible with all QuickShell component patterns

## Source
- QuickShell JsonAdapter Documentation: https://quickshell.outfoxxed.me/docs/types/Quickshell.Io/JsonAdapter
- Discovered through web search after initial API assumptions were incorrect 