#!/usr/bin/env python3

import os
import subprocess
from pathlib import Path
from typing import List, Dict

from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical, Container
from textual.widgets import ListView, ListItem, Label, Static
from textual.binding import Binding

from theme import get_textual_theme

WALLPAPER_DIR = "/home/martin/dotfiles/assets/wallpapers"

class WallpaperPreview(Static):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.current_image = None
    
    def update_preview(self, image_path: str):
        if self.current_image == image_path:
            return
        
        self.current_image = image_path
        try:
            # Clear previous image
            subprocess.run(["kitten", "icat", "--clear"], capture_output=True)
            
            # Display new image with kitty protocol
            subprocess.run([
                "kitten", "icat", 
                "--align", "center",
                "--place", "50x25@0x0",
                "--transfer-mode", "memory",
                image_path
            ], capture_output=True)
        except Exception:
            self.update(f"Preview unavailable\n{Path(image_path).name}")

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

class WallpaperApp(App):
    def __init__(self):
        super().__init__()
        
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
        
        #preview_panel {{
            width: 60;
            border-right: solid {theme['primary']};
            background: {theme['surface']};
        }}
        
        #list_panel {{
            width: 60;
            background: {theme['surface']};
        }}
        
        #preview_area {{
            height: 38;
            background: {theme['panel']};
        }}
        
        #wallpaper_list {{
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
        Binding("enter", "select", "Set Wallpaper"),
        Binding("q", "quit", "Quit"),
    ]
    
    def compose(self) -> ComposeResult:
        with Container(id="main_container"):
            with Horizontal():
                with Vertical(id="preview_panel"):
                    yield WallpaperPreview(id="preview_area")
                
                with Vertical(id="list_panel"):
                    yield Static("🌌 Wallpapers", id="title")
                    yield WallpaperList(id="wallpaper_list")
    
    def on_mount(self):
        wallpaper_list = self.query_one("#wallpaper_list", WallpaperList)
        wallpaper_list.focus()
        
        # Show first wallpaper preview
        if wallpaper_list.wallpapers:
            preview = self.query_one("#preview_area", WallpaperPreview)
            preview.update_preview(wallpaper_list.wallpapers[0]['path'])
    
    def on_list_view_highlighted(self, event):
        if event.list_view.id == "wallpaper_list" and event.item:
            wallpaper = event.item.wallpaper
            preview = self.query_one("#preview_area", WallpaperPreview)
            preview.update_preview(wallpaper['path'])
    
    def action_select(self):
        wallpaper_list = self.query_one("#wallpaper_list", WallpaperList)
        if wallpaper_list.highlighted_child:
            wallpaper = wallpaper_list.highlighted_child.wallpaper
            # Set wallpaper with swww
            subprocess.run(["swww", "img", wallpaper['path']])
            self.exit()

if __name__ == "__main__":
    app = WallpaperApp()
    app.run()