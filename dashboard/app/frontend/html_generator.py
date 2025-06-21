def get_dashboard_html():
    """Generate the main dashboard HTML"""
    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Evil Space Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #16213e 100%);
            color: #e0e0e0;
            min-height: 100vh;
            overflow-x: hidden;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem;
        }
        
        .header {
            text-align: center;
            margin-bottom: 3rem;
            position: relative;
        }
        
        .title {
            font-size: 3rem;
            font-weight: 700;
            background: linear-gradient(45deg, #64ffda, #00bcd4, #03a9f4);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: 0 0 30px rgba(100, 255, 218, 0.3);
            margin-bottom: 0.5rem;
        }
        
        .subtitle {
            font-size: 1.2rem;
            color: #90a4ae;
            font-weight: 300;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 2rem;
            margin-bottom: 2rem;
        }
        
        .card {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 16px;
            padding: 2rem;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, #64ffda, #00bcd4, #03a9f4);
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
        }
        
        .card-title {
            font-size: 1.5rem;
            font-weight: 600;
            margin-bottom: 1rem;
            color: #64ffda;
        }
        
        h4.card-title {
            font-size: 1.2rem;
            margin-bottom: 0.8rem;
        }
        
        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
            padding: 0.5rem 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .metric:last-child {
            border-bottom: none;
            margin-bottom: 0;
        }
        
        .metric-label {
            color: #b0bec5;
            font-weight: 500;
        }
        
        .metric-value {
            color: #e0e0e0;
            font-weight: 600;
            font-family: 'Courier New', monospace;
        }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        
        .status-online { background-color: #4caf50; }
        .status-warning { background-color: #ff9800; }
        .status-error { background-color: #f44336; }
        
        .loading {
            text-align: center;
            padding: 2rem;
            color: #64ffda;
        }
        
        .nav-tabs {
            display: flex;
            gap: 1rem;
            margin-bottom: 2rem;
            border-bottom: 2px solid rgba(255, 255, 255, 0.1);
        }
        
        .nav-tab {
            background: none;
            border: none;
            color: #90a4ae;
            padding: 1rem 2rem;
            cursor: pointer;
            border-bottom: 2px solid transparent;
            transition: all 0.3s ease;
            font-size: 1rem;
            font-weight: 500;
        }
        
        .nav-tab.active,
        .nav-tab:hover {
            color: #64ffda;
            border-bottom-color: #64ffda;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        
        .updating {
            animation: pulse 1s infinite;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="title">Evil Space Dashboard</h1>
            <p class="subtitle">Comprehensive Monitoring & Management</p>
        </div>
        
        <div class="nav-tabs">
            <button class="nav-tab active" onclick="showTab('overview')">Overview</button>
            <button class="nav-tab" onclick="showTab('system')">System</button>
            <button class="nav-tab" onclick="showTab('logs')">Logs</button>
            <button class="nav-tab" onclick="showTab('log-viewer')">Log Viewer</button>
            <button class="nav-tab" onclick="showTab('themes')">Themes</button>
            <button class="nav-tab" onclick="showTab('scripts')">Scripts</button>
        </div>
        
        <div id="overview" class="tab-content active">
            <div class="grid">
                <div class="card">
                    <h3 class="card-title">System Status</h3>
                    <div id="system-overview" class="loading">Loading system data...</div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">GPU Status</h3>
                    <div id="gpu-overview" class="loading">Loading GPU data...</div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">Process Monitor</h3>
                    <div id="processes-overview" class="loading">Loading process data...</div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">Network Status</h3>
                    <div id="network-overview" class="loading">Loading network data...</div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">Recent Logs</h3>
                    <div id="logs-overview" class="loading">Loading logs data...</div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">Theme Status</h3>
                    <div id="themes-overview" class="loading">Loading themes data...</div>
                </div>
            </div>
        </div>
        
        <div id="system" class="tab-content">
            <div class="grid">
                <div class="card">
                    <h3 class="card-title">Detailed System Information</h3>
                    <div id="system-details" class="loading">Loading detailed system data...</div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">Process Details</h3>
                    <div id="processes-details" class="loading">Loading process details...</div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">Network Details</h3>
                    <div id="network-details" class="loading">Loading network details...</div>
                </div>
            </div>
        </div>
        
        <div id="logs" class="tab-content">
            <div class="card">
                <h3 class="card-title">Log Management</h3>
                <div id="logs-details" class="loading">Loading logs data...</div>
            </div>
        </div>
        
        <div id="log-viewer" class="tab-content">
            <div class="grid">
                <div class="card">
                    <h3 class="card-title">Log Viewer</h3>
                    <div style="margin-bottom: 1rem;">
                        <select id="log-file-select" onchange="loadSelectedLog()" style="margin-right: 1rem; padding: 0.5rem; background: rgba(0,0,0,0.6); border: 1px solid rgba(100,255,218,0.3); color: #e0e0e0; border-radius: 4px; min-width: 300px; max-height: 200px; overflow-y: auto;">
                            <option value="">Select a log file...</option>
                        </select>
                        <select id="log-level-filter" onchange="applyLogFilters()" style="margin-right: 1rem; padding: 0.5rem; background: rgba(0,0,0,0.6); border: 1px solid rgba(100,255,218,0.3); color: #e0e0e0; border-radius: 4px;">
                            <option value="ALL">All Levels</option>
                            <option value="ERROR">Errors</option>
                            <option value="WARNING">Warnings</option>
                            <option value="INFO">Info</option>
                            <option value="DEBUG">Debug</option>
                        </select>
                        <input type="text" id="log-search-input" placeholder="Search logs..." onkeyup="applyLogFilters()" style="padding: 0.5rem; background: rgba(0,0,0,0.6); border: 1px solid rgba(100,255,218,0.3); color: #e0e0e0; border-radius: 4px; margin-right: 1rem; min-width: 150px;">
                        <button onclick="refreshLogContent()" style="padding: 0.5rem 1rem; background: #64ffda; color: #000; border: none; border-radius: 4px; cursor: pointer; font-weight: 600;">Refresh</button>
                    </div>
                    <div id="log-content" style="background: rgba(0,0,0,0.3); padding: 1rem; border-radius: 8px; max-height: 500px; overflow-y: auto; font-family: 'Courier New', monospace; font-size: 0.9rem; line-height: 1.4;">
                        <div style="color: #90a4ae; text-align: center; padding: 2rem;">Select a log file to view its content</div>
                    </div>
                </div>
                
                <div class="card">
                    <h3 class="card-title">Log Statistics</h3>
                    <div id="log-stats">
                        <div style="color: #90a4ae; text-align: center; padding: 2rem;">Select a log file to view statistics</div>
                    </div>
                </div>
            </div>
        </div>
        
        <div id="themes" class="tab-content">
            <div class="card">
                <h3 class="card-title">Theme Management</h3>
                <div id="themes-details" class="loading">Loading themes data...</div>
            </div>
        </div>
        
        <div id="scripts" class="tab-content">
            <div class="card">
                <h3 class="card-title">Script Management</h3>
                <div id="scripts-details" class="loading">Loading scripts data...</div>
            </div>
        </div>
    </div>
    
    <script>
        let updateInterval;
        let isActive = true;
        let currentTab = 'overview';
        
        // Tab switching
        function showTab(tabName) {
            loadTabData(tabName);
        }
        
        // Load data for specific tab
        function loadTabData(tab) {
            currentTab = tab;
            
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(t => t.style.display = 'none');
            document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
            
            // Show selected tab
            document.getElementById(tab).style.display = 'block';
            document.querySelector(`[onclick="showTab('${tab}')"]`).classList.add('active');
            
            // Load tab-specific data
            switch(tab) {
                case 'overview':
                    loadSystemOverview();
                    loadGpuOverview();
                    loadProcessesOverview();
                    loadNetworkOverview();
                    loadLogsOverview();
                    loadThemesOverview();
                    break;
                case 'system':
                    loadSystemDetails();
                    loadProcessDetails();
                    loadNetworkDetails();
                    break;
                case 'logs':
                    loadLogsDetails();
                    break;
                case 'log-viewer':
                    loadLogFileList();
                    break;
                case 'themes':
                    loadThemesDetails();
                    break;
                case 'scripts':
                    loadScriptsDetails();
                    break;
            }
        }
        
        // API fetch helper
        async function fetchAPI(endpoint) {
            try {
                const response = await fetch(`/api/${endpoint}`);
                return await response.json();
            } catch (error) {
                console.error(`Error fetching ${endpoint}:`, error);
                return { error: error.message };
            }
        }
        
        // System overview
        async function loadSystemOverview() {
            const element = document.getElementById('system-overview');
            element.classList.add('updating');
            
            const data = await fetchAPI('system');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                element.innerHTML = `
                    <div class="metric">
                        <span class="metric-label">
                            <span class="status-indicator status-online"></span>Status
                        </span>
                        <span class="metric-value">Online</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Uptime</span>
                        <span class="metric-value">${data.uptime || 'N/A'}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">CPU Usage</span>
                        <span class="metric-value">${data.cpu_usage ? data.cpu_usage.toFixed(1) + '%' : 'N/A'}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Memory Usage</span>
                        <span class="metric-value">${data.memory ? (data.memory.percent.toFixed(1) + '%') : 'N/A'}</span>
                    </div>
                `;
            }
            
            element.classList.remove('updating');
        }
        
        // GPU overview
        async function loadGpuOverview() {
            const element = document.getElementById('gpu-overview');
            element.classList.add('updating');
            
            const data = await fetchAPI('gpu');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else if (!data.available) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-warning"></span>GPU not detected</div>`;
            } else {
                element.innerHTML = `
                    <div class="metric">
                        <span class="metric-label">
                            <span class="status-indicator status-online"></span>${data.name}
                        </span>
                        <span class="metric-value">Online</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Usage</span>
                        <span class="metric-value">${data.usage !== null ? data.usage + '%' : 'N/A'}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">VRAM</span>
                        <span class="metric-value">${data.vram_percent !== null ? data.vram_percent + '%' : 'N/A'}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Temperature</span>
                        <span class="metric-value">${data.temperature !== null ? data.temperature.toFixed(1) + '°C' : 'N/A'}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Fan Speed</span>
                        <span class="metric-value">${data.fan_speed !== null ? data.fan_speed + '%' : 'N/A'}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Power Draw</span>
                        <span class="metric-value">${data.power !== null ? data.power.toFixed(1) + 'W' : 'N/A'}</span>
                    </div>
                `;
            }
            
            element.classList.remove('updating');
        }
        
        // Process overview
        async function loadProcessesOverview() {
            const element = document.getElementById('processes-overview');
            element.classList.add('updating');
            
            const data = await fetchAPI('processes');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                const topProcess = data.top_cpu_processes && data.top_cpu_processes[0];
                element.innerHTML = `
                    <div class="metric">
                        <span class="metric-label">Total Processes</span>
                        <span class="metric-value">${data.total_processes}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Running</span>
                        <span class="metric-value">${data.process_summary?.running || 0}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Top CPU Process</span>
                        <span class="metric-value">${topProcess ? topProcess.name + ' (' + topProcess.cpu_percent.toFixed(1) + '%)' : 'N/A'}</span>
                    </div>
                `;
            }
            
            element.classList.remove('updating');
        }
        
        // Network overview
        async function loadNetworkOverview() {
            const element = document.getElementById('network-overview');
            element.classList.add('updating');
            
            const data = await fetchAPI('network');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                const interfaceCount = Object.keys(data.interfaces || {}).length;
                const totalSent = (data.total_bytes_sent / 1024 / 1024 / 1024).toFixed(2);
                const totalRecv = (data.total_bytes_recv / 1024 / 1024 / 1024).toFixed(2);
                
                element.innerHTML = `
                    <div class="metric">
                        <span class="metric-label">Active Interfaces</span>
                        <span class="metric-value">${interfaceCount}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Data Sent</span>
                        <span class="metric-value">${totalSent} GB</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Data Received</span>
                        <span class="metric-value">${totalRecv} GB</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Active Connections</span>
                        <span class="metric-value">${data.active_connections || 0}</span>
                    </div>
                `;
            }
            
            element.classList.remove('updating');
        }
        
        // Logs overview
        async function loadLogsOverview() {
            const element = document.getElementById('logs-overview');
            element.classList.add('updating');
            
            const data = await fetchAPI('logs');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                const recentLog = data.recent_logs[0];
                element.innerHTML = `
                    <div class="metric">
                        <span class="metric-label">Total Logs</span>
                        <span class="metric-value">${data.total_logs}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Categories</span>
                        <span class="metric-value">${Object.keys(data.categories).length}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Most Recent</span>
                        <span class="metric-value">${recentLog ? recentLog.name : 'None'}</span>
                    </div>
                `;
            }
            
            element.classList.remove('updating');
        }
        
        // Themes overview
        async function loadThemesOverview() {
            const element = document.getElementById('themes-overview');
            element.classList.add('updating');
            
            const data = await fetchAPI('themes');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                element.innerHTML = `
                    <div class="metric">
                        <span class="metric-label">Current Theme</span>
                        <span class="metric-value">${data.current_theme || 'Unknown'}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Available Themes</span>
                        <span class="metric-value">${data.available_themes ? data.available_themes.length : 0}</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Wallpapers</span>
                        <span class="metric-value">${data.wallpapers ? Object.keys(data.wallpapers).length : 0} categories</span>
                    </div>
                `;
            }
            
            element.classList.remove('updating');
        }
        
        // Detailed views (properly formatted)
        async function loadSystemDetails() {
            const element = document.getElementById('system-details');
            element.classList.add('updating');
            
            const data = await fetchAPI('system');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                let html = '<div class="grid">';
                
                // System Status Card
                html += `
                    <div class="card">
                        <h4 class="card-title">System Status</h4>
                        <div class="metric">
                            <span class="metric-label">Uptime</span>
                            <span class="metric-value">${data.uptime || 'N/A'}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Load Average</span>
                            <span class="metric-value">${data.load_average ? data.load_average.join(', ') : 'N/A'}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Processes</span>
                            <span class="metric-value">${data.processes || 'N/A'}</span>
                        </div>
                    </div>
                `;
                
                // CPU Card
                html += `
                    <div class="card">
                        <h4 class="card-title">CPU Information</h4>
                        <div class="metric">
                            <span class="metric-label">Usage</span>
                            <span class="metric-value">${data.cpu_usage ? data.cpu_usage.toFixed(1) + '%' : 'N/A'}</span>
                        </div>
                    </div>
                `;
                
                // Memory Card
                if (data.memory) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Memory Information</h4>
                            <div class="metric">
                                <span class="metric-label">Total</span>
                                <span class="metric-value">${(data.memory.total / 1024 / 1024 / 1024).toFixed(1)} GB</span>
                            </div>
                            <div class="metric">
                                <span class="metric-label">Used</span>
                                <span class="metric-value">${(data.memory.used / 1024 / 1024 / 1024).toFixed(1)} GB</span>
                            </div>
                            <div class="metric">
                                <span class="metric-label">Available</span>
                                <span class="metric-value">${(data.memory.available / 1024 / 1024 / 1024).toFixed(1)} GB</span>
                            </div>
                            <div class="metric">
                                <span class="metric-label">Usage</span>
                                <span class="metric-value">${data.memory.percent.toFixed(1)}%</span>
                            </div>
                        </div>
                    `;
                }
                
                // Disk Card
                if (data.disk) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Disk Information</h4>
                            <div class="metric">
                                <span class="metric-label">Total</span>
                                <span class="metric-value">${(data.disk.total / 1024 / 1024 / 1024).toFixed(1)} GB</span>
                            </div>
                            <div class="metric">
                                <span class="metric-label">Used</span>
                                <span class="metric-value">${(data.disk.used / 1024 / 1024 / 1024).toFixed(1)} GB</span>
                            </div>
                            <div class="metric">
                                <span class="metric-label">Free</span>
                                <span class="metric-value">${(data.disk.free / 1024 / 1024 / 1024).toFixed(1)} GB</span>
                            </div>
                            <div class="metric">
                                <span class="metric-label">Usage</span>
                                <span class="metric-value">${data.disk.percent.toFixed(1)}%</span>
                            </div>
                        </div>
                    `;
                }
                
                html += '</div>';
                element.innerHTML = html;
            }
            
            element.classList.remove('updating');
        }
        
        async function loadProcessesDetails() {
            const element = document.getElementById('processes-details');
            element.classList.add('updating');
            
            const data = await fetchAPI('processes');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                let html = '<div class="grid">';
                
                // Process Summary Card
                html += `
                    <div class="card">
                        <h4 class="card-title">Process Summary</h4>
                        <div class="metric">
                            <span class="metric-label">Total Processes</span>
                            <span class="metric-value">${data.total_processes}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Running</span>
                            <span class="metric-value">${data.process_summary?.running || 0}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Sleeping</span>
                            <span class="metric-value">${data.process_summary?.sleeping || 0}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Zombie</span>
                            <span class="metric-value">${data.process_summary?.zombie || 0}</span>
                        </div>
                    </div>
                `;
                
                // Top CPU Processes Card
                if (data.top_cpu_processes && data.top_cpu_processes.length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Top CPU Processes</h4>
                    `;
                    
                    data.top_cpu_processes.slice(0, 5).forEach(process => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${process.name} (PID: ${process.pid})</span>
                                <span class="metric-value">${process.cpu_percent.toFixed(1)}%</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                // Top Memory Processes Card
                if (data.top_memory_processes && data.top_memory_processes.length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Top Memory Processes</h4>
                    `;
                    
                    data.top_memory_processes.slice(0, 5).forEach(process => {
                        const memoryMB = process.memory_mb ? process.memory_mb.toFixed(1) : process.memory_percent.toFixed(1);
                        const unit = process.memory_mb ? 'MB' : '%';
                        html += `
                            <div class="metric">
                                <span class="metric-label">${process.name} (PID: ${process.pid})</span>
                                <span class="metric-value">${memoryMB} ${unit}</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                html += '</div>';
                element.innerHTML = html;
            }
            
            element.classList.remove('updating');
        }
        
        async function loadNetworkDetails() {
            const element = document.getElementById('network-details');
            element.classList.add('updating');
            
            const data = await fetchAPI('network');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                let html = '<div class="grid">';
                
                // Network Summary Card
                html += `
                    <div class="card">
                        <h4 class="card-title">Network Summary</h4>
                        <div class="metric">
                            <span class="metric-label">Active Interfaces</span>
                            <span class="metric-value">${Object.keys(data.interfaces || {}).length}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Total Sent</span>
                            <span class="metric-value">${(data.total_bytes_sent / 1024 / 1024 / 1024).toFixed(2)} GB</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Total Received</span>
                            <span class="metric-value">${(data.total_bytes_recv / 1024 / 1024 / 1024).toFixed(2)} GB</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Active Connections</span>
                            <span class="metric-value">${data.active_connections || 0}</span>
                        </div>
                    </div>
                `;
                
                // Network Interfaces Card
                if (data.interfaces && Object.keys(data.interfaces).length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Network Interfaces</h4>
                    `;
                    
                    Object.entries(data.interfaces).forEach(([interface, stats]) => {
                        const sentMB = (stats.bytes_sent / 1024 / 1024).toFixed(1);
                        const recvMB = (stats.bytes_recv / 1024 / 1024).toFixed(1);
                        html += `
                            <div class="metric">
                                <span class="metric-label">${interface}</span>
                                <span class="metric-value">↑${sentMB}MB ↓${recvMB}MB</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                // Connection Summary Card
                if (data.connection_summary && Object.keys(data.connection_summary).length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Connection Status</h4>
                    `;
                    
                    Object.entries(data.connection_summary).forEach(([status, count]) => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${status}</span>
                                <span class="metric-value">${count}</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                html += '</div>';
                element.innerHTML = html;
            }
            
            element.classList.remove('updating');
        }
        
        async function loadLogsDetails() {
            const element = document.getElementById('logs-details');
            element.classList.add('updating');
            
            const data = await fetchAPI('logs');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                let html = '<div class="grid">';
                
                // Log Summary Card
                html += `
                    <div class="card">
                        <h4 class="card-title">Log Summary</h4>
                        <div class="metric">
                            <span class="metric-label">Total Log Files</span>
                            <span class="metric-value">${data.total_logs}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Categories</span>
                            <span class="metric-value">${Object.keys(data.categories || {}).length}</span>
                        </div>
                    </div>
                `;
                
                // Recent Logs Card
                if (data.recent_logs && data.recent_logs.length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Recent Logs</h4>
                    `;
                    
                    data.recent_logs.slice(0, 5).forEach(log => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${log.name}</span>
                                <span class="metric-value">${log.size}</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                // Log Categories Card
                if (data.categories) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Log Categories</h4>
                    `;
                    
                    Object.entries(data.categories).forEach(([category, count]) => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${category}</span>
                                <span class="metric-value">${count} files</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                html += '</div>';
                element.innerHTML = html;
            }
            
            element.classList.remove('updating');
        }
        
        // Log Viewer Functions
        let currentLogFile = '';
        let currentLogContent = [];
        
        async function loadLogFileList() {
            const data = await fetchAPI('logs');
            const select = document.getElementById('log-file-select');
            
            if (data.error) {
                select.innerHTML = '<option value="">Error loading logs</option>';
                return;
            }
            
            select.innerHTML = '<option value="">Select a log file...</option>';
            
            if (data.recent_logs && data.recent_logs.length > 0) {
                // Group logs by category and source
                const logGroups = {};
                
                data.recent_logs.forEach(log => {
                    const groupKey = `${log.source}_${log.category}`;
                    if (!logGroups[groupKey]) {
                        logGroups[groupKey] = {
                            source: log.source,
                            category: log.category,
                            logs: []
                        };
                    }
                    logGroups[groupKey].logs.push(log);
                });
                
                // Create optgroups for better organization
                const sortedGroups = Object.values(logGroups).sort((a, b) => {
                    // Sort: journal first, then system, then dashboard
                    const sourceOrder = { 'journal': 0, 'system': 1, 'dashboard': 2 };
                    return sourceOrder[a.source] - sourceOrder[b.source];
                });
                
                sortedGroups.forEach(group => {
                    const optgroup = document.createElement('optgroup');
                    optgroup.label = `${group.source.toUpperCase()}: ${group.category.toUpperCase()}`;
                    
                    // Sort logs within group by modification time (newest first)
                    group.logs.sort((a, b) => (b.modified_timestamp || 0) - (a.modified_timestamp || 0));
                    
                    group.logs.forEach(log => {
                        const option = document.createElement('option');
                        // Use path for API calls (handles both filenames and special identifiers like journal:current)
                        option.value = log.filename || log.path;
                        option.textContent = log.name;
                        optgroup.appendChild(option);
                    });
                    
                    select.appendChild(optgroup);
                });
            }
        }
        
        async function loadSelectedLog() {
            const select = document.getElementById('log-file-select');
            const logFile = select.value;
            
            if (!logFile) {
                document.getElementById('log-content').innerHTML = '<div style="color: #90a4ae; text-align: center; padding: 2rem;">Select a log file to view its content</div>';
                document.getElementById('log-stats').innerHTML = '<div style="color: #90a4ae; text-align: center; padding: 2rem;">Select a log file to view statistics</div>';
                return;
            }
            
            currentLogFile = logFile;
            await refreshLogContent();
        }
        
        async function refreshLogContent() {
            if (!currentLogFile) return;
            
            const contentDiv = document.getElementById('log-content');
            const statsDiv = document.getElementById('log-stats');
            
            contentDiv.innerHTML = '<div style="color: #90a4ae; text-align: center; padding: 2rem;">Loading log content...</div>';
            statsDiv.innerHTML = '<div style="color: #90a4ae; text-align: center; padding: 2rem;">Loading statistics...</div>';
            
            try {
                // Load log content
                const contentResponse = await fetch(`/api/logs/content?file=${encodeURIComponent(currentLogFile)}&lines=100`);
                const contentData = await contentResponse.json();
                
                if (contentData.error) {
                    contentDiv.innerHTML = `<div style="color: #f44336;">Error: ${contentData.error}</div>`;
                } else {
                    currentLogContent = contentData.lines || [];
                    applyLogFilters();
                }
                
                // Load log stats
                const statsResponse = await fetch(`/api/logs/stats?file=${encodeURIComponent(currentLogFile)}`);
                const statsData = await statsResponse.json();
                
                if (statsData.error) {
                    statsDiv.innerHTML = `<div style="color: #f44336;">Error: ${statsData.error}</div>`;
                } else {
                    displayLogStats(statsData);
                }
                
            } catch (error) {
                contentDiv.innerHTML = `<div style="color: #f44336;">Network error: ${error.message}</div>`;
                statsDiv.innerHTML = `<div style="color: #f44336;">Network error: ${error.message}</div>`;
            }
        }
        
        function applyLogFilters() {
            const levelFilter = document.getElementById('log-level-filter').value;
            const searchInput = document.getElementById('log-search-input').value.toLowerCase();
            const contentDiv = document.getElementById('log-content');
            
            let filteredLines = currentLogContent;
            
            // Apply level filter
            if (levelFilter !== 'ALL') {
                filteredLines = filteredLines.filter(line => 
                    line.toLowerCase().includes(levelFilter.toLowerCase())
                );
            }
            
            // Apply search filter
            if (searchInput) {
                filteredLines = filteredLines.filter(line =>
                    line.toLowerCase().includes(searchInput)
                );
            }
            
            if (filteredLines.length === 0) {
                contentDiv.innerHTML = '<div style="color: #90a4ae; text-align: center; padding: 2rem;">No matching log entries found</div>';
                return;
            }
            
            let html = '';
            filteredLines.forEach(line => {
                let colorClass = '';
                if (line.toLowerCase().includes('error')) {
                    colorClass = 'color: #f44336;';
                } else if (line.toLowerCase().includes('warning') || line.toLowerCase().includes('warn')) {
                    colorClass = 'color: #ff9800;';
                } else if (line.toLowerCase().includes('info')) {
                    colorClass = 'color: #2196f3;';
                } else if (line.toLowerCase().includes('debug')) {
                    colorClass = 'color: #90a4ae;';
                } else {
                    colorClass = 'color: #e0e0e0;';
                }
                
                html += `<div style="${colorClass}">${escapeHtml(line)}</div>`;
            });
            
            contentDiv.innerHTML = html;
        }
        
        function displayLogStats(stats) {
            const statsDiv = document.getElementById('log-stats');
            
            let html = '';
            
            // File info
            html += `
                <div class="metric">
                    <span class="metric-label">File Size</span>
                    <span class="metric-value">${stats.size || 'Unknown'}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Total Lines</span>
                    <span class="metric-value">${stats.total_lines || 0}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Last Modified</span>
                    <span class="metric-value">${stats.last_modified || 'Unknown'}</span>
                </div>
            `;
            
            // Log levels if available
            if (stats.log_levels) {
                html += '<div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid rgba(255,255,255,0.1);">';
                html += '<h4 style="margin-bottom: 0.5rem; color: #64ffda;">Log Levels</h4>';
                
                Object.entries(stats.log_levels).forEach(([level, count]) => {
                    html += `
                        <div class="metric">
                            <span class="metric-label">${level}</span>
                            <span class="metric-value">${count}</span>
                        </div>
                    `;
                });
                
                html += '</div>';
            }
            
            statsDiv.innerHTML = html;
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        async function loadThemesDetails() {
            const element = document.getElementById('themes-details');
            element.classList.add('updating');
            
            const data = await fetchAPI('themes');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                let html = '<div class="grid">';
                
                // Current Theme Card
                html += `
                    <div class="card">
                        <h4 class="card-title">Current Theme</h4>
                        <div class="metric">
                            <span class="metric-label">Active Theme</span>
                            <span class="metric-value">${data.current_theme || 'Unknown'}</span>
                        </div>
                    </div>
                `;
                
                // Available Themes Card
                if (data.available_themes && data.available_themes.length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Available Themes (${data.available_themes.length})</h4>
                    `;
                    
                    data.available_themes.slice(0, 8).forEach(theme => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${theme}</span>
                                <span class="metric-value">✓</span>
                            </div>
                        `;
                    });
                    
                    if (data.available_themes.length > 8) {
                        html += `
                            <div class="metric">
                                <span class="metric-label">And ${data.available_themes.length - 8} more...</span>
                                <span class="metric-value"></span>
                            </div>
                        `;
                    }
                    
                    html += '</div>';
                }
                
                // Wallpapers Card
                if (data.wallpapers) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Wallpaper Categories</h4>
                    `;
                    
                    Object.entries(data.wallpapers).forEach(([category, count]) => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${category}</span>
                                <span class="metric-value">${count} images</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                // Theme Mappings Card
                if (data.theme_mappings) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Theme Mappings</h4>
                    `;
                    
                    Object.entries(data.theme_mappings).forEach(([category, theme]) => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${category}</span>
                                <span class="metric-value">${theme}</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                html += '</div>';
                element.innerHTML = html;
            }
            
            element.classList.remove('updating');
        }
        
        async function loadScriptsDetails() {
            const element = document.getElementById('scripts-details');
            element.classList.add('updating');
            
            const data = await fetchAPI('scripts');
            
            if (data.error) {
                element.innerHTML = `<div class="metric"><span class="status-indicator status-error"></span>Error: ${data.error}</div>`;
            } else {
                let html = '<div class="grid">';
                
                // Script Summary Card
                html += `
                    <div class="card">
                        <h4 class="card-title">Script Summary</h4>
                        <div class="metric">
                            <span class="metric-label">Total Scripts</span>
                            <span class="metric-value">${data.total_scripts || 0}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Categories</span>
                            <span class="metric-value">${Object.keys(data.categories || {}).length}</span>
                        </div>
                    </div>
                `;
                
                // Script Categories Card
                if (data.categories) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Script Categories</h4>
                    `;
                    
                    Object.entries(data.categories).forEach(([category, count]) => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${category}</span>
                                <span class="metric-value">${count} scripts</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                // Recent Scripts Card
                if (data.recent_scripts && data.recent_scripts.length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">Recent Scripts</h4>
                    `;
                    
                    data.recent_scripts.slice(0, 5).forEach(script => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${script.name}</span>
                                <span class="metric-value">${script.category}</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                // AI Scripts Card
                if (data.ai_scripts && data.ai_scripts.length > 0) {
                    html += `
                        <div class="card">
                            <h4 class="card-title">AI Integration Scripts</h4>
                    `;
                    
                    data.ai_scripts.forEach(script => {
                        html += `
                            <div class="metric">
                                <span class="metric-label">${script.name}</span>
                                <span class="metric-value">${script.status || 'Active'}</span>
                            </div>
                        `;
                    });
                    
                    html += '</div>';
                }
                
                html += '</div>';
                element.innerHTML = html;
            }
            
            element.classList.remove('updating');
        }
        
        // Update frequency management
        function startUpdates() {
            stopUpdates();
            const interval = isActive ? 2000 : 30000; // 2s active, 30s inactive
            updateInterval = setInterval(() => {
                if (document.visibilityState === 'visible') {
                    loadTabData(currentTab);
                }
            }, interval);
        }
        
        function stopUpdates() {
            if (updateInterval) {
                clearInterval(updateInterval);
                updateInterval = null;
            }
        }
        
        // Page visibility handling
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'visible') {
                isActive = true;
                startUpdates();
                loadTabData(currentTab);
            } else {
                isActive = false;
                startUpdates(); // Restart with longer interval
            }
        });
        
        // User activity detection
        let activityTimeout;
        function resetActivityTimer() {
            isActive = true;
            clearTimeout(activityTimeout);
            activityTimeout = setTimeout(() => {
                isActive = false;
                startUpdates(); // Restart with longer interval
            }, 30000); // 30 seconds of inactivity
        }
        
        ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'].forEach(event => {
            document.addEventListener(event, resetActivityTimer, { passive: true });
        });
        
        // Initialize
        window.addEventListener('load', () => {
            loadTabData('overview');
            startUpdates();
            resetActivityTimer();
        });
    </script>
</body>
</html>'''