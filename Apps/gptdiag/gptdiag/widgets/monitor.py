from textual.widgets import Static

class MonitorWidget(Static):
    def __init__(self, system_info=None, **kwargs):
        super().__init__("Monitor Widget - Coming Soon!", **kwargs)
        self.system_info = system_info 