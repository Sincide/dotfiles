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

// Color utility functions for moderation
function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : null;
}

function rgbToHex(r, g, b) {
  return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

function getLuminance(r, g, b) {
  const [rs, gs, bs] = [r, g, b].map(c => {
    c = c / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}

function getContrastRatio(color1, color2) {
  const rgb1 = hexToRgb(color1);
  const rgb2 = hexToRgb(color2);
  if (!rgb1 || !rgb2) return 1;
  
  const lum1 = getLuminance(rgb1.r, rgb1.g, rgb1.b);
  const lum2 = getLuminance(rgb2.r, rgb2.g, rgb2.b);
  
  const brightest = Math.max(lum1, lum2);
  const darkest = Math.min(lum1, lum2);
  
  return (brightest + 0.05) / (darkest + 0.05);
}

function moderateColor(hex, intensity = 0.7) {
  const rgb = hexToRgb(hex);
  if (!rgb) return hex;
  
  // Reduce saturation for UI elements
  const max = Math.max(rgb.r, rgb.g, rgb.b);
  const min = Math.min(rgb.r, rgb.g, rgb.b);
  const range = max - min;
  
  if (range > 0) {
    const avg = (rgb.r + rgb.g + rgb.b) / 3;
    const newR = Math.round(avg + (rgb.r - avg) * intensity);
    const newG = Math.round(avg + (rgb.g - avg) * intensity);
    const newB = Math.round(avg + (rgb.b - avg) * intensity);
    
    return rgbToHex(
      Math.max(0, Math.min(255, newR)),
      Math.max(0, Math.min(255, newG)),
      Math.max(0, Math.min(255, newB))
    );
  }
  
  return hex;
}

function ensureMinContrastAgainst(foregroundColor, backgroundColor, minContrast = 4.5) {
  let testColor = foregroundColor;
  const bgRgb = hexToRgb(backgroundColor);
  if (!bgRgb) return foregroundColor;
  
  let currentContrast = getContrastRatio(testColor, backgroundColor);
  
  if (currentContrast >= minContrast) {
    return testColor;
  }
  
  // If contrast is too low, adjust brightness
  const rgb = hexToRgb(testColor);
  if (!rgb) return foregroundColor;
  
  const bgLum = getLuminance(bgRgb.r, bgRgb.g, bgRgb.b);
  
  // Determine if we should make the color lighter or darker
  const shouldLighten = bgLum < 0.5;
  const step = shouldLighten ? 20 : -20;
  
  for (let i = 0; i < 10; i++) {
    const adjustment = step * (i + 1);
    const newR = Math.max(0, Math.min(255, rgb.r + adjustment));
    const newG = Math.max(0, Math.min(255, rgb.g + adjustment));
    const newB = Math.max(0, Math.min(255, rgb.b + adjustment));
    
    testColor = rgbToHex(newR, newG, newB);
    currentContrast = getContrastRatio(testColor, backgroundColor);
    
    if (currentContrast >= minContrast) {
      break;
    }
  }
  
  return testColor;
}

// Update Firefox UI Theme
function updateFirefoxTheme(colors) {
  if (!colors || !colors.primary) {
    console.log('🎨 No colors available for Firefox theme');
    return;
  }

  // Use neutral base colors with just a tiny hint of wallpaper colors
  const neutralGray = "#3c3c3c";        // Base neutral gray
  const darkGray = "#2a2a2a";           // Darker neutral
  const lightGray = "#4a4a4a";          // Lighter neutral
  
  // Mix just 2-5% of the original color with neutral grays
  const subtleHint = (baseColor, wallpaperColor, mixPercent = 0.02) => {
    const base = hexToRgb(baseColor);
    const accent = hexToRgb(wallpaperColor);
    if (!base || !accent) return baseColor;
    
    const r = Math.round(base.r * (1 - mixPercent) + accent.r * mixPercent);
    const g = Math.round(base.g * (1 - mixPercent) + accent.g * mixPercent);
    const b = Math.round(base.b * (1 - mixPercent) + accent.b * mixPercent);
    
    return rgbToHex(r, g, b);
  };
  
  // Create barely tinted neutral colors
  const tintedPrimary = subtleHint(neutralGray, colors.primary, 0.03);    // 3% tint
  const tintedAccent = subtleHint(lightGray, colors.accent, 0.02);        // 2% tint  
  const tintedSecondary = subtleHint(darkGray, colors.secondary, 0.025);  // 2.5% tint
  const tintedFocus = subtleHint(neutralGray, colors.primary, 0.015);     // 1.5% tint
  
  console.log('🎨 Neutral theming with subtle tints applied:', {
    original: colors.primary,
    tintedPrimary: tintedPrimary,
    tintedFocus: tintedFocus
  });

  // Convert AI colors to Firefox theme format
  const firefoxTheme = {
    colors: {
      // Toolbar and address bar
      frame: colors.surface,                    // Main background (toolbar)
      tab_background_text: colors.onSurface,   // Text on inactive tabs
      tab_text: colors.onSurface,              // Text on active tab
      toolbar: colors.surface,                 // Toolbar background
      toolbar_text: colors.onSurface,          // Toolbar text
      
      // Address bar - use moderated colors
      toolbar_field: colors.surface,           // Address bar background
      toolbar_field_text: colors.onSurface,    // Address bar text
      toolbar_field_border: tintedSecondary,  // Address bar border
      toolbar_field_focus: tintedFocus,         // Address bar when focused (moderated)
      
      // Active tab - use moderated primary
      tab_selected: tintedPrimary,          // Active tab background (moderated)
      tab_background_separator: tintedSecondary, // Tab separators
      
      // Buttons and UI elements - use moderated colors
      button_background_hover: tintedFocus,     // Button hover (moderated)
      button_background_active: tintedAccent, // Button active (moderated)
      
      // Popup and menus
      popup: colors.surface,                   // Popup background
      popup_text: colors.onSurface,           // Popup text
      popup_border: tintedSecondary,       // Popup border
      popup_highlight: tintedPrimary,      // Popup highlight (moderated)
      
      // Sidebar
      sidebar: colors.surface,                 // Sidebar background
      sidebar_text: colors.onSurface,         // Sidebar text
      sidebar_border: tintedSecondary,     // Sidebar border
      
      // Accent colors
      ntp_background: colors.surface,         // New tab page background
      ntp_text: colors.onSurface,            // New tab page text
      
      // Bookmark toolbar
      bookmark_text: colors.onSurface,       // Bookmark text
      
      // Icons
      icons: colors.onSurface,               // Icon color
      icons_attention: tintedAccent,      // Attention icon color (moderated)
      
      // Tab line (active tab indicator)
      tab_line: tintedAccent,             // Active tab line (moderated)
      
      // Text selection
      textbox_border: tintedSecondary,    // Input borders
      
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
    console.log('🎨 Firefox UI theme updated with moderated colors:', tintedPrimary);
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