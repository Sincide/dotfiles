#!/usr/bin/env python3
"""
Test script to launch the GPTDiag TUI application
"""

import asyncio
from pathlib import Path
from gptdiag.config.manager import ConfigManager
from gptdiag.app import GPTDiagApp


def main():
    """Launch the TUI application."""
    print("🚀 Launching GPTDiag TUI Application...")
    
    try:
        # Initialize configuration
        config_dir = Path.home() / ".config" / "gptdiag"
        config_manager = ConfigManager(config_dir)
        
        # Create and run the app
        app = GPTDiagApp(config_manager, debug_mode=True)
        app.run()
        
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except Exception as e:
        print(f"❌ Error launching TUI: {e}")
        raise


if __name__ == "__main__":
    main() 