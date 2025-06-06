from textual.widgets import Static

class ServicesWidget(Static):
    def __init__(self, system_info=None, **kwargs):
        super().__init__("Services Widget - Coming Soon!", **kwargs)
        self.system_info = system_info 