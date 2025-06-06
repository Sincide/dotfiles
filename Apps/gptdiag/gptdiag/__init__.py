"""
GPTDiag - Advanced System Diagnostic TUI

A powerful terminal-based system diagnostic and monitoring tool with 
integrated AI-powered analysis capabilities.
"""

__version__ = "1.0.0"
__author__ = "System Administrator"
__email__ = "admin@localhost"
__description__ = "Advanced TUI-based system diagnostic and monitoring tool with AI integration"

from .main import main
from .app import GPTDiagApp

__all__ = ["main", "GPTDiagApp", "__version__"] 