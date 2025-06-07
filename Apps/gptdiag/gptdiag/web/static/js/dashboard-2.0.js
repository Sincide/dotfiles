/**
 * GPTDiag 2.0 Dashboard
 * Tabbed interface with AI-first system intelligence
 */

class Dashboard20 {
    constructor() {
        this.currentTab = 'dashboard';
        this.ws = null;
        this.aiOrchestrator = null;
        this.chatOpen = false;
        
        // UI elements
        this.elements = this.getElements();
        
        this.init();
    }
    
    getElements() {
        return {
            // Tab navigation
            tabButtons: document.querySelectorAll('.tab-btn'),
            tabContents: document.querySelectorAll('.tab-content'),
            
            // Health score
            healthValue: document.getElementById('health-value'),
            healthFill: document.getElementById('health-fill'),
            lastAnalysis: document.getElementById('last-analysis'),
            
            // AI cards
            criticalCount: document.getElementById('critical-count'),
            criticalIssues: document.getElementById('critical-issues'),
            predictiveCount: document.getElementById('predictive-count'),
            predictiveAlerts: document.getElementById('predictive-alerts'),
            performanceCount: document.getElementById('performance-count'),
            performanceOpportunities: document.getElementById('performance-opportunities'),
            
            // Quick metrics
            cpuValueCompact: document.getElementById('cpu-value-compact'),
            memoryValueCompact: document.getElementById('memory-value-compact'),
            diskValueCompact: document.getElementById('disk-value-compact'),
            loadValueCompact: document.getElementById('load-value-compact'),
            cpuTrend: document.getElementById('cpu-trend'),
            memoryTrend: document.getElementById('memory-trend'),
            diskTrend: document.getElementById('disk-trend'),
            loadTrend: document.getElementById('load-trend'),
            
            // Recommendations
            recommendationsGrid: document.getElementById('recommendations-grid'),
            refreshRecommendations: document.getElementById('refresh-recommendations'),
            
            // Log intelligence
            logQuery: document.getElementById('log-query'),
            autoScanLogs: document.getElementById('auto-scan-logs'),
            refreshLogAnalysis: document.getElementById('refresh-log-analysis'),
            analyzeCustomLogs: document.getElementById('analyze-custom-logs'),
            customLogResult: document.getElementById('custom-log-result'),
            
            // Log analysis containers
            logIssuesContainer: document.getElementById('log-issues-container'),
            logErrorsContainer: document.getElementById('log-errors-container'),
            logInsightsContainer: document.getElementById('log-insights-container'),
            logIssuesCount: document.getElementById('log-issues-count'),
            logErrorsCount: document.getElementById('log-errors-count'),
            logInsightsCount: document.getElementById('log-insights-count'),
            
            // AI Chat
            aiChatToggle: document.getElementById('ai-chat-toggle'),
            aiChatPanel: document.getElementById('ai-chat-panel'),
            chatClose: document.getElementById('chat-close'),
            chatMessages: document.getElementById('chat-messages'),
            chatInput: document.getElementById('chat-input'),
            chatSend: document.getElementById('chat-send'),
            
            // Connection status
            connectionStatus: document.getElementById('connection-status'),
            aiStatus: document.getElementById('ai-status'),
            aiModels: document.getElementById('ai-models')
        };
    }
    
    async init() {
        console.log('🚀 Initializing GPTDiag 2.0 Dashboard');
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Wait for AI Orchestrator to be ready
        this.waitForAIOrchestrator();
        
        // Connect WebSocket
        this.connectWebSocket();
        
        // Initial data load
        await this.loadInitialData();
        
        console.log('✅ Dashboard 2.0 initialized successfully');
    }
    
    waitForAIOrchestrator() {
        const checkAI = () => {
            if (window.aiOrchestrator) {
                this.aiOrchestrator = window.aiOrchestrator;
                console.log('🧠 AI Orchestrator connected to dashboard');
                this.runInitialAIAnalysis();
            } else {
                setTimeout(checkAI, 100);
            }
        };
        checkAI();
    }
    
    setupEventListeners() {
        // Tab navigation
        this.elements.tabButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const tabId = e.currentTarget.dataset.tab;
                this.switchTab(tabId);
            });
        });
        
        // Refresh recommendations
        if (this.elements.refreshRecommendations) {
            this.elements.refreshRecommendations.addEventListener('click', () => {
                this.runInitialAIAnalysis();
            });
        }
        
        // Automatic log scanning
        if (this.elements.autoScanLogs) {
            this.elements.autoScanLogs.addEventListener('click', () => {
                this.performAutoLogScan();
            });
        }
        
        if (this.elements.refreshLogAnalysis) {
            this.elements.refreshLogAnalysis.addEventListener('click', () => {
                this.performAutoLogScan();
            });
        }
        
        // Custom log analysis
        if (this.elements.analyzeCustomLogs) {
            this.elements.analyzeCustomLogs.addEventListener('click', () => {
                this.analyzeCustomLogQuery();
            });
        }
        
        if (this.elements.logQuery) {
            this.elements.logQuery.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.analyzeCustomLogQuery();
                }
            });
        }
        
        // AI Chat
        if (this.elements.aiChatToggle) {
            this.elements.aiChatToggle.addEventListener('click', () => {
                this.toggleAIChat();
            });
        }
        
        if (this.elements.chatClose) {
            this.elements.chatClose.addEventListener('click', () => {
                this.closeAIChat();
            });
        }
        
        if (this.elements.chatSend) {
            this.elements.chatSend.addEventListener('click', () => {
                this.sendChatMessage();
            });
        }
        
        if (this.elements.chatInput) {
            this.elements.chatInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.sendChatMessage();
                }
            });
        }
    }
    
    switchTab(tabId) {
        // Update active tab button
        this.elements.tabButtons.forEach(btn => {
            btn.classList.remove('active');
            if (btn.dataset.tab === tabId) {
                btn.classList.add('active');
            }
        });
        
        // Update active tab content
        this.elements.tabContents.forEach(content => {
            content.classList.remove('active');
            if (content.id === `tab-${tabId}`) {
                content.classList.add('active');
            }
        });
        
        this.currentTab = tabId;
        console.log(`📑 Switched to tab: ${tabId}`);
        
        // Load tab-specific data
        this.loadTabData(tabId);
    }
    
    loadTabData(tabId) {
        switch (tabId) {
            case 'dashboard':
                // Dashboard data already loaded
                break;
            case 'analytics':
                this.loadAnalyticsData();
                break;
            case 'logs':
                this.loadLogsData();
                break;
            case 'performance':
                this.loadPerformanceData();
                break;
            case 'maintenance':
                this.loadMaintenanceData();
                break;
            case 'security':
                this.loadSecurityData();
                break;
        }
    }
    
    async loadInitialData() {
        try {
            // Load basic system metrics
            const response = await fetch(`${window.location.origin}/api/system/summary`);
            if (response.ok) {
                const data = await response.json();
                this.updateQuickMetrics(data);
                
                // Update AI orchestrator context
                if (this.aiOrchestrator) {
                    this.aiOrchestrator.updateSystemContext(data);
                }
            }
        } catch (error) {
            console.error('❌ Failed to load initial data:', error);
        }
    }
    
    async runInitialAIAnalysis() {
        if (!this.aiOrchestrator) return;
        
        try {
            console.log('🧠 Running initial AI analysis...');
            
            // Show loading state
            this.showAIAnalysisLoading();
            
            const analysis = await this.aiOrchestrator.analyzeSystemHealth();
            
            // Update UI with AI analysis
            this.updateHealthScore(analysis.healthScore);
            this.updateCriticalIssues(analysis.criticalIssues);
            this.updatePredictiveAlerts(analysis.predictiveAlerts);
            this.updatePerformanceOpportunities(analysis.performanceOpportunities);
            this.updateRecommendations(analysis.recommendations);
            
            // Update last analysis time
            if (this.elements.lastAnalysis) {
                this.elements.lastAnalysis.textContent = `Last analysis: ${new Date().toLocaleTimeString()}`;
            }
            
            console.log('✅ AI analysis completed');
            
        } catch (error) {
            console.error('❌ AI analysis failed:', error);
            this.showAIAnalysisError(error.message);
        }
    }
    
    showAIAnalysisLoading() {
        // Show loading indicators for AI cards
        const loadingHTML = '<div class="ai-loading-indicator">🧠 AI analyzing...</div>';
        
        if (this.elements.criticalIssues) {
            this.elements.criticalIssues.innerHTML = loadingHTML;
        }
        if (this.elements.predictiveAlerts) {
            this.elements.predictiveAlerts.innerHTML = loadingHTML;
        }
        if (this.elements.performanceOpportunities) {
            this.elements.performanceOpportunities.innerHTML = loadingHTML;
        }
    }
    
    showAIAnalysisError(message) {
        const errorHTML = `<div class="ai-error-indicator">❌ Analysis failed: ${message}</div>`;
        
        if (this.elements.criticalIssues) {
            this.elements.criticalIssues.innerHTML = errorHTML;
        }
    }
    
    updateQuickMetrics(data) {
        // Update metric values
        if (this.elements.cpuValueCompact) {
            this.elements.cpuValueCompact.textContent = `${data.cpu_percent?.toFixed(1)}%`;
        }
        if (this.elements.memoryValueCompact) {
            this.elements.memoryValueCompact.textContent = `${data.memory_percent?.toFixed(1)}%`;
        }
        if (this.elements.diskValueCompact) {
            this.elements.diskValueCompact.textContent = `${data.disk_percent?.toFixed(1)}%`;
        }
        if (this.elements.loadValueCompact) {
            this.elements.loadValueCompact.textContent = data.load_avg?.toFixed(2);
        }
        
        // Update trends (placeholder for now)
        if (this.elements.cpuTrend) {
            this.elements.cpuTrend.textContent = '→ stable';
        }
        if (this.elements.memoryTrend) {
            this.elements.memoryTrend.textContent = '→ stable';
        }
        if (this.elements.diskTrend) {
            this.elements.diskTrend.textContent = '→ stable';
        }
        if (this.elements.loadTrend) {
            this.elements.loadTrend.textContent = '→ stable';
        }
    }
    
    updateHealthScore(score) {
        if (this.elements.healthValue) {
            this.elements.healthValue.textContent = score;
        }
        if (this.elements.healthFill) {
            this.elements.healthFill.style.width = `${score}%`;
            
            // Color based on score
            if (score >= 80) {
                this.elements.healthFill.style.background = '#10b981'; // Green
            } else if (score >= 60) {
                this.elements.healthFill.style.background = '#f59e0b'; // Yellow
            } else {
                this.elements.healthFill.style.background = '#ef4444'; // Red
            }
        }
    }
    
    updateCriticalIssues(issues) {
        if (!this.elements.criticalIssues || !this.elements.criticalCount) return;
        
        this.elements.criticalCount.textContent = issues.length;
        
        if (issues.length === 0) {
            this.elements.criticalIssues.innerHTML = '<div class="no-issues">✅ No critical issues detected</div>';
        } else {
            const issuesHTML = issues.map(issue => `
                <div class="issue-item ${issue.severity}">
                    <div class="issue-title">${issue.title}</div>
                    <div class="issue-description">${issue.description}</div>
                    <div class="issue-action">💡 ${issue.action}</div>
                </div>
            `).join('');
            this.elements.criticalIssues.innerHTML = issuesHTML;
        }
    }
    
    updatePredictiveAlerts(alerts) {
        if (!this.elements.predictiveAlerts || !this.elements.predictiveCount) return;
        
        this.elements.predictiveCount.textContent = alerts.length;
        
        if (alerts.length === 0) {
            this.elements.predictiveAlerts.innerHTML = '<div class="no-alerts">🔮 No issues predicted</div>';
        } else {
            const alertsHTML = alerts.map(alert => `
                <div class="alert-item">
                    <div class="alert-title">${alert.title}</div>
                    <div class="alert-description">${alert.description}</div>
                    <div class="alert-meta">
                        <span class="alert-probability">${alert.probability}% confidence</span>
                        <span class="alert-timeframe">${alert.timeframe}</span>
                    </div>
                    <div class="alert-action">💡 ${alert.action}</div>
                </div>
            `).join('');
            this.elements.predictiveAlerts.innerHTML = alertsHTML;
        }
    }
    
    updatePerformanceOpportunities(opportunities) {
        if (!this.elements.performanceOpportunities || !this.elements.performanceCount) return;
        
        this.elements.performanceCount.textContent = opportunities.length;
        
        if (opportunities.length === 0) {
            this.elements.performanceOpportunities.innerHTML = '<div class="no-opportunities">⚡ System running optimally</div>';
        } else {
            const oppsHTML = opportunities.map(opp => `
                <div class="opportunity-item">
                    <div class="opportunity-title">${opp.title}</div>
                    <div class="opportunity-description">${opp.description}</div>
                    <div class="opportunity-meta">
                        <span class="opportunity-impact">Impact: ${opp.impact}</span>
                        <span class="opportunity-effort">Effort: ${opp.effort}</span>
                    </div>
                    <div class="opportunity-command"><code>${opp.command}</code></div>
                    <div class="opportunity-savings">💾 ${opp.estimatedSavings}</div>
                </div>
            `).join('');
            this.elements.performanceOpportunities.innerHTML = oppsHTML;
        }
    }
    
    updateRecommendations(recommendations) {
        if (!this.elements.recommendationsGrid) return;
        
        if (recommendations.length === 0) {
            this.elements.recommendationsGrid.innerHTML = `
                <div class="recommendation-placeholder">
                    <div class="placeholder-icon">✅</div>
                    <h3>No Recommendations</h3>
                    <p>Your system is running optimally!</p>
                </div>
            `;
            return;
        }
        
        const recommendationsHTML = recommendations.map(rec => `
            <div class="recommendation-card ${rec.priority}">
                <div class="recommendation-header">
                    <h4>${rec.title}</h4>
                    <span class="recommendation-priority">${rec.priority}</span>
                </div>
                <div class="recommendation-description">${rec.description}</div>
                <div class="recommendation-actions">
                    ${rec.actions.map(action => `<div class="action-item">• ${action}</div>`).join('')}
                </div>
                <div class="recommendation-meta">
                    <span class="recommendation-frequency">Frequency: ${rec.frequency}</span>
                    <span class="recommendation-time">Time: ${rec.estimatedTime}</span>
                </div>
            </div>
        `).join('');
        
        this.elements.recommendationsGrid.innerHTML = recommendationsHTML;
    }
    
    async performAutoLogScan() {
        if (!this.aiOrchestrator) {
            console.warn('🤖 AI Orchestrator not available');
            return;
        }
        
        console.log('🔍 Starting automatic log scan...');
        
        // Show loading states
        this.showLogScanLoading();
        
        try {
            // Perform comprehensive log analysis
            const logAnalysis = await this.aiOrchestrator.performComprehensiveLogScan();
            
            // Update all log sections
            this.updateLogIssues(logAnalysis.issues || []);
            this.updateLogErrors(logAnalysis.errors || []);
            this.updateLogInsights(logAnalysis.insights || []);
            
            console.log('✅ Automatic log scan completed');
        } catch (error) {
            console.error('❌ Automatic log scan failed:', error);
            this.showLogScanError(error.message);
        }
    }
    
    async analyzeCustomLogQuery() {
        if (!this.aiOrchestrator) {
            console.warn('🤖 AI Orchestrator not available');
            return;
        }
        
        const query = this.elements.logQuery?.value?.trim();
        if (!query) {
            console.warn('📋 No log query provided');
            return;
        }
        
        const resultElement = this.elements.customLogResult;
        if (!resultElement) return;
        
        // Show loading state
        resultElement.innerHTML = `
            <div class="ai-loading">
                <div class="loading-spinner"></div>
                <div class="loading-text">AI analyzing custom query...</div>
                <div class="loading-details">Query: "${query}"</div>
            </div>
        `;
        
        try {
            const analysis = await this.aiOrchestrator.analyzeLogsWithAI(query);
            
            if (analysis.status === 'success') {
                const htmlContent = marked.parse(analysis.analysis);
                
                // Display analysis results
                resultElement.innerHTML = `
                    <div class="log-analysis-content">
                        <h4>🔍 Custom Query Results</h4>
                        <div class="analysis-meta">
                            <span>🤖 Model: ${analysis.model_used}</span>
                            <span>⚡ ${analysis.processing_time}s</span>
                        </div>
                        <div class="ai-analysis">${htmlContent}</div>
                    </div>
                `;
            } else {
                throw new Error(analysis.error || 'Log analysis failed');
            }
            
            // Clear the query input
            if (this.elements.logQuery) {
                this.elements.logQuery.value = '';
            }
            
            console.log('📋 Custom log analysis completed');
        } catch (error) {
            console.error('❌ Custom log analysis failed:', error);
            resultElement.innerHTML = `
                <div class="ai-error-indicator">
                    <h4>❌ Analysis Failed</h4>
                    <p>Unable to analyze logs: ${error.message}</p>
                    <p>Please check your query and try again.</p>
                </div>
            `;
        }
    }
    
    showLogScanLoading() {
        // Show loading for issues
        if (this.elements.logIssuesContainer) {
            this.elements.logIssuesContainer.innerHTML = `
                <div class="log-placeholder">
                    <div class="loading-icon">🧠</div>
                    <p>AI scanning system logs for issues...</p>
                </div>
            `;
        }
        
        // Show loading for errors
        if (this.elements.logErrorsContainer) {
            this.elements.logErrorsContainer.innerHTML = `
                <div class="log-placeholder">
                    <div class="loading-icon">📋</div>
                    <p>Analyzing recent log entries...</p>
                </div>
            `;
        }
        
        // Show loading for insights
        if (this.elements.logInsightsContainer) {
            this.elements.logInsightsContainer.innerHTML = `
                <div class="log-placeholder">
                    <div class="loading-icon">⚡</div>
                    <p>Identifying performance patterns...</p>
                </div>
            `;
        }
    }
    
    showLogScanError(message) {
        const errorContent = `
            <div class="ai-error-indicator">
                <h4>❌ Scan Failed</h4>
                <p>${message}</p>
                <button class="btn btn-primary" onclick="dashboard.performAutoLogScan()">
                    <span class="btn-icon">🔄</span>
                    Retry Scan
                </button>
            </div>
        `;
        
        if (this.elements.logIssuesContainer) {
            this.elements.logIssuesContainer.innerHTML = errorContent;
        }
        if (this.elements.logErrorsContainer) {
            this.elements.logErrorsContainer.innerHTML = errorContent;
        }
        if (this.elements.logInsightsContainer) {
            this.elements.logInsightsContainer.innerHTML = errorContent;
        }
    }
    
    updateLogIssues(issues) {
        if (!this.elements.logIssuesContainer) return;
        
        // Update issue count
        if (this.elements.logIssuesCount) {
            this.elements.logIssuesCount.textContent = issues.length;
        }
        
        if (issues.length === 0) {
            this.elements.logIssuesContainer.innerHTML = `
                <div class="log-placeholder">
                    <div class="placeholder-icon">✅</div>
                    <p>No critical issues detected in logs</p>
                </div>
            `;
            return;
        }
        
        const issuesHtml = issues.map(issue => `
            <div class="log-issue-item">
                <div class="log-item-header">
                    <h4 class="log-item-title">${issue.title}</h4>
                    <span class="log-item-time">${issue.time}</span>
                </div>
                <p class="log-item-description">${issue.description}</p>
            </div>
        `).join('');
        
        this.elements.logIssuesContainer.innerHTML = issuesHtml;
    }
    
    updateLogErrors(errors) {
        if (!this.elements.logErrorsContainer) return;
        
        // Update error count
        if (this.elements.logErrorsCount) {
            this.elements.logErrorsCount.textContent = errors.length;
        }
        
        if (errors.length === 0) {
            this.elements.logErrorsContainer.innerHTML = `
                <div class="log-placeholder">
                    <div class="placeholder-icon">✅</div>
                    <p>No recent errors or warnings found</p>
                </div>
            `;
            return;
        }
        
        const errorsHtml = errors.map(error => `
            <div class="log-error-item">
                <div class="log-item-header">
                    <h4 class="log-item-title">${error.title}</h4>
                    <span class="log-item-time">${error.time}</span>
                </div>
                <p class="log-item-description">${error.description}</p>
            </div>
        `).join('');
        
        this.elements.logErrorsContainer.innerHTML = errorsHtml;
    }
    
    updateLogInsights(insights) {
        if (!this.elements.logInsightsContainer) return;
        
        // Update insight count
        if (this.elements.logInsightsCount) {
            this.elements.logInsightsCount.textContent = insights.length;
        }
        
        if (insights.length === 0) {
            this.elements.logInsightsContainer.innerHTML = `
                <div class="log-placeholder">
                    <div class="placeholder-icon">📊</div>
                    <p>No performance insights available yet</p>
                </div>
            `;
            return;
        }
        
        const insightsHtml = insights.map(insight => `
            <div class="log-insight-item">
                <div class="log-item-header">
                    <h4 class="log-item-title">${insight.title}</h4>
                    <span class="log-item-time">${insight.time}</span>
                </div>
                <p class="log-item-description">${insight.description}</p>
            </div>
        `).join('');
        
        this.elements.logInsightsContainer.innerHTML = insightsHtml;
    }
    
    toggleAIChat() {
        this.chatOpen = !this.chatOpen;
        
        if (this.elements.aiChatPanel) {
            this.elements.aiChatPanel.classList.toggle('open', this.chatOpen);
        }
    }
    
    closeAIChat() {
        this.chatOpen = false;
        if (this.elements.aiChatPanel) {
            this.elements.aiChatPanel.classList.remove('open');
        }
    }
    
    async sendChatMessage() {
        if (!this.aiOrchestrator || !this.elements.chatInput || !this.elements.chatMessages) return;
        
        const message = this.elements.chatInput.value.trim();
        if (!message) return;
        
        // Add user message to chat
        this.addChatMessage('user', message);
        
        // Clear input
        this.elements.chatInput.value = '';
        
        try {
            // Add loading message
            this.addChatMessage('ai', '🧠 AI thinking...', true);
            
            const result = await this.aiOrchestrator.chatWithAI(message);
            
            // Remove loading message
            this.removeChatLoadingMessage();
            
            if (result.status === 'success') {
                this.addChatMessage('ai', result.analysis);
            } else {
                this.addChatMessage('ai', `❌ Sorry, I encountered an error: ${result.error}`);
            }
            
        } catch (error) {
            console.error('❌ Chat failed:', error);
            this.removeChatLoadingMessage();
            this.addChatMessage('ai', `❌ Sorry, I encountered an error: ${error.message}`);
        }
    }
    
    addChatMessage(sender, content, isLoading = false) {
        if (!this.elements.chatMessages) return;
        
        const messageDiv = document.createElement('div');
        messageDiv.className = `${sender}-message${isLoading ? ' loading' : ''}`;
        
        if (sender === 'user') {
            messageDiv.innerHTML = `
                <div class="message-avatar">👤</div>
                <div class="message-content">${content}</div>
            `;
        } else {
            messageDiv.innerHTML = `
                <div class="message-avatar">🤖</div>
                <div class="message-content">${isLoading ? content : marked.parse(content)}</div>
            `;
        }
        
        this.elements.chatMessages.appendChild(messageDiv);
        this.elements.chatMessages.scrollTop = this.elements.chatMessages.scrollHeight;
    }
    
    removeChatLoadingMessage() {
        if (!this.elements.chatMessages) return;
        
        const loadingMessage = this.elements.chatMessages.querySelector('.loading');
        if (loadingMessage) {
            loadingMessage.remove();
        }
    }
    
    connectWebSocket() {
        // WebSocket connection for real-time updates
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/updates`;
        
        try {
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = () => {
                console.log('✅ WebSocket connected');
                this.updateConnectionStatus('connected');
            };
            
            this.ws.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    this.handleWebSocketMessage(data);
                } catch (error) {
                    console.error('❌ WebSocket message parse error:', error);
                }
            };
            
            this.ws.onclose = () => {
                console.log('🔌 WebSocket disconnected');
                this.updateConnectionStatus('disconnected');
            };
            
        } catch (error) {
            console.error('❌ WebSocket connection failed:', error);
            this.updateConnectionStatus('error');
        }
    }
    
    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'system_update':
                this.updateQuickMetrics(data.data);
                
                // Update AI orchestrator context
                if (this.aiOrchestrator) {
                    this.aiOrchestrator.updateSystemContext(data.data);
                }
                break;
        }
    }
    
    updateConnectionStatus(status) {
        if (!this.elements.connectionStatus) return;
        
        const dot = this.elements.connectionStatus.querySelector('.status-dot');
        const text = this.elements.connectionStatus.querySelector('.status-text');
        
        if (dot) dot.className = `status-dot ${status}`;
        if (text) {
            switch (status) {
                case 'connected': text.textContent = 'Connected'; break;
                case 'disconnected': text.textContent = 'Disconnected'; break;
                case 'error': text.textContent = 'Connection Error'; break;
            }
        }
    }
    
    // Placeholder methods for other tabs
    loadAnalyticsData() {
        console.log('📊 Loading analytics data...');
    }
    
    loadLogsData() {
        console.log('📋 Loading logs data...');
        // Automatically scan logs when tab is loaded
        this.performAutoLogScan();
    }
    
    loadPerformanceData() {
        console.log('⚡ Loading performance data...');
    }
    
    loadMaintenanceData() {
        console.log('🛠️ Loading maintenance data...');
    }
    
    loadSecurityData() {
        console.log('🛡️ Loading security data...');
    }
}

// Initialize Dashboard 2.0 when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard20 = new Dashboard20();
});

// Export for use in other modules
window.Dashboard20 = Dashboard20; 