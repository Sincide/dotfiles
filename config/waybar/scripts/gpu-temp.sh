#!/bin/bash

# Get GPU temperature from sensors
TEMP=$(sensors amdgpu-* 2>/dev/null | grep -oP "edge:\s+\+\K[0-9.]+" | head -n1)

# Get GPU power - try different possible sensor names
GPU_POWER=$(sensors amdgpu-* 2>/dev/null | grep -oP "power1:\s+\K[0-9.]+" || \
            sensors amdgpu-* 2>/dev/null | grep -oP "PPT:\s+\K[0-9.]+" || \
            sensors amdgpu-* 2>/dev/null | grep -oP "average:\s+\K[0-9.]+" || \
            echo "N/A")

# Get GPU utilization and memory using radeontop
if command -v radeontop >/dev/null 2>&1; then
    # Get a single sample of GPU stats
    STATS=$(radeontop -d- -l1 2>/dev/null | tail -n1)
    
    # Extract GPU and memory usage
    GPU_UTIL=$(echo "$STATS" | grep -oP 'gpu \K[0-9.]+' || echo "N/A")
    GPU_MEM=$(echo "$STATS" | grep -oP 'vram \K[0-9.]+' || echo "N/A")
else
    GPU_UTIL="N/A"
    GPU_MEM="N/A"
fi

if [ -n "$TEMP" ]; then
    # Round the temperature to nearest integer
    TEMP=$(printf "%.0f" "$TEMP")
    
    # Build tooltip with all available information
    TOOLTIP="GPU Temperature: $TEMP°C"
    
    if [ "$GPU_UTIL" != "N/A" ]; then
        TOOLTIP="$TOOLTIP\nGPU Usage: $GPU_UTIL%"
    fi
    
    if [ "$GPU_MEM" != "N/A" ]; then
        TOOLTIP="$TOOLTIP\nMemory Usage: $GPU_MEM%"
    fi
    
    if [ "$GPU_POWER" != "N/A" ]; then
        TOOLTIP="$TOOLTIP\nPower Draw: $GPU_POWER W"
    fi
    
    # Remove the temperature from waybar text since it's added by the module format
    echo "{\"text\": \"$TEMP°C\", \"tooltip\": \"$TOOLTIP\", \"class\": \"gpu-temp\"}"
else
    echo "{\"text\": \"N/A\", \"tooltip\": \"GPU information unavailable\", \"class\": \"error\"}"
fi 