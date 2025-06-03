// AI Colors Content Script
console.log('🎨 AI Color Injector loading on:', window.location.hostname);

class AIColorInjector {
  constructor() {
    this.colors = {};
    this.isEnabled = true;
    this.aggressiveMode = false;
    this.injectedStyle = null;
    this.debugIndicator = null;
    this.lastUpdate = 0;
    
    this.init();
  }
  
  async init() {
    try {
      await this.loadSettings();
      await this.getInitialColors();
      this.setupMessageListener();
      this.createDebugIndicator();
      this.injectColors();
      
      console.log('✅ AI Color Injector ready!');
    } catch (error) {
      console.log('⚠️ Could not get initial colors:', error.message);
      this.createDebugIndicator();
    }
  }
  
  async loadSettings() {
    return new Promise(resolve => {
      chrome.storage.sync.get({
        enabled: true,
        aggressiveMode: false
      }, (result) => {
        this.isEnabled = result.enabled;
        this.aggressiveMode = result.aggressiveMode;
        resolve();
      });
    });
  }
  
  async getInitialColors() {
    return new Promise((resolve, reject) => {
      chrome.runtime.sendMessage({ action: 'getColors' }, (response) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
          return;
        }
        if (response && response.colors) {
          this.colors = response.colors;
          this.isEnabled = response.enabled;
          resolve();
        } else {
          // Fallback to storage
          chrome.storage.local.get(['aiColors'], (result) => {
            if (result.aiColors) {
              this.colors = result.aiColors;
              resolve();
            } else {
              reject(new Error('No colors available'));
            }
          });
        }
      });
    });
  }
  
  setupMessageListener() {
    chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
      if (message.action === 'colorsUpdated') {
        this.colors = message.colors;
        this.lastUpdate = Date.now();
        this.injectColors();
        this.updateDebugIndicator();
        console.log('🎨 Colors updated from background');
      }
    });
  }
  
  generateCSS() {
    if (!this.colors || Object.keys(this.colors).length === 0) {
      return '';
    }
    
    let css = `
      /* AI Dynamic Colors - CSS Variables */
      :root {
        --ai-primary: ${this.colors.primary} !important;
        --ai-surface: ${this.colors.surface} !important;
        --ai-on-surface: ${this.colors.onSurface} !important;
        --ai-secondary: ${this.colors.secondary} !important;
        --ai-on-primary: ${this.colors.onPrimary} !important;
        --ai-accent: ${this.colors.accent} !important;
      }
      
      /* Enhanced normal mode styling */
      h1, h2, h3, .Header-link, .markdown-title {
        color: var(--ai-accent) !important;
      }
      
      .btn-primary, .btn[aria-label*="primary"] {
        background-color: var(--ai-primary) !important;
        border-color: var(--ai-primary) !important;
        color: var(--ai-on-primary) !important;
      }
      
      .btn-primary:hover {
        background-color: var(--ai-accent) !important;
        border-color: var(--ai-accent) !important;
      }
      
      /* GitHub specific improvements */
      .Header, .Header-item {
        background-color: var(--ai-surface) !important;
        border-color: var(--ai-secondary) !important;
      }
      
      .Box-header, .dashboard-sidebar .Box-header {
        background-color: var(--ai-surface) !important;
        border-color: var(--ai-secondary) !important;
        color: var(--ai-on-surface) !important;
      }
      
      .subnav-item.selected, .subnav-item[aria-current] {
        background-color: var(--ai-primary) !important;
        color: var(--ai-on-primary) !important;
      }
      
      /* Links and navigation */
      a.Link--primary, .navigation-item.selected {
        color: var(--ai-primary) !important;
      }
      
      a.Link--primary:hover {
        color: var(--ai-accent) !important;
      }
      
      /* Scrollbars */
      ::-webkit-scrollbar-thumb {
        background-color: var(--ai-secondary) !important;
      }
      
      ::-webkit-scrollbar-thumb:hover {
        background-color: var(--ai-accent) !important;
      }
    `;
    
    // Aggressive mode - much more dramatic changes
    if (this.aggressiveMode) {
      css += `
        /* Aggressive Mode - Full Color Override */
        body {
          background-color: var(--ai-surface) !important;
          color: var(--ai-on-surface) !important;
        }
        
        .application-main, .Layout-main {
          background-color: var(--ai-surface) !important;
        }
        
        .Box, .repository-content, .js-navigation-container {
          background-color: var(--ai-surface) !important;
          border-color: var(--ai-secondary) !important;
        }
        
        .Header, .header {
          background: linear-gradient(135deg, var(--ai-primary) 0%, var(--ai-accent) 100%) !important;
          color: var(--ai-on-primary) !important;
        }
        
        .Header-link, .header-nav-link {
          color: var(--ai-on-primary) !important;
        }
        
        .Header-link:hover {
          color: var(--ai-accent) !important;
        }
        
        /* Buttons and interactive elements */
        .btn, button {
          background-color: var(--ai-primary) !important;
          color: var(--ai-on-primary) !important;
          border-color: var(--ai-primary) !important;
        }
        
        .btn:hover, button:hover {
          background-color: var(--ai-accent) !important;
          border-color: var(--ai-accent) !important;
        }
        
        /* Sidebar and navigation */
        .dashboard-sidebar {
          background-color: var(--ai-surface) !important;
        }
        
        .dashboard-sidebar .Box {
          background-color: var(--ai-surface) !important;
          border-color: var(--ai-secondary) !important;
        }
        
        /* Feed and content areas */
        .js-recent-activity-container .Box-row {
          border-color: var(--ai-secondary) !important;
        }
        
        /* Forms and inputs */
        .form-control, .form-select {
          background-color: var(--ai-surface) !important;
          border-color: var(--ai-secondary) !important;
          color: var(--ai-on-surface) !important;
        }
        
        /* Code and syntax highlighting */
        .highlight, .blob-code, .pl-c {
          background-color: var(--ai-surface) !important;
        }
        
        /* Typography overrides */
        h1, h2, h3, h4, h5, h6 {
          color: var(--ai-accent) !important;
        }
        
        .markdown-body h1, .markdown-body h2, .markdown-body h3 {
          color: var(--ai-accent) !important;
          border-color: var(--ai-secondary) !important;
        }
        
        /* Special elements */
        .Label, .IssueLabel {
          background-color: var(--ai-primary) !important;
          color: var(--ai-on-primary) !important;
        }
        
        .Counter {
          background-color: var(--ai-secondary) !important;
          color: var(--ai-on-surface) !important;
        }
      `;
    }
    
    return css;
  }
  
  injectColors() {
    if (!this.isEnabled) {
      this.removeInjectedStyle();
      return;
    }
    
    const css = this.generateCSS();
    if (!css) return;
    
    // Remove existing style
    this.removeInjectedStyle();
    
    // Inject new style
    this.injectedStyle = document.createElement('style');
    this.injectedStyle.id = 'ai-dynamic-colors';
    this.injectedStyle.textContent = css;
    document.head.appendChild(this.injectedStyle);
    
    console.log('🎨 Injecting AI colors:', window.location.hostname);
  }
  
  removeInjectedStyle() {
    if (this.injectedStyle) {
      this.injectedStyle.remove();
      this.injectedStyle = null;
    }
  }
  
  createDebugIndicator() {
    if (!localStorage.getItem('ai-colors-debug')) return;
    
    this.debugIndicator = document.createElement('div');
    this.debugIndicator.id = 'ai-colors-debug';
    this.updateDebugIndicator();
    
    // Position in top-right corner
    Object.assign(this.debugIndicator.style, {
      position: 'fixed',
      top: '10px',
      right: '10px',
      background: 'rgba(0, 0, 0, 0.8)',
      color: 'white',
      padding: '8px 12px',
      borderRadius: '8px',
      fontSize: '12px',
      fontFamily: 'monospace',
      zIndex: '10000',
      border: '1px solid #444',
      lineHeight: '1.3'
    });
    
    document.body.appendChild(this.debugIndicator);
  }
  
  updateDebugIndicator() {
    if (!this.debugIndicator) return;
    
    const site = window.location.hostname.replace('www.', '');
    const harmony = this.colors.aiMetadata?.harmonyScore || '--';
    const access = this.colors.aiMetadata?.accessibilityLevel?.replace('WCAG_', '') || '--';
    const time = this.lastUpdate ? new Date(this.lastUpdate).toLocaleTimeString() : new Date().toLocaleTimeString();
    const mode = this.aggressiveMode ? 'Aggressive' : 'Normal';
    
    this.debugIndicator.innerHTML = `
      🤖 AI Colors Active<br>
      Site: ${site}<br>
      Harmony: ${harmony}/100<br>
      Access: ${access}<br>
      Updated: ${time}<br>
      Mode: ${mode}
    `;
  }
  
  // Update settings from storage changes
  updateSettings() {
    chrome.storage.sync.get({
      enabled: true,
      aggressiveMode: false
    }, (result) => {
      const wasEnabled = this.isEnabled;
      const wasAggressive = this.aggressiveMode;
      
      this.isEnabled = result.enabled;
      this.aggressiveMode = result.aggressiveMode;
      
      if (wasEnabled !== this.isEnabled || wasAggressive !== this.aggressiveMode) {
        this.injectColors();
        this.updateDebugIndicator();
      }
    });
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new AIColorInjector();
  });
} else {
  new AIColorInjector();
}

// Listen for storage changes
chrome.storage.onChanged.addListener((changes, areaName) => {
  if (areaName === 'sync' && window.aiColorInjector) {
    window.aiColorInjector.updateSettings();
  }
});

// Export for global access
window.aiColorInjector = new AIColorInjector();