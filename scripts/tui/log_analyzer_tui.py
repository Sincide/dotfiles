#!/usr/bin/env python3
"""
Evil Space Log Analyzer TUI
A beautiful terminal interface for log analysis with local LLM integration
"""

import asyncio
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import (
    Button, 
    DataTable, 
    Header, 
    Input, 
    Label, 
    Log, 
    Select, 
    Static,
    TabbedContent,
    TabPane,
    TextArea
)
from textual.reactive import reactive
from textual import work
from textual.worker import Worker, WorkerState

# Add the AI scripts directory to path for imports
sys.path.append(str(Path(__file__).parent.parent / "ai"))
from realtime_log_analyzer import RealTimeLogAnalyzer, OllamaClient


class StatusBar(Static):
    """Status bar showing current state and statistics"""
    
    status = reactive("Ready")
    events_processed = reactive(0)
    critical_alerts = reactive(0)
    model_status = reactive("Unknown")
    
    def compose(self) -> ComposeResult:
        yield Label("Status: ", classes="status-label")
        yield Label("", id="status-text", classes="status-value")
        yield Label("Events: ", classes="status-label")
        yield Label("0", id="events-count", classes="status-value")
        yield Label("Alerts: ", classes="status-label")
        yield Label("0", id="alerts-count", classes="status-value")
        yield Label("Model: ", classes="status-label")
        yield Label("Unknown", id="model-status", classes="status-value")
    
    def watch_status(self, status: str) -> None:
        self.query_one("#status-text").update(status)
    
    def watch_events_processed(self, count: int) -> None:
        self.query_one("#events-count").update(str(count))
    
    def watch_critical_alerts(self, count: int) -> None:
        self.query_one("#alerts-count").update(str(count))
    
    def watch_model_status(self, status: str) -> None:
        self.query_one("#model-status").update(status)


class LogAnalyzerTUI(App):
    """Main TUI application for log analysis"""
    
    CSS = """
    Screen {
        layout: grid;
        grid-size: 2;
        grid-columns: 1fr 2fr;
        grid-rows: 1fr;
        grid-gutter: 1;
    }
    
    #left-panel {
        border: solid green;
        padding: 1;
        background: $surface;
    }
    
    #right-panel {
        border: solid blue;
        padding: 1;
        background: $surface;
    }
    
    .status-label {
        color: $text-muted;
        margin-right: 1;
    }
    
    .status-value {
        color: $text;
        text-style: bold;
        margin-right: 2;
    }
    
    #status-bar {
        height: 3;
        background: $surface;
        border-top: solid $primary;
        padding: 0 1;
    }
    
    .action-button {
        width: 100%;
        margin: 1 0;
        height: 3;
    }
    
    .quick-action {
        width: 100%;
        margin: 0 0;
        height: 2;
    }
    
    #log-output {
        height: 20;
        border: solid $primary;
        background: $boost;
    }
    
    #config-panel {
        height: 15;
        border: solid $primary;
        background: $boost;
    }
    
    .section-title {
        text-align: center;
        color: $primary;
        text-style: bold;
        margin: 1 0;
    }
    
    #model-select {
        width: 100%;
        margin: 1 0;
    }
    
    #timeframe-input {
        width: 100%;
        margin: 1 0;
    }
    
    DataTable {
        height: 15;
        border: solid $primary;
    }
    
    TextArea {
        height: 10;
        border: solid $primary;
    }
    """
    
    def __init__(self):
        super().__init__()
        self.analyzer = None
        self.ollama_client = None
        self.monitoring = False
        self.current_model = "codegemma:7b"
        self.available_models = []
        
    def compose(self) -> ComposeResult:
        """Create the main UI layout"""
        yield Header(show_clock=True)
        
        with Horizontal():
            # Left Panel - Choices and Actions
            with Vertical(id="left-panel"):
                yield Label("🔍 Log Analyzer Actions", classes="section-title")
                
                # Quick Actions
                yield Label("Quick Actions", classes="section-title")
                yield Button("🚀 Start Live Monitoring", id="live-monitor", classes="action-button")
                yield Button("🔍 Investigate Sudo Issues", id="sudo-investigate", classes="quick-action")
                yield Button("🛡️ Security Analysis", id="security-analysis", classes="quick-action")
                yield Button("📊 Today's Events", id="today-events", classes="quick-action")
                
                # Configuration
                yield Label("Configuration", classes="section-title")
                yield Select(
                    [("codegemma:7b", "codegemma:7b"), ("llama3.2:3b", "llama3.2:3b")],
                    value="codegemma:7b",
                    id="model-select"
                )
                yield Input(placeholder="Timeframe (e.g., '1 hour ago')", id="timeframe-input")
                yield Button("⚙️ Update Config", id="update-config", classes="action-button")
                
                # Custom Investigation
                yield Label("Custom Investigation", classes="section-title")
                yield Input(placeholder="Pattern to search for", id="pattern-input")
                yield Button("🔎 Custom Search", id="custom-search", classes="action-button")
                
                # Control
                yield Label("Control", classes="section-title")
                yield Button("⏹️ Stop Monitoring", id="stop-monitor", classes="action-button")
                yield Button("🔄 Refresh Status", id="refresh-status", classes="action-button")
                yield Button("❌ Exit", id="exit-app", classes="action-button")
            
            # Right Panel - Content and Results
            with Vertical(id="right-panel"):
                with TabbedContent():
                    with TabPane("📋 Log Output", id="log-tab"):
                        yield Log(id="log-output")
                    
                    with TabPane("📊 Statistics", id="stats-tab"):
                        yield DataTable(id="stats-table")
                        yield TextArea(id="ai-analysis")
                    
                    with TabPane("⚙️ Configuration", id="config-tab"):
                        yield Static(id="config-panel")
        
        yield StatusBar(id="status-bar")
    
    def on_mount(self) -> None:
        """Initialize the application"""
        self.log_output = self.query_one("#log-output")
        self.log_output.write("🚀 Evil Space Log Analyzer TUI initialized")
        self.initialize_analyzer()
        self.update_status("Ready")
        self.log_output.write("Select an action from the left panel to begin")
    
    def initialize_analyzer(self) -> None:
        """Initialize the log analyzer and Ollama client"""
        try:
            self.ollama_client = OllamaClient(self.current_model)
            self.analyzer = RealTimeLogAnalyzer(model=self.current_model)
            
            # Update model status
            status = "Available" if self.ollama_client.available else "Unavailable"
            self.query_one(StatusBar).model_status = f"{self.current_model} ({status})"
            
            self.log_output.write(f"✅ Analyzer initialized with model: {self.current_model}")
            
        except Exception as e:
            self.log_output.write(f"❌ Failed to initialize analyzer: {e}")
    
    def update_status(self, status: str) -> None:
        """Update the status bar"""
        self.query_one(StatusBar).status = status
    
    @work
    async def start_live_monitoring(self) -> None:
        """Start real-time log monitoring in background"""
        if self.monitoring:
            self.log_output.write("⚠️ Monitoring already active")
            return
        
        self.monitoring = True
        self.update_status("Monitoring...")
        self.log_output.write("🚀 Starting live log monitoring...")
        
        try:
            # Start journalctl process
            cmd = ['journalctl', '--follow', '--output=json', '--no-pager']
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            self.log_output.write("📡 Connected to journalctl stream")
            
            # Process events
            while self.monitoring:
                line = await process.stdout.readline()
                if not line:
                    break
                
                # Parse and analyze the event
                event_data = line.decode().strip()
                if event_data:
                    await self.process_log_event(event_data)
            
        except Exception as e:
            self.log_output.write(f"❌ Monitoring error: {e}")
        finally:
            self.monitoring = False
            self.update_status("Ready")
    
    async def process_log_event(self, event_data: str) -> None:
        """Process a single log event"""
        try:
            # Parse JSON event
            import json
            event = json.loads(event_data)
            
            # Extract key information
            timestamp = datetime.fromtimestamp(
                int(event.get('__REALTIME_TIMESTAMP', 0)) / 1000000
            )
            unit = event.get('_SYSTEMD_UNIT', 'unknown')
            message = event.get('MESSAGE', '')
            
            # Check for interesting patterns
            if any(pattern in message.lower() for pattern in ['error', 'failed', 'sudo', 'auth']):
                self.log_output.write(f"🚨 {timestamp.strftime('%H:%M:%S')} [{unit}] {message[:80]}")
                
                # Update statistics
                status_bar = self.query_one(StatusBar)
                status_bar.events_processed += 1
                
                if 'sudo' in message.lower() or 'auth' in message.lower():
                    status_bar.critical_alerts += 1
                    
                    # Get AI analysis for critical events
                    if self.ollama_client and self.ollama_client.available:
                        analysis = await self.get_ai_analysis(message)
                        self.log_output.write(f"🤖 AI: {analysis[:100]}...")
        
        except Exception as e:
            self.log_output.write(f"⚠️ Event processing error: {e}")
    
    async def get_ai_analysis(self, message: str) -> str:
        """Get AI analysis for a log message"""
        try:
            # Use subprocess for Ollama call
            result = await asyncio.create_subprocess_exec(
                'ollama', 'run', self.current_model, 
                f"Analyze this log entry: {message}",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await result.communicate()
            if result.returncode == 0:
                return stdout.decode().strip()
            else:
                return f"AI analysis failed: {stderr.decode()}"
        
        except Exception as e:
            return f"AI analysis error: {e}"
    
    @work
    async def investigate_timeframe(self, timeframe: str, pattern: str = None) -> None:
        """Investigate logs in a specific timeframe"""
        self.update_status("Investigating...")
        self.log_output.write(f"🔍 Investigating logs from {timeframe}")
        
        try:
            cmd = ['journalctl', '--output=json', '--since', timeframe]
            if pattern:
                cmd.extend(['--grep', pattern])
            
            result = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await result.communicate()
            
            if result.returncode == 0:
                events = stdout.decode().strip().split('\n')
                self.log_output.write(f"📊 Found {len(events)} events")
                
                # Process events and update statistics
                for event_data in events[-10:]:  # Show last 10 events
                    if event_data:
                        await self.process_log_event(event_data)
                
                # Update data table
                await self.update_statistics_table(events)
                
            else:
                self.log_output.write(f"❌ Investigation failed: {stderr.decode()}")
        
        except Exception as e:
            self.log_output.write(f"❌ Investigation error: {e}")
        finally:
            self.update_status("Ready")
    
    async def update_statistics_table(self, events: list) -> None:
        """Update the statistics table with event data"""
        table = self.query_one("#stats-table")
        table.clear(columns=True)
        
        # Add columns
        table.add_columns("Time", "Unit", "Message", "Severity")
        
        # Add sample events
        for event_data in events[-5:]:  # Last 5 events
            try:
                event = json.loads(event_data)
                timestamp = datetime.fromtimestamp(
                    int(event.get('__REALTIME_TIMESTAMP', 0)) / 1000000
                )
                unit = event.get('_SYSTEMD_UNIT', 'unknown')
                message = event.get('MESSAGE', '')[:50]
                
                # Determine severity
                severity = "LOW"
                if any(word in message.lower() for word in ['error', 'failed', 'critical']):
                    severity = "HIGH"
                elif any(word in message.lower() for word in ['warning', 'sudo']):
                    severity = "MEDIUM"
                
                table.add_row(
                    timestamp.strftime('%H:%M:%S'),
                    unit,
                    message,
                    severity
                )
            except:
                continue
    
    # Event handlers
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses"""
        button_id = event.button.id
        
        if button_id == "live-monitor":
            self.start_live_monitoring()
        
        elif button_id == "sudo-investigate":
            self.investigate_timeframe("6 hours ago", "sudo")
        
        elif button_id == "security-analysis":
            self.investigate_timeframe("24 hours ago", "security")
        
        elif button_id == "today-events":
            self.investigate_timeframe("today")
        
        elif button_id == "custom-search":
            pattern = self.query_one("#pattern-input").value
            timeframe = self.query_one("#timeframe-input").value or "1 hour ago"
            if pattern:
                self.investigate_timeframe(timeframe, pattern)
            else:
                self.log_output.write("⚠️ Please enter a pattern to search for")
        
        elif button_id == "update-config":
            self.current_model = self.query_one("#model-select").value
            self.initialize_analyzer()
            self.log_output.write(f"✅ Configuration updated: {self.current_model}")
        
        elif button_id == "stop-monitor":
            self.monitoring = False
            self.update_status("Ready")
            self.log_output.write("⏹️ Monitoring stopped")
        
        elif button_id == "refresh-status":
            self.initialize_analyzer()
            self.log_output.write("🔄 Status refreshed")
        
        elif button_id == "exit-app":
            self.exit()
    
    def on_select_changed(self, event: Select.Changed) -> None:
        """Handle select changes"""
        if event.select.id == "model-select":
            self.current_model = event.value
            self.log_output.write(f"📝 Model changed to: {self.current_model}")


def main():
    """Main entry point"""
    app = LogAnalyzerTUI()
    app.run()


if __name__ == "__main__":
    main() 