#!/usr/bin/python3

"""
AI Dynamic Theme Daemon
Native messaging host for real-time Firefox theming
Based on Pywalfox architecture
"""

import json
import sys
import time
import threading
import os
import struct
from pathlib import Path

class AIThemeDaemon:
    def __init__(self):
        self.colors_file = '/tmp/ai-optimized-colors.json'
        self.last_modified = 0
        self.running = True
        
    def log(self, message):
        """Log to file for debugging"""
        with open('/tmp/ai-theme-daemon.log', 'a') as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")
    
    def read_message(self):
        """Read message from Firefox extension (native messaging protocol)"""
        try:
            # Read exactly 4 bytes for message length (BLOCKING)
            raw_length = sys.stdin.buffer.read(4)
            if len(raw_length) == 0:
                # True EOF - Firefox closed connection
                self.log("EOF - Firefox disconnected")
                return None
            if len(raw_length) < 4:
                self.log(f"Partial read of length header: {len(raw_length)} bytes")
                return None
                
            message_length = struct.unpack('=I', raw_length)[0]
            if message_length == 0:
                self.log("Received zero-length message")
                # Don't return None - this might be valid, just continue
                return {"action": "noop"}
                
            # Read the actual message (BLOCKING)
            message_data = sys.stdin.buffer.read(message_length)
            if len(message_data) < message_length:
                self.log(f"Partial message read: expected {message_length}, got {len(message_data)}")
                return None
                
            message_text = message_data.decode('utf-8')
            self.log(f"Raw message received: {message_text}")
            return json.loads(message_text)
            
        except json.JSONDecodeError as e:
            self.log(f"JSON decode error: {e}")
            # Don't return None - continue processing
            return {"action": "invalid_json", "error": str(e)}
        except Exception as e:
            self.log(f"Read error: {e}")
            # Only return None for true connection errors
            if "Broken pipe" in str(e) or "EOF" in str(e):
                return None
            # For other errors, continue processing  
            return {"action": "read_error", "error": str(e)}
    
    def send_message(self, message):
        """Send message to Firefox extension (native messaging protocol)"""
        encoded_message = json.dumps(message).encode('utf-8')
        sys.stdout.buffer.write(struct.pack('=I', len(encoded_message)))
        sys.stdout.buffer.write(encoded_message)
        sys.stdout.buffer.flush()
    
    def load_ai_colors(self):
        """Load AI colors from JSON file"""
        try:
            if not os.path.exists(self.colors_file):
                return None
                
            current_modified = os.path.getmtime(self.colors_file)
            if current_modified <= self.last_modified:
                return None  # No changes
                
            self.last_modified = current_modified
            
            with open(self.colors_file, 'r') as f:
                colors = json.load(f)
            
            self.log(f"Loaded new AI colors from {self.colors_file}")
            return colors
            
        except Exception as e:
            self.log(f"Error loading AI colors: {e}")
            return None
    
    def monitor_colors(self):
        """Monitor AI colors file for changes (background thread)"""
        while self.running:
            try:
                colors = self.load_ai_colors()
                if colors:
                    # Send colors to Firefox extension
                    message = {
                        'action': 'updateColors',
                        'colors': colors,
                        'timestamp': time.time()
                    }
                    try:
                        self.send_message(message)
                        self.log("Sent color update to Firefox extension")
                    except Exception as e:
                        self.log(f"Error sending colors to extension: {e}")
                
                time.sleep(2)  # Check every 2 seconds
                
            except Exception as e:
                self.log(f"Error in color monitoring: {e}")
                time.sleep(5)
    
    def handle_extension_message(self, message):
        """Handle messages from Firefox extension"""
        action = message.get('action')
        
        if action == 'getColors':
            # Extension requesting current colors - use Pywalfox format
            colors = self.load_ai_colors()
            if colors:
                response = {
                    'action': 'getColors',
                    'success': True,
                    'data': colors
                }
                self.log("Sent colors to extension on request")
            else:
                response = {
                    'action': 'getColors', 
                    'success': False,
                    'error': 'No AI colors available'
                }
                self.log("No colors available to send")
            self.send_message(response)
            
        elif action == 'ping':
            # Extension checking connection
            response = {
                'action': 'connected',
                'version': '1.0',
                'daemon': 'ai-dynamic-theme'
            }
            self.send_message(response)
            self.log("Connection established with extension")
        
        elif action == 'noop':
            # Empty message, ignore
            self.log("Received empty/noop message")
            
        elif action == 'invalid_json':
            # JSON parsing error, send error response
            response = {
                'action': 'error',
                'message': f"Invalid JSON: {message.get('error', 'Unknown error')}"
            }
            self.send_message(response)
            
        elif action == 'read_error':
            # Read error, log but continue
            self.log(f"Read error handled: {message.get('error', 'Unknown error')}")
            
        else:
            self.log(f"Unknown action from extension: {action}")
    
    def run(self):
        """Main daemon loop"""
        self.log("AI Theme Daemon starting...")
        
        # Don't auto-monitor - respond to requests only
        # monitor_thread = threading.Thread(target=self.monitor_colors, daemon=True)
        # monitor_thread.start()
        
        # Main message loop - persistent connection
        try:
            while self.running:
                try:
                    message = self.read_message()
                    if message is None:
                        # Connection closed by Firefox
                        self.log("Firefox closed connection")
                        break
                    
                    self.log(f"Received message: {message}")
                    self.handle_extension_message(message)
                    
                except EOFError:
                    self.log("EOF - Firefox disconnected")
                    break
                except BrokenPipeError:
                    self.log("Broken pipe - Firefox disconnected")
                    break
                except Exception as e:
                    self.log(f"Message handling error: {e}")
                    # Don't break, keep trying to read messages
                    time.sleep(0.1)
                
        except KeyboardInterrupt:
            self.log("Daemon interrupted by user")
        except Exception as e:
            self.log(f"Fatal daemon error: {e}")
        finally:
            self.running = False
            self.log("AI Theme Daemon stopping...")

if __name__ == '__main__':
    daemon = AIThemeDaemon()
    daemon.run() 