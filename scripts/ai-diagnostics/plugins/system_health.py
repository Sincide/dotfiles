"""
System Health Diagnostic Plugin

Comprehensive system health monitoring including:
- SystemD service status monitoring
- Resource usage analysis (CPU, memory, disk)
- Network connectivity tests
- Hardware health checks
- Process monitoring
- System load analysis
"""

import asyncio
import subprocess
import psutil
import socket
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple

from ..core.models import DiagnosticResult, DiagnosticIssue, Severity
from ..core.plugin_manager import DiagnosticPlugin, PluginExecutionContext


class SystemHealthPlugin(DiagnosticPlugin):
    """
    System Health diagnostic plugin for comprehensive system monitoring.
    
    Features:
    - SystemD service monitoring
    - Resource usage analysis  
    - Network connectivity testing
    - Hardware health assessment
    - Process and load monitoring
    - Storage and filesystem checks
    """
    
    metadata = {
        "name": "System Health Check",
        "version": "1.0.0", 
        "description": "Comprehensive system health and resource monitoring",
        "author": "AI Diagnostic System",
        "category": "system_health",
        "supports_fix": True,
        "execution_time_target": 30.0  # seconds
    }
    
    def __init__(self):
        super().__init__()
        
        # Critical services to monitor
        self.critical_services = [
            "ollama",           # AI service
            "NetworkManager",   # Network connectivity
            "systemd-resolved", # DNS resolution
            "dbus",            # Inter-process communication
        ]
        
        # Optional services (warnings, not errors)
        self.optional_services = [
            "bluetooth",
            "cups",
            "avahi-daemon"
        ]
        
        # Resource thresholds
        self.resource_thresholds = {
            "cpu_warning": 70.0,    # CPU % warning level
            "cpu_critical": 90.0,   # CPU % critical level
            "memory_warning": 80.0, # Memory % warning
            "memory_critical": 95.0, # Memory % critical
            "disk_warning": 85.0,   # Disk % warning
            "disk_critical": 95.0,  # Disk % critical
            "load_warning": 2.0,    # Load average warning
            "load_critical": 4.0,   # Load average critical
        }
        
        # Network connectivity tests
        self.connectivity_tests = [
            ("8.8.8.8", 53, "Google DNS"),
            ("1.1.1.1", 53, "Cloudflare DNS"),
            ("archlinux.org", 80, "Arch Linux")
        ]
    
    async def execute(self, context: PluginExecutionContext) -> DiagnosticResult:
        """Execute system health diagnostics."""
        self.logger.info("Starting System Health diagnostics")
        start_time = time.time()
        
        issues = []
        metadata = {
            "services": {},
            "resources": {},
            "network": {},
            "hardware": {},
            "processes": {},
            "timestamp": datetime.now().isoformat()
        }
        
        try:
            # 1. Service health monitoring
            service_status = await self._check_services()
            metadata["services"] = service_status
            service_issues = self._evaluate_service_health(service_status)
            issues.extend(service_issues)
            
            # 2. Resource usage analysis
            resources = await self._analyze_resources()
            metadata["resources"] = resources
            resource_issues = self._evaluate_resource_usage(resources)
            issues.extend(resource_issues)
            
            # 3. Network connectivity testing
            network_status = await self._test_network_connectivity()
            metadata["network"] = network_status
            network_issues = self._evaluate_network_health(network_status)
            issues.extend(network_issues)
            
            # 4. Hardware health assessment
            hardware_status = await self._check_hardware_health()
            metadata["hardware"] = hardware_status
            hardware_issues = self._evaluate_hardware_health(hardware_status)
            issues.extend(hardware_issues)
            
            # 5. Process monitoring
            process_info = await self._analyze_processes()
            metadata["processes"] = process_info
            process_issues = self._evaluate_process_health(process_info)
            issues.extend(process_issues)
            
            execution_time = (time.time() - start_time) * 1000
            
            return DiagnosticResult(
                plugin_name=self.metadata["name"],
                status="success",
                execution_time_ms=execution_time,
                issues=issues,
                metadata=metadata
            )
            
        except Exception as e:
            self.logger.error(f"System Health check failed: {e}")
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.HIGH,
                title="System Health Check Failed",
                description=f"Diagnostic execution error: {str(e)}",
                fix_suggestion="Check system logs and retry diagnostic"
            ))
            
            return DiagnosticResult(
                plugin_name=self.metadata["name"],
                status="error",
                execution_time_ms=(time.time() - start_time) * 1000,
                issues=issues,
                metadata=metadata
            )
    
    async def _check_services(self) -> Dict[str, Any]:
        """Check status of critical and optional services."""
        service_status = {
            "critical": {},
            "optional": {},
            "summary": {
                "total_checked": 0,
                "running": 0,
                "failed": 0,
                "disabled": 0
            }
        }
        
        # Check critical services
        for service in self.critical_services:
            status = await self._get_service_status(service)
            service_status["critical"][service] = status
            service_status["summary"]["total_checked"] += 1
            
            if status.get("active") == "active":
                service_status["summary"]["running"] += 1
            elif status.get("active") == "failed":
                service_status["summary"]["failed"] += 1
            elif status.get("enabled") == "disabled":
                service_status["summary"]["disabled"] += 1
        
        # Check optional services
        for service in self.optional_services:
            status = await self._get_service_status(service)
            service_status["optional"][service] = status
            service_status["summary"]["total_checked"] += 1
            
            if status.get("active") == "active":
                service_status["summary"]["running"] += 1
            elif status.get("active") == "failed":
                service_status["summary"]["failed"] += 1
            elif status.get("enabled") == "disabled":
                service_status["summary"]["disabled"] += 1
        
        return service_status
    
    async def _get_service_status(self, service_name: str) -> Dict[str, Any]:
        """Get detailed status for a specific service."""
        try:
            # Check if it's a user service first
            for scope in ["--user", ""]:
                cmd = ["systemctl"] + ([scope] if scope else []) + ["status", service_name]
                
                result = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                )
                stdout, stderr = await result.communicate()
                
                if result.returncode == 0 or b"Active:" in stdout:
                    # Parse systemctl output
                    output = stdout.decode()
                    
                    active_state = "unknown"
                    enabled_state = "unknown"
                    main_pid = None
                    memory_usage = None
                    
                    for line in output.split('\n'):
                        line = line.strip()
                        if line.startswith("Active:"):
                            active_state = line.split()[1]
                        elif line.startswith("Loaded:"):
                            if "enabled" in line:
                                enabled_state = "enabled"
                            elif "disabled" in line:
                                enabled_state = "disabled"
                        elif line.startswith("Main PID:"):
                            try:
                                main_pid = int(line.split()[2])
                            except (IndexError, ValueError):
                                pass
                        elif line.startswith("Memory:"):
                            try:
                                memory_usage = line.split()[1]
                            except IndexError:
                                pass
                    
                    return {
                        "active": active_state,
                        "enabled": enabled_state,
                        "scope": scope or "system",
                        "main_pid": main_pid,
                        "memory_usage": memory_usage,
                        "found": True
                    }
            
            return {
                "active": "not-found",
                "enabled": "not-found", 
                "scope": "none",
                "found": False
            }
            
        except Exception as e:
            return {
                "active": "error",
                "enabled": "error",
                "error": str(e),
                "found": False
            }
    
    async def _analyze_resources(self) -> Dict[str, Any]:
        """Analyze system resource usage."""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            cpu_count = psutil.cpu_count()
            cpu_freq = psutil.cpu_freq()
            
            # Load average
            load_avg = psutil.getloadavg()
            
            # Memory usage
            memory = psutil.virtual_memory()
            swap = psutil.swap_memory()
            
            # Disk usage
            disk_usage = {}
            for partition in psutil.disk_partitions():
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    disk_usage[partition.mountpoint] = {
                        "total_gb": usage.total / (1024**3),
                        "used_gb": usage.used / (1024**3),
                        "free_gb": usage.free / (1024**3),
                        "used_percent": (usage.used / usage.total) * 100,
                        "filesystem": partition.fstype
                    }
                except PermissionError:
                    continue
            
            # Boot time and uptime
            boot_time = datetime.fromtimestamp(psutil.boot_time())
            uptime = datetime.now() - boot_time
            
            return {
                "cpu": {
                    "usage_percent": cpu_percent,
                    "count": cpu_count,
                    "frequency_mhz": cpu_freq.current if cpu_freq else None,
                    "load_average": {
                        "1min": load_avg[0],
                        "5min": load_avg[1], 
                        "15min": load_avg[2]
                    }
                },
                "memory": {
                    "total_gb": memory.total / (1024**3),
                    "available_gb": memory.available / (1024**3),
                    "used_gb": memory.used / (1024**3),
                    "used_percent": memory.percent,
                    "cached_gb": memory.cached / (1024**3),
                    "buffers_gb": memory.buffers / (1024**3)
                },
                "swap": {
                    "total_gb": swap.total / (1024**3),
                    "used_gb": swap.used / (1024**3),
                    "used_percent": swap.percent
                },
                "disk": disk_usage,
                "system": {
                    "boot_time": boot_time.isoformat(),
                    "uptime_hours": uptime.total_seconds() / 3600,
                    "uptime_days": uptime.days
                }
            }
            
        except Exception as e:
            self.logger.error(f"Resource analysis failed: {e}")
            return {"error": str(e)}
    
    async def _test_network_connectivity(self) -> Dict[str, Any]:
        """Test network connectivity to various endpoints."""
        connectivity_results = {
            "tests": [],
            "summary": {
                "total_tests": len(self.connectivity_tests),
                "successful": 0,
                "failed": 0,
                "avg_response_time_ms": 0
            }
        }
        
        response_times = []
        
        for host, port, description in self.connectivity_tests:
            result = await self._test_connection(host, port, description)
            connectivity_results["tests"].append(result)
            
            if result["success"]:
                connectivity_results["summary"]["successful"] += 1
                response_times.append(result["response_time_ms"])
            else:
                connectivity_results["summary"]["failed"] += 1
        
        if response_times:
            connectivity_results["summary"]["avg_response_time_ms"] = sum(response_times) / len(response_times)
        
        # Test DNS resolution
        dns_test = await self._test_dns_resolution()
        connectivity_results["dns"] = dns_test
        
        return connectivity_results
    
    async def _test_connection(self, host: str, port: int, description: str) -> Dict[str, Any]:
        """Test connection to a specific host:port."""
        try:
            start_time = time.time()
            
            # Create socket connection
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5.0)  # 5 second timeout
            
            result = sock.connect_ex((host, port))
            response_time = (time.time() - start_time) * 1000
            
            sock.close()
            
            return {
                "host": host,
                "port": port,
                "description": description,
                "success": result == 0,
                "response_time_ms": response_time,
                "error": None if result == 0 else f"Connection failed (code: {result})"
            }
            
        except Exception as e:
            return {
                "host": host,
                "port": port,
                "description": description,
                "success": False,
                "response_time_ms": 0,
                "error": str(e)
            }
    
    async def _test_dns_resolution(self) -> Dict[str, Any]:
        """Test DNS resolution functionality."""
        test_domains = ["google.com", "archlinux.org", "github.com"]
        
        dns_results = {
            "tests": [],
            "working": 0,
            "failed": 0
        }
        
        for domain in test_domains:
            try:
                start_time = time.time()
                addr_info = socket.getaddrinfo(domain, None)
                response_time = (time.time() - start_time) * 1000
                
                dns_results["tests"].append({
                    "domain": domain,
                    "success": True,
                    "response_time_ms": response_time,
                    "resolved_ips": [info[4][0] for info in addr_info[:3]]  # First 3 IPs
                })
                dns_results["working"] += 1
                
            except Exception as e:
                dns_results["tests"].append({
                    "domain": domain,
                    "success": False,
                    "error": str(e)
                })
                dns_results["failed"] += 1
        
        return dns_results
    
    async def _check_hardware_health(self) -> Dict[str, Any]:
        """Check hardware health indicators."""
        hardware_info = {
            "temperatures": {},
            "disk_health": {},
            "battery": {},
            "sensors_available": False
        }
        
        try:
            # Temperature sensors
            if hasattr(psutil, 'sensors_temperatures'):
                temps = psutil.sensors_temperatures()
                if temps:
                    hardware_info["sensors_available"] = True
                    for name, entries in temps.items():
                        for entry in entries:
                            sensor_name = f"{name}_{entry.label}" if entry.label else name
                            hardware_info["temperatures"][sensor_name] = {
                                "current": entry.current,
                                "high": entry.high,
                                "critical": entry.critical
                            }
            
            # Battery information
            if hasattr(psutil, 'sensors_battery'):
                battery = psutil.sensors_battery()
                if battery:
                    hardware_info["battery"] = {
                        "percent": battery.percent,
                        "plugged_in": battery.power_plugged,
                        "time_left_hours": battery.secsleft / 3600 if battery.secsleft != psutil.POWER_TIME_UNLIMITED else None
                    }
            
            # Disk health (basic checks)
            for disk in psutil.disk_partitions():
                if disk.device.startswith('/dev/'):
                    try:
                        disk_io = psutil.disk_io_counters(perdisk=True).get(disk.device.split('/')[-1])
                        if disk_io:
                            hardware_info["disk_health"][disk.device] = {
                                "read_count": disk_io.read_count,
                                "write_count": disk_io.write_count,
                                "read_bytes": disk_io.read_bytes,
                                "write_bytes": disk_io.write_bytes,
                                "read_time_ms": disk_io.read_time,
                                "write_time_ms": disk_io.write_time
                            }
                    except Exception:
                        continue
        
        except Exception as e:
            hardware_info["error"] = str(e)
        
        return hardware_info
    
    async def _analyze_processes(self) -> Dict[str, Any]:
        """Analyze running processes for potential issues."""
        process_info = {
            "total_processes": 0,
            "high_cpu_processes": [],
            "high_memory_processes": [],
            "zombie_processes": [],
            "process_summary": {}
        }
        
        try:
            all_processes = []
            
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'status', 'create_time']):
                try:
                    pinfo = proc.info
                    all_processes.append(pinfo)
                    process_info["total_processes"] += 1
                    
                    # Check for high CPU usage (>20%)
                    if pinfo['cpu_percent'] > 20:
                        process_info["high_cpu_processes"].append({
                            "pid": pinfo['pid'],
                            "name": pinfo['name'],
                            "cpu_percent": pinfo['cpu_percent']
                        })
                    
                    # Check for high memory usage (>10%)
                    if pinfo['memory_percent'] > 10:
                        process_info["high_memory_processes"].append({
                            "pid": pinfo['pid'],
                            "name": pinfo['name'],
                            "memory_percent": pinfo['memory_percent']
                        })
                    
                    # Check for zombie processes
                    if pinfo['status'] == psutil.STATUS_ZOMBIE:
                        process_info["zombie_processes"].append({
                            "pid": pinfo['pid'],
                            "name": pinfo['name']
                        })
                
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            # Process summary by status
            status_counts = {}
            for proc in all_processes:
                status = proc.get('status', 'unknown')
                status_counts[status] = status_counts.get(status, 0) + 1
            
            process_info["process_summary"] = status_counts
            
        except Exception as e:
            process_info["error"] = str(e)
        
        return process_info
    
    def _evaluate_service_health(self, service_status: Dict[str, Any]) -> List[DiagnosticIssue]:
        """Evaluate service health and generate issues."""
        issues = []
        
        # Check critical services
        for service, status in service_status.get("critical", {}).items():
            if not status.get("found", False):
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.MEDIUM,
                    title=f"Service Not Found: {service}",
                    description=f"Critical service {service} not found on system",
                    fix_suggestion=f"Install package providing {service} service"
                ))
            elif status.get("active") != "active":
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.HIGH,
                    title=f"Critical Service Down: {service}",
                    description=f"Service {service} is {status.get('active', 'unknown')}",
                    fix_suggestion=f"Start service: systemctl {status.get('scope', '--user')} start {service}".replace("system ", "")
                ))
        
        # Check optional services (warnings only)
        for service, status in service_status.get("optional", {}).items():
            if status.get("found", False) and status.get("active") == "failed":
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.LOW,
                    title=f"Optional Service Failed: {service}",
                    description=f"Non-critical service {service} has failed",
                    fix_suggestion=f"Check service logs: journalctl -u {service}"
                ))
        
        return issues
    
    def _evaluate_resource_usage(self, resources: Dict[str, Any]) -> List[DiagnosticIssue]:
        """Evaluate resource usage and generate issues."""
        issues = []
        
        if "error" in resources:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="Resource Analysis Failed",
                description=f"Could not analyze system resources: {resources['error']}",
                fix_suggestion="Check system permissions and psutil installation"
            ))
            return issues
        
        # CPU usage checks
        cpu = resources.get("cpu", {})
        cpu_usage = cpu.get("usage_percent", 0)
        
        if cpu_usage >= self.resource_thresholds["cpu_critical"]:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.HIGH,
                title="Critical CPU Usage",
                description=f"CPU usage at {cpu_usage:.1f}% (critical threshold: {self.resource_thresholds['cpu_critical']}%)",
                fix_suggestion="Identify and reduce high CPU processes"
            ))
        elif cpu_usage >= self.resource_thresholds["cpu_warning"]:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="High CPU Usage",
                description=f"CPU usage at {cpu_usage:.1f}% (warning threshold: {self.resource_thresholds['cpu_warning']}%)",
                fix_suggestion="Monitor CPU usage and consider reducing system load"
            ))
        
        # Memory usage checks
        memory = resources.get("memory", {})
        memory_usage = memory.get("used_percent", 0)
        
        if memory_usage >= self.resource_thresholds["memory_critical"]:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.HIGH,
                title="Critical Memory Usage",
                description=f"Memory usage at {memory_usage:.1f}% (critical threshold: {self.resource_thresholds['memory_critical']}%)",
                fix_suggestion="Free memory by closing applications or add more RAM"
            ))
        elif memory_usage >= self.resource_thresholds["memory_warning"]:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="High Memory Usage",
                description=f"Memory usage at {memory_usage:.1f}% (warning threshold: {self.resource_thresholds['memory_warning']}%)",
                fix_suggestion="Monitor memory usage and consider optimizing applications"
            ))
        
        # Disk usage checks
        for mountpoint, disk_info in resources.get("disk", {}).items():
            disk_usage = disk_info.get("used_percent", 0)
            
            if disk_usage >= self.resource_thresholds["disk_critical"]:
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.HIGH,
                    title=f"Critical Disk Usage: {mountpoint}",
                    description=f"Disk usage at {disk_usage:.1f}% on {mountpoint}",
                    fix_suggestion=f"Free up space on {mountpoint} filesystem"
                ))
            elif disk_usage >= self.resource_thresholds["disk_warning"]:
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.MEDIUM,
                    title=f"High Disk Usage: {mountpoint}",
                    description=f"Disk usage at {disk_usage:.1f}% on {mountpoint}",
                    fix_suggestion=f"Consider cleaning up files on {mountpoint}"
                ))
        
        # Load average checks
        load_avg = cpu.get("load_average", {})
        load_1min = load_avg.get("1min", 0)
        
        if load_1min >= self.resource_thresholds["load_critical"]:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.HIGH,
                title="High System Load",
                description=f"1-minute load average: {load_1min:.2f} (critical threshold: {self.resource_thresholds['load_critical']})",
                fix_suggestion="Reduce system load by stopping unnecessary processes"
            ))
        elif load_1min >= self.resource_thresholds["load_warning"]:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="Elevated System Load",
                description=f"1-minute load average: {load_1min:.2f} (warning threshold: {self.resource_thresholds['load_warning']})",
                fix_suggestion="Monitor system load and optimize running processes"
            ))
        
        return issues
    
    def _evaluate_network_health(self, network_status: Dict[str, Any]) -> List[DiagnosticIssue]:
        """Evaluate network connectivity and generate issues."""
        issues = []
        
        summary = network_status.get("summary", {})
        failed_tests = summary.get("failed", 0)
        total_tests = summary.get("total_tests", 0)
        
        if failed_tests == total_tests and total_tests > 0:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.HIGH,
                title="Complete Network Connectivity Failure",
                description="All network connectivity tests failed",
                fix_suggestion="Check network configuration and internet connection"
            ))
        elif failed_tests > 0:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="Partial Network Connectivity Issues",
                description=f"{failed_tests}/{total_tests} connectivity tests failed",
                fix_suggestion="Check specific failed connections and network configuration"
            ))
        
        # DNS resolution issues
        dns = network_status.get("dns", {})
        dns_failed = dns.get("failed", 0)
        dns_total = len(dns.get("tests", []))
        
        if dns_failed == dns_total and dns_total > 0:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.HIGH,
                title="DNS Resolution Failure",
                description="All DNS resolution tests failed",
                fix_suggestion="Check DNS configuration: /etc/resolv.conf"
            ))
        elif dns_failed > 0:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="Partial DNS Resolution Issues",
                description=f"{dns_failed}/{dns_total} DNS resolution tests failed",
                fix_suggestion="Check DNS servers and resolution configuration"
            ))
        
        return issues
    
    def _evaluate_hardware_health(self, hardware_status: Dict[str, Any]) -> List[DiagnosticIssue]:
        """Evaluate hardware health and generate issues."""
        issues = []
        
        # Temperature checks
        temperatures = hardware_status.get("temperatures", {})
        for sensor, temp_info in temperatures.items():
            current_temp = temp_info.get("current", 0)
            critical_temp = temp_info.get("critical")
            high_temp = temp_info.get("high")
            
            if critical_temp and current_temp >= critical_temp:
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.HIGH,
                    title=f"Critical Temperature: {sensor}",
                    description=f"Temperature {current_temp}°C exceeds critical threshold {critical_temp}°C",
                    fix_suggestion="Check cooling system and reduce system load"
                ))
            elif high_temp and current_temp >= high_temp:
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.MEDIUM,
                    title=f"High Temperature: {sensor}",
                    description=f"Temperature {current_temp}°C exceeds high threshold {high_temp}°C",
                    fix_suggestion="Monitor temperature and ensure adequate cooling"
                ))
        
        # Battery checks
        battery = hardware_status.get("battery", {})
        if battery:
            battery_percent = battery.get("percent", 100)
            plugged_in = battery.get("plugged_in", True)
            
            if battery_percent < 10 and not plugged_in:
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.HIGH,
                    title="Critical Battery Level",
                    description=f"Battery at {battery_percent}% and not charging",
                    fix_suggestion="Connect power adapter immediately"
                ))
            elif battery_percent < 20 and not plugged_in:
                issues.append(DiagnosticIssue(
                    category="system_health",
                    severity=Severity.MEDIUM,
                    title="Low Battery Level",
                    description=f"Battery at {battery_percent}% and not charging",
                    fix_suggestion="Consider connecting power adapter"
                ))
        
        return issues
    
    def _evaluate_process_health(self, process_info: Dict[str, Any]) -> List[DiagnosticIssue]:
        """Evaluate process health and generate issues."""
        issues = []
        
        # Zombie processes
        zombie_count = len(process_info.get("zombie_processes", []))
        if zombie_count > 0:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title=f"Zombie Processes Detected",
                description=f"{zombie_count} zombie processes found",
                fix_suggestion="Restart parent processes or reboot system if persistent"
            ))
        
        # High resource usage processes
        high_cpu_count = len(process_info.get("high_cpu_processes", []))
        if high_cpu_count > 3:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="Multiple High CPU Processes",
                description=f"{high_cpu_count} processes using >20% CPU",
                fix_suggestion="Review and optimize high CPU usage processes"
            ))
        
        high_memory_count = len(process_info.get("high_memory_processes", []))
        if high_memory_count > 2:
            issues.append(DiagnosticIssue(
                category="system_health",
                severity=Severity.MEDIUM,
                title="Multiple High Memory Processes",
                description=f"{high_memory_count} processes using >10% memory",
                fix_suggestion="Review and optimize high memory usage processes"
            ))
        
        return issues
    
    async def can_fix(self, issue: DiagnosticIssue) -> bool:
        """Check if this plugin can fix the given issue."""
        fixable_issues = [
            "Critical Service Down",
            "Optional Service Failed"
        ]
        return any(fixable in issue.title for fixable in fixable_issues) and issue.category == "system_health"
    
    async def apply_fix(self, issue: DiagnosticIssue) -> bool:
        """Apply fix for the given issue."""
        try:
            if "Service Down" in issue.title or "Service Failed" in issue.title:
                # Extract service name from title
                service_name = issue.title.split(": ")[-1]
                return await self._fix_service(service_name, issue.fix_suggestion)
            
            return False
            
        except Exception as e:
            self.logger.error(f"Fix application failed: {e}")
            return False
    
    async def _fix_service(self, service_name: str, fix_suggestion: str) -> bool:
        """Fix a failed service."""
        try:
            # Extract systemctl command from fix suggestion
            if "systemctl" in fix_suggestion:
                # Parse the command from fix_suggestion
                cmd_parts = fix_suggestion.split("systemctl")[1].strip().split()
                
                # Build systemctl command
                cmd = ["systemctl"] + cmd_parts
                
                result = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                )
                stdout, stderr = await result.communicate()
                
                if result.returncode == 0:
                    self.logger.info(f"Successfully started service: {service_name}")
                    return True
                else:
                    self.logger.error(f"Failed to start service {service_name}: {stderr.decode()}")
                    return False
            
            return False
            
        except Exception as e:
            self.logger.error(f"Service fix failed for {service_name}: {e}")
            return False 