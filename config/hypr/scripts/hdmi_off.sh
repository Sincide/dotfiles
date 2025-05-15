#!/bin/bash
timeout 20 sh -c "while true; do hyprctl dispatch dpms off HDMI-A-1; sleep 1; done" 