#!/usr/bin/env python3
"""
GPTDiag Main TUI Application

The core TUI application built with Textual framework.
Provides the main interface with tab navigation and all features.
"""

import asyncio
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import (
    Header, Footer, TabbedContent, TabPane, Static, 
    ProgressBar, DataTable, Log, Button, Input, Label
)
from textual.binding import Binding
from textual.reactive import reactive
from textual import events
from rich.text import Text
from rich.console import Group
from rich.panel import Panel
from rich.table import Table
from rich.live import Live

from .config import ConfigManager
from .widgets.dashboard import DashboardWidget
from .widgets.monitor import MonitorWidget  
from .widgets.ai_diag import AIDiagWidget
from .widgets.services import ServicesWidget
from .widgets.logs import LogsWidget
from .widgets.history import HistoryWidget
from .utils.system import SystemInfo
from .diagnostics.runner import DiagnosticRunner


class GPTDiagApp(App):
    """Main GPTDiag TUI Application."""
    
    CSS_PATH = "styles.css"
    
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("h", "help", "Help"),
        Binding("ctrl+c", "quit", "Quit"),
        Binding("escape", "back", "Back"),
        Binding("/", "search", "Search"),
        Binding("f1", "show_tab('dashboard')", "Dashboard"),
        Binding("f2", "show_tab('monitor')", "Monitor"),
        Binding("f3", "show_tab('ai_diag')", "AI Diag"),
        Binding("f4", "show_tab('services')", "Services"),
        Binding("f5", "show_tab('logs')", "Logs"),
        Binding("f6", "show_tab('history')", "History"),
    ]
    
    # Reactive attributes
    current_tab = reactive("dashboard")
    system_status = reactive("loading")
    last_update = reactive(datetime.now())
    
    def __init__(self, config_manager: ConfigManager, debug: bool = False):
        """Initialize the GPTDiag application."""
        super().__init__()
        self.config_manager = config_manager
        self.debug = debug
        self.system_info = SystemInfo()
        self.diagnostic_runner = DiagnosticRunner(config_manager)
        
        # Application state
        self.system_data = {}
        self.update_interval = 2.0  # seconds
        self.auto_update = True
        
    def compose(self) -> ComposeResult:
        """Create the application layout."""
        yield Header(show_clock=True)
        
        with TabbedContent(initial="dashboard", id="main_tabs"):
            with TabPane("Dashboard", id="dashboard"):
                yield DashboardWidget(
                    system_info=self.system_info,
                    config_manager=self.config_manager,
                    id="dashboard_widget"
                )
            
            with TabPane("Monitor", id="monitor"):
                yield MonitorWidget(
                    system_info=self.system_info,
                    id="monitor_widget"
                )
            
            with TabPane("AI Diag", id="ai_diag"):
                yield AIDiagWidget(
                    config_manager=self.config_manager,
                    diagnostic_runner=self.diagnostic_runner,
                    id="ai_diag_widget"
                )
            
            with TabPane("Services", id="services"):
                yield ServicesWidget(
                    system_info=self.system_info,
                    id="services_widget"
                )
            
            with TabPane("Logs", id="logs"):
                yield LogsWidget(
                    config_manager=self.config_manager,
                    id="logs_widget"
                )
            
            with TabPane("History", id="history"):
                yield HistoryWidget(
                    diagnostic_runner=self.diagnostic_runner,
                    id="history_widget"
                )
        
        yield Footer()
    
    def on_mount(self) -> None:
        """Initialize the application after mounting."""
        self.title = "GPTDiag - System Diagnostic Hub"
        self.sub_title = f"Version {self.get_version()}"
        
        # Start background tasks
        self.set_interval(self.update_interval, self.update_system_data)
        
        # Load initial data
        self.call_later(self.load_initial_data)
    
    def get_version(self) -> str:
        """Get application version."""
        try:
            from . import __version__
            return __version__
        except ImportError:
            return "1.0.0"
    
    async def load_initial_data(self) -> None:
        """Load initial system data."""
        try:
            self.system_data = await self.system_info.get_async_info()
            self.system_status = "ready"
            self.last_update = datetime.now()
            
            # Notify widgets of initial data
            self.notify_widgets_data_updated()
            
        except Exception as e:
            self.system_status = f"error: {e}"
            if self.debug:
                self.log(f"Error loading initial data: {e}")
    
    async def update_system_data(self) -> None:
        """Update system data periodically."""
        if not self.auto_update:
            return
            
        try:
            # Update system information
            new_data = await self.system_info.get_async_info()
            self.system_data.update(new_data)
            self.last_update = datetime.now()
            
            # Notify all widgets of data update
            self.notify_widgets_data_updated()
            
        except Exception as e:
            if self.debug:
                self.log(f"Error updating system data: {e}")
    
    def notify_widgets_data_updated(self) -> None:
        """Notify all widgets that system data has been updated."""
        # Find and update all our custom widgets
        widgets_to_update = [
            self.query_one("#dashboard_widget", DashboardWidget),
            self.query_one("#monitor_widget", MonitorWidget),
            self.query_one("#services_widget", ServicesWidget),
        ]
        
        for widget in widgets_to_update:
            if hasattr(widget, 'update_data'):
                widget.update_data(self.system_data)
    
    def action_quit(self) -> None:
        """Quit the application."""
        self.exit()
    
    def action_help(self) -> None:
        """Show help information."""
        help_text = """
GPTDiag - System Diagnostic Hub

Navigation:
• ←/→ or F1-F6: Switch between tabs
• ↑/↓: Navigate within tabs
• Enter: Select/activate item
• Tab: Move between panels
• Escape: Go back/cancel
• /: Global search
• h: Show this help
• q: Quit application

Tabs:
• F1 - Dashboard: System overview and quick actions
• F2 - Monitor: Real-time system monitoring
• F3 - AI Diag: AI-powered diagnostics and chat
• F4 - Services: System service management
• F5 - Logs: Log viewing and analysis
• F6 - History: Diagnostic history and reports

Features:
• Real-time system monitoring
• AI-powered system analysis
• Service management
• Log analysis
• Automated diagnostics
• Historical reporting

For more information, visit the documentation.
        """
        
        self.push_screen("help", help_text)
    
    def action_back(self) -> None:
        """Go back or cancel current action."""
        # Try to close any open modals or screens first
        if len(self.screen_stack) > 1:
            self.pop_screen()
        else:
            # Handle tab-specific back actions
            current_tab = self.query_one("#main_tabs", TabbedContent)
            active_tab = current_tab.active
            
            # Let the active widget handle the back action
            if active_tab and hasattr(active_tab, 'action_back'):
                active_tab.action_back()
    
    def action_search(self) -> None:
        """Open global search."""
        # TODO: Implement global search functionality
        self.notify("Global search coming soon!", severity="info")
    
    def action_show_tab(self, tab_id: str) -> None:
        """Show specific tab by ID."""
        tabs = self.query_one("#main_tabs", TabbedContent)
        if tab_id in ["dashboard", "monitor", "ai_diag", "services", "logs", "history"]:
            tabs.active = tab_id
            self.current_tab = tab_id
    
    def on_tabbed_content_tab_activated(
        self, event: TabbedContent.TabActivated
    ) -> None:
        """Handle tab activation."""
        self.current_tab = event.tab.id
        
        # Notify the newly active widget
        widget_id = f"{event.tab.id}_widget"
        try:
            widget = self.query_one(f"#{widget_id}")
            if hasattr(widget, 'on_tab_activated'):
                widget.on_tab_activated()
        except:
            pass  # Widget might not exist or have the method
    
    def toggle_auto_update(self) -> None:
        """Toggle automatic data updates."""
        self.auto_update = not self.auto_update
        status = "enabled" if self.auto_update else "disabled"
        self.notify(f"Auto-update {status}", severity="info")
    
    def force_update(self) -> None:
        """Force an immediate data update."""
        self.call_later(self.update_system_data)
        self.notify("System data updated", severity="info")
    
    async def run_diagnostic_scan(self, scan_type: str = "standard") -> None:
        """Run a diagnostic scan."""
        try:
            self.notify("Starting diagnostic scan...", severity="info")
            
            # Run the scan in the background
            results = await self.diagnostic_runner.run_scan(scan_type)
            
            # Update the history widget
            history_widget = self.query_one("#history_widget", HistoryWidget)
            if hasattr(history_widget, 'add_scan_result'):
                history_widget.add_scan_result(results)
            
            self.notify("Diagnostic scan completed", severity="success")
            
        except Exception as e:
            self.notify(f"Scan failed: {e}", severity="error")
            if self.debug:
                self.log(f"Diagnostic scan error: {e}")
    
    def export_current_data(self, format_type: str = "json") -> None:
        """Export current system data."""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"gptdiag_export_{timestamp}.{format_type}"
            
            # TODO: Implement actual export functionality
            self.notify(f"Export to {filename} - Coming soon!", severity="info")
            
        except Exception as e:
            self.notify(f"Export failed: {e}", severity="error")
    
    def get_system_summary(self) -> Dict[str, Any]:
        """Get a summary of current system status."""
        return {
            "status": self.system_status,
            "last_update": self.last_update,
            "current_tab": self.current_tab,
            "auto_update": self.auto_update,
            "data_keys": list(self.system_data.keys()) if self.system_data else []
        } 