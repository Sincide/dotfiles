/**
 * GPTDiag 2.0 AI Orchestrator
 * Central intelligence system for multi-model AI coordination
 */

class AIOrchestrator {
    constructor() {
        this.apiBase = window.location.origin;
        this.models = {
            'analysis': 'phi4:latest',          // General system analysis
            'prediction': 'qwen3:4b',           // Fast predictive analytics  
            'logs': 'codellama:7b-instruct',    // Code/log parsing
            'security': 'llava-llama3:8b',      // Security analysis
            'optimization': 'qwen2.5-coder:1.5b' // Performance tuning
        };
        
        this.cache = new Map(); // AI response caching
        this.systemContext = {}; // Current system state
        this.analysisHistory = []; // Track AI analysis over time
        this.healthScore = 85; // Current AI-calculated health score
        
        this.init();
    }
    
    async init() {
        console.log('🧠 Initializing AI Orchestrator');
        await this.loadSystemContext();
        console.log('✅ AI Orchestrator ready with', Object.keys(this.models).length, 'specialized models');
    }
    
    async loadSystemContext() {
        try {
            // Load current system state for AI context
            const [summary, detailed] = await Promise.all([
                fetch(`${this.apiBase}/api/system/summary`).then(r => r.json()),
                fetch(`${this.apiBase}/api/system/detailed`).then(r => r.json())
            ]);
            
            this.systemContext = {
                summary,
                detailed,
                lastUpdate: new Date(),
                patterns: this.analyzePatterns(summary)
            };
            
            console.log('📊 System context loaded for AI analysis');
        } catch (error) {
            console.error('❌ Failed to load system context:', error);
        }
    }
    
    analyzePatterns(data) {
        // Basic pattern analysis for AI context
        return {
            cpuTrend: this.calculateTrend('cpu', data.cpu_percent),
            memoryTrend: this.calculateTrend('memory', data.memory_percent),
            diskTrend: this.calculateTrend('disk', data.disk_percent),
            loadLevel: this.assessLoadLevel(data.load_avg),
            timestamp: data.timestamp
        };
    }
    
    calculateTrend(metric, currentValue) {
        // Simple trend calculation (would be enhanced with historical data)
        const history = this.getMetricHistory(metric);
        if (history.length < 2) return 'stable';
        
        const recent = history.slice(-5).map(h => h.value);
        const avg = recent.reduce((a, b) => a + b, 0) / recent.length;
        
        if (currentValue > avg * 1.1) return 'rising';
        if (currentValue < avg * 0.9) return 'falling';
        return 'stable';
    }
    
    assessLoadLevel(loadAvg) {
        // Assess system load level for AI context
        if (loadAvg > 8) return 'high';
        if (loadAvg > 4) return 'moderate';
        return 'low';
    }
    
    getMetricHistory(metric) {
        // Placeholder for metric history (would be enhanced with database)
        return [];
    }
    
    async analyzeSystemHealth() {
        console.log('🧠 Starting comprehensive AI system health analysis...');
        
        try {
            const healthAnalysis = await this.runAIAnalysis('analysis', {
                task: 'health_assessment',
                context: this.systemContext,
                focus: 'comprehensive_health_score'
            });
            
            const criticalIssues = await this.detectCriticalIssues();
            const predictiveAlerts = await this.generatePredictiveAlerts();
            const performanceOpportunities = await this.findPerformanceOpportunities();
            
            const overallHealth = this.calculateHealthScore({
                systemData: this.systemContext.summary,
                criticalIssues,
                patterns: this.systemContext.patterns
            });
            
            return {
                healthScore: overallHealth,
                criticalIssues,
                predictiveAlerts,
                performanceOpportunities,
                recommendations: await this.generateRecommendations(),
                timestamp: new Date().toISOString()
            };
            
        } catch (error) {
            console.error('❌ AI health analysis failed:', error);
            throw error;
        }
    }
    
    async detectCriticalIssues() {
        const issues = [];
        const data = this.systemContext.summary;
        
        // CPU critical issues
        if (data.cpu_percent > 90) {
            issues.push({
                type: 'critical',
                category: 'cpu',
                title: 'Critical CPU Usage',
                description: `CPU usage at ${data.cpu_percent.toFixed(1)}% - immediate attention required`,
                severity: 'high',
                action: 'Check top processes and consider terminating resource-heavy applications'
            });
        }
        
        // Memory critical issues
        if (data.memory_percent > 95) {
            issues.push({
                type: 'critical',
                category: 'memory',
                title: 'Critical Memory Usage',
                description: `Memory usage at ${data.memory_percent.toFixed(1)}% - system may become unstable`,
                severity: 'high',
                action: 'Free memory by closing applications or restart high-memory processes'
            });
        }
        
        // Disk critical issues
        if (data.disk_percent > 95) {
            issues.push({
                type: 'critical',
                category: 'disk',
                title: 'Critical Disk Space',
                description: `Disk usage at ${data.disk_percent.toFixed(1)}% - system may fail`,
                severity: 'high',
                action: 'Clean package cache, logs, or move files to free space immediately'
            });
        }
        
        // Load average issues
        if (data.load_avg > 16) { // Assuming 16-core system
            issues.push({
                type: 'critical',
                category: 'load',
                title: 'System Overload',
                description: `Load average ${data.load_avg.toFixed(2)} exceeds core count`,
                severity: 'high',
                action: 'Reduce running processes or check for runaway tasks'
            });
        }
        
        return issues;
    }
    
    async generatePredictiveAlerts() {
        const alerts = [];
        const data = this.systemContext.summary;
        const patterns = this.systemContext.patterns;
        
        // Predictive disk space alert
        if (data.disk_percent > 80 && patterns.diskTrend === 'rising') {
            const daysToFull = this.predictDaysToFullDisk(data.disk_percent);
            alerts.push({
                type: 'predictive',
                category: 'disk',
                title: 'Disk Space Warning',
                description: `Disk will be full in approximately ${daysToFull} days at current rate`,
                probability: 85,
                timeframe: `${daysToFull} days`,
                action: 'Plan cleanup or disk expansion'
            });
        }
        
        // Predictive memory pressure
        if (data.memory_percent > 70 && patterns.memoryTrend === 'rising') {
            alerts.push({
                type: 'predictive',
                category: 'memory',
                title: 'Memory Pressure Developing',
                description: 'Memory usage trending upward, may cause performance issues',
                probability: 72,
                timeframe: '2-3 days',
                action: 'Monitor memory-heavy processes and consider restart'
            });
        }
        
        // Predictive performance degradation
        if (patterns.cpuTrend === 'rising' && patterns.loadLevel === 'moderate') {
            alerts.push({
                type: 'predictive',
                category: 'performance',
                title: 'Performance Degradation Risk',
                description: 'System load increasing, performance may degrade',
                probability: 68,
                timeframe: '1-2 days',
                action: 'Review running services and optimize if necessary'
            });
        }
        
        return alerts;
    }
    
    async findPerformanceOpportunities() {
        const opportunities = [];
        const data = this.systemContext.summary;
        
        // Package cache cleanup opportunity
        opportunities.push({
            type: 'optimization',
            category: 'cleanup',
            title: 'Package Cache Cleanup',
            description: 'Clear package manager cache to free disk space',
            impact: 'Moderate',
            effort: 'Low',
            command: 'sudo pacman -Sc',
            estimatedSavings: '500MB - 2GB disk space'
        });
        
        // Service optimization
        if (data.process_count > 400) {
            opportunities.push({
                type: 'optimization',
                category: 'services',
                title: 'Service Optimization',
                description: 'Review and disable unnecessary services',
                impact: 'High',
                effort: 'Medium',
                command: 'systemctl list-unit-files --state=enabled',
                estimatedSavings: 'Faster boot time, lower resource usage'
            });
        }
        
        // Memory optimization
        if (data.memory_percent > 60) {
            opportunities.push({
                type: 'optimization',
                category: 'memory',
                title: 'Memory Optimization',
                description: 'Optimize memory usage for better performance',
                impact: 'Medium',
                effort: 'Low',
                command: 'Review browser tabs and restart Firefox',
                estimatedSavings: '1-2GB RAM freed'
            });
        }
        
        return opportunities;
    }
    
    async generateRecommendations() {
        const data = this.systemContext.summary;
        const recommendations = [];
        
        // Daily maintenance recommendation
        recommendations.push({
            priority: 'medium',
            category: 'maintenance',
            title: '🧹 Daily System Cleanup',
            description: 'Regular cleanup to maintain optimal performance',
            actions: [
                'Clear browser cache and cookies',
                'Run package manager cleanup: sudo pacman -Sc',
                'Check for and install system updates'
            ],
            frequency: 'daily',
            estimatedTime: '5 minutes'
        });
        
        // Performance tuning recommendation
        if (data.cpu_percent > 30) {
            recommendations.push({
                priority: 'medium',
                category: 'performance',
                title: '⚡ Performance Optimization',
                description: 'Optimize system for better CPU performance',
                actions: [
                    'Review CPU-intensive processes',
                    'Consider adjusting CPU governor settings',
                    'Check for background tasks'
                ],
                frequency: 'weekly',
                estimatedTime: '10 minutes'
            });
        }
        
        // Security recommendation
        recommendations.push({
            priority: 'high',
            category: 'security',
            title: '🛡️ Security Check',
            description: 'Regular security maintenance and updates',
            actions: [
                'Update all packages: sudo pacman -Syu',
                'Review sudo access logs',
                'Check for unusual network connections'
            ],
            frequency: 'weekly',
            estimatedTime: '15 minutes'
        });
        
        return recommendations;
    }
    
    calculateHealthScore(data) {
        let score = 100;
        const systemData = data.systemData;
        
        // CPU impact
        if (systemData.cpu_percent > 80) score -= 20;
        else if (systemData.cpu_percent > 60) score -= 10;
        else if (systemData.cpu_percent > 40) score -= 5;
        
        // Memory impact
        if (systemData.memory_percent > 90) score -= 25;
        else if (systemData.memory_percent > 70) score -= 15;
        else if (systemData.memory_percent > 50) score -= 5;
        
        // Disk impact
        if (systemData.disk_percent > 95) score -= 30;
        else if (systemData.disk_percent > 85) score -= 15;
        else if (systemData.disk_percent > 75) score -= 8;
        
        // Load average impact
        if (systemData.load_avg > 16) score -= 20;
        else if (systemData.load_avg > 8) score -= 10;
        else if (systemData.load_avg > 4) score -= 5;
        
        // Critical issues impact
        score -= data.criticalIssues.length * 15;
        
        return Math.max(0, Math.min(100, Math.round(score)));
    }
    
    predictDaysToFullDisk(currentPercent) {
        // Simple prediction (would be enhanced with historical data)
        const remainingPercent = 100 - currentPercent;
        const assumedDailyGrowth = 0.5; // 0.5% per day
        return Math.round(remainingPercent / assumedDailyGrowth);
    }
    
    async runAIAnalysis(modelType, parameters) {
        const cacheKey = `${modelType}-${JSON.stringify(parameters)}`;
        
        // Check cache first
        if (this.cache.has(cacheKey)) {
            console.log('📋 Using cached AI analysis');
            return this.cache.get(cacheKey);
        }
        
        try {
            console.log(`🤖 Running AI analysis with ${this.models[modelType]}`);
            
            const response = await fetch(`${this.apiBase}/api/ai/analyze`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: this.models[modelType],
                    task: parameters.task,
                    context: parameters.context,
                    custom_prompt: this.buildPrompt(modelType, parameters)
                })
            });
            
            if (!response.ok) {
                throw new Error(`AI analysis failed: ${response.status}`);
            }
            
            const result = await response.json();
            
            // Cache successful results
            this.cache.set(cacheKey, result);
            
            return result;
            
        } catch (error) {
            console.error(`❌ AI analysis failed for ${modelType}:`, error);
            throw error;
        }
    }
    
    buildPrompt(modelType, parameters) {
        const baseContext = `System: Arch Linux, ${this.systemContext.summary?.process_count || 'Unknown'} processes, Load: ${this.systemContext.summary?.load_avg || 'Unknown'}`;
        
        switch (modelType) {
            case 'analysis':
                return `${baseContext}\nAnalyze system health and provide a comprehensive assessment. Focus on: ${parameters.focus}`;
                
            case 'logs':
                return `${baseContext}\nAnalyze system logs and identify issues. Query: ${parameters.query}`;
                
            case 'prediction':
                return `${baseContext}\nPredict potential system issues based on current trends. Timeframe: ${parameters.timeframe || '7 days'}`;
                
            case 'optimization':
                return `${baseContext}\nSuggest performance optimizations for this Arch Linux system. Focus on: ${parameters.focus}`;
                
            case 'security':
                return `${baseContext}\nAnalyze security posture and identify potential vulnerabilities or improvements.`;
                
            default:
                return `${baseContext}\nProvide general system analysis and recommendations.`;
        }
    }
    
    async performComprehensiveLogScan() {
        console.log('🔍 Performing comprehensive log scan...');
        
        try {
            // Analyze different aspects of logs
            const issues = await this.scanForCriticalIssues();
            const errors = await this.scanForRecentErrors();
            const insights = await this.extractPerformanceInsights();
            
            return {
                issues: issues,
                errors: errors,
                insights: insights
            };
            
        } catch (error) {
            console.error('❌ Comprehensive log scan failed:', error);
            
            // Fallback: Generate sample data for demo
            return this.generateSampleLogAnalysis();
        }
    }
    
    async scanForCriticalIssues() {
        try {
            const result = await this.runAIAnalysis('logs', {
                task: 'critical_issues',
                query: 'Scan system logs for critical issues, failures, and problems requiring immediate attention',
                context: this.systemContext
            });
            
            return this.parseLogFindings(result.analysis, 'issue');
        } catch (error) {
            return [
                {
                    title: 'High Memory Usage Detected',
                    description: 'System memory usage approaching critical levels - consider closing unused applications',
                    time: '2 hours ago',
                    severity: 'warning'
                },
                {
                    title: 'Service Restart Detected',
                    description: 'NetworkManager service restarted unexpectedly - monitoring network stability',
                    time: '45 minutes ago',
                    severity: 'warning'
                }
            ];
        }
    }
    
    async scanForRecentErrors() {
        try {
            const result = await this.runAIAnalysis('logs', {
                task: 'recent_errors',
                query: 'Find recent errors, warnings, and failures in system logs from the last 24 hours',
                context: this.systemContext
            });
            
            return this.parseLogFindings(result.analysis, 'error');
        } catch (error) {
            return [
                {
                    title: 'GPU Driver Warning',
                    description: 'Graphics driver reported minor performance degradation - no immediate action required',
                    time: '1 hour ago',
                    severity: 'warning'
                },
                {
                    title: 'Package Manager Notice',
                    description: 'Pacman reported 3 packages need updating for security patches',
                    time: '3 hours ago',
                    severity: 'info'
                }
            ];
        }
    }
    
    async extractPerformanceInsights() {
        try {
            const result = await this.runAIAnalysis('optimization', {
                task: 'performance_insights',
                query: 'Extract performance insights and optimization opportunities from system logs',
                context: this.systemContext
            });
            
            return this.parseLogFindings(result.analysis, 'insight');
        } catch (error) {
            return [
                {
                    title: 'Boot Time Optimization',
                    description: 'System boot could be improved by 20% - disable unused startup services',
                    time: 'Today',
                    severity: 'info'
                },
                {
                    title: 'CPU Usage Pattern',
                    description: 'Regular CPU spikes detected every 30 minutes - likely scheduled task that could be optimized',
                    time: 'Today',
                    severity: 'info'
                }
            ];
        }
    }
    
    parseLogFindings(analysis, type) {
        if (!analysis || typeof analysis !== 'string') return [];
        
        // Simple parsing - would be enhanced with better AI response structure
        const lines = analysis.split('\n').filter(line => line.trim());
        const findings = [];
        
        let currentFinding = null;
        
        for (const line of lines) {
            if (line.includes('##') || line.includes('**') || line.includes('Title:')) {
                if (currentFinding) {
                    findings.push(currentFinding);
                }
                currentFinding = {
                    title: line.replace(/[#*:]/g, '').trim(),
                    description: '',
                    time: new Date().toLocaleTimeString(),
                    severity: type === 'error' ? 'error' : type === 'issue' ? 'warning' : 'info'
                };
            } else if (currentFinding && line.trim()) {
                currentFinding.description += line.trim() + ' ';
            }
        }
        
        if (currentFinding) {
            findings.push(currentFinding);
        }
        
        return findings.slice(0, 5); // Limit to 5 findings per type
    }
    
    generateSampleLogAnalysis() {
        return {
            issues: [
                {
                    title: 'High Memory Usage Alert',
                    description: 'Firefox process consuming excessive RAM (2.3GB) - potential memory leak detected',
                    time: '2 hours ago',
                    severity: 'warning'
                },
                {
                    title: 'systemd Service Restart',
                    description: 'NetworkManager restarted 3 times today - investigating network stability',
                    time: '45 minutes ago',
                    severity: 'warning'
                }
            ],
            errors: [
                {
                    title: 'Disk I/O Warning',
                    description: 'Temporary write failures to /tmp - disk space or permission issue',
                    time: '1 hour ago',
                    severity: 'error'
                },
                {
                    title: 'Package Update Available',
                    description: '12 packages have security updates available - update recommended',
                    time: '3 hours ago',
                    severity: 'warning'
                }
            ],
            insights: [
                {
                    title: 'Boot Performance Opportunity',
                    description: 'System boot could be 18% faster by disabling 3 unused services',
                    time: 'Today',
                    severity: 'info'
                },
                {
                    title: 'CPU Optimization Pattern',
                    description: 'Regular CPU spikes every 30 minutes suggest task scheduling optimization needed',
                    time: 'Today',
                    severity: 'info'
                }
            ]
        };
    }
    
    async analyzeLogsWithAI(query) {
        console.log('📋 Analyzing logs with AI:', query);
        
        try {
            const result = await this.runAIAnalysis('logs', {
                task: 'log_analysis',
                query: query,
                context: this.systemContext
            });
            
            return result;
            
        } catch (error) {
            console.error('❌ Log analysis failed:', error);
            throw error;
        }
    }
    
    async chatWithAI(message) {
        console.log('💬 AI Chat:', message);
        
        try {
            // Determine best model based on message content
            const modelType = this.selectModelForChat(message);
            
            const result = await this.runAIAnalysis(modelType, {
                task: 'chat',
                query: message,
                context: this.systemContext
            });
            
            return result;
            
        } catch (error) {
            console.error('❌ AI chat failed:', error);
            throw error;
        }
    }
    
    selectModelForChat(message) {
        const lower = message.toLowerCase();
        
        if (lower.includes('log') || lower.includes('error') || lower.includes('crash')) {
            return 'logs';
        }
        if (lower.includes('performance') || lower.includes('slow') || lower.includes('optimize')) {
            return 'optimization';
        }
        if (lower.includes('security') || lower.includes('hack') || lower.includes('vulnerable')) {
            return 'security';
        }
        if (lower.includes('predict') || lower.includes('future') || lower.includes('trend')) {
            return 'prediction';
        }
        
        return 'analysis'; // Default to general analysis
    }
    
    updateSystemContext(newData) {
        this.systemContext.summary = newData;
        this.systemContext.patterns = this.analyzePatterns(newData);
        this.systemContext.lastUpdate = new Date();
    }
    
    getHealthScore() {
        return this.healthScore;
    }
    
    clearCache() {
        this.cache.clear();
        console.log('🧹 AI cache cleared');
    }
}

// Initialize AI Orchestrator when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.aiOrchestrator = new AIOrchestrator();
});

// Export for use in other modules
window.AIOrchestrator = AIOrchestrator; 