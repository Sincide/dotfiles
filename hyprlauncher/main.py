#!/usr/bin/env python3
import gi
import os
import subprocess
import sys

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, GdkPixbuf, Gio

class WallpaperSelector(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.example.WallpaperSelector")
        self.connect("activate", self.on_activate)
        self.backend = "swww"

    def on_activate(self, app):
        # Main window
        self.win = Gtk.ApplicationWindow(application=app)
        self.win.set_title("Wallpaper Selector")
        self.win.set_default_size(800, 600)

        # Vertical layout
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.win.set_child(vbox)

        # Controls: backend selector + folder button
        controls = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        vbox.append(controls)

        # Backend combo using Gio.StringList + new_for_model()
        model = Gio.StringList.new(["swww", "matugen"])
        combo = Gtk.ComboBox.new_for_model(model)
        combo.set_selected(0)
        combo.connect("changed", self.on_backend_changed)
        controls.append(Gtk.Label(label="Backend:"))
        controls.append(combo)

        # Folder-select button
        folder_btn = Gtk.Button(label="Select Wallpaper Folder")
        # pass flowbox by late binding
        folder_btn.connect("clicked", lambda btn: self.open_folder_dialog(flowbox))
        controls.append(folder_btn)

        # Scrollable thumbnail area
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        vbox.append(scroll)

        flowbox = Gtk.FlowBox()
        flowbox.set_max_children_per_line(5)
        flowbox.set_selection_mode(Gtk.SelectionMode.NONE)
        flowbox.connect("child-activated", self.on_thumbnail_activated)
        scroll.set_child(flowbox)

        self.win.present()

    def on_backend_changed(self, combo):
        selected = combo.get_selected_item()
        if isinstance(selected, str):
            self.backend = selected

    def open_folder_dialog(self, flowbox):
        dlg = Gtk.FileChooserDialog(
            title="Select Wallpaper Folder",
            transient_for=self.win,
            modal=True,
            action=Gtk.FileChooserAction.SELECT_FOLDER,
        )
        dlg.add_buttons("_Cancel", Gtk.ResponseType.CANCEL,
                        "_Open",    Gtk.ResponseType.ACCEPT)
        dlg.connect("response", lambda dlg, resp: self.on_folder_response(dlg, resp, flowbox))
        dlg.present()

    def on_folder_response(self, dlg, response, flowbox):
        if response == Gtk.ResponseType.ACCEPT:
            gfile = dlg.get_file()
            self.load_thumbnails(gfile, flowbox)
        dlg.destroy()

    def load_thumbnails(self, gfile, flowbox):
        # Clear previous thumbnails
        for child in flowbox.get_children():
            flowbox.remove(child)

        folder = gfile.get_path()
        for fname in os.listdir(folder):
            if not fname.lower().endswith((".jpg", ".jpeg", ".png")):
                continue

            fullpath = os.path.join(folder, fname)
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(fullpath)
                thumb = pixbuf.scale_simple(128, 128, GdkPixbuf.InterpType.BILINEAR)
                img = Gtk.Image.new_from_pixbuf(thumb)

                eventbox = Gtk.EventBox()
                eventbox.add(img)
                eventbox.set_margin(5)
                eventbox.filepath = fullpath

                flowbox.append(eventbox)
            except Exception as e:
                print(f"Error loading {fullpath}: {e}")

        flowbox.show_all()

    def on_thumbnail_activated(self, flowbox, eventbox):
        path = getattr(eventbox, "filepath", None)
        if not path:
            return

        self.show_preview(path)
        self.set_wallpaper(path)

    def show_preview(self, path):
        preview = Gtk.Window(transient_for=self.win, modal=True)
        preview.set_title("Preview")
        preview.set_default_size(800, 600)
        pix = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 800, 600, True)
        img = Gtk.Image.new_from_pixbuf(pix)
        preview.set_child(img)
        preview.present()

    def set_wallpaper(self, path):
        if self.backend == "swww":
            cmd = ["swww", "img", path]
        else:
            cmd = ["matugen", "tile", path]
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Failed to set wallpaper ({self.backend}): {e}")

def main():
    app = WallpaperSelector()
    return app.run(None)

if __name__ == "__main__":
    sys.exit(main())
