"""
Environment Check Plugin

This plugin validates the system environment for AI theming functionality:
- Wayland/Hyprland availability
- Required services status
- File system permissions
- Basic connectivity tests

This serves as an example of the plugin system architecture.
"""

import asyncio
import os
import subprocess
from datetime import datetime
from typing import Dict, Any

from core.plugin_manager import DiagnosticPlugin
from core.models import DiagnosticResult, DiagnosticIssue, Severity, CheckStatus


class EnvironmentCheckPlugin(DiagnosticPlugin):
    """Plugin to check system environment for AI theming compatibility."""
    
    metadata = {
        "name": "Environment Check",
        "version": "1.0.0",
        "description": "Validates system environment for AI theming functionality",
        "author": "AI Diagnostic System",
        "category": "environment", 
        "dependencies": [],
        "enabled": True
    }
    
    async def execute(self) -> DiagnosticResult:
        """Execute environment validation checks."""
        start_time = datetime.now()
        issues = []
        metrics = {}
        
        # Check Wayland environment
        wayland_display = os.environ.get('WAYLAND_DISPLAY')
        if wayland_display:
            metrics['wayland_display'] = wayland_display
        else:
            issues.append(DiagnosticIssue(
                id="env_no_wayland",
                title="Wayland not available",
                description="WAYLAND_DISPLAY environment variable not set. Theming system requires Wayland/Hyprland.",
                severity=Severity.WARNING,
                category="environment",
                timestamp=datetime.now(),
                affected_components=["waybar", "hyprland", "theming"],
                fix_available=False
            ))
        
        # Check Hyprland process
        try:
            result = subprocess.run(['pgrep', '-f', 'hypr'], capture_output=True, text=True)
            if result.returncode == 0:
                metrics['hyprland_running'] = True
                metrics['hyprland_pids'] = result.stdout.strip().split('\n')
            else:
                metrics['hyprland_running'] = False
                issues.append(DiagnosticIssue(
                    id="env_no_hyprland",
                    title="Hyprland not running", 
                    description="Hyprland window manager is not running. Required for theming system.",
                    severity=Severity.CRITICAL,
                    category="environment",
                    timestamp=datetime.now(),
                    affected_components=["hyprland", "waybar", "theming"],
                    fix_available=True,
                    fix_command="hyprland",
                    fix_description="Start Hyprland window manager"
                ))
        except Exception as e:
            issues.append(DiagnosticIssue(
                id="env_check_failed",
                title="Environment check failed",
                description=f"Failed to check Hyprland status: {e}",
                severity=Severity.ERROR,
                category="environment",
                timestamp=datetime.now()
            ))
        
        # Check Ollama availability
        try:
            result = subprocess.run(['ollama', 'list'], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                metrics['ollama_available'] = True
                models = result.stdout.count('\n') - 1  # Subtract header line
                metrics['ollama_models_count'] = models
                if models == 0:
                    issues.append(DiagnosticIssue(
                        id="env_no_models",
                        title="No Ollama models available",
                        description="Ollama is running but no models are installed. AI features will not work.",
                        severity=Severity.WARNING,
                        category="ai",
                        timestamp=datetime.now(),
                        fix_available=True,
                        fix_command="ollama pull phi4 && ollama pull llama3.2",
                        fix_description="Install required AI models"
                    ))
            else:
                metrics['ollama_available'] = False
                issues.append(DiagnosticIssue(
                    id="env_ollama_error",
                    title="Ollama not responding",
                    description="Ollama service is not responding. AI features will be unavailable.",
                    severity=Severity.ERROR,
                    category="ai",
                    timestamp=datetime.now(),
                    fix_available=True,
                    fix_command="systemctl --user restart ollama",
                    fix_description="Restart Ollama service"
                ))
        except subprocess.TimeoutExpired:
            issues.append(DiagnosticIssue(
                id="env_ollama_timeout",
                title="Ollama service timeout",
                description="Ollama service is not responding within timeout. May be overloaded.",
                severity=Severity.WARNING,
                category="ai",
                timestamp=datetime.now()
            ))
        except FileNotFoundError:
            issues.append(DiagnosticIssue(
                id="env_ollama_missing",
                title="Ollama not installed",
                description="Ollama binary not found. AI features will be unavailable.",
                severity=Severity.CRITICAL,
                category="ai",
                timestamp=datetime.now(),
                fix_available=True,
                fix_command="curl -fsSL https://ollama.com/install.sh | sh",
                fix_description="Install Ollama"
            ))
        
        # Check file permissions for config directories
        config_dirs = [
            "~/.config/waybar",
            "~/.config/hypr", 
            "~/.config/kitty",
            "~/.config/fuzzel",
            "~/.config/gtk-3.0",
            "~/.config/gtk-4.0"
        ]
        
        permission_issues = []
        for config_dir in config_dirs:
            expanded_dir = os.path.expanduser(config_dir)
            if os.path.exists(expanded_dir):
                if not os.access(expanded_dir, os.R_OK | os.W_OK):
                    permission_issues.append(config_dir)
            else:
                permission_issues.append(f"{config_dir} (missing)")
        
        if permission_issues:
            issues.append(DiagnosticIssue(
                id="env_permissions",
                title="Configuration directory permissions",
                description=f"Permission issues with config directories: {', '.join(permission_issues)}",
                severity=Severity.WARNING,
                category="permissions",
                timestamp=datetime.now(),
                affected_components=permission_issues
            ))
        
        metrics['config_dirs_accessible'] = len(config_dirs) - len(permission_issues)
        
        return DiagnosticResult(
            check_id="environment_check",
            check_name="Environment Check",
            status=CheckStatus.COMPLETED,
            duration_ms=0,  # Will be filled by plugin manager
            timestamp=start_time,
            issues=issues,
            metrics=metrics
        )
    
    async def can_fix(self, issue: DiagnosticIssue) -> bool:
        """Check if this plugin can fix the given issue."""
        fixable_issues = {
            "env_no_hyprland",
            "env_no_models", 
            "env_ollama_error",
            "env_ollama_missing"
        }
        return issue.id in fixable_issues
    
    async def apply_fix(self, issue: DiagnosticIssue) -> bool:
        """Apply automatic fix for the given issue."""
        if not await self.can_fix(issue):
            return False
        
        try:
            if issue.fix_command:
                self.logger.info(f"Applying fix: {issue.fix_command}")
                result = subprocess.run(
                    issue.fix_command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.returncode == 0:
                    self.logger.info(f"Fix applied successfully for {issue.id}")
                    return True
                else:
                    self.logger.error(f"Fix failed for {issue.id}: {result.stderr}")
                    return False
            else:
                self.logger.warning(f"No fix command available for {issue.id}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error applying fix for {issue.id}: {e}")
            return False 