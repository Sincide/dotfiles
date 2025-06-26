#!/usr/bin/env python3

import os
import re
from pathlib import Path
from typing import Dict, Any

def parse_kitty_config() -> Dict[str, str]:
    """Parse kitty config to extract color scheme"""
    kitty_config_path = Path.home() / ".config" / "kitty" / "kitty.conf"
    colors = {}
    
    if not kitty_config_path.exists():
        # Fallback to default colors
        return {
            "background": "#1e1e2e",
            "foreground": "#cdd6f4", 
            "selection_background": "#313244",
            "selection_foreground": "#cdd6f4",
            "cursor": "#f5e0dc",
            "cursor_text_color": "#1e1e2e",
            "color0": "#45475a",
            "color1": "#f38ba8",
            "color2": "#a6e3a1", 
            "color3": "#f9e2af",
            "color4": "#89b4fa",
            "color5": "#f5c2e7",
            "color6": "#94e2d5",
            "color7": "#bac2de",
            "color8": "#585b70",
            "color9": "#f38ba8",
            "color10": "#a6e3a1",
            "color11": "#f9e2af", 
            "color12": "#89b4fa",
            "color13": "#f5c2e7",
            "color14": "#94e2d5",
            "color15": "#a6adc8"
        }
    
    try:
        with open(kitty_config_path, 'r') as f:
            content = f.read()
            
        # Extract color definitions
        color_pattern = r'^(\w+)\s+#([0-9a-fA-F]{6}).*$'
        for line in content.split('\n'):
            line = line.strip()
            match = re.match(color_pattern, line)
            if match:
                color_name, color_value = match.groups()
                colors[color_name] = f"#{color_value}"
                
    except Exception:
        pass
    
    return colors

def get_textual_theme() -> Dict[str, Any]:
    """Convert kitty colors to Textual theme"""
    kitty_colors = parse_kitty_config()
    
    # Map kitty colors to Textual theme variables
    return {
        "background": kitty_colors.get("background", "#1e1e2e"),
        "surface": kitty_colors.get("color0", "#45475a"),
        "panel": kitty_colors.get("selection_background", "#313244"),
        "primary": kitty_colors.get("color4", "#89b4fa"),
        "accent": kitty_colors.get("color5", "#f5c2e7"),
        "text": kitty_colors.get("foreground", "#cdd6f4"),
        "text-muted": kitty_colors.get("color8", "#585b70"),
        "success": kitty_colors.get("color2", "#a6e3a1"),
        "warning": kitty_colors.get("color3", "#f9e2af"),
        "error": kitty_colors.get("color1", "#f38ba8"),
    }