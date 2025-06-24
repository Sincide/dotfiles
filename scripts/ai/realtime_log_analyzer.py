#!/usr/bin/env python3
"""
Evil Space Real-Time Log Analyzer with Local LLM
A comprehensive system log analyzer with AI-powered explanations using Ollama.
"""

import json
import subprocess
import sys
import time
import re
import argparse
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from collections import defaultdict, deque
import threading
import signal

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

class LogPattern:
    """Represents a suspicious or interesting log pattern"""
    def __init__(self, name: str, regex: str, severity: str, description: str):
        self.name = name
        self.regex = re.compile(regex, re.IGNORECASE)
        self.severity = severity  # CRITICAL, HIGH, MEDIUM, LOW
        self.description = description

class OllamaClient:
    """Client for interacting with local Ollama LLM"""
    
    def __init__(self, model: str = "codegemma:7b"):
        self.model = model
        self.available = self._check_ollama_available()
    
    def _check_ollama_available(self) -> bool:
        """Check if Ollama is running and model is available"""
        try:
            result = subprocess.run(['ollama', 'list'], capture_output=True, text=True, timeout=5)
            return result.returncode == 0 and self.model in result.stdout
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False
    
    def explain_log_entry(self, log_entry: str, context: str = "") -> str:
        """Get AI explanation of a log entry"""
        if not self.available:
            return "Ollama not available for analysis"
        
        prompt = f"""You are a Linux system administrator analyzing log entries. 
Explain this log entry in simple terms:

Log Entry: {log_entry}

Context: {context}

Provide:
1. What happened (1-2 sentences)
2. Severity level (LOW/MEDIUM/HIGH/CRITICAL)
3. Recommended action (if any)

Keep the explanation concise and practical."""

        try:
            # Use subprocess to call ollama run command
            result = subprocess.run([
                'ollama', 'run', self.model, prompt
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                return f"Error getting AI explanation: {result.stderr}"
        except subprocess.TimeoutExpired:
            return "AI analysis timed out"
        except Exception as e:
            return f"Error: {e}"
    
    def analyze_pattern(self, events: List[Dict], pattern_name: str) -> str:
        """Analyze a series of related events"""
        if not self.available:
            return "Ollama not available for pattern analysis"
        
        event_summary = "\n".join([
            f"{event.get('timestamp', 'Unknown')}: {event.get('message', '')[:100]}"
            for event in events[-5:]  # Last 5 events
        ])
        
        prompt = f"""Analyze this sequence of related system events:

Pattern: {pattern_name}

Recent Events:
{event_summary}

Provide:
1. Root cause analysis
2. Impact assessment
3. Immediate actions needed
4. Prevention recommendations

Be specific and actionable."""

        try:
            result = subprocess.run([
                'ollama', 'run', self.model, prompt
            ], capture_output=True, text=True, timeout=45)
            
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                return f"Error in pattern analysis: {result.stderr}"
        except subprocess.TimeoutExpired:
            return "Pattern analysis timed out"
        except Exception as e:
            return f"Analysis error: {e}"

class RealTimeLogAnalyzer:
    """Main real-time log analyzer class"""
    
    def __init__(self, model: str = "codegemma:7b", verbose: bool = False):
        self.ollama = OllamaClient(model)
        self.verbose = verbose
        self.running = False
        self.patterns = self._initialize_patterns()
        self.event_buffer = deque(maxlen=1000)  # Keep last 1000 events
        self.pattern_counts = defaultdict(int)
        self.alerts_sent = set()  # Prevent duplicate alerts
        
        # Statistics
        self.start_time = None
        self.total_events = 0
        self.critical_events = 0
        
        # Signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        print(f"\n{Colors.YELLOW}Received signal {signum}, shutting down gracefully...{Colors.END}")
        self.running = False
    
    def _initialize_patterns(self) -> List[LogPattern]:
        """Initialize suspicious patterns to watch for"""
        return [
            LogPattern(
                "sudo_auth_failure",
                r"sudo.*authentication failure|sudo.*incorrect password",
                "HIGH",
                "Sudo authentication failures - potential security issue"
            ),
            LogPattern(
                "account_lockout",
                r"account.*locked|too many.*attempts|authentication.*temporarily",
                "CRITICAL",
                "Account lockout detected - security protection activated"
            ),
            LogPattern(
                "permission_change",
                r"chmod|chown|usermod|visudo|sudoers",
                "MEDIUM",
                "Permission or sudo configuration changes"
            ),
            LogPattern(
                "service_failure",
                r"failed|error|critical|emergency",
                "MEDIUM",
                "Service failures or critical errors"
            ),
            LogPattern(
                "network_issues",
                r"network.*down|connection.*failed|timeout",
                "MEDIUM",
                "Network connectivity issues"
            ),
            LogPattern(
                "disk_issues",
                r"disk.*full|no space|i/o error|filesystem.*error",
                "HIGH",
                "Disk or filesystem problems"
            ),
            LogPattern(
                "security_events",
                r"ssh.*failed|login.*failed|invalid.*user|security",
                "HIGH",
                "Security-related events"
            ),
            LogPattern(
                "package_updates",
                r"pacman.*upgrade|alpm.*transaction|package.*install",
                "LOW",
                "Package management activity"
            )
        ]
    
    def _colorize_severity(self, severity: str) -> str:
        """Colorize severity levels"""
        colors = {
            "CRITICAL": Colors.RED + Colors.BOLD,
            "HIGH": Colors.RED,
            "MEDIUM": Colors.YELLOW,
            "LOW": Colors.GREEN
        }
        return f"{colors.get(severity, Colors.WHITE)}{severity}{Colors.END}"
    
    def _parse_journal_entry(self, line: str) -> Optional[Dict]:
        """Parse a journalctl JSON entry"""
        try:
            entry = json.loads(line)
            return {
                'timestamp': datetime.fromtimestamp(int(entry.get('__REALTIME_TIMESTAMP', 0)) / 1000000),
                'hostname': entry.get('_HOSTNAME', 'unknown'),
                'unit': entry.get('_SYSTEMD_UNIT', entry.get('SYSLOG_IDENTIFIER', 'unknown')),
                'message': entry.get('MESSAGE', ''),
                'priority': int(entry.get('PRIORITY', 6)),
                'uid': entry.get('_UID'),
                'pid': entry.get('_PID'),
                'raw': entry
            }
        except (json.JSONDecodeError, ValueError, KeyError) as e:
            if self.verbose:
                print(f"{Colors.YELLOW}Failed to parse journal entry: {e}{Colors.END}")
            return None
    
    def _check_patterns(self, event: Dict) -> List[Tuple[LogPattern, str]]:
        """Check if an event matches any suspicious patterns"""
        matches = []
        message = event.get('message') or ''
        message = message.lower()
        
        if not message:  # Skip empty messages
            return matches
        
        for pattern in self.patterns:
            if pattern.regex.search(message):
                matches.append((pattern, event['message']))
                self.pattern_counts[pattern.name] += 1
        
        return matches
    
    def _format_event(self, event: Dict, highlight: bool = False) -> str:
        """Format an event for display"""
        timestamp = event['timestamp'].strftime('%H:%M:%S')
        unit = event['unit'][:15].ljust(15)
        message = event['message'][:80]
        
        if highlight:
            return f"{Colors.BOLD}{Colors.CYAN}{timestamp}{Colors.END} {Colors.BLUE}{unit}{Colors.END} {Colors.WHITE}{message}{Colors.END}"
        else:
            return f"{Colors.CYAN}{timestamp}{Colors.END} {Colors.BLUE}{unit}{Colors.END} {message}"
    
    def _send_alert(self, pattern: LogPattern, event: Dict, ai_explanation: str = ""):
        """Send alert for suspicious activity"""
        alert_key = f"{pattern.name}_{event['timestamp'].strftime('%Y%m%d_%H%M')}"
        
        # Prevent spam - only one alert per pattern per minute
        if alert_key in self.alerts_sent:
            return
        
        self.alerts_sent.add(alert_key)
        
        print(f"\n{Colors.RED}{'='*80}{Colors.END}")
        print(f"{Colors.RED}🚨 ALERT: {pattern.name.upper()}{Colors.END}")
        print(f"{Colors.BOLD}Severity:{Colors.END} {self._colorize_severity(pattern.severity)}")
        print(f"{Colors.BOLD}Time:{Colors.END} {event['timestamp']}")
        print(f"{Colors.BOLD}Unit:{Colors.END} {event['unit']}")
        print(f"{Colors.BOLD}Message:{Colors.END} {event['message']}")
        
        if ai_explanation:
            print(f"{Colors.BOLD}AI Analysis:{Colors.END}")
            print(f"{Colors.YELLOW}{ai_explanation}{Colors.END}")
        
        print(f"{Colors.RED}{'='*80}{Colors.END}\n")
        
        # Track critical events
        if pattern.severity == "CRITICAL":
            self.critical_events += 1
    
    def _get_related_events(self, target_event: Dict, time_window: int = 300) -> List[Dict]:
        """Get events related to a target event within a time window"""
        target_time = target_event['timestamp']
        start_time = target_time - timedelta(seconds=time_window)
        end_time = target_time + timedelta(seconds=time_window)
        
        related = []
        for event in self.event_buffer:
            if start_time <= event['timestamp'] <= end_time:
                # Check if events are related (same unit, user, or pattern)
                if (event['unit'] == target_event['unit'] or 
                    event.get('uid') == target_event.get('uid') or
                    any(pattern.regex.search((event.get('message') or '').lower()) 
                        for pattern in self.patterns if event.get('message'))):
                    related.append(event)
        
        return sorted(related, key=lambda x: x['timestamp'])
    
    def _print_status(self):
        """Print current analysis status"""
        if not self.start_time:
            return
        
        uptime = datetime.now() - self.start_time
        events_per_minute = self.total_events / max(uptime.total_seconds() / 60, 1)
        
        print(f"\n{Colors.MAGENTA}{'='*60}{Colors.END}")
        print(f"{Colors.BOLD}Evil Space Log Analyzer Status{Colors.END}")
        print(f"Uptime: {uptime}")
        print(f"Events processed: {self.total_events}")
        print(f"Critical alerts: {self.critical_events}")
        print(f"Events/minute: {events_per_minute:.1f}")
        print(f"Ollama model: {self.ollama.model} ({'available' if self.ollama.available else 'unavailable'})")
        
        if self.pattern_counts:
            print(f"\n{Colors.BOLD}Pattern Matches:{Colors.END}")
            for pattern, count in sorted(self.pattern_counts.items(), key=lambda x: x[1], reverse=True):
                if count > 0:
                    print(f"  {pattern}: {count}")
        
        print(f"{Colors.MAGENTA}{'='*60}{Colors.END}\n")
    
    def start_monitoring(self, show_all: bool = False, ai_analysis: bool = True):
        """Start real-time log monitoring"""
        print(f"{Colors.GREEN}🚀 Starting Evil Space Real-Time Log Analyzer{Colors.END}")
        print(f"Model: {self.ollama.model}")
        print(f"AI Analysis: {'Enabled' if ai_analysis and self.ollama.available else 'Disabled'}")
        print(f"Show all events: {show_all}")
        print(f"Press Ctrl+C to stop\n")
        
        self.running = True
        self.start_time = datetime.now()
        
        # Start journalctl process
        cmd = ['journalctl', '--follow', '--output=json', '--no-pager']
        
        try:
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            
            # Status update thread
            def status_updater():
                while self.running:
                    time.sleep(60)  # Update every minute
                    if self.running:
                        self._print_status()
            
            status_thread = threading.Thread(target=status_updater, daemon=True)
            status_thread.start()
            
            # Main monitoring loop
            for line in process.stdout:
                if not self.running:
                    break
                
                event = self._parse_journal_entry(line.strip())
                if not event:
                    continue
                
                self.total_events += 1
                self.event_buffer.append(event)
                
                # Check for suspicious patterns
                pattern_matches = self._check_patterns(event)
                
                # Display event if requested or if it matches patterns
                if show_all or pattern_matches:
                    print(self._format_event(event, bool(pattern_matches)))
                
                # Handle alerts for pattern matches
                for pattern, message in pattern_matches:
                    ai_explanation = ""
                    
                    # Get AI analysis for critical/high severity events
                    if ai_analysis and self.ollama.available and pattern.severity in ["CRITICAL", "HIGH"]:
                        # Get related events for context
                        related_events = self._get_related_events(event)
                        context = f"Related events in the last 5 minutes: {len(related_events)}"
                        ai_explanation = self.ollama.explain_log_entry(message, context)
                    
                    self._send_alert(pattern, event, ai_explanation)
        
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Monitoring stopped by user{Colors.END}")
        except Exception as e:
            print(f"\n{Colors.RED}Error during monitoring: {e}{Colors.END}")
        finally:
            self.running = False
            if 'process' in locals():
                process.terminate()
            
            self._print_status()
            print(f"{Colors.GREEN}Log analyzer stopped{Colors.END}")
    
    def investigate_timeframe(self, since: str, until: str = None, pattern: str = None):
        """Investigate logs in a specific timeframe"""
        print(f"{Colors.CYAN}🔍 Investigating logs from {since}{' to ' + until if until else ''}{Colors.END}")
        
        cmd = ['journalctl', '--output=json', '--since', since]
        if until:
            cmd.extend(['--until', until])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode != 0:
                print(f"{Colors.RED}Error running journalctl: {result.stderr}{Colors.END}")
                return
            
            events = []
            pattern_events = defaultdict(list)
            
            for line in result.stdout.strip().split('\n'):
                if not line:
                    continue
                
                event = self._parse_journal_entry(line)
                if not event:
                    continue
                
                events.append(event)
                
                # Check patterns
                matches = self._check_patterns(event)
                for match_pattern, message in matches:
                    if not pattern or pattern.lower() in match_pattern.name.lower():
                        pattern_events[match_pattern.name].append(event)
            
            print(f"Analyzed {len(events)} events")
            
            # Show pattern summary
            if pattern_events:
                print(f"\n{Colors.BOLD}Pattern Matches Found:{Colors.END}")
                for pattern_name, matched_events in pattern_events.items():
                    print(f"  {pattern_name}: {len(matched_events)} events")
                    
                    # Show AI analysis for significant patterns
                    if len(matched_events) >= 3 and self.ollama.available:
                        print(f"    {Colors.YELLOW}Getting AI analysis...{Colors.END}")
                        analysis = self.ollama.analyze_pattern(matched_events, pattern_name)
                        print(f"    {Colors.GREEN}AI Analysis:{Colors.END}")
                        for line in analysis.split('\n'):
                            if line.strip():
                                print(f"      {line}")
            else:
                print(f"{Colors.GREEN}No suspicious patterns found in the specified timeframe{Colors.END}")
        
        except subprocess.TimeoutExpired:
            print(f"{Colors.RED}Investigation timed out{Colors.END}")
        except Exception as e:
            import traceback
            print(f"{Colors.RED}Investigation error: {e}{Colors.END}")
            if self.verbose:
                print(f"{Colors.YELLOW}Traceback:{Colors.END}")
                traceback.print_exc()

def main():
    parser = argparse.ArgumentParser(description="Evil Space Real-Time Log Analyzer")
    parser.add_argument('--model', default='codegemma:7b', 
                       help='Ollama model to use (default: codegemma:7b)')
    parser.add_argument('--live', action='store_true', 
                       help='Start real-time monitoring')
    parser.add_argument('--investigate', 
                       help='Investigate specific timeframe (e.g., "1 hour ago")')
    parser.add_argument('--until', 
                       help='End time for investigation (e.g., "30 minutes ago")')
    parser.add_argument('--pattern', 
                       help='Focus on specific pattern during investigation')
    parser.add_argument('--show-all', action='store_true',
                       help='Show all events during live monitoring')
    parser.add_argument('--no-ai', action='store_true',
                       help='Disable AI analysis')
    parser.add_argument('--verbose', action='store_true',
                       help='Verbose output')
    
    args = parser.parse_args()
    
    analyzer = RealTimeLogAnalyzer(model=args.model, verbose=args.verbose)
    
    if args.live:
        analyzer.start_monitoring(show_all=args.show_all, ai_analysis=not args.no_ai)
    elif args.investigate:
        analyzer.investigate_timeframe(args.investigate, args.until, args.pattern)
    else:
        # Default: show recent suspicious activity
        print(f"{Colors.CYAN}No specific action requested. Investigating last hour for suspicious activity...{Colors.END}")
        analyzer.investigate_timeframe("1 hour ago")

if __name__ == "__main__":
    main()