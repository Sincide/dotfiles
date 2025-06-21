import re
from datetime import datetime

def get_themes_info(dashboard):
    """Get information about themes and wallpapers"""
    themes_info = {
        'timestamp': datetime.now().isoformat(),
        'current_theme': _get_current_theme(dashboard),
        'available_themes': _get_available_themes(dashboard),
        'wallpapers': _get_wallpapers(dashboard),
        'theme_mappings': _get_theme_mappings(dashboard)
    }
    
    return themes_info

def _get_current_theme(dashboard):
    """Detect current theme"""
    try:
        # Check GTK theme
        gtk_settings = dashboard.dotfiles_path / "gtk-3.0" / "settings.ini"
        if gtk_settings.exists():
            with open(gtk_settings, 'r') as f:
                content = f.read()
                theme_match = re.search(r'gtk-theme-name=(.+)', content)
                if theme_match:
                    return theme_match.group(1).strip()
    except:
        pass
    
    return "Unknown"

def _get_available_themes(dashboard):
    """Get list of available themes"""
    themes = []
    
    if dashboard.themes_path.exists():
        for theme_dir in dashboard.themes_path.iterdir():
            if theme_dir.is_dir() and theme_dir.name != 'cached':
                themes.append(theme_dir.name)
    
    return sorted(themes)

def _get_wallpapers(dashboard):
    """Get wallpaper categories and counts"""
    wallpapers = {}
    
    if dashboard.wallpapers_path.exists():
        for category_dir in dashboard.wallpapers_path.iterdir():
            if category_dir.is_dir():
                image_files = [f for f in category_dir.iterdir() 
                             if f.suffix.lower() in ['.jpg', '.jpeg', '.png', '.webp']]
                if image_files:
                    wallpapers[category_dir.name] = len(image_files)
    
    return wallpapers

def _get_theme_mappings(dashboard):
    """Get theme mapping configuration"""
    # Based on the dynamic theme switcher script
    return {
        "space": "Graphite-Dark",
        "nature": "Orchis-Green",
        "gaming": "Graphite-Dark", 
        "minimal": "Graphite-Light",
        "abstract": "Graphite-Dark",
        "dark": "Graphite-Dark"
    } 