#!/bin/bash

RADEONTOP_OUT=$(radeontop -d - -l 1 | grep 'gpu')
USAGE=$(echo "$RADEONTOP_OUT" | grep -oP 'gpu \K[0-9.]+')
VRAM_MB=$(echo "$RADEONTOP_OUT" | grep -oP 'vram [0-9.]+% \K[0-9.]+' | head -1)
VRAM_PERC=$(echo "$RADEONTOP_OUT" | grep -oP 'vram \K[0-9.]+')
MCLK=$(echo "$RADEONTOP_OUT" | grep -oP 'mclk [0-9.]+% \K[0-9.]+ghz' | head -1)
SCLK=$(echo "$RADEONTOP_OUT" | grep -oP 'sclk [0-9.]+% \K[0-9.]+ghz' | head -1)
TEMP=$(sensors | grep -m1 'edge' | awk '{print $2}')
FAN=$(sensors | grep -m1 'fan' | awk '{print $2" "$3}')
POWER=$(sensors | grep -iE 'power1|PPT|chip|average' | grep -oP '[0-9.]+(?= W)' | head -1)

# Color function
colorize() {
  local value=$1; local low=$2; local mid=$3; local high=$4; local unit=$5
  if [[ -z "$value" ]]; then echo "N/A"; return; fi
  if (( $(echo "$value < $mid" | bc -l) )); then
    echo "<span color='#a6e3a1'>$value$unit</span>" # green
  elif (( $(echo "$value < $high" | bc -l) )); then
    echo "<span color='#f9e2af'>$value$unit</span>" # yellow
  else
    echo "<span color='#f38ba8'>$value$unit</span>" # red
  fi
}

# GPU Usage coloring
USAGE_COLOR=$(colorize "${USAGE}" 0 50 90 "%")
# Temp coloring
if [[ -n "$TEMP" ]]; then TEMP_VAL=$(echo "$TEMP" | grep -oP '[0-9.]+' | head -1); fi
TEMP_COLOR=$(colorize "${TEMP_VAL}" 0 60 80 "°C")
# VRAM coloring (percentage)
VRAM_COLOR=$(colorize "${VRAM_PERC}" 0 50 90 "%")
# Fan coloring (RPM)
FAN_VAL=$(echo "$FAN" | grep -oP '^[0-9]+')
FAN_COLOR=$(colorize "${FAN_VAL}" 0 1500 2500 " RPM")
# Power coloring (W)
POWER_COLOR=$(colorize "${POWER}" 0 150 250 "W")
# Clocks (always green)
SCLK_COLOR="<span color='#a6e3a1'>${SCLK:-N/A}</span>"
MCLK_COLOR="<span color='#a6e3a1'>${MCLK:-N/A}</span>"

TEXT="GPU: ${USAGE_COLOR}  |  Temp: ${TEMP_COLOR}  |  VRAM: ${VRAM_MB:-N/A}MB (${VRAM_COLOR})  |  Fan: ${FAN_COLOR}  |  Power: ${POWER_COLOR}  |  Core: ${SCLK_COLOR}  |  Mem: ${MCLK_COLOR}"

printf '{"text": "%s", "tooltip": "%s"}\n' "$TEXT" "$TEXT"
