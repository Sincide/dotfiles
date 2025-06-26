#!/usr/bin/env python3

import os
import subprocess
import glob
from pathlib import Path
from typing import List, Dict

from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical, Container
from textual.widgets import Input, ListView, ListItem, Label, Static
from textual.coordinate import Coordinate
from textual.geometry import Size
from textual.binding import Binding

from theme import get_textual_theme

WALLPAPER_DIR = "/home/martin/dotfiles/assets/wallpapers"

class WallpaperPreview(Static):
    def __init__(self, image_path: str, **kwargs):
        super().__init__(**kwargs)
        self.image_path = image_path
        self.image_displayed = False
    
    def on_mount(self):
        if not self.image_displayed:
            self.display_image()
    
    def display_image(self):
        try:
            # Use kitty's icat to display image
            result = subprocess.run([
                "kitten", "icat", 
                "--align", "left",
                "--place", "30x15@0x0",
                "--transfer-mode", "memory",
                self.image_path
            ], capture_output=True, text=True)
            self.image_displayed = True
        except Exception as e:
            self.update(f"Preview unavailable\n{Path(self.image_path).name}")

class WallpaperList(ListView):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.wallpapers = self.get_wallpapers()
    
    def on_mount(self):
        self.populate_wallpapers()
    
    def get_wallpapers(self) -> List[Dict[str, str]]:
        wallpapers = []
        for root, dirs, files in os.walk(WALLPAPER_DIR):
            for file in files:
                if file.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                    full_path = os.path.join(root, file)
                    category = os.path.basename(root)
                    wallpapers.append({
                        'name': file,
                        'path': full_path,
                        'category': category
                    })
        return sorted(wallpapers, key=lambda x: (x['category'], x['name']))
    
    def populate_wallpapers(self):
        for wallpaper in self.wallpapers:
            item = ListItem(Label(f"[bold]{wallpaper['category']}[/bold] • {wallpaper['name']}"))
            item.wallpaper = wallpaper
            self.append(item)

class AppList(ListView):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.apps = self.get_desktop_apps()
    
    def on_mount(self):
        self.populate_apps()
    
    def get_desktop_apps(self) -> List[Dict[str, str]]:
        apps = []
        desktop_dirs = [
            "/usr/share/applications",
            "/usr/local/share/applications",
            os.path.expanduser("~/.local/share/applications")
        ]
        
        for desktop_dir in desktop_dirs:
            if os.path.exists(desktop_dir):
                for file in glob.glob(f"{desktop_dir}/*.desktop"):
                    try:
                        with open(file, 'r') as f:
                            content = f.read()
                            if 'NoDisplay=true' in content or 'Hidden=true' in content:
                                continue
                            
                            name = ""
                            exec_cmd = ""
                            for line in content.split('\n'):
                                if line.startswith('Name=') and not name:
                                    name = line.split('=', 1)[1]
                                elif line.startswith('Exec='):
                                    exec_cmd = line.split('=', 1)[1]
                            
                            if name and exec_cmd:
                                apps.append({'name': name, 'exec': exec_cmd, 'file': file})
                    except Exception:
                        continue
        
        return sorted(apps, key=lambda x: x['name'].lower())
    
    def populate_apps(self):
        for app in self.apps:
            self.append(ListItem(Label(app['name'])))

class LauncherApp(App):
    def __init__(self):
        super().__init__()
        self.current_preview = None
        self.focused_panel = "wallpaper"
        
        # Apply dynamic theme from kitty config
        theme = get_textual_theme()
        self.CSS = f"""
        Screen {{
            background: {theme['background']};
        }}
        
        #main_container {{
            width: 120;
            height: 40;
            border: thick {theme['primary']};
            background: {theme['surface']};
            margin: 1;
        }}
        
        #wallpaper_panel {{
            width: 60;
            border-right: solid {theme['primary']};
            background: {theme['surface']};
        }}
        
        #app_panel {{
            width: 60;
            background: {theme['surface']};
        }}
        
        #preview_area {{
            height: 20;
            border-bottom: solid {theme['primary']};
            background: {theme['panel']};
        }}
        
        #wallpaper_list {{
            height: 18;
            background: {theme['surface']};
        }}
        
        #search_input {{
            margin: 1;
            background: {theme['primary']};
            color: {theme['background']};
        }}
        
        #app_list {{
            height: 36;
            background: {theme['surface']};
        }}
        
        ListView {{
            scrollbar-size: 1 1;
            scrollbar-color: {theme['primary']};
            scrollbar-color-hover: {theme['accent']};
        }}
        
        ListItem {{
            padding: 0 1;
            color: {theme['text']};
        }}
        
        ListItem:hover {{
            background: {theme['primary']} 30%;
        }}
        
        ListItem.-highlight {{
            background: {theme['primary']};
            color: {theme['background']};
        }}
        
        Static {{
            color: {theme['text']};
        }}
        
        #wallpaper_title, #app_title {{
            text-align: center;
            text-style: bold;
            background: {theme['primary']};
            color: {theme['background']};
            height: 1;
            margin-bottom: 1;
        }}
        """
    
    BINDINGS = [
        Binding("escape", "quit", "Quit"),
        Binding("enter", "select", "Select"),
        Binding("tab", "switch_panel", "Switch Panel"),
    ]
    
    def compose(self) -> ComposeResult:
        with Container(id="main_container"):
            with Horizontal():
                with Vertical(id="wallpaper_panel"):
                    yield Static("🌌 Wallpapers", id="wallpaper_title")
                    yield WallpaperPreview("", id="preview_area")
                    yield WallpaperList(id="wallpaper_list")
                
                with Vertical(id="app_panel"):
                    yield Static("🚀 Applications", id="app_title")
                    yield Input(placeholder="Search apps...", id="search_input")
                    yield AppList(id="app_list")
    
    def on_mount(self):
        self.center_window()
        wallpaper_list = self.query_one("#wallpaper_list", WallpaperList)
        wallpaper_list.focus()
    
    def center_window(self):
        # Kitty handles centering with placement_strategy=center
        pass
    
    def on_list_view_selected(self, event):
        if event.list_view.id == "wallpaper_list":
            wallpaper = event.item.wallpaper
            # Update preview
            preview = self.query_one("#preview_area", WallpaperPreview)
            preview.image_path = wallpaper['path']
            preview.display_image()
            
        elif event.list_view.id == "app_list":
            app_list = self.query_one("#app_list", AppList)
            app = app_list.apps[event.list_view.index]
            # Launch app and exit
            subprocess.Popen(app['exec'], shell=True)
            self.exit()
    
    def action_select(self):
        if self.focused_panel == "wallpaper":
            wallpaper_list = self.query_one("#wallpaper_list", WallpaperList)
            if wallpaper_list.highlighted_child:
                wallpaper = wallpaper_list.highlighted_child.wallpaper
                # Set wallpaper with swww
                subprocess.run(["swww", "img", wallpaper['path']])
                self.exit()
        else:
            app_list = self.query_one("#app_list", AppList)
            if app_list.highlighted_child and app_list.index is not None:
                app = app_list.apps[app_list.index]
                subprocess.Popen(app['exec'], shell=True)
                self.exit()
    
    def action_switch_panel(self):
        if self.focused_panel == "wallpaper":
            self.focused_panel = "app"
            self.query_one("#app_list").focus()
        else:
            self.focused_panel = "wallpaper"
            self.query_one("#wallpaper_list").focus()
    
    def on_input_changed(self, event):
        if event.input.id == "search_input":
            search_term = event.value.lower()
            app_list = self.query_one("#app_list", AppList)
            app_list.clear()
            
            filtered_apps = [app for app in app_list.apps if search_term in app['name'].lower()]
            for app in filtered_apps:
                app_list.append(ListItem(Label(app['name'])))

if __name__ == "__main__":
    app = LauncherApp()
    app.run()