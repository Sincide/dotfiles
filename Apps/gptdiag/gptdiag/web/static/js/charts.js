/**
 * GPTDiag Charts Manager
 * Handles all Chart.js charts for real-time system monitoring
 */

class ChartManager {
    constructor() {
        this.charts = {};
        this.colors = {
            cpu: '#06b6d4',
            memory: '#10b981',
            disk: '#f59e0b',
            background: 'rgba(255, 255, 255, 0.1)',
            border: 'rgba(255, 255, 255, 0.2)'
        };
        
        this.init();
    }
    
    init() {
        console.log('📊 Initializing Chart Manager');
        
        // Set Chart.js defaults for dark theme
        Chart.defaults.color = '#b0b0b0';
        Chart.defaults.borderColor = '#374151';
        Chart.defaults.backgroundColor = 'rgba(255, 255, 255, 0.1)';
        
        // Initialize all charts
        this.initializeProgressCharts();
        this.initializeHistoryCharts();
        
        console.log('✅ Charts initialized');
    }
    
    initializeProgressCharts() {
        // CPU Progress Chart
        const cpuCtx = document.getElementById('cpu-chart');
        if (cpuCtx) {
            this.charts.cpuProgress = new Chart(cpuCtx, {
                type: 'doughnut',
                data: {
                    datasets: [{
                        data: [0, 100],
                        backgroundColor: [this.colors.cpu, this.colors.background],
                        borderWidth: 0,
                        cutout: '75%'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: { enabled: false }
                    },
                    rotation: -90,
                    circumference: 180,
                    animation: {
                        animateRotate: true,
                        duration: 1000
                    }
                }
            });
        }
        
        // Memory Progress Chart
        const memoryCtx = document.getElementById('memory-chart');
        if (memoryCtx) {
            this.charts.memoryProgress = new Chart(memoryCtx, {
                type: 'doughnut',
                data: {
                    datasets: [{
                        data: [0, 100],
                        backgroundColor: [this.colors.memory, this.colors.background],
                        borderWidth: 0,
                        cutout: '75%'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: { enabled: false }
                    },
                    rotation: -90,
                    circumference: 180,
                    animation: {
                        animateRotate: true,
                        duration: 1000
                    }
                }
            });
        }
        
        // Disk Progress Chart
        const diskCtx = document.getElementById('disk-chart');
        if (diskCtx) {
            this.charts.diskProgress = new Chart(diskCtx, {
                type: 'doughnut',
                data: {
                    datasets: [{
                        data: [0, 100],
                        backgroundColor: [this.colors.disk, this.colors.background],
                        borderWidth: 0,
                        cutout: '75%'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: { enabled: false }
                    },
                    rotation: -90,
                    circumference: 180,
                    animation: {
                        animateRotate: true,
                        duration: 1000
                    }
                }
            });
        }
    }
    
    initializeHistoryCharts() {
        // CPU History Chart
        const cpuHistoryCtx = document.getElementById('cpu-history-chart');
        if (cpuHistoryCtx) {
            this.charts.cpuHistory = new Chart(cpuHistoryCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'CPU Usage %',
                        data: [],
                        borderColor: this.colors.cpu,
                        backgroundColor: this.colors.cpu + '20',
                        fill: true,
                        tension: 0.4,
                        pointRadius: 0,
                        pointHoverRadius: 4,
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            display: true,
                            grid: {
                                color: this.colors.border
                            },
                            ticks: {
                                maxTicksLimit: 10,
                                callback: function(value, index, values) {
                                    const date = new Date(this.getLabelForValue(value));
                                    return date.toLocaleTimeString('en-US', { 
                                        hour12: false, 
                                        hour: '2-digit', 
                                        minute: '2-digit' 
                                    });
                                }
                            }
                        },
                        y: {
                            display: true,
                            min: 0,
                            max: 100,
                            grid: {
                                color: this.colors.border
                            },
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            mode: 'index',
                            intersect: false,
                            backgroundColor: 'rgba(0, 0, 0, 0.8)',
                            titleColor: '#ffffff',
                            bodyColor: '#ffffff',
                            borderColor: this.colors.cpu,
                            borderWidth: 1,
                            callbacks: {
                                title: function(context) {
                                    const date = new Date(context[0].label);
                                    return date.toLocaleString();
                                },
                                label: function(context) {
                                    return `CPU: ${context.parsed.y.toFixed(1)}%`;
                                }
                            }
                        }
                    },
                    interaction: {
                        mode: 'nearest',
                        axis: 'x',
                        intersect: false
                    },
                    animation: {
                        duration: 750,
                        easing: 'easeInOutQuart'
                    }
                }
            });
        }
        
        // Memory History Chart
        const memoryHistoryCtx = document.getElementById('memory-history-chart');
        if (memoryHistoryCtx) {
            this.charts.memoryHistory = new Chart(memoryHistoryCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Memory Usage %',
                        data: [],
                        borderColor: this.colors.memory,
                        backgroundColor: this.colors.memory + '20',
                        fill: true,
                        tension: 0.4,
                        pointRadius: 0,
                        pointHoverRadius: 4,
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            display: true,
                            grid: {
                                color: this.colors.border
                            },
                            ticks: {
                                maxTicksLimit: 10,
                                callback: function(value, index, values) {
                                    const date = new Date(this.getLabelForValue(value));
                                    return date.toLocaleTimeString('en-US', { 
                                        hour12: false, 
                                        hour: '2-digit', 
                                        minute: '2-digit' 
                                    });
                                }
                            }
                        },
                        y: {
                            display: true,
                            min: 0,
                            max: 100,
                            grid: {
                                color: this.colors.border
                            },
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            mode: 'index',
                            intersect: false,
                            backgroundColor: 'rgba(0, 0, 0, 0.8)',
                            titleColor: '#ffffff',
                            bodyColor: '#ffffff',
                            borderColor: this.colors.memory,
                            borderWidth: 1,
                            callbacks: {
                                title: function(context) {
                                    const date = new Date(context[0].label);
                                    return date.toLocaleString();
                                },
                                label: function(context) {
                                    return `Memory: ${context.parsed.y.toFixed(1)}%`;
                                }
                            }
                        }
                    },
                    interaction: {
                        mode: 'nearest',
                        axis: 'x',
                        intersect: false
                    },
                    animation: {
                        duration: 750,
                        easing: 'easeInOutQuart'
                    }
                }
            });
        }
    }
    
    updateProgressCharts(data) {
        // Update CPU progress
        if (this.charts.cpuProgress && data.cpu_percent !== undefined) {
            const cpuPercent = Math.round(data.cpu_percent);
            this.charts.cpuProgress.data.datasets[0].data = [cpuPercent, 100 - cpuPercent];
            
            // Update color based on usage
            const cpuColor = this.getUsageColor(cpuPercent, 'cpu');
            this.charts.cpuProgress.data.datasets[0].backgroundColor[0] = cpuColor;
            
            this.charts.cpuProgress.update('none'); // No animation for real-time updates
        }
        
        // Update Memory progress
        if (this.charts.memoryProgress && data.memory_percent !== undefined) {
            const memoryPercent = Math.round(data.memory_percent);
            this.charts.memoryProgress.data.datasets[0].data = [memoryPercent, 100 - memoryPercent];
            
            // Update color based on usage
            const memoryColor = this.getUsageColor(memoryPercent, 'memory');
            this.charts.memoryProgress.data.datasets[0].backgroundColor[0] = memoryColor;
            
            this.charts.memoryProgress.update('none');
        }
        
        // Update Disk progress
        if (this.charts.diskProgress && data.disk_percent !== undefined) {
            const diskPercent = Math.round(data.disk_percent);
            this.charts.diskProgress.data.datasets[0].data = [diskPercent, 100 - diskPercent];
            
            // Update color based on usage
            const diskColor = this.getUsageColor(diskPercent, 'disk');
            this.charts.diskProgress.data.datasets[0].backgroundColor[0] = diskColor;
            
            this.charts.diskProgress.update('none');
        }
    }
    
    updateHistoryCharts(systemData) {
        // Update CPU history
        if (this.charts.cpuHistory && systemData.cpu.length > 0) {
            const labels = systemData.timestamps.map(ts => ts.toISOString());
            
            this.charts.cpuHistory.data.labels = labels;
            this.charts.cpuHistory.data.datasets[0].data = systemData.cpu;
            this.charts.cpuHistory.update('none');
        }
        
        // Update Memory history
        if (this.charts.memoryHistory && systemData.memory.length > 0) {
            const labels = systemData.timestamps.map(ts => ts.toISOString());
            
            this.charts.memoryHistory.data.labels = labels;
            this.charts.memoryHistory.data.datasets[0].data = systemData.memory;
            this.charts.memoryHistory.update('none');
        }
    }
    
    getUsageColor(percent, type) {
        const baseColors = {
            cpu: { low: '#06b6d4', medium: '#f59e0b', high: '#ef4444' },
            memory: { low: '#10b981', medium: '#f59e0b', high: '#ef4444' },
            disk: { low: '#f59e0b', medium: '#f59e0b', high: '#ef4444' }
        };
        
        const thresholds = {
            cpu: { medium: 50, high: 80 },
            memory: { medium: 60, high: 85 },
            disk: { medium: 70, high: 90 }
        };
        
        const colors = baseColors[type];
        const threshold = thresholds[type];
        
        if (percent < threshold.medium) {
            return colors.low;
        } else if (percent < threshold.high) {
            return colors.medium;
        } else {
            return colors.high;
        }
    }
    
    destroy() {
        // Clean up all charts
        Object.values(this.charts).forEach(chart => {
            if (chart && typeof chart.destroy === 'function') {
                chart.destroy();
            }
        });
        this.charts = {};
    }
    
    resize() {
        // Resize all charts
        Object.values(this.charts).forEach(chart => {
            if (chart && typeof chart.resize === 'function') {
                chart.resize();
            }
        });
    }
}

// Initialize charts when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.chartManager = new ChartManager();
});

// Handle window resize
window.addEventListener('resize', () => {
    if (window.chartManager) {
        window.chartManager.resize();
    }
});

// Export for use in other modules
window.ChartManager = ChartManager; 