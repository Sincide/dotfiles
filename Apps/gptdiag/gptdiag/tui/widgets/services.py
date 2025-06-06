#!/usr/bin/env python3
"""
Services Widget for GPTDiag
"""

from textual.app import ComposeResult
from textual.containers import Container
from textual.widgets import Static


class ServicesWidget(Container):
    """Services widget placeholder."""
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]System Services[/bold]\n\nService management features coming soon...") 