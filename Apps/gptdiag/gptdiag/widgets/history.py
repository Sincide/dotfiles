from textual.widgets import Static

class HistoryWidget(Static):
    def __init__(self, diagnostic_runner=None, **kwargs):
        super().__init__("History Widget - Coming Soon!", **kwargs)
        self.diagnostic_runner = diagnostic_runner 