/**
 * GPTDiag Dashboard JavaScript
 * Main dashboard functionality for real-time system monitoring and AI integration
 */

class GPTDiagDashboard {
    constructor() {
        this.apiBase = window.location.origin;
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 1000;
        
        // Data storage for charts
        this.systemData = {
            cpu: [],
            memory: [],
            disk: [],
            timestamps: []
        };
        this.maxDataPoints = 50;
        
        // UI elements
        this.elements = {
            connectionStatus: document.getElementById('connection-status'),
            aiStatus: document.getElementById('ai-status'),
            cpuValue: document.getElementById('cpu-value'),
            memoryValue: document.getElementById('memory-value'),
            diskValue: document.getElementById('disk-value'),
            cpuCores: document.getElementById('cpu-cores'),
            cpuLoad: document.getElementById('cpu-load'),
            memoryTotal: document.getElementById('memory-total'),
            memoryAvailable: document.getElementById('memory-available'),
            diskTotal: document.getElementById('disk-total'),
            diskFree: document.getElementById('disk-free'),
            uptimeValue: document.getElementById('uptime-value'),
            processesValue: document.getElementById('processes-value'),
            loadAvgValue: document.getElementById('load-avg-value'),
            lastUpdate: document.getElementById('last-update'),
            analyzeBtn: document.getElementById('analyze-btn'),
            aiContent: document.getElementById('ai-content'),
            aiLoading: document.getElementById('ai-loading'),
            alertsSection: document.getElementById('alerts-section'),
            alertsList: document.getElementById('alerts-list')
        };
        
        this.init();
    }
    
    async init() {
        console.log('🚀 Initializing GPTDiag Dashboard');
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Initialize charts
        await this.initializeCharts();
        
        // Connect to WebSocket
        this.connectWebSocket();
        
        // Initial data load
        await this.loadInitialData();
        
        console.log('✅ Dashboard initialized successfully');
    }
    
    setupEventListeners() {
        // AI Analysis button
        if (this.elements.analyzeBtn) {
            this.elements.analyzeBtn.addEventListener('click', () => this.runAIAnalysis());
        }
        
        // Window events
        window.addEventListener('beforeunload', () => {
            if (this.ws) {
                this.ws.close();
            }
        });
        
        // Visibility change handling
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                // Page hidden - reduce update frequency or pause
                console.log('📱 Dashboard hidden, reducing updates');
            } else {
                // Page visible - resume normal operation
                console.log('👁️ Dashboard visible, resuming updates');
                if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
                    this.connectWebSocket();
                }
            }
        });
    }
    
    async loadInitialData() {
        try {
            // Load system summary
            const summaryResponse = await fetch(`${this.apiBase}/api/system/summary`);
            if (summaryResponse.ok) {
                const summary = await summaryResponse.json();
                this.updateSystemMetrics(summary);
            }
            
            // Load detailed system info
            const detailedResponse = await fetch(`${this.apiBase}/api/system/detailed`);
            if (detailedResponse.ok) {
                const detailed = await detailedResponse.json();
                this.updateDetailedInfo(detailed);
            }
            
            // Check AI status
            const healthResponse = await fetch(`${this.apiBase}/`);
            if (healthResponse.ok) {
                const health = await healthResponse.json();
                this.updateAIStatus(health.ai_available);
            }
            
        } catch (error) {
            console.error('❌ Failed to load initial data:', error);
            this.showError('Failed to load initial system data');
        }
    }
    
    connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/updates`;
        
        console.log('🔌 Connecting to WebSocket:', wsUrl);
        
        try {
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = () => {
                console.log('✅ WebSocket connected');
                this.reconnectAttempts = 0;
                this.updateConnectionStatus('connected');
                
                // Send ping to keep connection alive
                this.sendPing();
                this.pingInterval = setInterval(() => this.sendPing(), 30000);
            };
            
            this.ws.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    this.handleWebSocketMessage(data);
                } catch (error) {
                    console.error('❌ WebSocket message parse error:', error);
                }
            };
            
            this.ws.onclose = (event) => {
                console.log('🔌 WebSocket disconnected:', event.code, event.reason);
                this.updateConnectionStatus('disconnected');
                
                if (this.pingInterval) {
                    clearInterval(this.pingInterval);
                }
                
                // Attempt reconnection
                if (this.reconnectAttempts < this.maxReconnectAttempts) {
                    this.reconnectAttempts++;
                    console.log(`🔄 Attempting reconnection ${this.reconnectAttempts}/${this.maxReconnectAttempts}`);
                    setTimeout(() => this.connectWebSocket(), this.reconnectDelay * this.reconnectAttempts);
                }
            };
            
            this.ws.onerror = (error) => {
                console.error('❌ WebSocket error:', error);
                this.updateConnectionStatus('error');
            };
            
        } catch (error) {
            console.error('❌ WebSocket connection failed:', error);
            this.updateConnectionStatus('error');
        }
    }
    
    sendPing() {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({ type: 'ping' }));
        }
    }
    
    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'initial_data':
                console.log('📊 Received initial data');
                this.updateSystemMetrics(data.data);
                break;
                
            case 'system_update':
                console.log('🔄 Received system update');
                this.updateSystemMetrics(data.data);
                this.updateChartsData(data.data);
                break;
                
            case 'pong':
                // Heartbeat response
                break;
                
            default:
                console.log('📩 Unknown message type:', data.type);
        }
    }
    
    updateSystemMetrics(data) {
        // Update metric values
        if (this.elements.cpuValue) {
            this.elements.cpuValue.textContent = `${data.cpu_percent?.toFixed(1)}%`;
        }
        if (this.elements.memoryValue) {
            this.elements.memoryValue.textContent = `${data.memory_percent?.toFixed(1)}%`;
        }
        if (this.elements.diskValue) {
            this.elements.diskValue.textContent = `${data.disk_percent?.toFixed(1)}%`;
        }
        if (this.elements.processesValue) {
            this.elements.processesValue.textContent = data.process_count?.toLocaleString();
        }
        if (this.elements.loadAvgValue) {
            this.elements.loadAvgValue.textContent = data.load_avg?.toFixed(2);
        }
        
        // Update timestamp
        if (this.elements.lastUpdate) {
            const updateTime = new Date(data.timestamp).toLocaleTimeString();
            this.elements.lastUpdate.textContent = updateTime;
        }
        
        // Update alerts
        if (data.alerts && data.alerts.length > 0) {
            this.showAlerts(data.alerts);
        } else {
            this.hideAlerts();
        }
        
        // Update progress bars/charts
        this.updateProgressCharts(data);
    }
    
    updateDetailedInfo(data) {
        // Update CPU info
        if (data.cpu && this.elements.cpuCores) {
            this.elements.cpuCores.textContent = `${data.cpu.cores} cores`;
        }
        if (data.cpu && this.elements.cpuLoad) {
            this.elements.cpuLoad.textContent = `Load: ${data.cpu.load_1min}`;
        }
        
        // Update memory info
        if (data.memory && this.elements.memoryTotal) {
            this.elements.memoryTotal.textContent = `${data.memory.total} GB total`;
        }
        if (data.memory && this.elements.memoryAvailable) {
            this.elements.memoryAvailable.textContent = `${data.memory.available} GB free`;
        }
        
        // Update disk info (use first disk)
        if (data.disk && data.disk.length > 0) {
            const mainDisk = data.disk[0];
            if (this.elements.diskTotal) {
                this.elements.diskTotal.textContent = `${mainDisk.total} GB total`;
            }
            if (this.elements.diskFree) {
                this.elements.diskFree.textContent = `${mainDisk.free} GB free`;
            }
        }
        
        // Update uptime
        if (data.uptime && this.elements.uptimeValue) {
            this.elements.uptimeValue.textContent = data.uptime.human_readable;
        }
    }
    
    updateChartsData(data) {
        const now = new Date(data.timestamp);
        
        // Add new data point
        this.systemData.cpu.push(data.cpu_percent);
        this.systemData.memory.push(data.memory_percent);
        this.systemData.disk.push(data.disk_percent);
        this.systemData.timestamps.push(now);
        
        // Keep only recent data points
        if (this.systemData.cpu.length > this.maxDataPoints) {
            this.systemData.cpu.shift();
            this.systemData.memory.shift();
            this.systemData.disk.shift();
            this.systemData.timestamps.shift();
        }
        
        // Update charts
        this.updateHistoryCharts();
    }
    
    updateConnectionStatus(status) {
        const statusElement = this.elements.connectionStatus;
        const dot = statusElement?.querySelector('.status-dot');
        const text = statusElement?.querySelector('.status-text');
        
        if (!dot || !text) return;
        
        dot.className = 'status-dot';
        
        switch (status) {
            case 'connected':
                dot.classList.add('connected');
                text.textContent = 'Connected';
                break;
            case 'connecting':
                dot.classList.add('connecting');
                text.textContent = 'Connecting...';
                break;
            case 'disconnected':
                dot.classList.add('disconnected');
                text.textContent = 'Disconnected';
                break;
            case 'error':
                dot.classList.add('disconnected');
                text.textContent = 'Connection Error';
                break;
        }
    }
    
    updateAIStatus(available) {
        const aiStatus = this.elements.aiStatus;
        const text = aiStatus?.querySelector('.ai-text');
        
        if (text) {
            text.textContent = available ? 'AI Ready' : 'AI Unavailable';
            aiStatus.style.opacity = available ? '1' : '0.6';
        }
    }
    
    showAlerts(alerts) {
        if (!this.elements.alertsSection || !this.elements.alertsList) return;
        
        this.elements.alertsList.innerHTML = '';
        alerts.forEach(alert => {
            const alertElement = document.createElement('div');
            alertElement.className = 'alert-item';
            alertElement.textContent = alert;
            this.elements.alertsList.appendChild(alertElement);
        });
        
        this.elements.alertsSection.style.display = 'block';
    }
    
    hideAlerts() {
        if (this.elements.alertsSection) {
            this.elements.alertsSection.style.display = 'none';
        }
    }
    
    async runAIAnalysis() {
        if (!this.elements.analyzeBtn || !this.elements.aiContent || !this.elements.aiLoading) {
            return;
        }
        
        // Disable button and show loading
        this.elements.analyzeBtn.disabled = true;
        this.elements.aiContent.style.display = 'none';
        this.elements.aiLoading.style.display = 'block';
        
        try {
            console.log('🤖 Starting AI analysis...');
            
            const response = await fetch(`${this.apiBase}/api/ai/analyze`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    custom_prompt: "Analyze my system health and provide recommendations"
                })
            });
            
            if (!response.ok) {
                throw new Error(`AI analysis failed: ${response.status}`);
            }
            
            const result = await response.json();
            
            if (result.status === 'success') {
                this.displayAIAnalysis(result);
                console.log(`✅ AI analysis completed in ${result.processing_time}s using ${result.model_used}`);
            } else {
                throw new Error(result.error || 'AI analysis failed');
            }
            
        } catch (error) {
            console.error('❌ AI analysis error:', error);
            this.showAIError(error.message);
        } finally {
            // Re-enable button and hide loading
            this.elements.analyzeBtn.disabled = false;
            this.elements.aiLoading.style.display = 'none';
            this.elements.aiContent.style.display = 'block';
        }
    }
    
    displayAIAnalysis(result) {
        if (!this.elements.aiContent) return;
        
        // Convert markdown to HTML
        const htmlContent = marked.parse(result.analysis);
        
        // Create analysis container
        const analysisContainer = document.createElement('div');
        analysisContainer.className = 'ai-analysis';
        analysisContainer.innerHTML = htmlContent;
        
        // Add metadata
        const metadata = document.createElement('div');
        metadata.className = 'ai-metadata';
        metadata.style.cssText = `
            margin-top: 2rem;
            padding: 1rem;
            background: rgba(139, 92, 246, 0.1);
            border-radius: 0.5rem;
            border: 1px solid rgba(139, 92, 246, 0.2);
            font-size: 0.875rem;
            color: var(--text-muted);
        `;
        metadata.innerHTML = `
            <div style="display: flex; justify-content: space-between; flex-wrap: wrap; gap: 1rem;">
                <span>🤖 Model: ${result.model_used}</span>
                <span>⚡ Processing: ${result.processing_time}s</span>
                <span>🎯 Tokens: ${result.tokens_used}</span>
                <span>📅 ${new Date(result.timestamp).toLocaleString()}</span>
            </div>
        `;
        
        analysisContainer.appendChild(metadata);
        
        // Replace content
        this.elements.aiContent.innerHTML = '';
        this.elements.aiContent.appendChild(analysisContainer);
    }
    
    showAIError(message) {
        if (!this.elements.aiContent) return;
        
        this.elements.aiContent.innerHTML = `
            <div class="ai-error" style="
                text-align: center;
                padding: 2rem;
                background: rgba(239, 68, 68, 0.1);
                border-radius: 0.75rem;
                border: 1px solid rgba(239, 68, 68, 0.2);
            ">
                <div style="font-size: 3rem; margin-bottom: 1rem;">❌</div>
                <h3 style="color: var(--error); margin-bottom: 1rem;">AI Analysis Failed</h3>
                <p style="color: var(--text-secondary); margin-bottom: 1rem;">${message}</p>
                <button class="btn btn-primary" onclick="location.reload()">Retry</button>
            </div>
        `;
    }
    
    showError(message) {
        console.error('💥 Dashboard error:', message);
        
        // You could implement a toast notification system here
        // For now, we'll just log to console
    }
    
    // Placeholder methods for chart functionality
    async initializeCharts() {
        // Charts will be initialized by charts.js
        console.log('📊 Chart initialization delegated to charts.js');
    }
    
    updateProgressCharts(data) {
        // Progress chart updates will be handled by charts.js
        if (window.chartManager) {
            window.chartManager.updateProgressCharts(data);
        }
    }
    
    updateHistoryCharts() {
        // History chart updates will be handled by charts.js
        if (window.chartManager) {
            window.chartManager.updateHistoryCharts(this.systemData);
        }
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new GPTDiagDashboard();
});

// Export for use in other modules
window.GPTDiagDashboard = GPTDiagDashboard; 