import os
import subprocess
import re
from datetime import datetime, timedelta
import json

def get_system_info(dashboard):
    """Get current system information"""
    info = {
        'timestamp': datetime.now().isoformat(),
        'uptime': _get_uptime(),
        'load_average': _get_load_average(),
    }
    
    if dashboard.has_psutil:
        info.update({
            'cpu_usage': dashboard.psutil.cpu_percent(interval=1),
            'memory': dashboard.psutil.virtual_memory()._asdict(),
            'disk': dashboard.psutil.disk_usage('/')._asdict(),
            'processes': len(dashboard.psutil.pids())
        })
    else:
        # Fallback to basic system commands
        info.update(_get_basic_system_info(dashboard))
    
    return info

def get_gpu_info(dashboard):
    """Get GPU information from rocm-smi"""
    gpu_info = {
        'timestamp': datetime.now().isoformat(),
        'available': False,
        'name': 'N/A',
        'temperature': None,
        'usage': None,
        'vram_used': None,
        'vram_total': None,
        'vram_percent': None,
        'fan_speed': None,
        'power': None
    }

    try:
        # Get GPU metrics
        result = subprocess.run(['rocm-smi', '--showtemp', '--showuse', '--showmemuse', '--showfan', '--showpower', '--json'],
                              capture_output=True, text=True, timeout=5)

        if result.returncode == 0:
            data = json.loads(result.stdout)
            # Assume we are interested in the first card
            card_id = next(iter(data))
            card_data = data[card_id]

            gpu_info['available'] = True
            
            # Get GPU name separately
            try:
                name_result = subprocess.run(['rocm-smi', '--showproductname', '--json'],
                                           capture_output=True, text=True, timeout=5)
                if name_result.returncode == 0:
                    name_data = json.loads(name_result.stdout)
                    card_name_data = name_data[card_id]
                    gpu_info['name'] = card_name_data.get('Card Series', 'Unknown GPU')
            except:
                gpu_info['name'] = 'AMD GPU'

            # Temperature (using junction temp as it's typically the most relevant)
            temp_str = card_data.get('Temperature (Sensor junction) (C)', card_data.get('Temperature (Sensor edge) (C)', '0.0'))
            gpu_info['temperature'] = float(temp_str) if temp_str else 0.0

            # GPU Usage
            usage_str = card_data.get('GPU use (%)', '0')
            gpu_info['usage'] = int(usage_str) if usage_str else 0

            # VRAM - rocm-smi gives us percentage, we need to calculate MB
            vram_percent_str = card_data.get('GPU Memory Allocated (VRAM%)', '0')
            gpu_info['vram_percent'] = int(vram_percent_str) if vram_percent_str else 0
            
            # For VRAM total/used, we need to get it from a different command or estimate
            # For now, we'll show percentage and note that total/used need additional info
            gpu_info['vram_used'] = gpu_info['vram_percent']  # Just show percentage for now
            gpu_info['vram_total'] = 100  # Will show as percentage

            # Fan Speed
            fan_str = card_data.get('Fan speed (%)', '0')
            gpu_info['fan_speed'] = int(fan_str) if fan_str else 0
            
            # Power
            power_str = card_data.get('Average Graphics Package Power (W)', '0.0')
            gpu_info['power'] = float(power_str) if power_str else 0.0

    except (subprocess.TimeoutExpired, FileNotFoundError, json.JSONDecodeError, KeyError, StopIteration):
        # Handles rocm-smi not found, timeout, bad json, or empty json
        pass

    return gpu_info

def get_process_info(dashboard):
    """Get detailed process information"""
    process_info = {
        'timestamp': datetime.now().isoformat(),
        'total_processes': 0,
        'top_cpu_processes': [],
        'top_memory_processes': [],
        'process_summary': {
            'running': 0,
            'sleeping': 0,
            'zombie': 0,
            'stopped': 0
        }
    }
    
    if dashboard.has_psutil:
        try:
            processes = []
            status_count = {'running': 0, 'sleeping': 0, 'zombie': 0, 'stopped': 0}
            
            for proc in dashboard.psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'status', 'create_time', 'username']):
                try:
                    pinfo = proc.info
                    pinfo['cpu_percent'] = proc.cpu_percent()
                    pinfo['memory_mb'] = proc.memory_info().rss / 1024 / 1024  # Convert to MB
                    processes.append(pinfo)
                    
                    # Count status
                    status = pinfo.get('status', 'unknown').lower()
                    if status in status_count:
                        status_count[status] += 1
                    elif status in ['running', 'disk-sleep']:
                        status_count['running'] += 1
                    else:
                        status_count['sleeping'] += 1
                        
                except (dashboard.psutil.NoSuchProcess, dashboard.psutil.AccessDenied):
                    continue
            
            process_info['total_processes'] = len(processes)
            process_info['process_summary'] = status_count
            
            # Top 10 processes by CPU usage
            process_info['top_cpu_processes'] = sorted(
                processes, key=lambda x: x.get('cpu_percent', 0), reverse=True
            )[:10]
            
            # Top 10 processes by memory usage
            process_info['top_memory_processes'] = sorted(
                processes, key=lambda x: x.get('memory_percent', 0), reverse=True
            )[:10]
            
        except Exception as e:
            process_info['error'] = str(e)
    else:
        # Fallback without psutil
        try:
            result = subprocess.run(['ps', 'aux'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')[1:]  # Skip header
                process_info['total_processes'] = len(lines)
                process_info['top_cpu_processes'] = _parse_ps_output(lines, sort_by='cpu')[:10]
                process_info['top_memory_processes'] = _parse_ps_output(lines, sort_by='memory')[:10]
        except Exception as e:
            process_info['error'] = str(e)
    
    return process_info

def get_network_info(dashboard):
    """Get network interface information"""
    network_info = {
        'timestamp': datetime.now().isoformat(),
        'interfaces': {},
        'total_bytes_sent': 0,
        'total_bytes_recv': 0,
        'active_connections': 0
    }
    
    if dashboard.has_psutil:
        try:
            # Network interface statistics
            net_io = dashboard.psutil.net_io_counters(pernic=True)
            for interface, stats in net_io.items():
                if interface != 'lo':  # Skip loopback
                    network_info['interfaces'][interface] = {
                        'bytes_sent': stats.bytes_sent,
                        'bytes_recv': stats.bytes_recv,
                        'packets_sent': stats.packets_sent,
                        'packets_recv': stats.packets_recv,
                        'errors_in': stats.errin,
                        'errors_out': stats.errout,
                        'drops_in': stats.dropin,
                        'drops_out': stats.dropout
                    }
                    network_info['total_bytes_sent'] += stats.bytes_sent
                    network_info['total_bytes_recv'] += stats.bytes_recv
            
            # Active network connections
            connections = dashboard.psutil.net_connections()
            network_info['active_connections'] = len([c for c in connections if c.status == 'ESTABLISHED'])
            
            # Connection summary
            connection_summary = {}
            for conn in connections:
                status = conn.status or 'UNKNOWN'
                connection_summary[status] = connection_summary.get(status, 0) + 1
            network_info['connection_summary'] = connection_summary
            
        except Exception as e:
            network_info['error'] = str(e)
    else:
        # Fallback without psutil
        try:
            # Get interface stats from /proc/net/dev
            with open('/proc/net/dev', 'r') as f:
                lines = f.readlines()[2:]  # Skip header lines
                
            for line in lines:
                parts = line.split()
                interface = parts[0].rstrip(':')
                if interface != 'lo':  # Skip loopback
                    network_info['interfaces'][interface] = {
                        'bytes_recv': int(parts[1]),
                        'packets_recv': int(parts[2]),
                        'errors_in': int(parts[3]),
                        'drops_in': int(parts[4]),
                        'bytes_sent': int(parts[9]),
                        'packets_sent': int(parts[10]),
                        'errors_out': int(parts[11]),
                        'drops_out': int(parts[12])
                    }
                    network_info['total_bytes_sent'] += int(parts[9])
                    network_info['total_bytes_recv'] += int(parts[1])
                    
        except Exception as e:
            network_info['error'] = str(e)
    
    return network_info

# Helper methods
def _get_uptime():
    """Get system uptime"""
    try:
        with open('/proc/uptime', 'r') as f:
            uptime_seconds = float(f.readline().split()[0])
            uptime_delta = timedelta(seconds=uptime_seconds)
            return str(uptime_delta).split('.')[0]  # Remove microseconds
    except:
        return "Unknown"

def _get_load_average():
    """Get system load average"""
    try:
        return os.getloadavg()
    except:
        return None

def _get_basic_system_info(dashboard):
    """Get basic system info without psutil"""
    info = {}
    
    # CPU usage via /proc/stat
    try:
        with open('/proc/stat', 'r') as f:
            line = f.readline()
        
        parts = [int(p) for p in line.split()[1:]]
        idle_time = parts[3]
        total_time = sum(parts)
        
        if dashboard.prev_proc_stat:
            prev_idle, prev_total = dashboard.prev_proc_stat
            
            delta_idle = idle_time - prev_idle
            delta_total = total_time - prev_total
            
            if delta_total > 0:
                cpu_usage = 100.0 * (1.0 - (delta_idle / delta_total))
                info['cpu_usage'] = round(cpu_usage, 1)
        
        dashboard.prev_proc_stat = (idle_time, total_time)
    except Exception:
        info['cpu_usage'] = None # Failed to calculate
    
    try:
        # Memory info via /proc/meminfo
        with open('/proc/meminfo', 'r') as f:
            meminfo = {}
            for line in f:
                key, value = line.split(':')
                meminfo[key.strip()] = int(value.strip().split()[0]) * 1024  # Convert KB to bytes
            
            total = meminfo.get('MemTotal', 0)
            available = meminfo.get('MemAvailable', 0)
            used = total - available
            
            info['memory'] = {
                'total': total,
                'available': available,
                'used': used,
                'percent': (used / total * 100) if total > 0 else 0
            }
    except:
        pass
    
    return info 

def _parse_ps_output(lines, sort_by='cpu'):
    """Parse ps aux output into process list"""
    processes = []
    for line in lines:
        parts = line.split(None, 10)  # Split on whitespace, max 11 parts
        if len(parts) >= 11:
            try:
                processes.append({
                    'username': parts[0],
                    'pid': int(parts[1]),
                    'cpu_percent': float(parts[2]),
                    'memory_percent': float(parts[3]),
                    'name': parts[10].split()[0] if parts[10] else 'unknown',
                    'status': 'running'  # ps aux doesn't show detailed status
                })
            except (ValueError, IndexError):
                continue
    
    # Sort by requested field
    if sort_by == 'cpu':
        return sorted(processes, key=lambda x: x['cpu_percent'], reverse=True)
    elif sort_by == 'memory':
        return sorted(processes, key=lambda x: x['memory_percent'], reverse=True)
    else:
        return processes 