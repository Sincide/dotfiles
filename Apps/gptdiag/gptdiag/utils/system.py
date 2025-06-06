#!/usr/bin/env python3
"""
System Information Collector for GPTDiag

Collects comprehensive system metrics using psutil and system commands.
"""

import asyncio
import json
import subprocess
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any
import psutil


class SystemInfo:
    """Comprehensive system information collector."""
    
    def __init__(self):
        """Initialize system info collector."""
        self.boot_time = psutil.boot_time()
        
    async def get_async_info(self) -> Dict[str, Any]:
        """Get comprehensive system information asynchronously."""
        loop = asyncio.get_event_loop()
        
        # Gather basic metrics
        cpu_info = await loop.run_in_executor(None, self._get_cpu_info)
        memory_info = await loop.run_in_executor(None, self._get_memory_info)
        disk_info = await loop.run_in_executor(None, self._get_disk_info)
        processes = await loop.run_in_executor(None, self._get_processes)
        services = await loop.run_in_executor(None, self._get_systemd_services)
        
        return {
            "timestamp": datetime.now().isoformat(),
            "cpu": cpu_info,
            "memory": memory_info,
            "disk": disk_info,
            "processes": processes,
            "services": services,
            "uptime": self._get_uptime(),
            "load_avg": self._get_load_average()
        }
    
    def _get_cpu_info(self) -> Dict[str, Any]:
        """Get CPU information."""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            cpu_count = psutil.cpu_count()
            load_avg = psutil.getloadavg()
            
            return {
                "percent": round(cpu_percent, 1),
                "cores": cpu_count,
                "load_1min": round(load_avg[0], 2),
                "load_5min": round(load_avg[1], 2),
                "load_15min": round(load_avg[2], 2)
            }
        except Exception as e:
            return {"error": str(e)}
    
    def _get_memory_info(self) -> Dict[str, Any]:
        """Get memory information."""
        try:
            vmem = psutil.virtual_memory()
            swap = psutil.swap_memory()
            
            return {
                "total": round(vmem.total / (1024**3), 2),  # GB
                "available": round(vmem.available / (1024**3), 2),
                "used": round(vmem.used / (1024**3), 2),
                "percent": vmem.percent,
                "swap": {
                    "total": round(swap.total / (1024**3), 2),
                    "used": round(swap.used / (1024**3), 2),
                    "percent": swap.percent
                }
            }
        except Exception as e:
            return {"error": str(e)}
    
    def _get_disk_info(self) -> List[Dict[str, Any]]:
        """Get disk information."""
        try:
            disks = []
            partitions = psutil.disk_partitions()
            
            for partition in partitions:
                try:
                    if partition.fstype in ['tmpfs', 'devtmpfs', 'squashfs']:
                        continue
                    
                    usage = psutil.disk_usage(partition.mountpoint)
                    
                    disks.append({
                        "device": partition.device,
                        "mountpoint": partition.mountpoint,
                        "fstype": partition.fstype,
                        "total": round(usage.total / (1024**3), 2),  # GB
                        "used": round(usage.used / (1024**3), 2),
                        "free": round(usage.free / (1024**3), 2),
                        "percent": round((usage.used / usage.total) * 100, 1)
                    })
                    
                except (PermissionError, FileNotFoundError):
                    continue
            
            return disks
        except Exception as e:
            return [{"error": str(e)}]
    
    def _get_processes(self) -> List[Dict[str, Any]]:
        """Get top processes by CPU usage."""
        try:
            processes = []
            
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    pinfo = proc.info
                    if pinfo['cpu_percent'] > 0:  # Only include active processes
                        processes.append({
                            "pid": pinfo['pid'],
                            "name": pinfo['name'],
                            "cpu_percent": round(pinfo['cpu_percent'], 1),
                            "memory_percent": round(pinfo['memory_percent'], 1)
                        })
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            # Sort by CPU usage and return top 10
            processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
            return processes[:10]
            
        except Exception as e:
            return [{"error": str(e)}]
    
    def _get_systemd_services(self) -> List[Dict[str, Any]]:
        """Get systemd service status."""
        try:
            result = subprocess.run(
                ['systemctl', 'list-units', '--type=service', '--no-pager', '--failed'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            failed_services = []
            if result.returncode == 0:
                lines = result.stdout.split('\n')[1:]  # Skip header
                for line in lines:
                    if line.strip() and not line.startswith('●'):
                        parts = line.split(None, 4)
                        if len(parts) >= 4:
                            failed_services.append({
                                "name": parts[0],
                                "load": parts[1],
                                "active": parts[2],
                                "sub": parts[3],
                                "description": parts[4] if len(parts) > 4 else ""
                            })
            
            return failed_services
                
        except Exception as e:
            return [{"error": str(e)}]
    
    def _get_uptime(self) -> Dict[str, Any]:
        """Get system uptime."""
        try:
            uptime_seconds = time.time() - self.boot_time
            uptime_timedelta = timedelta(seconds=uptime_seconds)
            
            return {
                "seconds": int(uptime_seconds),
                "days": uptime_timedelta.days,
                "hours": uptime_timedelta.seconds // 3600,
                "human_readable": str(uptime_timedelta).split('.')[0]
            }
        except Exception as e:
            return {"error": str(e)}
    
    def _get_load_average(self) -> Dict[str, Any]:
        """Get system load average."""
        try:
            load1, load5, load15 = psutil.getloadavg()
            cpu_count = psutil.cpu_count()
            
            return {
                "1min": round(load1, 2),
                "5min": round(load5, 2), 
                "15min": round(load15, 2),
                "cpu_count": cpu_count
            }
        except Exception as e:
            return {"error": str(e)}
    
    def get_quick_summary(self) -> Dict[str, Any]:
        """Get quick system summary."""
        try:
            return {
                "cpu_percent": psutil.cpu_percent(interval=0.1),
                "memory_percent": psutil.virtual_memory().percent,
                "disk_percent": psutil.disk_usage('/').percent,
                "load_avg": psutil.getloadavg()[0],
                "process_count": len(psutil.pids()),
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": str(e)} 