from textual.widgets import Static

class AIDiagWidget(Static):
    def __init__(self, config_manager=None, diagnostic_runner=None, **kwargs):
        super().__init__("AI Diagnostics Widget - Coming Soon!", **kwargs)
        self.config_manager = config_manager
        self.diagnostic_runner = diagnostic_runner 