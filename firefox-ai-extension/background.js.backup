// Firefox AI Colors - Background Script (Manifest v2)
console.log('🤖 AI Colors Background starting...');

let currentColors = {};
let isEnabled = true;
let lastUpdate = 0;
let serverAvailable = false;

// Initialize extension
async function initializeExtension() {
  console.log('🚀 Initializing AI Color Manager...');
  
  // Load settings
  const result = await new Promise(resolve => {
    chrome.storage.sync.get({
      enabled: true,
      aggressiveMode: false
    }, resolve);
  });
  
  isEnabled = result.enabled;
  
  await loadInitialColors();
  startColorMonitoring();
  
  console.log('✅ AI Color Manager ready!');
}

// Load colors from local AI server
async function loadColorsFromServer() {
  try {
    console.log('🌐 Fetching colors from AI server...');
    
    const response = await fetch('http://localhost:8080/ai-colors');
    if (!response.ok) {
      throw new Error(`Server responded with ${response.status}`);
    }
    
    const serverColors = await response.json();
    console.log('🎨 Got colors from server:', serverColors);
    
    // Convert server format to extension format
    const extensionColors = {
      primary: serverColors.primary || '#6366f1',
      surface: serverColors.surface || '#1e1e2e', 
      onSurface: serverColors.onSurface || '#cdd6f4',
      secondary: serverColors.secondary || '#a6adc8',
      onPrimary: serverColors.onPrimary || '#ffffff',
      accent: serverColors.accent || '#f38ba8',
      aiMetadata: {
        harmonyScore: serverColors.harmonyScore || 85,
        accessibilityLevel: serverColors.accessibilityLevel || 'WCAG_AA',
        timestamp: new Date().toISOString(),
        source: 'ai-wallpaper-server',
        wallpaperPath: serverColors.wallpaperPath || 'unknown'
      }
    };
    
    await updateColors(extensionColors);
    serverAvailable = true;
    console.log('✅ Updated colors from AI server');
    return true;
    
  } catch (error) {
    console.log('❌ Failed to load from server:', error.message);
    serverAvailable = false;
    
    // Only fallback to demo if we don't have any colors yet
    if (Object.keys(currentColors).length === 0) {
      console.log('🔄 Falling back to demo colors...');
      await loadDemoColors();
    }
    return false;
  }
}

// Load demo colors (fallback)
async function loadDemoColors() {
  const demoColors = {
    primary: '#6366f1',
    surface: '#1e1e2e',
    onSurface: '#cdd6f4',
    secondary: '#a6adc8',
    onPrimary: '#ffffff',
    accent: '#f38ba8',
    aiMetadata: {
      harmonyScore: 87,
      accessibilityLevel: 'WCAG_AAA',
      timestamp: new Date().toISOString(),
      source: 'demo'
    }
  };
  
  await updateColors(demoColors);
  console.log('🎨 Loaded demo colors');
}

async function loadInitialColors() {
  // Try server first, fallback to demo if needed
  const serverSuccess = await loadColorsFromServer();
  if (!serverSuccess) {
    console.log('🎯 Server not available, using demo colors');
  }
}

// Update Firefox UI Theme
function updateFirefoxTheme(colors) {
  if (!colors || !colors.primary) {
    console.log('🎨 No colors available for Firefox theme');
    return;
  }

  // Convert AI colors to Firefox theme format
  const firefoxTheme = {
    colors: {
      // Toolbar and address bar
      frame: colors.surface,                    // Main background (toolbar)
      tab_background_text: colors.onSurface,   // Text on inactive tabs
      tab_text: colors.onSurface,              // Text on active tab
      toolbar: colors.surface,                 // Toolbar background
      toolbar_text: colors.onSurface,          // Toolbar text
      
      // Address bar
      toolbar_field: colors.surface,           // Address bar background
      toolbar_field_text: colors.onSurface,    // Address bar text
      toolbar_field_border: colors.secondary,  // Address bar border
      toolbar_field_focus: colors.primary,     // Address bar when focused
      
      // Active tab
      tab_selected: colors.primary,            // Active tab background
      tab_background_separator: colors.secondary, // Tab separators
      
      // Buttons and UI elements
      button_background_hover: colors.primary, // Button hover
      button_background_active: colors.accent, // Button active
      
      // Popup and menus
      popup: colors.surface,                   // Popup background
      popup_text: colors.onSurface,           // Popup text
      popup_border: colors.secondary,         // Popup border
      popup_highlight: colors.primary,        // Popup highlight
      
      // Sidebar
      sidebar: colors.surface,                 // Sidebar background
      sidebar_text: colors.onSurface,         // Sidebar text
      sidebar_border: colors.secondary,       // Sidebar border
      
      // Accent colors
      ntp_background: colors.surface,         // New tab page background
      ntp_text: colors.onSurface,            // New tab page text
      
      // Bookmark toolbar
      bookmark_text: colors.onSurface,       // Bookmark text
      
      // Icons
      icons: colors.onSurface,               // Icon color
      icons_attention: colors.accent,        // Attention icon color
      
      // Tab line (active tab indicator)
      tab_line: colors.accent,              // Active tab line
      
      // Text selection
      textbox_border: colors.secondary,     // Input borders
      
      // Find bar
      findbar: colors.surface,             // Find bar background
      findbar_text: colors.onSurface       // Find bar text
    },
    
    // Custom properties for consistency
    properties: {
      color_scheme: "dark",
      content_color_scheme: "dark"
    }
  };

  // Update Firefox theme
  try {
    browser.theme.update(firefoxTheme);
    console.log('🎨 Firefox UI theme updated with colors:', colors.primary);
  } catch (error) {
    console.log('❌ Failed to update Firefox theme:', error);
  }
}

// Reset Firefox theme to default
function resetFirefoxTheme() {
  try {
    browser.theme.reset();
    console.log('🔄 Firefox theme reset to default');
  } catch (error) {
    console.log('❌ Failed to reset Firefox theme:', error);
  }
}

async function updateColors(colors) {
  currentColors = {
    ...colors,
    lastUpdate: Date.now()
  };
  
  lastUpdate = Date.now();
  
  console.log('🎨 Colors updated:', currentColors.primary);
  
  // Save to storage
  chrome.storage.local.set({ aiColors: currentColors });
  
  // Update Firefox UI theme
  updateFirefoxTheme(currentColors);
  
  // Notify content scripts
  notifyContentScripts({
    action: 'colorsUpdated',
    colors: currentColors
  });
}

function notifyContentScripts(message) {
  chrome.tabs.query({}, (tabs) => {
    tabs.forEach(tab => {
      chrome.tabs.sendMessage(tab.id, message, () => {
        // Ignore errors for tabs without content scripts
        chrome.runtime.lastError;
      });
    });
  });
}

function startColorMonitoring() {
  console.log('🔄 Starting real-time color monitoring...');
  
  // Check for updates every 5 seconds
  setInterval(async () => {
    if (isEnabled) {
      const success = await loadColorsFromServer();
      if (success && !serverAvailable) {
        console.log('🔗 AI server reconnected!');
      } else if (!success && serverAvailable) {
        console.log('💔 AI server disconnected');
      }
    }
  }, 5000);
  
  // Also check every minute for longer interval updates
  setInterval(async () => {
    if (isEnabled) {
      console.log('⏰ Periodic color check...');
      await loadColorsFromServer();
    }
  }, 60000);
}

// Message handling
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('📨 Background received message:', request.action, 'from:', sender.tab?.url || 'popup');
  
  // Handle each action
  if (request.action === 'getColors') {
    console.log('🎨 Sending colors:', Object.keys(currentColors).length, 'colors');
    sendResponse({ colors: currentColors, enabled: isEnabled });
    return true;
  }
  
  if (request.action === 'getStatus') {
    console.log('📊 Sending status:', isEnabled, lastUpdate);
    sendResponse({
      enabled: isEnabled,
      lastUpdate: lastUpdate,
      colorsCount: Object.keys(currentColors).length,
      serverAvailable: serverAvailable,
      source: currentColors.aiMetadata?.source || 'unknown'
    });
    return true;
  }
  
  if (request.action === 'toggleEnabled') {
    isEnabled = !isEnabled;
    chrome.storage.sync.set({ enabled: isEnabled });
    console.log('🔄 Toggled to:', isEnabled);
    
    if (isEnabled) {
      // Re-inject colors when enabled
      updateFirefoxTheme(currentColors);
      notifyContentScripts({
        action: 'colorsUpdated',
        colors: currentColors
      });
    } else {
      // Remove colors when disabled
      resetFirefoxTheme();
      notifyContentScripts({
        action: 'colorsDisabled'
      });
    }
    
    sendResponse({ enabled: isEnabled });
    return true;
  }
  
  if (request.action === 'forceRefresh') {
    console.log('🔄 Force refreshing colors...');
    loadColorsFromServer().then(() => {
      sendResponse({ success: true, serverAvailable: serverAvailable });
    });
    return true;
  }
  
  return true; // Keep message channel open
});

// Initialize when background starts
initializeExtension();

// Periodic health check
setInterval(() => {
  console.log('🩺 Health check:', {
    enabled: isEnabled,
    colors: Object.keys(currentColors).length,
    server: serverAvailable,
    lastUpdate: new Date(lastUpdate).toLocaleTimeString(),
    firefoxTheme: isEnabled ? 'active' : 'default'
  });
}, 300000); // Every 5 minutes

console.log('🤖 Background script fully loaded and ready for messages');