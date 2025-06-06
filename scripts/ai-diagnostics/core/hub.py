"""
Central Diagnostic Hub

The main orchestration system for AI-powered diagnostics. Coordinates between
plugins, LLM analysis, data storage, and user interface.
"""

import asyncio
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path

from rich.console import Console
from rich.progress import Progress, TaskID

from .models import (
    DiagnosticSession, DiagnosticResult, DiagnosticIssue, 
    SystemSnapshot, Severity, DiagnosticMode
)
from .plugin_manager import PluginManager, PluginExecutionContext
from .llm_engine import LLMEngine, AnalysisContext
from .storage import DiagnosticStorage


class SessionPhase(str, Enum):
    """Phases of a diagnostic session."""
    INITIALIZING = "initializing"
    DISCOVERY = "discovery"
    TESTING = "testing"
    ANALYSIS = "analysis"
    REPORTING = "reporting"
    COMPLETE = "complete"
    ERROR = "error"


@dataclass
class SessionContext:
    """Context information for the entire diagnostic session."""
    session_id: str
    mode: DiagnosticMode
    start_time: datetime
    phase: SessionPhase = SessionPhase.INITIALIZING
    ai_model: Optional[str] = None
    plugins_enabled: List[str] = field(default_factory=list)
    user_preferences: Dict[str, Any] = field(default_factory=dict)
    performance_targets: Dict[str, float] = field(default_factory=dict)


class DiagnosticHub:
    """
    Central orchestration hub for comprehensive system diagnostics.
    
    Coordinates between:
    - Plugin manager (system checks)
    - LLM engine (AI analysis)
    - Storage system (historical data)
    - User interface (interaction)
    
    Provides intelligent workflow management and session coordination.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize the diagnostic hub."""
        self.console = Console()
        self.logger = logging.getLogger(__name__)
        
        # Configuration
        self.config = {
            "data_dir": Path("data"),
            "plugin_dir": Path("plugins"),
            "session_timeout": 300,  # 5 minutes
            "max_concurrent_checks": 10,
            "ai_confidence_threshold": 0.7,
            "auto_fix_enabled": False,
            "historical_retention_days": 90,
        }
        
        if config:
            self.config.update(config)
            
        # Core components
        self.plugin_manager: Optional[PluginManager] = None
        self.llm_engine: Optional[LLMEngine] = None
        self.storage: Optional[DiagnosticStorage] = None
        
        # Session state
        self.current_session: Optional[SessionContext] = None
        self.active_tasks: Dict[str, TaskID] = {}
        self.session_results: List[DiagnosticResult] = []
        
        # Performance tracking
        self.performance_baselines: Dict[str, float] = {}
        self.trend_analysis_cache: Dict[str, Any] = {}
        
    async def initialize(self, ai_model: Optional[str] = None) -> bool:
        """Initialize all hub components."""
        try:
            self.logger.info("Initializing Diagnostic Hub")
            
            # Initialize storage system
            self.storage = DiagnosticStorage(self.config["data_dir"])
            await self.storage.initialize()
            self.logger.info("Storage system initialized")
            
            # Initialize LLM engine
            llm_config = {}
            if ai_model:
                llm_config["primary_model"] = ai_model
                
            self.llm_engine = LLMEngine(llm_config)
            llm_ready = await self.llm_engine.initialize()
            
            if llm_ready:
                self.logger.info("LLM engine initialized successfully")
            else:
                self.logger.warning("LLM engine initialization failed - running without AI features")
                
            # Initialize plugin manager
            self.plugin_manager = PluginManager(self.config["plugin_dir"])
            await self.plugin_manager.initialize()
            self.logger.info(f"Plugin manager initialized with {len(self.plugin_manager.get_available_plugins())} plugins")
            
            # Load performance baselines from historical data
            await self._load_performance_baselines()
            
            self.logger.info("Diagnostic Hub initialization complete")
            return True
            
        except Exception as e:
            self.logger.error(f"Hub initialization failed: {e}")
            return False
    
    async def start_session(
        self, 
        mode: DiagnosticMode,
        ai_model: Optional[str] = None,
        plugins: Optional[List[str]] = None,
        user_preferences: Optional[Dict[str, Any]] = None
    ) -> SessionContext:
        """Start a new diagnostic session."""
        
        session_id = f"diag_{int(time.time())}"
        
        self.current_session = SessionContext(
            session_id=session_id,
            mode=mode,
            start_time=datetime.now(),
            ai_model=ai_model,
            plugins_enabled=plugins or [],
            user_preferences=user_preferences or {},
            performance_targets=self._get_performance_targets(mode)
        )
        
        # Store session start in database
        session_record = DiagnosticSession(
            session_id=session_id,
            mode=mode,
            started_at=self.current_session.start_time,
            ai_model=ai_model,
            plugins_requested=plugins or []
        )
        
        if self.storage:
            await self.storage.store_session(session_record)
            
        self.logger.info(f"Started diagnostic session {session_id} in {mode} mode")
        return self.current_session
    
    async def run_diagnostics(self, progress: Optional[Progress] = None) -> List[DiagnosticResult]:
        """Execute the full diagnostic workflow."""
        if not self.current_session:
            raise RuntimeError("No active session - call start_session() first")
            
        session = self.current_session
        results = []
        
        try:
            # Phase 1: Discovery and Planning
            session.phase = SessionPhase.DISCOVERY
            system_snapshot = await self._capture_system_snapshot()
            
            # Determine which plugins to run based on mode and system state
            plugins_to_run = await self._plan_plugin_execution(session.mode, system_snapshot)
            
            # Phase 2: Execute diagnostic plugins
            session.phase = SessionPhase.TESTING
            plugin_results = await self._execute_plugins(plugins_to_run, progress)
            results.extend(plugin_results)
            
            # Phase 3: AI Analysis
            if self.llm_engine:
                session.phase = SessionPhase.ANALYSIS
                ai_analysis = await self._perform_ai_analysis(plugin_results, system_snapshot)
                results.extend(ai_analysis)
            
            # Phase 4: Historical Analysis and Trends
            trend_analysis = await self._analyze_trends(plugin_results)
            if trend_analysis:
                results.extend(trend_analysis)
                
            # Phase 5: Generate comprehensive report
            session.phase = SessionPhase.REPORTING
            
            # Store results
            if self.storage:
                for result in results:
                    await self.storage.store_result(session.session_id, result)
                    
            # Update session completion
            await self._complete_session(results)
            
            session.phase = SessionPhase.COMPLETE
            self.session_results = results
            
            return results
            
        except Exception as e:
            session.phase = SessionPhase.ERROR
            self.logger.error(f"Diagnostic session failed: {e}")
            raise
    
    async def _capture_system_snapshot(self) -> SystemSnapshot:
        """Capture comprehensive system state snapshot."""
        # Implementation would capture:
        # - System info (OS, kernel, hardware)
        # - Resource usage (CPU, memory, disk)
        # - Network status
        # - Service states
        # - Log summaries
        # - Configuration files
        
        return SystemSnapshot(
            timestamp=datetime.now(),
            hostname="localhost",  # placeholder
            os_info={},
            resource_usage={},
            service_states={},
            active_processes=[],
            network_status={},
            storage_info={}
        )
    
    async def _plan_plugin_execution(
        self, 
        mode: DiagnosticMode, 
        snapshot: SystemSnapshot
    ) -> List[str]:
        """Intelligently plan which plugins to execute based on mode and system state."""
        
        if not self.plugin_manager:
            return []
            
        available_plugins = self.plugin_manager.get_available_plugins()
        
        if mode == DiagnosticMode.QUICK:
            # Quick mode: essential checks only
            return [p for p in available_plugins if p in ["environment", "ai_health", "system_health"]]
            
        elif mode == DiagnosticMode.DEEP:
            # Deep mode: comprehensive analysis
            return available_plugins
            
        elif mode == DiagnosticMode.STRESS:
            # Stress mode: performance testing plugins
            return [p for p in available_plugins if "performance" in p or "stress" in p]
            
        return available_plugins
    
    async def _execute_plugins(
        self, 
        plugin_names: List[str], 
        progress: Optional[Progress] = None
    ) -> List[DiagnosticResult]:
        """Execute diagnostic plugins with progress tracking."""
        
        if not self.plugin_manager:
            return []
            
        results = []
        
        # Create execution context
        context = PluginExecutionContext(
            session_id=self.current_session.session_id,
            mode=self.current_session.mode,
            ai_model=self.current_session.ai_model,
            config=self.config
        )
        
        # Execute plugins
        for plugin_name in plugin_names:
            try:
                result = await self.plugin_manager.execute_plugin(plugin_name, context)
                if result:
                    results.append(result)
                    
            except Exception as e:
                self.logger.error(f"Plugin {plugin_name} execution failed: {e}")
                
        return results
    
    async def _perform_ai_analysis(
        self, 
        plugin_results: List[DiagnosticResult],
        system_snapshot: SystemSnapshot
    ) -> List[DiagnosticResult]:
        """Perform AI-powered analysis of diagnostic results."""
        
        if not self.llm_engine:
            return []
            
        # Create analysis context
        analysis_context = AnalysisContext(
            system_snapshot=system_snapshot,
            recent_logs=await self._get_recent_logs(),
            historical_issues=await self._get_historical_issues(),
            performance_metrics=self._extract_performance_metrics(plugin_results)
        )
        
        # Perform AI analysis
        ai_results = []
        
        try:
            # System health analysis
            health_analysis = await self.llm_engine.analyze_system_health(analysis_context)
            if health_analysis:
                ai_results.append(self._convert_ai_analysis_to_result(health_analysis, "system_health"))
                
            # Pattern recognition in issues
            issues = [issue for result in plugin_results for issue in result.issues]
            if issues:
                for issue in issues:
                    diagnosis = await self.llm_engine.diagnose_issue(str(issue), analysis_context)
                    if diagnosis:
                        ai_results.append(self._convert_diagnosis_to_result(diagnosis))
                        
        except Exception as e:
            self.logger.error(f"AI analysis failed: {e}")
            
        return ai_results
    
    async def _analyze_trends(self, current_results: List[DiagnosticResult]) -> List[DiagnosticResult]:
        """Analyze trends and historical patterns."""
        
        if not self.storage:
            return []
            
        # Get historical data for comparison
        historical_sessions = await self.storage.get_recent_sessions(days=30)
        
        # Analyze performance trends
        # Analyze error patterns
        # Detect degradation
        
        # Placeholder implementation
        return []
    
    async def _complete_session(self, results: List[DiagnosticResult]) -> None:
        """Complete the diagnostic session with final updates."""
        
        if not self.current_session or not self.storage:
            return
            
        # Calculate session summary
        total_issues = sum(len(result.issues) for result in results)
        session_duration = (datetime.now() - self.current_session.start_time).total_seconds()
        
        # Update session record
        await self.storage.update_session_completion(
            self.current_session.session_id,
            datetime.now(),
            total_issues,
            session_duration
        )
        
        self.logger.info(f"Session {self.current_session.session_id} completed: {total_issues} issues in {session_duration:.1f}s")
    
    def _get_performance_targets(self, mode: DiagnosticMode) -> Dict[str, float]:
        """Get performance targets based on diagnostic mode."""
        
        base_targets = {
            "session_duration": 30.0,  # seconds
            "plugin_timeout": 10.0,    # seconds per plugin
            "ai_response_time": 15.0,  # seconds for AI analysis
        }
        
        if mode == DiagnosticMode.DEEP:
            base_targets["session_duration"] = 180.0  # 3 minutes
            base_targets["plugin_timeout"] = 30.0
            
        elif mode == DiagnosticMode.STRESS:
            base_targets["session_duration"] = 300.0  # 5 minutes
            base_targets["plugin_timeout"] = 60.0
            
        return base_targets
    
    async def _load_performance_baselines(self) -> None:
        """Load performance baselines from historical data."""
        # Implementation would load historical performance data
        # to establish baselines for comparison
        pass
    
    async def _get_recent_logs(self) -> List[str]:
        """Get recent system logs for AI analysis."""
        # Implementation would extract recent logs from journald
        return []
    
    async def _get_historical_issues(self) -> List[DiagnosticIssue]:
        """Get historical issues for pattern analysis."""
        if not self.storage:
            return []
        return await self.storage.get_recent_issues(days=7)
    
    def _extract_performance_metrics(self, results: List[DiagnosticResult]) -> Dict[str, float]:
        """Extract performance metrics from diagnostic results."""
        metrics = {}
        
        for result in results:
            if hasattr(result, 'execution_time_ms'):
                metrics[f"{result.plugin_name}_time"] = result.execution_time_ms
                
            # Extract other performance indicators
            for issue in result.issues:
                if issue.category == "performance":
                    # Extract metrics from performance issues
                    pass
                    
        return metrics
    
    def _convert_ai_analysis_to_result(self, analysis: Dict[str, Any], category: str) -> DiagnosticResult:
        """Convert AI analysis to diagnostic result format."""
        # Implementation would convert AI analysis to standard result format
        pass
    
    def _convert_diagnosis_to_result(self, diagnosis: DiagnosticIssue) -> DiagnosticResult:
        """Convert AI diagnosis to diagnostic result format."""
        # Implementation would convert diagnosis to result format
        pass
    
    # Public API methods
    
    def get_session_summary(self) -> Optional[Dict[str, Any]]:
        """Get summary of current or last session."""
        if not self.current_session:
            return None
            
        return {
            "session_id": self.current_session.session_id,
            "mode": self.current_session.mode,
            "phase": self.current_session.phase,
            "duration": (datetime.now() - self.current_session.start_time).total_seconds(),
            "results_count": len(self.session_results),
            "issues_count": sum(len(r.issues) for r in self.session_results)
        }
    
    def get_available_plugins(self) -> List[str]:
        """Get list of available diagnostic plugins."""
        if not self.plugin_manager:
            return []
        return self.plugin_manager.get_available_plugins()
    
    def get_ai_status(self) -> Dict[str, Any]:
        """Get current AI/LLM engine status."""
        if not self.llm_engine:
            return {"available": False, "reason": "LLM engine not initialized"}
            
        return {
            "available": True,
            "models": self.llm_engine.get_available_models(),
            "health": self.llm_engine.get_model_health()
        } 