#!/usr/bin/env python3
"""
Dashboard Widget for GPTDiag

Main dashboard showing system overview and quick actions.
"""

from textual.widgets import Static


class DashboardWidget(Static):
    """Dashboard widget showing system overview."""
    
    def __init__(self, system_info=None, config_manager=None, **kwargs):
        """Initialize dashboard widget."""
        super().__init__("Dashboard Widget - Coming Soon!", **kwargs)
        self.system_info = system_info
        self.config_manager = config_manager 