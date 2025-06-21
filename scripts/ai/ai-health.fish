#!/usr/bin/fish

# ============================================================================
# AI HEALTH CHECK - COMPREHENSIVE OLLAMA & LOCAL LLM DIAGNOSTICS
# ============================================================================
# Monitor and diagnose your local AI setup
# Author: Fish Script
# Version: 1.0
# 
# Features:
# - System resource monitoring (RAM, CPU, GPU)
# - Ollama service health checks
# - Model analysis and benchmarking
# - GPU acceleration detection
# - Performance recommendations
# - Interactive menu interface
#
# Requirements:
# - Fish shell
# - Ollama (for AI features)
# - Optional: nvidia-smi (for NVIDIA GPU info)
# - Optional: rocm-smi (for AMD GPU info)
#
# Usage:
#   ./ai-health.fish           # Interactive menu
#   ./ai-health.fish quick     # Fast status check
#   ./ai-health.fish gpu       # GPU diagnostics
# ============================================================================

# Colors and styling
function info
    set_color blue; echo -n "[ℹ]"; set_color normal; echo " $argv"
end

function success
    set_color green; echo -n "[✓]"; set_color normal; echo " $argv"
end

function error
    set_color red; echo -n "[✗]"; set_color normal; echo " $argv"
end

function warn
    set_color yellow; echo -n "[⚠]"; set_color normal; echo " $argv"
end

function header
    echo
    set_color purple; echo "━━━ $argv ━━━"; set_color normal
end

function subheader
    set_color cyan; echo "┌─ $argv"; set_color normal
end

function item
    echo "│ $argv"
end

function good
    set_color green; echo -n "│ ✓ "; set_color normal; echo $argv
end

function bad
    set_color red; echo -n "│ ✗ "; set_color normal; echo $argv
end

function neutral
    set_color yellow; echo -n "│ ◦ "; set_color normal; echo $argv
end

# Convert bytes to human readable
function human_size
    set bytes $argv[1]
    set units B KB MB GB TB
    set size $bytes
    set unit_index 1
    
    while test $size -gt 1024 -a $unit_index -lt (count $units)
        set size (math "$size / 1024")
        set unit_index (math "$unit_index + 1")
    end
    
    printf "%.1f %s" $size $units[$unit_index]
end

# Get GPU info
function check_gpu
    subheader "GPU Information"
    
    # Check for NVIDIA
    if command -v nvidia-smi >/dev/null 2>&1
        set gpu_info (nvidia-smi --query-gpu=name,memory.total,memory.used,utilization.gpu --format=csv,noheader,nounits 2>/dev/null)
        if test -n "$gpu_info"
            good "NVIDIA GPU detected"
            for line in $gpu_info
                set fields (string split "," $line)
                set name (string trim $fields[1])
                set total_mem (string trim $fields[2])
                set used_mem (string trim $fields[3])
                set utilization (string trim $fields[4])
                
                item "GPU: $name"
                item "VRAM: $used_mem MB / $total_mem MB used"
                item "Utilization: $utilization%"
            end
        else
            neutral "NVIDIA drivers installed but no GPU info available"
        end
    else if command -v rocm-smi >/dev/null 2>&1
        good "AMD ROCm detected"
        set rocm_info (rocm-smi --showtemp --showmeminfo --showuse 2>/dev/null | grep -E "(Card|Temperature|Memory|GPU use)")
        if test -n "$rocm_info"
            echo $rocm_info | while read line
                item (string trim $line)
            end
        end
    else if test -e /sys/class/drm/card0/device/vendor
        set vendor_id (cat /sys/class/drm/card0/device/vendor 2>/dev/null)
        switch $vendor_id
            case "0x10de"
                neutral "NVIDIA GPU detected but nvidia-smi not available"
            case "0x1002"
                neutral "AMD GPU detected but ROCm tools not available"
            case "0x8086"
                neutral "Intel GPU detected"
            case "*"
                neutral "GPU detected (vendor: $vendor_id)"
        end
    else
        bad "No dedicated GPU detected"
    end
    
    # Check for GPU compute libraries
    if test -e /usr/local/cuda/version.txt
        set cuda_version (cat /usr/local/cuda/version.txt | grep "CUDA Version" | awk '{print $3}')
        good "CUDA $cuda_version available"
    else if command -v nvcc >/dev/null 2>&1
        set cuda_version (nvcc --version | grep "release" | awk '{print $6}' | cut -d, -f1)
        good "CUDA $cuda_version available"
    else
        neutral "CUDA not detected"
    end
end

# Check system resources
function check_system
    subheader "System Resources"
    
    # RAM
    set total_ram (free -b | awk '/^Mem:/{print $2}')
    set used_ram (free -b | awk '/^Mem:/{print $3}')
    set available_ram (free -b | awk '/^Mem:/{print $7}')
    
    good "RAM: "(human_size $used_ram)" / "(human_size $total_ram)" used"
    item "Available: "(human_size $available_ram)
    
    if test $available_ram -lt 8000000000  # Less than 8GB available
        warn "Low available RAM for large models"
    end
    
    # CPU
    set cpu_cores (nproc)
    set cpu_model (grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | string trim)
    good "CPU: $cpu_model ($cpu_cores cores)"
    
    # Disk space
    set disk_info (df -h . | tail -1)
    set disk_usage (echo $disk_info | awk '{print $5}' | tr -d %)
    set disk_avail (echo $disk_info | awk '{print $4}')
    
    if test $disk_usage -lt 90
        good "Disk space: $disk_avail available"
    else
        warn "Disk space: $disk_avail available ($(100-$disk_usage)% free)"
    end
end

# Check Ollama installation and service
function check_ollama_service
    subheader "Ollama Service"
    
    if command -v ollama >/dev/null 2>&1
        good "Ollama binary found: "(which ollama)
        
        set ollama_version (ollama --version 2>/dev/null | head -1)
        if test -n "$ollama_version"
            item "Version: $ollama_version"
        end
    else
        bad "Ollama not installed"
        item "Install: curl -fsSL https://ollama.ai/install.sh | sh"
        return 1
    end
    
    # Check if service is running
    if pgrep -f ollama >/dev/null 2>&1
        good "Ollama service is running"
        
        set ollama_pid (pgrep -f ollama)
        set ollama_mem (ps -p $ollama_pid -o rss= 2>/dev/null | string trim)
        if test -n "$ollama_mem"
            set ollama_mem_human (human_size (math "$ollama_mem * 1024"))
            item "Memory usage: $ollama_mem_human"
        end
    else
        bad "Ollama service not running"
        item "Start with: ollama serve"
        return 1
    end
    
    # Test basic connectivity
    if curl -s http://localhost:11434/api/version >/dev/null 2>&1
        good "API endpoint responding"
    else
        bad "API endpoint not responding"
        item "Check: curl http://localhost:11434/api/version"
    end
end

# Check available models
function check_models
    subheader "Installed Models"
    
    if not ollama list >/dev/null 2>&1
        bad "Cannot retrieve model list"
        return 1
    end
    
    set models_output (ollama list 2>/dev/null | tail -n +2)
    
    if test -z "$models_output"
        warn "No models installed"
        item "Install a model: ollama pull llama3.2:3b"
        return
    end
    
    set total_size 0
    set model_count 0
    
    echo $models_output | while read line
        if test -n (string trim $line)
            set model_count (math "$model_count + 1")
            set fields (string split -m 3 (string repeat -n 10 " ") $line)
            set name (string trim $fields[1])
            set id (string trim $fields[2])
            set size_str (string trim $fields[3])
            set modified (string trim $fields[4])
            
            # Parse size
            set size_num (echo $size_str | sed 's/[^0-9.]//g')
            set size_unit (echo $size_str | sed 's/[0-9.]//g' | string trim)
            
            # Convert to bytes for total
            switch $size_unit
                case "*GB*"
                    set size_bytes (math "$size_num * 1000000000")
                case "*MB*"
                    set size_bytes (math "$size_num * 1000000")
                case "*KB*"
                    set size_bytes (math "$size_num * 1000")
                case "*"
                    set size_bytes $size_num
            end
            
            set total_size (math "$total_size + $size_bytes")
            
            # Categorize model by size and type
            set category "Unknown"
            if string match -q "*coder*" $name
                set category "🔧 Code"
            else if string match -q "*llama*" $name
                set category "🦙 Chat"
            else if string match -q "*mistral*" $name
                set category "💬 Chat"
            else if string match -q "*qwen*" $name
                set category "🔧 Code/Chat"
            else if string match -q "*gemma*" $name
                set category "🔧 Code"
            end
            
            good "$name ($size_str) - $category"
            item "ID: $id"
            item "Modified: $modified"
            echo
        end
    end
    
    item "Total models: $model_count"
    item "Total size: "(human_size $total_size)
end

# Performance benchmark
function benchmark_model
    set model $argv[1]
    if test -z "$model"
        return 1
    end
    
    subheader "Benchmarking $model"
    
    info "Running performance test..."
    
    set start_time (date +%s.%N)
    set response (echo "Count from 1 to 10" | timeout 30s ollama run $model 2>/dev/null)
    set end_time (date +%s.%N)
    
    if test $status -eq 0 -a -n "$response"
        set duration (math "$end_time - $start_time")
        set word_count (echo $response | wc -w)
        set tokens_per_sec (math "$word_count / $duration")
        
        good "Response time: "(printf "%.2f" $duration)" seconds"
        good "Tokens per second: "(printf "%.1f" $tokens_per_sec)
        item "Response: "(echo $response | head -c 50)"..."
        
        # Rate performance
        if test (math "$tokens_per_sec > 20") -eq 1
            good "Performance: Excellent"
        else if test (math "$tokens_per_sec > 10") -eq 1
            neutral "Performance: Good"
        else if test (math "$tokens_per_sec > 5") -eq 1
            warn "Performance: Slow"
        else
            bad "Performance: Very slow"
        end
    else
        bad "Benchmark failed or timed out"
    end
end

# Check GPU acceleration
function check_gpu_acceleration
    subheader "GPU Acceleration Status"
    
    # Check if Ollama is using GPU
    if pgrep -f ollama >/dev/null 2>&1
        set ollama_pid (pgrep -f ollama)
        
        # Check GPU memory usage during a test
        if command -v nvidia-smi >/dev/null 2>&1
            info "Testing GPU usage..."
            set before_mem (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1)
            
            # Run a quick inference
            echo "Hello" | timeout 10s ollama run (detect_best_model) >/dev/null 2>&1 &
            set test_pid $last_pid
            
            sleep 2
            set during_mem (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1)
            
            wait $test_pid 2>/dev/null
            
            set mem_diff (math "$during_mem - $before_mem")
            
            if test $mem_diff -gt 100  # More than 100MB increase
                good "GPU acceleration active (VRAM increased by $mem_diff MB)"
            else
                warn "GPU acceleration may not be active (VRAM change: $mem_diff MB)"
                item "Check: ollama ps during model loading"
            end
        else
            neutral "Cannot check GPU usage (nvidia-smi not available)"
        end
    else
        bad "Ollama not running, cannot test GPU acceleration"
    end
end

# Detect best model for testing
function detect_best_model
    set models (ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
    
    # Prefer smaller, faster models for testing
    for model in llama3.2:1b llama3.2:3b mistral:7b qwen2.5:3b
        if contains $model $models
            echo $model
            return
        end
    end
    
    # Fallback to first available
    echo $models | head -1
end

# Health recommendations
function health_recommendations
    subheader "Recommendations"
    
    set total_ram (free -b | awk '/^Mem:/{print $2}')
    set available_ram (free -b | awk '/^Mem:/{print $7}')
    
    # RAM recommendations
    if test $total_ram -lt 16000000000  # Less than 16GB
        warn "Consider 16GB+ RAM for better performance with larger models"
    end
    
    if test $available_ram -lt 4000000000  # Less than 4GB available
        warn "Close other applications for better model performance"
    end
    
    # GPU recommendations
    if not command -v nvidia-smi >/dev/null 2>&1
        neutral "Install NVIDIA drivers for GPU acceleration"
        item "Faster inference with GPU support"
    end
    
    # Model recommendations
    set models (ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
    
    if test (count $models) -eq 0
        warn "Install some models to get started:"
        item "Small/Fast: ollama pull llama3.2:3b"
        item "Coding: ollama pull qwen2.5-coder:7b"
        item "Large/Smart: ollama pull llama3.1:8b"
    else if not contains "qwen2.5-coder:7b" $models; and not contains "qwen2.5-coder:14b" $models
        neutral "For coding tasks, consider: ollama pull qwen2.5-coder:7b"
    end
end

# Show quick stats
function show_quick_stats
    header "Quick Stats"
    
    # System info one-liner
    set ram_gb (math (free -b | awk '/^Mem:/{print $2}') / 1000000000)
    set cpu_model (grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | string trim | sed 's/.*) //')
    
    info "System: $cpu_model, "(printf "%.0f" $ram_gb)"GB RAM"
    
    if command -v nvidia-smi >/dev/null 2>&1
        set gpu_name (nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
        info "GPU: $gpu_name"
    end
    
    if command -v ollama >/dev/null 2>&1; and pgrep -f ollama >/dev/null 2>&1
        set model_count (ollama list 2>/dev/null | tail -n +2 | wc -l)
        info "Ollama: $model_count models installed"
    else
        warn "Ollama: Not running"
    end
end

# Main health check
function full_health_check
    set_color purple
    echo "╭─────────────────────────────────────────────╮"
    echo "│            AI Health Check                  │"
    echo "│         Local LLM Diagnostics               │"
    echo "╰─────────────────────────────────────────────╯"
    set_color normal
    
    show_quick_stats
    check_system
    check_gpu
    check_ollama_service
    check_models
    
    # If we have models, run benchmarks
    set test_model (detect_best_model)
    if test -n "$test_model"
        benchmark_model $test_model
        check_gpu_acceleration
    end
    
    health_recommendations
    
    header "Summary"
    success "Health check completed!"
    info "Log: Review any warnings above"
    info "Next: Run './ai-health.fish quick' for fast status"
end

# Quick check
function quick_check
    header "AI Quick Check"
    show_quick_stats
    
    # Just check if Ollama is responding
    if ollama list >/dev/null 2>&1
        success "Ollama: Responding normally"
    else
        error "Ollama: Not responding"
    end
    
    # Quick GPU check
    if command -v nvidia-smi >/dev/null 2>&1
        set gpu_mem (nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1)
        info "GPU VRAM: $gpu_mem MB used"
    end
end

# Interactive menu
function show_interactive_menu
    while true
        set_color purple
        echo "╭─────────────────────────────────────────────╮"
        echo "│            AI Health Check                  │"
        echo "│         Local LLM Diagnostics               │"
        echo "╰─────────────────────────────────────────────╯"
        set_color normal
        echo
        
        set_color yellow; echo "What would you like to check?"; set_color normal
        echo
        echo "  1️⃣  Full Health Check (comprehensive)"
        echo "  2️⃣  Quick Status (fast overview)"
        echo "  3️⃣  GPU Diagnostics (detailed GPU info)"
        echo "  4️⃣  Model Analysis (installed models)"
        echo "  5️⃣  Performance Benchmark (speed test)"
        echo "  6️⃣  System Resources (RAM, CPU, disk)"
        echo "  7️⃣  Ollama Service Status"
        echo "  8️⃣  Recommendations (optimization tips)"
        echo
        echo "  0️⃣  Exit"
        echo
        
        read -P "Enter your choice [1-8, 0 to exit]: " choice
        echo
        
        switch $choice
            case 1
                full_health_check
                break
            case 2
                quick_check
                break
            case 3
                check_gpu
                check_gpu_acceleration
                break
            case 4
                check_models
                break
            case 5
                set model (detect_best_model)
                if test -n "$model"
                    benchmark_model $model
                else
                    error "No models available for benchmark"
                end
                break
            case 6
                check_system
                break
            case 7
                check_ollama_service
                break
            case 8
                health_recommendations
                break
            case 0 q quit exit
                info "Goodbye! 👋"
                exit 0
            case ""
                # Default to full check if just Enter is pressed
                full_health_check
                break
            case "*"
                error "Invalid choice: $choice"
                echo "Please enter a number from 1-8, or 0 to exit"
                echo
                read -P "Press Enter to continue..." dummy
                clear
        end
    end
    
    echo
    read -P "Press Enter to return to menu, or 'q' to quit: " continue
    if test "$continue" = "q" -o "$continue" = "quit"
        info "Goodbye! 👋"
        exit 0
    else
        clear
        show_interactive_menu
    end
end

# Show help
function show_help
    set_color purple
    echo "AI Health Check - Comprehensive Local LLM Diagnostics"
    set_color normal
    echo
    set_color yellow; echo "Usage:"; set_color normal
    echo "  ./ai-health.fish           - Interactive menu (default)"
    echo "  ./ai-health.fish [command] - Direct command"
    echo
    set_color yellow; echo "Commands:"; set_color normal
    echo "  full         - Complete health check"
    echo "  quick        - Quick status check"
    echo "  gpu          - GPU-specific diagnostics"
    echo "  models       - List and analyze models"
    echo "  benchmark    - Performance test best model"
    echo "  system       - System resources check"
    echo "  ollama       - Ollama service status"
    echo "  recommendations - Optimization tips"
    echo "  help         - Show this help"
    
    echo
    set_color yellow; echo "Interactive Menu:"; set_color normal
    echo "  Run without arguments for a nice menu interface!"
    echo "  Perfect for exploring what's available."
    
    echo
    set_color yellow; echo "Examples:"; set_color normal
    echo "  ./ai-health.fish           # Interactive menu"
    echo "  ./ai-health.fish quick     # Fast check"
    echo "  ./ai-health.fish gpu       # GPU details"
end

# Main function
function main
    set command $argv[1]
    
    # If no arguments, show interactive menu
    if test (count $argv) -eq 0
        show_interactive_menu
        return
    end
    
    # Otherwise handle command line arguments
    switch $command
        case full f
            full_health_check
        case quick q
            quick_check
        case gpu g
            check_gpu
            check_gpu_acceleration
        case models m
            check_models
        case benchmark bench b
            set model (detect_best_model)
            if test -n "$model"
                benchmark_model $model
            else
                error "No models available for benchmark"
            end
        case system sys s
            check_system
        case ollama o
            check_ollama_service
        case recommendations rec r
            health_recommendations
        case interactive menu i ""
            show_interactive_menu
        case help h --help -h
            show_help
        case "*"
            error "Unknown command: $command"
            echo
            info "Starting interactive menu..."
            sleep 1
            show_interactive_menu
    end
end

# Run main with all arguments
main $argv