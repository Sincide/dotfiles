#!/usr/bin/env python3

import os
import subprocess
import glob
from pathlib import Path
from typing import List, Dict

from textual.app import App, ComposeResult
from textual.containers import Vertical, Container
from textual.widgets import Input, ListView, ListItem, Label, Static
from textual.binding import Binding

from theme import get_textual_theme

class AppList(ListView):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.apps = self.get_desktop_apps()
        self.all_apps = self.apps.copy()
    
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
    
    def filter_apps(self, search_term: str):
        self.clear()
        self.apps = [app for app in self.all_apps if search_term.lower() in app['name'].lower()]
        self.populate_apps()

class AppLauncherApp(App):
    def __init__(self):
        super().__init__()
        
        # Apply dynamic theme from kitty config
        theme = get_textual_theme()
        self.CSS = f"""
        Screen {{
            background: {theme['background']};
        }}
        
        #main_container {{
            width: 80;
            height: 40;
            border: thick {theme['primary']};
            background: {theme['surface']};
            margin: 1;
        }}
        
        #search_input {{
            margin: 1;
            background: {theme['primary']};
            color: {theme['background']};
        }}
        
        #app_list {{
            height: 35;
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
        
        #title {{
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
        Binding("enter", "launch", "Launch App"),
        Binding("ctrl+c", "quit", "Quit"),
        Binding("tab", "focus_list", "Focus List"),
    ]
    
    def compose(self) -> ComposeResult:
        with Container(id="main_container"):
            with Vertical():
                yield Static("🚀 Applications", id="title")
                yield Input(placeholder="Search apps...", id="search_input")
                yield AppList(id="app_list")
    
    def on_mount(self):
        search_input = self.query_one("#search_input", Input)
        search_input.focus()
    
    def on_input_changed(self, event):
        if event.input.id == "search_input":
            app_list = self.query_one("#app_list", AppList)
            app_list.filter_apps(event.value)
    
    def on_list_view_selected(self, event):
        if event.list_view.id == "app_list":
            app_list = self.query_one("#app_list", AppList)
            if event.list_view.index is not None and event.list_view.index < len(app_list.apps):
                app = app_list.apps[event.list_view.index]
                subprocess.Popen(app['exec'], shell=True)
                self.exit()
    
    def action_launch(self):
        app_list = self.query_one("#app_list", AppList)
        if app_list.highlighted_child and app_list.index is not None and app_list.index < len(app_list.apps):
            app = app_list.apps[app_list.index]
            subprocess.Popen(app['exec'], shell=True)
            self.exit()
    
    def action_focus_list(self):
        app_list = self.query_one("#app_list", AppList)
        app_list.focus()

if __name__ == "__main__":
    app = AppLauncherApp()
    app.run()