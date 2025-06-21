#!/usr/bin/fish

# ============================================================================
# AI HEALTH CHECK - COMPREHENSIVE OLLAMA & LOCAL LLM DIAGNOSTICS
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

# Convert various size formats to human readable
function human_size
    set input $argv[1]
    
    # If input already has units (like "8.0Gi"), just clean it up
    if string match -q "*Gi" $input
        set size (string replace "Gi" "" $input)
        printf "%.1f GB" $size
        return
    else if string match -q "*Mi" $input
        set size (string replace "Mi" "" $input)
        printf "%.1f MB" $size
        return
    else if string match -q "*Ki" $input
        set size (string replace "Ki" "" $input)
        printf "%.1f KB" $size
        return
    else if string match -q "*GB" $input
        echo $input
        return
    else if string match -q "*MB" $input
        echo $input
        return
    end
    
    # Otherwise assume it's bytes and convert
    set bytes $input
    if not string match -qr '^\d+$' $bytes
        echo $input  # Return as-is if not a number
        return
    end
    
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
    
    # Check for AMD ROCm first (since you're AMD-only)
    if command -v rocm-smi >/dev/null 2>&1
        good "AMD ROCm detected"
        set rocm_info (rocm-smi --showtemp --showmeminfo vram --showuse 2>/dev/null)
        if test -n "$rocm_info"
            # Parse temperature info using sed to extract numbers
            set temp_edge (echo $rocm_info | grep "Temperature (Sensor edge)" | sed 's/.*: \([0-9.]*\)$/\1/')
            set temp_junction (echo $rocm_info | grep "Temperature (Sensor junction)" | sed 's/.*: \([0-9.]*\)$/\1/')
            set temp_memory (echo $rocm_info | grep "Temperature (Sensor memory)" | sed 's/.*: \([0-9.]*\)$/\1/')
            
            if test -n "$temp_edge"
                item "Temperature: Edge $temp_edge°C, Junction $temp_junction°C, Memory $temp_memory°C"
            end
            
            # Parse GPU utilization using sed
            set gpu_use (echo $rocm_info | grep "GPU use" | sed 's/.*: \([0-9]*\)$/\1/')
            if test -n "$gpu_use"
                item "GPU utilization: $gpu_use%"
            end
            
            # Parse VRAM info using sed to extract numbers
            set vram_total (echo $rocm_info | grep "VRAM Total Memory" | sed 's/.*: \([0-9]*\)$/\1/')
            set vram_used (echo $rocm_info | grep "VRAM Total Used Memory" | sed 's/.*: \([0-9]*\)$/\1/')
            
            if test -n "$vram_total" -a -n "$vram_used"
                set vram_total_gb (math "$vram_total / 1024 / 1024 / 1024")
                set vram_used_gb (math "$vram_used / 1024 / 1024 / 1024")
                item "VRAM: "(printf "%.1f GB" $vram_used_gb)" / "(printf "%.1f GB" $vram_total_gb)" used"
            end
            
            # Try to get GPU name from ROCm
            set gpu_name (rocm-smi --showproductname 2>/dev/null | grep "Card" | head -1)
            if test -n "$gpu_name"
                item "GPU: "(echo $gpu_name | cut -d: -f2 | string trim)
            end
        else
            item "ROCm tools installed but no detailed info available"
        end
    else if test -e /sys/class/drm/card0/device/vendor
        set vendor_id (cat /sys/class/drm/card0/device/vendor 2>/dev/null)
        if test "$vendor_id" = "0x1002"
            good "AMD GPU detected"
            
            # Try to get GPU name from PCI info
            set gpu_name (lspci | grep -i "vga\|3d\|display" | grep -i amd | head -1)
            if test -n "$gpu_name"
                item "GPU: "(echo $gpu_name | cut -d: -f3 | string trim)
            end
            
            neutral "Consider installing ROCm for GPU acceleration"
            item "Install: Follow AMD ROCm installation guide"
        else
            neutral "Non-AMD GPU detected (vendor: $vendor_id)"
        end
    else
        neutral "No GPU information available"
    end
    
    # Check for ROCm libraries
    if test -d /opt/rocm
        good "ROCm installed in /opt/rocm"
        if test -f /opt/rocm/bin/rocm-smi
            item "ROCm tools available"
        end
    else
        neutral "ROCm not installed"
        item "For AMD GPU acceleration: install ROCm"
    end
    
    # Check if HSA is configured (important for AMD)
    if test -n "$HSA_OVERRIDE_GFX_VERSION"
        good "HSA override configured: $HSA_OVERRIDE_GFX_VERSION"
    else
        neutral "HSA_OVERRIDE_GFX_VERSION not set"
        item "May be needed for some AMD GPUs"
    end
end

# Check system resources
function check_system
    subheader "System Resources"
    
    # RAM - handle different free output formats
    set free_output (free -h 2>/dev/null)
    if test $status -eq 0
        set mem_line (echo $free_output | grep "^Mem:")
        
        if test -n "$mem_line"
            # Parse human-readable output (handle both spaces and multiple spaces)
            set mem_fields (echo $mem_line | string split -n ' ')
            if test (count $mem_fields) -ge 3
                set total_ram_hr $mem_fields[2]
                set used_ram_hr $mem_fields[3]
                
                # Try to get available (column 7), fallback to free (column 4)
                if test (count $mem_fields) -ge 7
                    set available_ram_hr $mem_fields[7]
                else if test (count $mem_fields) -ge 4  
                    set available_ram_hr $mem_fields[4]
                else
                    set available_ram_hr "Unknown"
                end
                
                good "RAM: "(human_size $used_ram_hr)" / "(human_size $total_ram_hr)" used"
                item "Available: "(human_size $available_ram_hr)
                
                # Simple low memory warning
                if test "$available_ram_hr" != "Unknown"
                    set available_num (echo $available_ram_hr | sed 's/[^0-9.]//g')
                    
                    if string match -q "*Mi" $available_ram_hr
                        set available_int (printf "%.0f" $available_num)
                        if test $available_int -lt 4000
                            warn "Low available RAM for large models"
                        end
                    else if string match -q "*Gi" $available_ram_hr
                        set available_int (printf "%.0f" $available_num)
                        if test $available_int -lt 4
                            warn "Low available RAM for large models"
                        end
                    end
                end
            else
                neutral "Could not parse memory fields from free command"
                item "Fields found: "(count $mem_fields)
            end
        else
            neutral "Could not parse memory line from free command"
            item "Raw output: $free_output"
        end
    else
        neutral "free command failed"
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
        warn "Disk space: $disk_avail available ($disk_usage% used)"
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
    
    set models_raw (ollama list 2>/dev/null)
    set models_output (echo $models_raw | tail -n +2)
    
    if test -z "$models_output"
        warn "No models installed"
        item "Install a model: ollama pull llama3.2:3b"
        return
    end
    
    set model_count 0
    set total_size_gb 0
    
    # Debug: show raw output format
    # item "Debug - Raw ollama list output:"
    # echo $models_raw | head -5
    
    # Parse each line more carefully
    echo $models_output | while read -l line
        if test -n (string trim $line)
            set model_count (math "$model_count + 1")
            
            # Split by whitespace, but be more careful about the parsing
            set line_clean (string trim $line)
            set fields (string split -n ' ' $line_clean)
            
            # Extract fields more robustly
            set name ""
            set id ""
            set size_str ""
            set modified ""
            
            if test (count $fields) -ge 1
                set name $fields[1]
            end
            if test (count $fields) -ge 2
                set id $fields[2]
            end
            if test (count $fields) -ge 3
                set size_str $fields[3]
            end
            if test (count $fields) -ge 4
                # Join remaining fields for modified date
                set modified (string join " " $fields[4..-1])
            end
            
            # Parse size and convert to GB for totaling
            if test -n "$size_str"
                set size_num (echo $size_str | sed 's/[^0-9.]//g')
                if test -n "$size_num"
                    if string match -q "*GB" $size_str
                        set total_size_gb (math "$total_size_gb + $size_num")
                    else if string match -q "*MB" $size_str
                        set total_size_gb (math "$total_size_gb + ($size_num / 1000)")
                    end
                end
            end
            
            # Categorize model by name
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
            else if string match -q "*llava*" $name
                set category "👁️ Vision"
            end
            
            good "$name ($size_str) - $category"
            if test -n "$id"
                item "ID: $id"
            end
            if test -n "$modified"
                item "Modified: $modified"
            end
            echo
        end
    end
    
    # Count models properly
    set actual_count (echo $models_output | grep -c "^")
    item "Total models: $actual_count"
    item "Total size: "(printf "%.1f GB" $total_size_gb)
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
        
        # Rate performance - use proper Fish test syntax
        set tokens_int (printf "%.0f" $tokens_per_sec)
        if test $tokens_int -gt 20
            good "Performance: Excellent"
        else if test $tokens_int -gt 10
            neutral "Performance: Good"
        else if test $tokens_int -gt 5
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
        
        # For AMD GPUs, check ROCm usage
        if command -v rocm-smi >/dev/null 2>&1
            info "Testing AMD GPU usage..."
            
            # Get initial GPU memory usage
            set before_mem (rocm-smi --showmeminfo vram 2>/dev/null | grep "VRAM Total Used Memory" | awk '{print $NF}' | head -1)
            
            # Run a quick inference
            echo "Hello" | timeout 10s ollama run (detect_best_model) >/dev/null 2>&1 &
            set test_pid $last_pid
            
            sleep 3
            set during_mem (rocm-smi --showmeminfo vram 2>/dev/null | grep "VRAM Total Used Memory" | awk '{print $NF}' | head -1)
            
            wait $test_pid 2>/dev/null
            
            if test -n "$before_mem" -a -n "$during_mem" -a "$before_mem" != "Memory" -a "$during_mem" != "Memory"
                # Validate that we got numeric values
                if string match -qr '^\d+$' "$before_mem"; and string match -qr '^\d+$' "$during_mem"
                    # Convert bytes to GB for display
                    set before_gb (math "$before_mem / 1024 / 1024 / 1024")
                    set during_gb (math "$during_mem / 1024 / 1024 / 1024")
                    
                    item "VRAM before: "(printf "%.1f GB" $before_gb)" ($before_mem bytes)"
                    item "VRAM during: "(printf "%.1f GB" $during_gb)" ($during_mem bytes)"
                    
                    # Calculate difference
                    set diff_bytes (math "$during_mem - $before_mem")
                    set diff_gb (math "$diff_bytes / 1024 / 1024 / 1024")
                    
                    if test $diff_bytes -gt 0
                        item "VRAM increase: +"(printf "%.1f GB" $diff_gb)" during inference"
                        good "GPU acceleration appears to be working"
                    else
                        neutral "No significant VRAM increase detected"
                    end
                    
                    good "GPU monitoring available via ROCm"
                else
                    neutral "Failed to parse VRAM usage numbers"
                    item "Raw values: before='$before_mem', during='$during_mem'"
                end
            else
                neutral "ROCm GPU memory monitoring unclear"
                item "Check: rocm-smi --showmeminfo vram"
            end
        else
            # Fallback: check if ROCm processes are active
            set rocm_processes (ps aux | grep -c "hip\|rocm" | head -1)
            if test $rocm_processes -gt 1
                neutral "ROCm-related processes detected"
                good "GPU acceleration may be active"
            else
                neutral "Cannot verify GPU acceleration without ROCm tools"
                item "Install ROCm for better GPU monitoring"
            end
        end
        
        # Check environment variables that suggest GPU usage
        if test -n "$ROCR_VISIBLE_DEVICES" -o -n "$HIP_VISIBLE_DEVICES"
            good "GPU environment variables set"
            test -n "$ROCR_VISIBLE_DEVICES" && item "ROCR_VISIBLE_DEVICES: $ROCR_VISIBLE_DEVICES"
            test -n "$HIP_VISIBLE_DEVICES" && item "HIP_VISIBLE_DEVICES: $HIP_VISIBLE_DEVICES"
        end
        
        # Check if /dev/dri devices are accessible (AMD GPU access)
        if test -e /dev/dri/card0
            good "GPU device nodes available (/dev/dri/card0)"
        else if test -e /dev/dri/card1
            good "GPU device nodes available (/dev/dri/card1)"
        else if test -d /dev/dri
            set dri_devices (ls /dev/dri/card* 2>/dev/null)
            if test -n "$dri_devices"
                good "GPU device nodes available: "(echo $dri_devices | tr '\n' ' ')
            else
                warn "GPU device nodes not found"
            end
        else
            warn "GPU device nodes not found"
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
    
    # Get RAM info in human-readable format
    set free_output (free -h 2>/dev/null)
    if test $status -eq 0
        set mem_line (echo $free_output | grep "^Mem:")
        if test -n "$mem_line"
            set mem_fields (echo $mem_line | string split -n ' ')
            if test (count $mem_fields) -ge 2
                set total_ram_hr $mem_fields[2]
                set total_num (echo $total_ram_hr | sed 's/[^0-9.]//g')
                set total_int (printf "%.0f" $total_num)
                
                if string match -q "*Gi" $total_ram_hr
                    if test $total_int -lt 16
                        warn "Consider 16GB+ RAM for better performance with larger models"
                    end
                end
            end
            
            if test (count $mem_fields) -ge 7
                set available_ram_hr $mem_fields[7]
            else if test (count $mem_fields) -ge 4
                set available_ram_hr $mem_fields[4]
            else
                set available_ram_hr ""
            end
            
            if test -n "$available_ram_hr"
                set available_num (echo $available_ram_hr | sed 's/[^0-9.]//g')
                set available_int (printf "%.0f" $available_num)
                
                if string match -q "*Gi" $available_ram_hr
                    if test $available_int -lt 4
                        warn "Close other applications for better model performance"
                    end
                end
            end
        end
    end
    
    # AMD GPU recommendations
    if not command -v rocm-smi >/dev/null 2>&1
        if test -e /sys/class/drm/card0/device/vendor
            set vendor_id (cat /sys/class/drm/card0/device/vendor 2>/dev/null)
            if test "$vendor_id" = "0x1002"
                neutral "Install ROCm for AMD GPU acceleration"
                item "Guide: https://rocm.docs.amd.com/en/latest/deploy/linux/quick_start.html"
                item "Better performance for AI workloads"
            end
        end
    else
        # ROCm is installed, check configuration
        if test -z "$HSA_OVERRIDE_GFX_VERSION"
            neutral "Consider setting HSA_OVERRIDE_GFX_VERSION for your GPU"
            item "May improve compatibility with some AMD GPUs"
        end
        
        good "ROCm detected - GPU acceleration available"
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
    
    # Performance recommendations for AMD
    neutral "AMD-specific performance tips:"
    item "Ensure your user is in the 'render' group for GPU access"
    item "Set appropriate ROCR_VISIBLE_DEVICES if multiple GPUs"
    item "Monitor GPU usage with: watch rocm-smi"
end

# Show quick stats
function show_quick_stats
    header "Quick Stats"
    
    # System info one-liner - handle different free formats
    set free_output (free -h 2>/dev/null)
    if test $status -eq 0
        set mem_line (echo $free_output | grep "^Mem:")
        if test -n "$mem_line"
            set mem_fields (echo $mem_line | string split -n ' ')
            if test (count $mem_fields) -ge 2
                set total_ram_hr $mem_fields[2]
            else
                set total_ram_hr "Unknown"
            end
        else
            set total_ram_hr "Unknown"
        end
    else
        set total_ram_hr "Unknown"
    end
    
    set cpu_model (grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | string trim | sed 's/.*) //')
    
    info "System: $cpu_model, $total_ram_hr RAM"
    
    # AMD GPU detection
    if command -v rocm-smi >/dev/null 2>&1
        # Try to get AMD GPU name from ROCm
        set gpu_name (rocm-smi --showproductname 2>/dev/null | grep "Card" | head -1 | cut -d: -f2 | string trim)
        if test -n "$gpu_name"
            info "GPU: $gpu_name (ROCm)"
        else
            info "GPU: AMD GPU (ROCm detected)"
        end
    else if test -e /sys/class/drm/card0/device/vendor
        set vendor_id (cat /sys/class/drm/card0/device/vendor 2>/dev/null)
        if test "$vendor_id" = "0x1002"
            # Try to get GPU name from lspci
            set gpu_name (lspci | grep -i "vga\|3d\|display" | grep -i amd | head -1 | cut -d: -f3 | string trim)
            if test -n "$gpu_name"
                info "GPU: $gpu_name"
            else
                info "GPU: AMD GPU detected"
            end
        else
            info "GPU: Unknown (vendor: $vendor_id)"
        end
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
    info "Next: Run 'ai-quick' for fast status"
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