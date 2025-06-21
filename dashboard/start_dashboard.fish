#!/usr/bin/env fish

# Evil Space Dashboard Launcher
# Starts the comprehensive monitoring dashboard

function start_dashboard
    # Detect dotfiles directory - could be run from dotfiles root or dashboard subdirectory
    if test -f "evil_space_dashboard.py"
        # Running from dashboard directory
        set DOTFILES_DIR (dirname (pwd))
        set DASHBOARD_DIR (pwd)
    else if test -f "dashboard/evil_space_dashboard.py"
        # Running from dotfiles root
        set DOTFILES_DIR (pwd)
        set DASHBOARD_DIR $DOTFILES_DIR/dashboard
    else
        echo "❌ Error: Cannot find dashboard. Run from either:"
        echo "   ~/dotfiles/ (root directory)"
        echo "   ~/dotfiles/dashboard/ (dashboard directory)"
        return 1
    end
    
    set LOG_FILE $DOTFILES_DIR/logs/dashboard_(date +%Y%m%d_%H%M%S).log
    
    echo "🚀 Starting Evil Space Dashboard..."
    echo "📍 Dotfiles directory: $DOTFILES_DIR"
    echo "📊 Dashboard directory: $DASHBOARD_DIR"
    echo "📝 Log file: $LOG_FILE"
    
    # Check if dashboard file exists (should always pass after directory detection above)
    if not test -f "$DASHBOARD_DIR/evil_space_dashboard.py"
        echo "❌ Error: Dashboard file not found at $DASHBOARD_DIR/evil_space_dashboard.py"
        return 1
    end
    
    # Create logs directory if it doesn't exist
    mkdir -p (dirname $LOG_FILE)
    
    # Check for Python
    if not command -v python >/dev/null 2>&1
        echo "❌ Error: Python not found. Please install Python 3."
        return 1
    end
    
    echo "🔍 Checking system dependencies..."
    
    # Check for psutil (optional)
    if python -c "import psutil" >/dev/null 2>&1
        echo "✅ psutil available - Full system monitoring enabled"
    else
        echo "⚠️  psutil not available - Using basic system monitoring"
        echo "   Install with: sudo pacman -S python-psutil"
    end
    
    # Check for ROCm (AMD GPU monitoring)
    if command -v rocm-smi >/dev/null 2>&1
        echo "✅ ROCm available - GPU monitoring enabled"
    else
        echo "⚠️  ROCm not available - GPU monitoring disabled"
    end
    
    echo ""
    echo "🔌 Checking port 8080..."
    
    # More aggressive port cleanup
    echo "🔄 Cleaning up any existing dashboard processes..."
    pkill -f "evil_space_dashboard" 2>/dev/null || true
    sleep 1
    
    # Kill anything using port 8080
    if command -v fuser >/dev/null 2>&1
        fuser -k 8080/tcp 2>/dev/null || true
        sleep 1
    end
    
    if command -v lsof >/dev/null 2>&1
        # Check if port 8080 is in use and kill the process
        set PORT_PID (lsof -ti:8080 2>/dev/null)
        if test -n "$PORT_PID"
            echo "⚠️  Port 8080 is in use by PID $PORT_PID"
            echo "🔄 Killing existing process..."
            kill -9 $PORT_PID 2>/dev/null
            sleep 2
            
            # Double-check if process was killed
            set PORT_PID_CHECK (lsof -ti:8080 2>/dev/null)
            if test -n "$PORT_PID_CHECK"
                echo "❌ Failed to kill process on port 8080"
                echo "   Please manually kill the process or use a different port"
                return 1
            else
                echo "✅ Port 8080 cleared successfully"
            end
        else
            echo "✅ Port 8080 is available"
        end
    else
        echo "⚠️  lsof not found, cannot check port status."
        echo "   Please install lsof or ensure port 8080 is free."
    end
    
    echo ""
    echo "🌟 Evil Space Dashboard Features:"
    echo "   • Real-time system monitoring"
    echo "   • GPU metrics and temperature"
    echo "   • Comprehensive log management" 
    echo "   • Dynamic theme switching"
    echo "   • Script execution and monitoring"
    echo "   • AI-powered insights"
    echo ""
    echo "🌐 Dashboard will be available at: http://localhost:8080"
    echo "🔄 Auto-updates: 2s (active) / 30s (inactive)"
    echo "⏸️  Updates pause when tab is hidden"
    echo ""
    echo "📝 Logs will be saved to: $LOG_FILE"
    echo "🛑 Press Ctrl+C to stop the dashboard"
    echo ""
    
    # Start the dashboard with logging
    cd $DASHBOARD_DIR
    python evil_space_dashboard.py 2>&1 | tee $LOG_FILE
end

# Run the function
start_dashboard 