#!/usr/bin/env python3
"""
AI-Powered Theming System Diagnostics

Main entry point for the sophisticated diagnostic and troubleshooting system
for AI-enhanced theming environments.

Usage:
    python ai_diagnostics.py --mode quick
    python ai_diagnostics.py --interactive
    python ai_diagnostics.py --mode deep --export json
"""

import asyncio
import click
import logging
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

from rich.console import Console
from rich.logging import RichHandler
from rich.panel import Panel
from rich.text import Text

# Add the current directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

try:
    from core.models import DiagnosticSession, SystemSnapshot
    from core.llm_engine import LLMEngine
    from core.plugin_manager import PluginManager, PluginExecutionContext
except ImportError as e:
    print(f"Import error: {e}")
    print("Please ensure all dependencies are installed. See README.md for installation instructions.")
    sys.exit(1)


class DiagnosticApp:
    """Main application class for the AI diagnostic system."""
    
    def __init__(self):
        self.console = Console()
        self.logger = self._setup_logging()
        self.llm_engine: Optional[LLMEngine] = None
        self.plugin_manager: Optional[PluginManager] = None
        self.current_session: Optional[DiagnosticSession] = None
        
    def _setup_logging(self) -> logging.Logger:
        """Setup logging with rich handler."""
        logging.basicConfig(
            level=logging.INFO,
            format="%(message)s",
            datefmt="[%X]",
            handlers=[RichHandler(console=self.console, rich_tracebacks=True)]
        )
        return logging.getLogger("ai_diagnostics")
    
    async def initialize(self) -> bool:
        """Initialize the diagnostic system components."""
        try:
            self.console.print("[yellow]🔧 Initializing AI Diagnostic System...[/yellow]")
            
            # Initialize LLM engine
            self.llm_engine = LLMEngine()
            if not await self.llm_engine.initialize():
                self.console.print("[red]❌ Failed to initialize LLM engine[/red]")
                return False
            self.console.print("[green]✅ LLM engine initialized[/green]")
            
            # Initialize plugin manager
            self.plugin_manager = PluginManager(
                plugins_dir="plugins",
                llm_engine=self.llm_engine
            )
            if not await self.plugin_manager.initialize():
                self.console.print("[red]❌ Failed to initialize plugin manager[/red]")
                return False
            self.console.print("[green]✅ Plugin manager initialized[/green]")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Initialization failed: {e}")
            return False
    
    async def run_diagnostic(self, mode: str = "quick", export_format: Optional[str] = None) -> bool:
        """Run diagnostic session in specified mode."""
        if not await self.initialize():
            return False
        
        # Create diagnostic session
        session_id = f"diag_{int(time.time())}"
        self.current_session = DiagnosticSession(
            session_id=session_id,
            start_time=datetime.now(),
            mode=mode
        )
        
        self.console.print(Panel(
            f"[bold blue]AI Diagnostic Session Started[/bold blue]\n"
            f"Session ID: {session_id}\n"
            f"Mode: {mode}\n"
            f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            title="🤖 AI Diagnostics",
            border_style="blue"
        ))
        
        try:
            # Create execution context
            context = PluginExecutionContext(
                session_id=session_id,
                mode=mode,
                parallel_execution=(mode != "stress"),  # Sequential for stress tests
                timeout_seconds=30 if mode == "quick" else 120,
                ai_analysis_enabled=True
            )
            
            # Execute diagnostic plugins
            results = await self.plugin_manager.execute_all_plugins(context)
            self.current_session.results = results
            self.current_session.end_time = datetime.now()
            
            # Generate summary
            await self._generate_session_summary()
            
            # Export results if requested
            if export_format:
                await self._export_results(export_format)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Diagnostic session failed: {e}")
            return False
    
    async def run_interactive(self) -> bool:
        """Run interactive diagnostic session."""
        if not await self.initialize():
            return False
        
        # TODO: Implement textual-based interactive UI
        self.console.print("[yellow]📋 Interactive mode coming soon![/yellow]")
        self.console.print("For now, running quick diagnostic...")
        
        return await self.run_diagnostic("quick")
    
    async def show_trends(self, days: int = 30) -> bool:
        """Show historical trends analysis."""
        self.console.print(f"[yellow]📊 Trends analysis for last {days} days coming soon![/yellow]")
        return True
    
    async def _generate_session_summary(self) -> None:
        """Generate and display session summary."""
        if not self.current_session:
            return
        
        session = self.current_session
        total_issues = sum(len(result.issues) for result in session.results)
        total_duration = (session.end_time - session.start_time).total_seconds()
        
        # Create summary panel
        summary_text = Text()
        summary_text.append(f"🔍 Diagnostic Summary\n\n", style="bold")
        summary_text.append(f"Session Duration: {total_duration:.1f}s\n")
        summary_text.append(f"Plugins Executed: {len(session.results)}\n")
        summary_text.append(f"Issues Detected: {total_issues}\n\n")
        
        # Show plugin results
        for result in session.results:
            status_icon = "✅" if result.status.value == "completed" else "❌"
            summary_text.append(f"{status_icon} {result.check_name}: ")
            summary_text.append(f"{len(result.issues)} issues", style="yellow" if result.issues else "green")
            summary_text.append(f" ({result.duration_ms}ms)\n")
        
        self.console.print(Panel(summary_text, title="Session Results", border_style="green"))
        
        # Show critical issues
        critical_issues = []
        for result in session.results:
            critical_issues.extend([issue for issue in result.issues if issue.severity.value == "critical"])
        
        if critical_issues:
            self.console.print("\n[red]🚨 Critical Issues Found:[/red]")
            for issue in critical_issues:
                self.console.print(f"  • {issue.title}: {issue.description}")
    
    async def _export_results(self, format_type: str) -> None:
        """Export diagnostic results in specified format."""
        if not self.current_session:
            return
        
        # Ensure exports directory exists
        exports_dir = Path("data/exports")
        exports_dir.mkdir(parents=True, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = exports_dir / f"diagnostic_{timestamp}.{format_type}"
        
        if format_type == "json":
            import json
            with open(filename, 'w') as f:
                json.dump(self.current_session.dict(), f, indent=2, default=str)
        else:
            self.console.print(f"[red]Export format '{format_type}' not yet implemented[/red]")
            return
        
        self.console.print(f"[green]📄 Results exported to: {filename}[/green]")


@click.command()
@click.option('--mode', type=click.Choice(['quick', 'deep', 'stress']), default='quick',
              help='Diagnostic depth level')
@click.option('--interactive', is_flag=True, help='Launch interactive terminal UI')
@click.option('--ai-model', default='phi4', help='Primary LLM model to use')
@click.option('--export', type=click.Choice(['json', 'html', 'terminal']),
              help='Export results in specified format')
@click.option('--trends', is_flag=True, help='Show historical trend analysis')
@click.option('--days', default=30, help='Days of history for trend analysis')
@click.option('--verbose', is_flag=True, help='Enable detailed logging')
def main(mode: str, interactive: bool, ai_model: str, export: Optional[str], 
         trends: bool, days: int, verbose: bool):
    """AI-Powered Theming System Diagnostics"""
    
    app = DiagnosticApp()
    
    if verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    async def run_app():
        if trends:
            return await app.show_trends(days)
        elif interactive:
            return await app.run_interactive()
        else:
            return await app.run_diagnostic(mode, export)
    
    # Run the async application
    success = asyncio.run(run_app())
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main() 