#!/usr/bin/env python3
"""
Real-time System Dashboard Widget for GPTDiag
"""

import asyncio
from datetime import datetime
from typing import Dict, Any, Optional

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import Static, ProgressBar, DataTable, Button
from textual.reactive import reactive
from textual.timer import Timer

from ...utils.system import SystemInfo
from ...ai.manager import AIManager


class SystemMetricWidget(Static):
    """Widget for displaying a single system metric."""
    
    def __init__(self, label: str, value: str = "0", unit: str = "", **kwargs):
        super().__init__(**kwargs)
        self.label = label
        self.value = value
        self.unit = unit
        self.update_display()
    
    def update_value(self, value: str, unit: str = ""):
        """Update the metric value."""
        self.value = value
        self.unit = unit
        self.update_display()
    
    def update_display(self):
        """Update the widget display."""
        self.update(f"[bold]{self.label}[/bold]\n{self.value}{self.unit}")


class SystemProgressWidget(Container):
    """Widget for displaying system metrics with progress bars."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.cpu_progress = ProgressBar(total=100, show_percentage=True)
        self.memory_progress = ProgressBar(total=100, show_percentage=True)
        self.disk_progress = ProgressBar(total=100, show_percentage=True)
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]System Resources[/bold]", classes="section-title")
        yield Static("CPU Usage:")
        yield self.cpu_progress
        yield Static("Memory Usage:")
        yield self.memory_progress
        yield Static("Disk Usage:")
        yield self.disk_progress
    
    def update_metrics(self, cpu_percent: float, memory_percent: float, disk_percent: float):
        """Update the progress bars with dynamic colors."""
        # Update progress
        self.cpu_progress.update(progress=cpu_percent)
        self.memory_progress.update(progress=memory_percent)
        self.disk_progress.update(progress=disk_percent)
        
        # Update CSS classes based on usage levels
        self._update_cpu_color(cpu_percent)
        self._update_memory_color(memory_percent)
        self._update_disk_color(disk_percent)
    
    def _update_cpu_color(self, percent: float):
        """Update CPU progress bar color based on usage."""
        self.cpu_progress.remove_class("cpu-low", "cpu-medium", "cpu-high")
        if percent < 50:
            self.cpu_progress.add_class("cpu-low")
        elif percent < 80:
            self.cpu_progress.add_class("cpu-medium")
        else:
            self.cpu_progress.add_class("cpu-high")
    
    def _update_memory_color(self, percent: float):
        """Update memory progress bar color based on usage."""
        self.memory_progress.remove_class("memory-low", "memory-medium", "memory-high")
        if percent < 60:
            self.memory_progress.add_class("memory-low")
        elif percent < 85:
            self.memory_progress.add_class("memory-medium")
        else:
            self.memory_progress.add_class("memory-high")
    
    def _update_disk_color(self, percent: float):
        """Update disk progress bar color based on usage."""
        self.disk_progress.remove_class("disk-low", "disk-medium", "disk-high")
        if percent < 70:
            self.disk_progress.add_class("disk-low")
        elif percent < 90:
            self.disk_progress.add_class("disk-medium")
        else:
            self.disk_progress.add_class("disk-high")


class QuickStatsWidget(Container):
    """Widget for displaying quick system statistics."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.stats = {
            "uptime": SystemMetricWidget("Uptime", "0s"),
            "processes": SystemMetricWidget("Processes", "0"),
            "load": SystemMetricWidget("Load Avg", "0.00"),
            "temp": SystemMetricWidget("Temperature", "N/A", "°C")
        }
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]Quick Stats[/bold]", classes="section-title")
        with Horizontal():
            yield self.stats["uptime"]
            yield self.stats["processes"]
        with Horizontal():
            yield self.stats["load"]
            yield self.stats["temp"]
    
    def update_stats(self, uptime: str, processes: int, load_avg: float, temp: str = "N/A"):
        """Update the statistics with better formatting."""
        # Format uptime nicely
        if uptime and uptime != "Unknown":
            # Convert from "H:MM:SS" to more readable format
            parts = uptime.split(":")
            if len(parts) >= 2:
                hours = int(parts[0])
                if hours == 0:
                    uptime_str = f"{parts[1]}:{parts[2]}"
                elif hours < 24:
                    uptime_str = f"{hours}h {parts[1]}m"
                else:
                    days = hours // 24
                    remaining_hours = hours % 24
                    uptime_str = f"{days}d {remaining_hours}h"
            else:
                uptime_str = uptime
        else:
            uptime_str = "Unknown"
        
        self.stats["uptime"].update_value(uptime_str)
        self.stats["processes"].update_value(f"{processes:,}")  # Add thousands separator
        self.stats["load"].update_value(f"{load_avg:.2f}")
        
        # Show CPU temperature if available, otherwise show core count
        if temp != "N/A":
            self.stats["temp"].update_value(temp, "°C")
        else:
            # Get CPU core count as fallback
            import psutil
            cores = psutil.cpu_count()
            self.stats["temp"].label = "CPU Cores"
            self.stats["temp"].update_value(str(cores), " cores")
            self.stats["temp"].update_display()


class TopProcessesWidget(Container):
    """Widget for displaying top processes."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.table = DataTable()
        # Don't add columns in __init__, do it in compose() or on_mount()
        self._columns_added = False
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]Top Processes[/bold]", classes="section-title")
        yield self.table
    
    def on_mount(self) -> None:
        """Add table columns when widget is mounted."""
        if not self._columns_added:
            self.table.add_columns("PID", "Name", "CPU%", "Memory%")
            self._columns_added = True
    
    def update_processes(self, processes: list):
        """Update the processes table."""
        if not self._columns_added:
            return  # Can't update if columns aren't added yet
            
        self.table.clear()
        for proc in processes[:5]:  # Show top 5 processes
            self.table.add_row(
                str(proc.get("pid", "N/A")),
                proc.get("name", "N/A"),
                f"{proc.get('cpu_percent', 0):.1f}%",
                f"{proc.get('memory_percent', 0):.1f}%"
            )


class SystemAlertsWidget(Container):
    """Widget for displaying system alerts."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.alerts_display = Static("✅ No alerts", classes="alerts-good")
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]System Alerts[/bold]", classes="section-title")
        yield self.alerts_display
    
    def update_alerts(self, alerts: list):
        """Update the alerts display."""
        if not alerts:
            self.alerts_display.update("✅ System running normally")
            self.alerts_display.classes = "alerts-good"
        else:
            alert_text = "\n".join([f"⚠️  {alert}" for alert in alerts])
            self.alerts_display.update(alert_text)
            self.alerts_display.classes = "alerts-warning"


class AIInsightsWidget(Container):
    """Widget for displaying AI insights."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.insights_display = Static("🤖 AI analysis pending...", classes="ai-insights")
        self.analyze_button = Button("Analyze System", id="analyze-btn")
        self.last_analysis = None
    
    def compose(self) -> ComposeResult:
        """Compose the widget."""
        yield Static("[bold]AI Insights[/bold]", classes="section-title")
        yield self.analyze_button
        yield self.insights_display
    
    def update_insights(self, insights: str):
        """Update the AI insights display."""
        # Truncate long insights for dashboard display
        truncated = insights[:200] + "..." if len(insights) > 200 else insights
        self.insights_display.update(f"🤖 {truncated}")
        self.last_analysis = datetime.now()
    
    def show_analyzing(self):
        """Show analyzing state."""
        self.insights_display.update("🤖 Analyzing system... Please wait.")
        self.analyze_button.disabled = True
    
    def analysis_complete(self):
        """Enable button after analysis."""
        self.analyze_button.disabled = False


class DashboardWidget(Container):
    """Main dashboard widget with real-time system monitoring."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.system_info = SystemInfo()
        self.ai_manager: Optional[AIManager] = None
        self.update_timer: Optional[Timer] = None
        self.auto_refresh = True
        self.refresh_interval = 5.0  # seconds
        
        # Initialize child widgets
        self.progress_widget = SystemProgressWidget()
        self.stats_widget = QuickStatsWidget()
        self.processes_widget = TopProcessesWidget()
        self.alerts_widget = SystemAlertsWidget()
        self.ai_widget = AIInsightsWidget()
        
        # Dashboard state
        self.last_update = None
        self.update_count = 0
    
    def compose(self) -> ComposeResult:
        """Compose the dashboard."""
        yield Static("[bold]GPTDiag - System Dashboard[/bold]", classes="dashboard-title")
        
        with Horizontal():
            with Vertical(classes="left-panel"):
                yield self.progress_widget
                yield self.stats_widget
            
            with Vertical(classes="right-panel"):
                yield self.processes_widget
                yield self.alerts_widget
        
        yield self.ai_widget
        
        # Status bar
        yield Static(f"Last updated: Never | Auto-refresh: {'ON' if self.auto_refresh else 'OFF'}", 
                    id="status-bar")
    
    def on_mount(self) -> None:
        """Start monitoring when widget is mounted."""
        self.start_monitoring()
    
    def on_unmount(self) -> None:
        """Stop monitoring when widget is unmounted."""
        self.stop_monitoring()
    
    def start_monitoring(self) -> None:
        """Start real-time monitoring."""
        if self.update_timer is None:
            self.update_timer = self.set_interval(self.refresh_interval, self.update_dashboard)
        self.update_dashboard()  # Initial update
    
    def stop_monitoring(self) -> None:
        """Stop real-time monitoring."""
        if self.update_timer:
            self.update_timer.stop()
            self.update_timer = None
    
    async def update_dashboard(self) -> None:
        """Update all dashboard widgets with current system data."""
        try:
            # Get quick system summary for fast updates
            summary = self.system_info.get_quick_summary()
            
            if "error" in summary:
                self.alerts_widget.update_alerts([f"System monitoring error: {summary['error']}"])
                return
            
            # Update progress bars
            self.progress_widget.update_metrics(
                summary["cpu_percent"],
                summary["memory_percent"],
                summary["disk_percent"]
            )
            
            # Update quick stats
            uptime_info = self.system_info._get_uptime()
            self.stats_widget.update_stats(
                uptime_info.get("human_readable", "Unknown"),
                summary["process_count"],
                summary["load_avg"]
            )
            
            # Get detailed info for processes (less frequent)
            if self.update_count % 3 == 0:  # Every 3rd update
                detailed_info = await self.system_info.get_async_info()
                
                # Update processes
                processes = detailed_info.get("processes", [])
                self.processes_widget.update_processes(processes)
                
                # Update alerts (basic threshold checking)
                alerts = []
                if summary["cpu_percent"] > 80:
                    alerts.append(f"High CPU usage: {summary['cpu_percent']:.1f}%")
                if summary["memory_percent"] > 85:
                    alerts.append(f"High memory usage: {summary['memory_percent']:.1f}%")
                if summary["disk_percent"] > 90:
                    alerts.append(f"High disk usage: {summary['disk_percent']:.1f}%")
                
                self.alerts_widget.update_alerts(alerts)
            
            # Update status bar
            self.last_update = datetime.now()
            self.update_count += 1
            status_bar = self.query_one("#status-bar", Static)
            status_bar.update(
                f"Last updated: {self.last_update.strftime('%H:%M:%S')} | "
                f"Updates: {self.update_count} | "
                f"Auto-refresh: {'ON' if self.auto_refresh else 'OFF'}"
            )
            
        except Exception as e:
            self.alerts_widget.update_alerts([f"Dashboard update error: {str(e)}"])
    
    async def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "analyze-btn":
            await self.run_ai_analysis()
    
    async def run_ai_analysis(self) -> None:
        """Run AI analysis of the current system state."""
        if not self.ai_manager:
            # Try to initialize AI manager
            try:
                from ...config.manager import ConfigManager
                from pathlib import Path
                
                config_dir = Path.home() / ".config" / "gptdiag"
                config_manager = ConfigManager(config_dir)
                config = config_manager.get_ai_config()
                self.ai_manager = AIManager(config)
                
                if not await self.ai_manager.initialize():
                    self.ai_widget.update_insights("❌ AI unavailable - no providers initialized")
                    return
            except Exception as e:
                self.ai_widget.update_insights(f"❌ AI initialization failed: {str(e)}")
                return
        
        # Start analysis
        self.ai_widget.show_analyzing()
        
        try:
            # Get current system data
            system_data = await self.system_info.get_async_info()
            
            # Request AI analysis
            response = await self.ai_manager.analyze_system_health(system_data)
            
            if response.error:
                self.ai_widget.update_insights(f"❌ AI analysis failed: {response.error}")
            else:
                # Extract key insights (first few lines of response)
                lines = response.content.split('\n')
                key_insights = []
                for line in lines:
                    if line.strip() and not line.startswith('#'):
                        key_insights.append(line.strip())
                    if len(key_insights) >= 3:  # Get first 3 meaningful lines
                        break
                
                insights_text = " ".join(key_insights)
                self.ai_widget.update_insights(insights_text)
                
        except Exception as e:
            self.ai_widget.update_insights(f"❌ Analysis error: {str(e)}")
        
        finally:
            self.ai_widget.analysis_complete()
    
    def toggle_auto_refresh(self) -> None:
        """Toggle auto-refresh on/off."""
        self.auto_refresh = not self.auto_refresh
        if self.auto_refresh:
            self.start_monitoring()
        else:
            self.stop_monitoring() 