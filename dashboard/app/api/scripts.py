from datetime import datetime

def get_scripts_info(dashboard):
    """Get information about available scripts"""
    scripts_info = {
        'timestamp': datetime.now().isoformat(),
        'categories': {},
        'total_scripts': 0,
        'recent_executions': []
    }
    
    if not dashboard.scripts_path.exists():
        return scripts_info
    
    # Scan script directories
    for category_path in dashboard.scripts_path.iterdir():
        if category_path.is_dir() and category_path.name != 'setup':  # Exclude setup scripts
            scripts = []
            for script_file in category_path.glob('*'):
                if script_file.is_file() and (script_file.suffix in ['.sh', '.fish'] or script_file.stat().st_mode & 0o111):
                    scripts.append({
                        'name': script_file.name,
                        'path': str(script_file.relative_to(dashboard.dotfiles_path)),
                        'size': script_file.stat().st_size,
                        'executable': bool(script_file.stat().st_mode & 0o111)
                    })
            
            if scripts:
                scripts_info['categories'][category_path.name] = len(scripts)
                scripts_info['total_scripts'] += len(scripts)
    
    return scripts_info 