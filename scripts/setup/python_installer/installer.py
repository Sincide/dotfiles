#!/usr/bin/env python3
"""
Dotfiles Python TUI Installer - Main Entry Point
"""
import sys
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Static, ListView, ListItem
from textual.containers import Container, Horizontal
from textual.reactive import reactive
from textual import events

SECTIONS = [
    "Packages",
    "Configs",
    "Assets",
    "System Tasks",
    "LLMs",
    "Brave Restore",
    "Summary",
    "Help/About",
    "Exit"
]

class Sidebar(ListView):
    def __init__(self, sections, **kwargs):
        super().__init__(*[ListItem(Static(section)) for section in sections], **kwargs)
        self.sections = sections

class MainContent(Static):
    section = reactive("Packages")

    def render(self) -> str:
        # Placeholder content for each section
        if self.section == "Packages":
            return "[Packages]\n\nPackage management UI will go here."
        elif self.section == "Configs":
            return "[Configs]\n\nConfig symlinking UI will go here."
        elif self.section == "Assets":
            return "[Assets]\n\nAsset deployment UI will go here."
        elif self.section == "System Tasks":
            return "[System Tasks]\n\nSystem-level tasks UI will go here."
        elif self.section == "LLMs":
            return "[LLMs]\n\nOllama and LLM model management UI will go here."
        elif self.section == "Brave Restore":
            return "[Brave Restore]\n\nBrave backup/restore UI will go here."
        elif self.section == "Summary":
            return "[Summary]\n\nSummary and review UI will go here."
        elif self.section == "Help/About":
            return "[Help/About]\n\nHelp and about information will go here."
        elif self.section == "Exit":
            return "[Exit]\n\nPress 'q' to quit the installer."
        else:
            return "[Unknown Section]"

class DotfilesInstallerApp(App):
    CSS_PATH = None  # We'll add custom dark theme CSS later
    BINDINGS = [
        ("up", "cursor_up", "Up"),
        ("down", "cursor_down", "Down"),
        ("enter", "select_section", "Select"),
        ("q", "quit", "Quit"),
    ]

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal():
            self.sidebar = Sidebar(SECTIONS, id="sidebar")
            self.main_content = MainContent(id="main-content")
            yield self.sidebar
            yield self.main_content
        yield Footer()

    def on_mount(self) -> None:
        self.sidebar.index = 0
        self.main_content.section = SECTIONS[0]
        self.set_focus(self.sidebar)

    def action_cursor_up(self) -> None:
        self.sidebar.cursor_up()

    def action_cursor_down(self) -> None:
        self.sidebar.cursor_down()

    def action_select_section(self) -> None:
        idx = self.sidebar.index
        self.main_content.section = SECTIONS[idx]

    def action_quit(self) -> None:
        self.exit()

if __name__ == "__main__":
    try:
        DotfilesInstallerApp().run()
    except KeyboardInterrupt:
        sys.exit(0) 