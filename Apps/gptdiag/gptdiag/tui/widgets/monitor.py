#!/usr/bin/env python3
"""
Monitor Widget for GPTDiag
"""

from textual.app import ComposeResult
from textual.containers import Container
from textual.widgets import Static


class MonitorWidget(Container):
    """Monitor widget placeholder."""
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]System Monitor[/bold]\n\nMonitoring features coming soon...") 