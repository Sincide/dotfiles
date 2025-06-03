#!/usr/bin/env python3
"""
Simple local server for AI color data
Serves AI-optimized colors to Firefox extension
"""

import http.server
import socketserver
import json
import os
import time

PORT = 8080
COLORS_FILE = "/tmp/ai-optimized-colors.json"

class ColorHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path in ['/ai-colors', '/api/colors', '/colors.json']:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            colors = self.load_colors()
            self.wfile.write(json.dumps(colors).encode())
        else:
            super().do_GET()
    
    def load_colors(self):
        try:
            if os.path.exists(COLORS_FILE):
                with open(COLORS_FILE, 'r') as f:
                    data = json.load(f)
                    
                    # Transform nested structure to flat structure for Firefox extension
                    if 'colors' in data and 'dark' in data['colors']:
                        dark_colors = data['colors']['dark']
                        
                        # Convert to format expected by Firefox extension
                        colors = {
                            "primary": dark_colors.get('primary', '#6366f1'),
                            "surface": dark_colors.get('surface', '#1e1e2e'),
                            "onSurface": dark_colors.get('on_surface', '#cdd6f4'),
                            "secondary": dark_colors.get('secondary', '#a6adc8'),
                            "onPrimary": dark_colors.get('on_primary', '#ffffff'),
                            "accent": dark_colors.get('tertiary', '#f38ba8'),  # Use tertiary as accent
                            "aiMetadata": {
                                "harmonyScore": 90,  # Could be enhanced based on color analysis
                                "accessibilityLevel": "WCAG_AA",
                                "timestamp": time.strftime('%Y-%m-%dT%H:%M:%S'),
                                "source": "ai-wallpaper-pipeline"
                            },
                            "lastUpdate": int(time.time() * 1000)
                        }
                        
                        print(f"🎨 Loaded colors from AI pipeline: {colors['primary']}")
                        return colors
                    else:
                        print("⚠️  Invalid color structure in JSON file")
        except Exception as e:
            print(f"Error loading colors: {e}")
        
        # Demo colors
        demo = {
            "primary": "#6366f1",
            "surface": "#1e1e2e",
            "onSurface": "#cdd6f4",
            "secondary": "#a6adc8",
            "onPrimary": "#ffffff",
            "accent": "#f38ba8",
            "aiMetadata": {
                "harmonyScore": 87,
                "accessibilityLevel": "WCAG_AAA",
                "timestamp": time.strftime('%Y-%m-%dT%H:%M:%S'),
                "source": "demo"
            },
            "lastUpdate": int(time.time() * 1000)
        }
        return demo
    
    def log_message(self, format, *args):
        print(f"[{time.strftime('%H:%M:%S')}] {format % args}")

def main():
    with socketserver.TCPServer(("", PORT), ColorHandler) as httpd:
        print(f"🚀 AI Color Server starting on http://localhost:{PORT}")
        print(f"📁 Serving colors from: {COLORS_FILE}")
        print("🔄 Extension will fetch colors from /ai-colors endpoint")
        print("⏹️  Press Ctrl+C to stop")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Color server stopped")

if __name__ == "__main__":
    main()
