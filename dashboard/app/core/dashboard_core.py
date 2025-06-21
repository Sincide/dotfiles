import sqlite3
from pathlib import Path

# psutil will be imported dynamically if available

class EvilSpaceDashboard:
    """Main dashboard class for core logic and state"""
    
    def __init__(self, dotfiles_path="/home/martin/dotfiles"):
        self.dotfiles_path = Path(dotfiles_path)
        self.dashboard_path = self.dotfiles_path / "dashboard"
        self.data_path = self.dashboard_path / "data"
        self.logs_path = self.dotfiles_path / "logs"
        self.scripts_path = self.dotfiles_path / "scripts"
        self.themes_path = self.dotfiles_path / "themes"
        self.wallpapers_path = self.dotfiles_path / "assets" / "wallpapers"
        
        self.prev_proc_stat = None  # For CPU usage calculation
        
        # Initialize database
        self.init_database()
        
        # Check for psutil availability
        self.has_psutil = False
        try:
            import psutil
            self.has_psutil = True
            self.psutil = psutil
        except ImportError:
            print("psutil not available, using basic system monitoring")
            self.psutil = None
    
    def init_database(self):
        """Initialize SQLite database for persistent storage"""
        self.data_path.mkdir(parents=True, exist_ok=True)
        db_path = self.data_path / "dashboard.db"
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Create tables if they don't exist
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS system_stats (
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                cpu_usage REAL,
                memory_usage REAL,
                gpu_temp INTEGER,
                gpu_usage REAL
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS log_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                log_file TEXT,
                level TEXT,
                message TEXT,
                indexed_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close() 