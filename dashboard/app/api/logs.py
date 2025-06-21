from datetime import datetime
import re
import os
import subprocess
import glob
from pathlib import Path

def get_logs_info(dashboard):
    """Get information about log files from multiple sources"""
    logs_info = {
        'timestamp': datetime.now().isoformat(),
        'total_logs': 0,
        'recent_logs': [],
        'log_sources': {},
        'categories': {}
    }
    
    all_logs = []
    
    # 1. Dashboard logs (with rotation)
    dashboard_logs = _get_dashboard_logs(dashboard)
    all_logs.extend(dashboard_logs)
    logs_info['log_sources']['dashboard'] = len(dashboard_logs)
    
    # 2. System logs (readable ones)
    system_logs = _get_system_logs()
    all_logs.extend(system_logs)
    logs_info['log_sources']['system'] = len(system_logs)
    
    # 3. Journal logs (virtual entries)
    journal_logs = _get_journal_logs()
    all_logs.extend(journal_logs)
    logs_info['log_sources']['journal'] = len(journal_logs)
    
    # Sort all logs by modification time
    all_logs.sort(key=lambda x: x.get('modified_timestamp', 0), reverse=True)
    
    logs_info['total_logs'] = len(all_logs)
    logs_info['recent_logs'] = all_logs[:20]  # Top 20 most recent
    
    # Categorize logs
    categories = {}
    for log in all_logs:
        category = log.get('category', 'other')
        if category not in categories:
            categories[category] = 0
        categories[category] += 1
    
    logs_info['categories'] = categories
    return logs_info

def _get_dashboard_logs(dashboard):
    """Get dashboard logs and perform rotation"""
    logs = []
    
    if not dashboard.logs_path.exists():
        return logs
    
    # Perform log rotation first
    _rotate_dashboard_logs(dashboard.logs_path)
    
    # Get remaining logs
    log_files = list(dashboard.logs_path.glob('*.log'))
    
    for log_file in log_files:
        try:
            stat = log_file.stat()
            size_mb = stat.st_size / 1024 / 1024
            size_str = f"{size_mb:.1f} MB" if size_mb >= 1 else f"{stat.st_size} bytes"
            
            # Parse filename for better display
            display_name, category = _parse_log_filename(log_file.name)
            
            logs.append({
                'name': display_name,
                'filename': log_file.name,  # Keep original filename for API calls
                'path': str(log_file),
                'size': size_str,
                'size_bytes': stat.st_size,
                'modified': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S'),
                'modified_timestamp': stat.st_mtime,
                'lines': _count_lines(log_file),
                'category': category,
                'source': 'dashboard',
                'readable': True
            })
        except Exception:
            continue
    
    return logs

def _parse_log_filename(filename):
    """Parse log filename to create readable display name and extract category"""
    # Remove .log extension
    base_name = filename.replace('.log', '')
    
    # Common patterns for dashboard logs
    if '_' in base_name:
        parts = base_name.split('_')
        category = parts[0]
        
        # Try to parse timestamp if present
        if len(parts) >= 3:
            try:
                # Format: category_YYYYMMDD_HHMMSS
                date_part = parts[1]  # YYYYMMDD
                time_part = parts[2]  # HHMMSS
                
                # Parse date
                year = date_part[:4]
                month = date_part[4:6]
                day = date_part[6:8]
                
                # Parse time
                hour = time_part[:2]
                minute = time_part[2:4]
                second = time_part[4:6]
                
                # Create readable display name
                readable_date = f"{year}-{month}-{day} {hour}:{minute}:{second}"
                display_name = f"{category.title()} ({readable_date})"
                
                return display_name, category
                
            except (ValueError, IndexError):
                pass
    
    # Fallback for non-standard filenames
    if filename.startswith('dashboard_'):
        return f"Dashboard Log ({filename})", 'dashboard'
    elif filename.startswith('setup_'):
        return f"Setup Log ({filename})", 'setup'
    elif filename.startswith('backup_'):
        return f"Backup Log ({filename})", 'backup'
    else:
        # Extract category from first part before underscore
        category = filename.split('_')[0] if '_' in filename else 'other'
        return f"{category.title()} Log ({filename})", category

def _get_system_logs():
    """Get readable system logs"""
    logs = []
    system_log_configs = [
        ('/var/log/pacman.log', 'Package Manager (Pacman)', 'system'),
        ('/var/log/Xorg.0.log', 'X Server Display', 'system'),
        ('/var/log/boot.log', 'System Boot', 'system'),
        ('/var/log/dmesg', 'Kernel Messages', 'system'),
        ('/var/log/kern.log', 'Kernel Log', 'system'),
        ('/var/log/syslog', 'System Log', 'system'),
        ('/var/log/auth.log', 'Authentication', 'system'),
        ('/var/log/daemon.log', 'System Daemons', 'system'),
        ('/var/log/user.log', 'User Activities', 'system')
    ]
    
    for log_path, display_name, category in system_log_configs:
        try:
            if os.path.exists(log_path) and os.access(log_path, os.R_OK):
                stat = os.stat(log_path)
                size_mb = stat.st_size / 1024 / 1024
                size_str = f"{size_mb:.1f} MB" if size_mb >= 1 else f"{stat.st_size} bytes"
                
                # Add file size to display name for clarity
                full_display_name = f"{display_name} ({size_str})"
                
                logs.append({
                    'name': full_display_name,
                    'filename': os.path.basename(log_path),
                    'path': log_path,
                    'size': size_str,
                    'size_bytes': stat.st_size,
                    'modified': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S'),
                    'modified_timestamp': stat.st_mtime,
                    'lines': _count_lines(Path(log_path)),
                    'category': category,
                    'source': 'system',
                    'readable': True
                })
        except Exception:
            continue
    
    return logs

def _get_journal_logs():
    """Get systemd journal virtual log entries"""
    logs = []
    
    try:
        # Get list of available journal boots
        result = subprocess.run(['journalctl', '--list-boots', '--no-pager'], 
                              capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0:
            boots = []
            for line in result.stdout.strip().split('\n')[1:]:  # Skip header
                if line.strip():
                    parts = line.split()
                    if len(parts) >= 2:
                        boot_id = parts[1]
                        boots.append(boot_id)
            
            # Add current boot journal
            logs.append({
                'name': 'Current Boot Journal',
                'path': 'journal:current',
                'size': 'Dynamic',
                'size_bytes': 0,
                'modified': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'modified_timestamp': datetime.now().timestamp(),
                'lines': 'Dynamic',
                'category': 'journal',
                'source': 'journal',
                'readable': True
            })
            
            # Add recent boot journals (max 3)
            for i, boot_id in enumerate(boots[-3:]):
                logs.append({
                    'name': f'Boot Journal {boot_id[:8]}',
                    'path': f'journal:{boot_id}',
                    'size': 'Dynamic',
                    'size_bytes': 0,
                    'modified': 'Variable',
                    'modified_timestamp': datetime.now().timestamp() - (i * 3600),  # Approximate
                    'lines': 'Dynamic',
                    'category': 'journal',
                    'source': 'journal',
                    'readable': True
                })
                
    except Exception:
        # If journalctl is not available, add a placeholder
        logs.append({
            'name': 'System Journal (unavailable)',
            'path': 'journal:unavailable',
            'size': 'N/A',
            'size_bytes': 0,
            'modified': 'N/A',
            'modified_timestamp': 0,
            'lines': 0,
            'category': 'journal',
            'source': 'journal',
            'readable': False
        })
    
    return logs

def _rotate_dashboard_logs(logs_path):
    """Keep only the 5 most recent logs of each type"""
    try:
        # Group logs by category (prefix before first underscore)
        log_groups = {}
        
        for log_file in logs_path.glob('*.log'):
            category = log_file.name.split('_')[0] if '_' in log_file.name else 'other'
            if category not in log_groups:
                log_groups[category] = []
            log_groups[category].append(log_file)
        
        # For each category, keep only the 5 most recent
        for category, log_files in log_groups.items():
            if len(log_files) > 5:
                # Sort by modification time (newest first)
                log_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                
                # Remove oldest logs (keep first 5)
                for old_log in log_files[5:]:
                    try:
                        old_log.unlink()
                        print(f"Rotated old log: {old_log.name}")
                    except Exception as e:
                        print(f"Failed to remove {old_log.name}: {e}")
                        
    except Exception as e:
        print(f"Log rotation failed: {e}")

def get_log_content(dashboard, log_identifier, lines=100, filter_level=None, search_term=None):
    """Get content of a specific log file or journal"""
    log_content = {
        'timestamp': datetime.now().isoformat(),
        'log_name': log_identifier,
        'lines': [],
        'total_lines': 0,
        'filtered_lines': 0,
        'error': None
    }
    
    try:
        if log_identifier.startswith('journal:'):
            # Handle systemd journal
            log_content = _get_journal_content(log_identifier, lines, filter_level, search_term)
        else:
            # Handle regular log files
            log_content = _get_file_content(dashboard, log_identifier, lines, filter_level, search_term)
            
    except Exception as e:
        log_content['error'] = str(e)
    
    return log_content

def _get_journal_content(journal_identifier, lines=100, filter_level=None, search_term=None):
    """Get content from systemd journal"""
    log_content = {
        'timestamp': datetime.now().isoformat(),
        'log_name': journal_identifier,
        'lines': [],
        'total_lines': 0,
        'filtered_lines': 0,
        'error': None
    }
    
    try:
        # Build journalctl command
        cmd = ['journalctl', '--no-pager', '-n', str(lines)]
        
        if journal_identifier == 'journal:current':
            cmd.extend(['-b'])  # Current boot
        elif journal_identifier.startswith('journal:') and journal_identifier != 'journal:unavailable':
            boot_id = journal_identifier.split(':', 1)[1]
            if boot_id != 'current':
                cmd.extend(['-b', boot_id])
        
        # Add priority filter if specified
        if filter_level and filter_level.upper() != 'ALL':
            priority_map = {
                'ERROR': '0..3',    # emerg, alert, crit, err
                'WARNING': '4',     # warning
                'INFO': '6',        # info
                'DEBUG': '7'        # debug
            }
            if filter_level.upper() in priority_map:
                cmd.extend(['-p', priority_map[filter_level.upper()]])
        
        # Execute journalctl
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            all_lines = result.stdout.strip().split('\n')
            log_content['total_lines'] = len(all_lines)
            
            # Apply search filter
            filtered_lines = []
            for line in all_lines:
                if search_term and search_term.lower() not in line.lower():
                    continue
                filtered_lines.append(line)
            
            log_content['filtered_lines'] = len(filtered_lines)
            log_content['lines'] = filtered_lines
        else:
            log_content['error'] = f"journalctl failed: {result.stderr}"
            
    except subprocess.TimeoutExpired:
        log_content['error'] = "journalctl command timed out"
    except Exception as e:
        log_content['error'] = str(e)
    
    return log_content

def _get_file_content(dashboard, log_name, lines=100, filter_level=None, search_term=None):
    """Get content from a regular log file"""
    log_content = {
        'timestamp': datetime.now().isoformat(),
        'log_name': log_name,
        'lines': [],
        'total_lines': 0,
        'filtered_lines': 0,
        'error': None
    }
    
    # Determine log file path
    log_path = None
    
    if log_name.startswith('/'):
        # Absolute path (system log)
        log_path = Path(log_name)
    else:
        # Relative path (dashboard log)
        log_path = dashboard.logs_path / log_name
    
    if not log_path.exists():
        log_content['error'] = f"Log file '{log_name}' not found"
        return log_content
    
    try:
        # Read the file
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            all_lines = f.readlines()
        
        log_content['total_lines'] = len(all_lines)
        
        # Apply filters
        filtered_lines = []
        for line in all_lines:
            line_stripped = line.strip()
            
            # Skip empty lines
            if not line_stripped:
                continue
            
            # Filter by log level
            if filter_level and filter_level.upper() not in ['ALL', 'ANY']:
                line_upper = line_stripped.upper()
                level_found = False
                
                if filter_level.upper() == 'ERROR':
                    # Look for error indicators
                    if any(keyword in line_upper for keyword in ['ERROR', 'CRITICAL', 'FATAL', 'FAIL']):
                        level_found = True
                elif filter_level.upper() == 'WARNING':
                    # Look for warning indicators
                    if any(keyword in line_upper for keyword in ['WARNING', 'WARN', 'CAUTION']):
                        level_found = True
                elif filter_level.upper() == 'INFO':
                    # Look for info indicators
                    if any(keyword in line_upper for keyword in ['INFO', 'INFORMATION', 'NOTICE']):
                        level_found = True
                elif filter_level.upper() == 'DEBUG':
                    # Look for debug indicators
                    if any(keyword in line_upper for keyword in ['DEBUG', 'TRACE', 'VERBOSE']):
                        level_found = True
                
                # If no level found and we're filtering, skip this line
                if not level_found:
                    continue
            
            # Search filter
            if search_term:
                if search_term.lower() not in line_stripped.lower():
                    continue
            
            filtered_lines.append(line_stripped)
        
        log_content['filtered_lines'] = len(filtered_lines)
        log_content['lines'] = filtered_lines[-lines:] if lines > 0 else filtered_lines
        
    except Exception as e:
        log_content['error'] = str(e)
    
    return log_content

def get_log_stats(dashboard, log_identifier):
    """Get detailed statistics for a specific log file or journal"""
    stats = {
        'timestamp': datetime.now().isoformat(),
        'log_name': log_identifier,
        'size': '0 bytes',
        'total_lines': 0,
        'last_modified': 'Unknown',
        'log_levels': {},
        'error': None
    }
    
    try:
        if log_identifier.startswith('journal:'):
            stats = _get_journal_stats(log_identifier)
        else:
            stats = _get_file_stats(dashboard, log_identifier)
    except Exception as e:
        stats['error'] = str(e)
    
    return stats

def _get_journal_stats(journal_identifier):
    """Get statistics for systemd journal"""
    stats = {
        'timestamp': datetime.now().isoformat(),
        'log_name': journal_identifier,
        'size': 'Dynamic',
        'total_lines': 0,
        'last_modified': 'Real-time',
        'log_levels': {},
        'error': None
    }
    
    try:
        # Get journal statistics
        cmd = ['journalctl', '--no-pager', '-n', '1000']
        
        if journal_identifier == 'journal:current':
            cmd.extend(['-b'])
        elif journal_identifier.startswith('journal:') and journal_identifier != 'journal:unavailable':
            boot_id = journal_identifier.split(':', 1)[1]
            if boot_id != 'current':
                cmd.extend(['-b', boot_id])
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            stats['total_lines'] = len(lines)
            
            # Count log levels (approximate)
            log_levels = {'ERROR': 0, 'WARNING': 0, 'INFO': 0, 'DEBUG': 0, 'OTHER': 0}
            
            for line in lines:
                line_upper = line.upper()
                if 'ERROR' in line_upper or 'CRITICAL' in line_upper:
                    log_levels['ERROR'] += 1
                elif 'WARNING' in line_upper or 'WARN' in line_upper:
                    log_levels['WARNING'] += 1
                elif 'INFO' in line_upper:
                    log_levels['INFO'] += 1
                elif 'DEBUG' in line_upper:
                    log_levels['DEBUG'] += 1
                else:
                    log_levels['OTHER'] += 1
            
            stats['log_levels'] = log_levels
        else:
            stats['error'] = f"journalctl failed: {result.stderr}"
            
    except Exception as e:
        stats['error'] = str(e)
    
    return stats

def _get_file_stats(dashboard, log_name):
    """Get statistics for a regular log file"""
    stats = {
        'timestamp': datetime.now().isoformat(),
        'log_name': log_name,
        'size': '0 bytes',
        'total_lines': 0,
        'last_modified': 'Unknown',
        'log_levels': {},
        'error': None
    }
    
    # Determine log file path
    log_path = None
    
    if log_name.startswith('/'):
        # Absolute path (system log)
        log_path = Path(log_name)
    else:
        # Relative path (dashboard log)
        log_path = dashboard.logs_path / log_name
    
    if not log_path.exists():
        stats['error'] = f"Log file '{log_name}' not found"
        return stats
    
    try:
        # File info
        stat_info = log_path.stat()
        size_mb = stat_info.st_size / 1024 / 1024
        stats['size'] = f"{size_mb:.1f} MB" if size_mb >= 1 else f"{stat_info.st_size} bytes"
        stats['last_modified'] = datetime.fromtimestamp(stat_info.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
        
        # Read and analyze content
        log_levels = {'ERROR': 0, 'WARNING': 0, 'INFO': 0, 'DEBUG': 0, 'OTHER': 0}
        
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        stats['total_lines'] = len(lines)
        
        # Count log levels
        for line in lines:
            line_upper = line.upper()
            if 'ERROR' in line_upper:
                log_levels['ERROR'] += 1
            elif 'WARNING' in line_upper or 'WARN' in line_upper:
                log_levels['WARNING'] += 1
            elif 'INFO' in line_upper:
                log_levels['INFO'] += 1
            elif 'DEBUG' in line_upper:
                log_levels['DEBUG'] += 1
            else:
                log_levels['OTHER'] += 1
        
        stats['log_levels'] = log_levels
        
    except Exception as e:
        stats['error'] = str(e)
    
    return stats

def _count_lines(file_path):
    """Count lines in a file efficiently"""
    try:
        with open(file_path, 'rb') as f:
            return sum(1 for _ in f)
    except:
        return 0 