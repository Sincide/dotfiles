from textual.widgets import Static

class LogsWidget(Static):
    def __init__(self, config_manager=None, **kwargs):
        super().__init__("Logs Widget - Coming Soon!", **kwargs)
        self.config_manager = config_manager 