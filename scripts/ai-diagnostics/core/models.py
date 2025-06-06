from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class Severity(str, Enum):
    INFO = "info"
    WARNING = "warning" 
    ERROR = "error"
    CRITICAL = "critical"


class CheckStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


class DiagnosticIssue(BaseModel):
    id: str
    title: str
    description: str
    severity: Severity
    category: str
    timestamp: datetime
    affected_components: List[str] = []
    fix_available: bool = False
    fix_command: Optional[str] = None
    fix_description: Optional[str] = None
    ai_analysis: Optional[str] = None
    ai_confidence: Optional[float] = None


class DiagnosticResult(BaseModel):
    check_id: str
    check_name: str
    status: CheckStatus
    duration_ms: int
    timestamp: datetime
    issues: List[DiagnosticIssue] = []
    metrics: Dict[str, Any] = {}
    ai_insights: Optional[str] = None


class SystemSnapshot(BaseModel):
    timestamp: datetime
    wayland_display: Optional[str]
    hyprland_running: bool
    waybar_running: bool
    ollama_running: bool
    ollama_models: List[str]
    theme_files_age: Dict[str, int]  # filename -> age in minutes
    performance_metrics: Dict[str, float]
    active_wallpaper: Optional[str]


class DiagnosticSession(BaseModel):
    session_id: str
    start_time: datetime
    end_time: Optional[datetime] = None
    mode: str  # "quick", "deep", "stress"
    results: List[DiagnosticResult] = []
    system_snapshot: Optional[SystemSnapshot] = None
    overall_health_score: Optional[float] = None
    ai_summary: Optional[str] = None


class PluginMetadata(BaseModel):
    name: str
    version: str
    description: str
    author: str
    category: str
    dependencies: List[str] = []
    enabled: bool = True 