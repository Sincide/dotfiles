import http.server
import socketserver
import json
import os
import functools
import socket

from .frontend.html_generator import get_dashboard_html
from .api import system, logs, themes, scripts

class EvilSpaceHandler(http.server.SimpleHTTPRequestHandler):
    """Custom HTTP handler for the Evil Space Dashboard"""
    
    def __init__(self, *args, dashboard_instance=None, **kwargs):
        self.dashboard = dashboard_instance
        # The 'directory' argument is not used by our handler, but is passed by TCPServer
        if 'directory' in kwargs:
             del kwargs['directory']
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/':
            self.serve_dashboard()
        elif self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            # For static files, we need to set the directory context
            # The 'directory' kwarg is not available in __init__ in Python < 3.8
            # So we temporarily chdir. This is safe due to single-threaded nature of the server.
            cwd = os.getcwd()
            try:
                os.chdir(self.dashboard.dashboard_path)
                super().do_GET()
            finally:
                os.chdir(cwd)

    def serve_dashboard(self):
        """Serve the main dashboard HTML"""
        html_content = get_dashboard_html()
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html_content.encode())
    
    def handle_api_request(self):
        """Handle API requests"""
        # Handle nested endpoints like logs/content and logs/stats
        path_parts = self.path.split('/')
        endpoint = path_parts[-1].split('?')[0]
        
        # Check for nested endpoints
        if len(path_parts) >= 4 and path_parts[2] == 'logs':
            nested_endpoint = path_parts[3].split('?')[0]
            
            from urllib.parse import parse_qs, urlparse
            parsed_url = urlparse(self.path)
            params = parse_qs(parsed_url.query)
            
            if nested_endpoint == 'content':
                # Handle logs/content endpoint
                log_file = params.get('file', [''])[0]
                lines = int(params.get('lines', ['100'])[0])
                filter_level = params.get('level', [None])[0]
                search_term = params.get('search', [None])[0]
                
                if log_file and log_file != 'undefined':
                    # Use the log_file as-is (could be filename or special identifier like journal:current)
                    data = logs.get_log_content(self.dashboard, log_file, lines, filter_level, search_term)
                else:
                    data = {'error': 'Log file parameter required', 'lines': []}
            elif nested_endpoint == 'stats':
                # Handle logs/stats endpoint
                log_file = params.get('file', [''])[0]
                
                if log_file and log_file != 'undefined':
                    # Use the log_file as-is (could be filename or special identifier like journal:current)
                    data = logs.get_log_stats(self.dashboard, log_file)
                else:
                    data = {'error': 'Log file parameter required'}
            else:
                data = {'error': f'Unknown logs endpoint: {nested_endpoint}'}
        else:
            # Handle regular endpoints
            try:
                if endpoint == 'system':
                    data = system.get_system_info(self.dashboard)
                elif endpoint == 'gpu':
                    data = system.get_gpu_info(self.dashboard)
                elif endpoint == 'processes':
                    data = system.get_process_info(self.dashboard)
                elif endpoint == 'network':
                    data = system.get_network_info(self.dashboard)
                elif endpoint == 'logs':
                    data = logs.get_logs_info(self.dashboard)
                elif endpoint == 'themes':
                    data = themes.get_themes_info(self.dashboard)
                elif endpoint == 'scripts':
                    data = scripts.get_scripts_info(self.dashboard)
                else:
                    data = {'error': f'Unknown endpoint: {endpoint}'}
                    
            except Exception as e:
                data = {'error': str(e)}
        
        try:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(data, indent=2).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            error_data = {'error': str(e)}
            self.wfile.write(json.dumps(error_data).encode())

def run_server(dashboard_instance):
    """Main function to start the dashboard server"""
    
    # Create handler with the dashboard instance
    handler = functools.partial(EvilSpaceHandler, dashboard_instance=dashboard_instance)
    
    # Start server
    PORT = 8080
    
    # Ensure we are serving from the dashboard directory for static assets
    os.chdir(dashboard_instance.dashboard_path)
    
    # Create server with socket reuse enabled
    class ReusableTCPServer(socketserver.TCPServer):
        allow_reuse_address = True
        
        def server_bind(self):
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            super().server_bind()
    
    with ReusableTCPServer(("", PORT), handler) as httpd:
        print(f"Evil Space Dashboard running at http://localhost:{PORT}")
        print("Press Ctrl+C to stop the server")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down dashboard...")
            httpd.shutdown() 