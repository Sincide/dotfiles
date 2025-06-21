#!/usr/bin/env python3
"""
Evil Space Dashboard Runner
"""
import sys
from pathlib import Path

# Add the dashboard directory to the python path to allow imports from app
dashboard_dir = Path(__file__).parent.resolve()
sys.path.insert(0, str(dashboard_dir))

from app.core.dashboard_core import EvilSpaceDashboard
from app.server import run_server

def main():
    """Initializes the dashboard and runs the server."""
    # The dotfiles path is the parent of the dashboard directory
    dotfiles_path = dashboard_dir.parent
    
    # Create an instance of the main dashboard class
    dashboard_instance = EvilSpaceDashboard(dotfiles_path=str(dotfiles_path))
    
    # Run the server with the instance
    run_server(dashboard_instance)

if __name__ == "__main__":
    main() 