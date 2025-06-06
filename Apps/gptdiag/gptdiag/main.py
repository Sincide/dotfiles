#!/usr/bin/env python3
"""
GPTDiag Main Entry Point

Command-line interface and application launcher for GPTDiag.
"""

import asyncio
import argparse
import sys
import os
from pathlib import Path
from typing import Optional

import click
from rich.console import Console
from rich.traceback import install

from . import __version__
from .app import GPTDiagApp
from .config import ConfigManager
from .utils.system import SystemInfo
from .diagnostics.runner import DiagnosticRunner

# Install rich traceback handler
install()

console = Console()


def setup_paths():
    """Setup necessary directories for GPTDiag."""
    config_dir = Path.home() / ".config" / "gptdiag"
    data_dir = Path.home() / ".local" / "share" / "gptdiag"
    cache_dir = Path.home() / ".cache" / "gptdiag"
    
    for directory in [config_dir, data_dir, cache_dir]:
        directory.mkdir(parents=True, exist_ok=True)
    
    return config_dir, data_dir, cache_dir


@click.group(invoke_without_command=True)
@click.option('--version', is_flag=True, help='Show version information')
@click.option('--debug', is_flag=True, help='Enable debug mode')
@click.option('--config-dir', type=click.Path(), help='Custom config directory')
@click.pass_context
def cli(ctx, version, debug, config_dir):
    """GPTDiag - Advanced System Diagnostic TUI
    
    A powerful terminal-based system diagnostic and monitoring tool with 
    integrated AI-powered analysis capabilities.
    """
    if version:
        console.print(f"GPTDiag version {__version__}")
        sys.exit(0)
    
    # Setup application paths
    config_path, data_path, cache_path = setup_paths()
    
    # Store context for subcommands
    ctx.ensure_object(dict)
    ctx.obj['debug'] = debug
    ctx.obj['config_dir'] = Path(config_dir) if config_dir else config_path
    ctx.obj['data_dir'] = data_path
    ctx.obj['cache_dir'] = cache_path
    
    # If no subcommand is provided, launch the main TUI
    if ctx.invoked_subcommand is None:
        launch_tui(ctx.obj)


def launch_tui(context: dict):
    """Launch the main TUI application."""
    try:
        # Initialize configuration
        config_manager = ConfigManager(context['config_dir'])
        
        # Create and run the TUI app
        app = GPTDiagApp(
            config_manager=config_manager,
            debug=context['debug']
        )
        
        asyncio.run(app.run_async())
        
    except KeyboardInterrupt:
        console.print("\n[yellow]Application interrupted by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        if context['debug']:
            console.print_exception()
        else:
            console.print(f"[red]Error: {e}[/red]")
        sys.exit(1)


@cli.command()
@click.pass_context
def config(ctx):
    """Launch configuration wizard."""
    console.print("[bold blue]GPTDiag Configuration Wizard[/bold blue]")
    
    config_manager = ConfigManager(ctx.obj['config_dir'])
    
    # Run configuration wizard
    from .config.wizard import ConfigWizard
    wizard = ConfigWizard(config_manager)
    wizard.run()
    
    console.print("[green]Configuration completed![/green]")


@cli.command()
@click.option('--format', type=click.Choice(['json', 'yaml', 'text']), default='json')
@click.option('--output', type=click.Path(), help='Output file path')
@click.pass_context
def export_report(ctx, format, output):
    """Export latest diagnostic report."""
    console.print("[blue]Exporting diagnostic report...[/blue]")
    
    try:
        # Initialize diagnostic runner
        config_manager = ConfigManager(ctx.obj['config_dir'])
        runner = DiagnosticRunner(config_manager)
        
        # Export report
        report_data = runner.get_latest_report()
        
        if not report_data:
            console.print("[yellow]No diagnostic reports found[/yellow]")
            return
        
        if output:
            runner.export_report(report_data, output, format)
            console.print(f"[green]Report exported to: {output}[/green]")
        else:
            # Print to stdout
            runner.print_report(report_data, format)
            
    except Exception as e:
        console.print(f"[red]Export failed: {e}[/red]")
        sys.exit(1)


@cli.command()
@click.option('--quick', is_flag=True, help='Run quick scan only')
@click.option('--full', is_flag=True, help='Run comprehensive scan')
@click.option('--ai', is_flag=True, help='Include AI analysis')
@click.pass_context
def headless_scan(ctx, quick, full, ai):
    """Run diagnostics without TUI interface."""
    console.print("[blue]Running headless diagnostic scan...[/blue]")
    
    try:
        config_manager = ConfigManager(ctx.obj['config_dir'])
        runner = DiagnosticRunner(config_manager)
        
        # Determine scan type
        scan_type = 'quick' if quick else 'full' if full else 'standard'
        
        # Run the scan
        with console.status("[bold green]Scanning system..."):
            results = asyncio.run(runner.run_scan(scan_type, include_ai=ai))
        
        # Display results
        runner.display_results(results)
        
        console.print("[green]Scan completed successfully![/green]")
        
    except Exception as e:
        if ctx.obj['debug']:
            console.print_exception()
        else:
            console.print(f"[red]Scan failed: {e}[/red]")
        sys.exit(1)


@cli.command()
@click.pass_context
def system_info(ctx):
    """Display system information."""
    console.print("[bold blue]System Information[/bold blue]")
    
    try:
        system_info = SystemInfo()
        info = system_info.get_comprehensive_info()
        
        # Display system info in a nice format
        from rich.table import Table
        
        table = Table(title="System Overview")
        table.add_column("Category", style="cyan")
        table.add_column("Information", style="green")
        
        for category, details in info.items():
            if isinstance(details, dict):
                for key, value in details.items():
                    table.add_row(f"{category}.{key}", str(value))
            else:
                table.add_row(category, str(details))
        
        console.print(table)
        
    except Exception as e:
        console.print(f"[red]Failed to get system info: {e}[/red]")
        sys.exit(1)


def main():
    """Main entry point for the application."""
    try:
        cli()
    except KeyboardInterrupt:
        console.print("\n[yellow]Operation cancelled by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        console.print(f"[red]Unexpected error: {e}[/red]")
        sys.exit(1)


if __name__ == "__main__":
    main() 