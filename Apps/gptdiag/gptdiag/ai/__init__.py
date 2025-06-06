"""
AI Integration Package for GPTDiag

This package provides AI-powered analysis and automation capabilities
with primary support for Ollama local models and fallback to cloud providers.
"""

from .providers import AIProvider
from .ollama import OllamaProvider
from .manager import AIManager

__all__ = ["AIProvider", "OllamaProvider", "AIManager"] 