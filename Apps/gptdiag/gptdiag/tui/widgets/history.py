#!/usr/bin/env python3
"""
History Widget for GPTDiag
"""

from textual.app import ComposeResult
from textual.containers import Container
from textual.widgets import Static


class HistoryWidget(Container):
    """History widget placeholder."""
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]Diagnostic History[/bold]\n\nHistory features coming soon...") 