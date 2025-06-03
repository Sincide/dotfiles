class PopupController {
  constructor() {
    this.colors = {};
    this.isEnabled = true;
    this.aggressiveMode = false;
    this.status = {};
    this.initializePopup();
  }
  async initializePopup() {
    try {
      console.log('🎛️ Popup loading from storage...');
      
      // Get data from storage instead of messaging
      const [settings, aiColorsData] = await Promise.all([
        new Promise(resolve => chrome.storage.sync.get({ 
          enabled: true, 
          aggressiveMode: false 
        }, resolve)),
        new Promise(resolve => chrome.storage.local.get(['aiColors'], resolve))
      ]);
      
      this.isEnabled = settings.enabled;
      this.aggressiveMode = settings.aggressiveMode;
      this.colors = aiColorsData.aiColors || {};
      
      console.log('🎛️ Loaded from storage:', this.isEnabled, Object.keys(this.colors).length);
      
      this.updateUI();
      this.setupEventListeners();
      document.getElementById('loading').style.display = 'none';
      document.getElementById('main-content').style.display = 'block';
      
    } catch (error) {
      console.error('Failed to initialize popup:', error);
      document.getElementById('loading').innerHTML = '❌ Failed to load: ' + error.message;
    }
  }
  updateUI() {
    this.updateStatus();
    this.updateToggles();
    this.updateColorsGrid();
    this.updateStats();
  }
  updateStatus() {
    const statusEl = document.getElementById('status');
    const statusTextEl = document.getElementById('status-text');
    if (this.isEnabled && Object.keys(this.colors).length > 0) {
      statusEl.className = 'status enabled';
      statusTextEl.textContent = '🟢 AI colors active';
    } else if (this.isEnabled) {
      statusEl.className = 'status enabled';
      statusTextEl.textContent = '🟡 AI enabled, no colors loaded';
    } else {
      statusEl.className = 'status disabled';
      statusTextEl.textContent = '🔴 AI colors disabled';
    }
  }
  updateToggles() {
    const enableToggle = document.getElementById('enable-toggle');
    const aggressiveToggle = document.getElementById('aggressive-toggle');
    enableToggle.className = this.isEnabled ? 'toggle active' : 'toggle';
    aggressiveToggle.className = this.aggressiveMode ? 'toggle active' : 'toggle';
  }
  updateColorsGrid() {
    const gridEl = document.getElementById('colors-grid');
    if (Object.keys(this.colors).length === 0) {
      gridEl.innerHTML = '<div style="grid-column: 1 / -1; text-align: center; color: #6c7086; padding: 20px;">No colors loaded</div>';
      return;
    }
    const colorSwatches = [
      { name: 'Primary', color: this.colors.primary, text: this.colors.onPrimary },
      { name: 'Surface', color: this.colors.surface, text: this.colors.onSurface },
      { name: 'Accent', color: this.colors.accent, text: this.colors.onSurface }
    ];
    gridEl.innerHTML = colorSwatches.map(swatch => `
      <div class="color-swatch"
           style="background: ${swatch.color || '#45475a'}; color: ${swatch.text || '#cdd6f4'};">
        ${swatch.name}
      </div>
    `).join('');
  }
  updateStats() {
    const harmonyEl = document.getElementById('harmony-score');
    const accessibilityEl = document.getElementById('accessibility-level');
    if (this.colors.aiMetadata) {
      harmonyEl.textContent = `${this.colors.aiMetadata.harmonyScore || '--'}/100`;
      const accessLevel = this.colors.aiMetadata.accessibilityLevel || '--';
      accessibilityEl.textContent = accessLevel.replace('WCAG_', '');
    } else {
      harmonyEl.textContent = '--';
      accessibilityEl.textContent = '--';
    }
  }
  setupEventListeners() {
    document.getElementById('enable-toggle').addEventListener('click', async () => {
      try {
        const response = await chrome.runtime.sendMessage({ action: 'toggleEnabled' });
        this.isEnabled = response.enabled;
        this.updateUI();
      } catch (error) {
        console.error('Failed to toggle enabled:', error);
      }
    });
    document.getElementById('aggressive-toggle').addEventListener('click', async () => {
      this.aggressiveMode = !this.aggressiveMode;
      await chrome.storage.sync.set({ aggressiveMode: this.aggressiveMode });
      this.updateUI();
    });
    document.getElementById('refresh-btn').addEventListener('click', async () => {
      try {
        await chrome.runtime.sendMessage({ action: 'forceRefresh' });
        setTimeout(() => window.location.reload(), 500);
      } catch (error) {
        console.error('Failed to refresh:', error);
      }
    });
    document.getElementById('options-btn').addEventListener('click', () => {
      chrome.runtime.openOptionsPage();
    });
  }
}
document.addEventListener('DOMContentLoaded', () => {
  new PopupController();
});
