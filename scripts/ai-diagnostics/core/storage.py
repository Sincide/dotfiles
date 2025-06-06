"""
Diagnostic Data Storage System

SQLite-based storage for historical tracking, trend analysis, and session management.
Provides comprehensive data persistence for AI-powered diagnostics.
"""

import asyncio
import sqlite3
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import asdict

import aiosqlite

from .models import (
    DiagnosticSession, DiagnosticResult, DiagnosticIssue, 
    SystemSnapshot, Severity
)


class DiagnosticStorage:
    """
    Comprehensive storage system for diagnostic data.
    
    Features:
    - Session tracking and management
    - Historical diagnostic results
    - Trend analysis and performance baselines
    - Issue pattern recognition data
    - System snapshots for correlation analysis
    """
    
    def __init__(self, data_dir: Path):
        """Initialize storage system."""
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(exist_ok=True)
        
        self.db_path = self.data_dir / "diagnostics.db"
        self.logger = logging.getLogger(__name__)
        
        # Schema version for migrations
        self.schema_version = 1
        
    async def initialize(self) -> bool:
        """Initialize database and create tables if needed."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await self._create_tables(db)
                await self._check_schema_version(db)
                await db.commit()
                
            self.logger.info(f"Storage initialized: {self.db_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Storage initialization failed: {e}")
            return False
    
    async def _create_tables(self, db: aiosqlite.Connection) -> None:
        """Create database tables."""
        
        # Sessions table
        await db.execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                session_id TEXT PRIMARY KEY,
                mode TEXT NOT NULL,
                started_at TIMESTAMP NOT NULL,
                completed_at TIMESTAMP,
                ai_model TEXT,
                plugins_requested TEXT,  -- JSON array
                total_issues INTEGER,
                session_duration_seconds REAL,
                system_snapshot TEXT,    -- JSON
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Results table  
        await db.execute("""
            CREATE TABLE IF NOT EXISTS results (
                result_id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                plugin_name TEXT NOT NULL,
                status TEXT NOT NULL,
                execution_time_ms REAL,
                issues_count INTEGER,
                metadata TEXT,           -- JSON
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (session_id) REFERENCES sessions (session_id)
            )
        """)
        
        # Issues table
        await db.execute("""
            CREATE TABLE IF NOT EXISTS issues (
                issue_id INTEGER PRIMARY KEY AUTOINCREMENT,
                result_id INTEGER NOT NULL,
                session_id TEXT NOT NULL,
                category TEXT NOT NULL,
                severity TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                fix_suggestion TEXT,
                fix_applied BOOLEAN DEFAULT FALSE,
                fix_applied_at TIMESTAMP,
                metadata TEXT,           -- JSON
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (result_id) REFERENCES results (result_id),
                FOREIGN KEY (session_id) REFERENCES sessions (session_id)
            )
        """)
        
        # Performance metrics table
        await db.execute("""
            CREATE TABLE IF NOT EXISTS performance_metrics (
                metric_id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                metric_name TEXT NOT NULL,
                metric_value REAL NOT NULL,
                metric_unit TEXT,
                baseline_value REAL,
                deviation_percent REAL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (session_id) REFERENCES sessions (session_id)
            )
        """)
        
        # System snapshots table
        await db.execute("""
            CREATE TABLE IF NOT EXISTS system_snapshots (
                snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                hostname TEXT,
                os_info TEXT,            -- JSON
                resource_usage TEXT,     -- JSON
                service_states TEXT,     -- JSON
                network_status TEXT,     -- JSON
                active_processes TEXT,   -- JSON
                storage_info TEXT,       -- JSON
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (session_id) REFERENCES sessions (session_id)
            )
        """)
        
        # AI analysis table
        await db.execute("""
            CREATE TABLE IF NOT EXISTS ai_analysis (
                analysis_id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                analysis_type TEXT NOT NULL,  -- health, diagnostic, trend, etc.
                ai_model TEXT NOT NULL,
                confidence_score REAL,
                analysis_data TEXT,      -- JSON
                processing_time_ms REAL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (session_id) REFERENCES sessions (session_id)
            )
        """)
        
        # Trends table for historical analysis
        await db.execute("""
            CREATE TABLE IF NOT EXISTS trends (
                trend_id INTEGER PRIMARY KEY AUTOINCREMENT,
                metric_name TEXT NOT NULL,
                time_period TEXT NOT NULL,  -- daily, weekly, monthly
                start_date DATE NOT NULL,
                end_date DATE NOT NULL,
                baseline_value REAL,
                current_value REAL,
                trend_direction TEXT,       -- improving, degrading, stable
                confidence REAL,
                data_points INTEGER,
                analysis TEXT,              -- JSON
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Create indexes for performance
        await db.execute("CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON sessions(started_at)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_results_session_id ON results(session_id)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_issues_session_id ON issues(session_id)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_issues_severity ON issues(severity)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_metrics_session_id ON performance_metrics(session_id)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_metrics_name ON performance_metrics(metric_name)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_trends_metric ON trends(metric_name)")
        
    async def _check_schema_version(self, db: aiosqlite.Connection) -> None:
        """Check and handle schema migrations."""
        # Implementation for future schema migrations
        pass
    
    # Session Management
    
    async def store_session(self, session: DiagnosticSession) -> bool:
        """Store a new diagnostic session."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute("""
                    INSERT INTO sessions (
                        session_id, mode, started_at, ai_model, plugins_requested
                    ) VALUES (?, ?, ?, ?, ?)
                """, (
                    session.session_id,
                    session.mode,
                    session.started_at,
                    session.ai_model,
                    json.dumps(session.plugins_requested)
                ))
                await db.commit()
                
            self.logger.debug(f"Stored session: {session.session_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to store session: {e}")
            return False
    
    async def update_session_completion(
        self, 
        session_id: str, 
        completed_at: datetime,
        total_issues: int,
        duration_seconds: float
    ) -> bool:
        """Update session with completion information."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute("""
                    UPDATE sessions 
                    SET completed_at = ?, total_issues = ?, session_duration_seconds = ?
                    WHERE session_id = ?
                """, (completed_at, total_issues, duration_seconds, session_id))
                await db.commit()
                
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to update session completion: {e}")
            return False
    
    async def get_recent_sessions(self, days: int = 30) -> List[DiagnosticSession]:
        """Get recent diagnostic sessions."""
        try:
            cutoff_date = datetime.now() - timedelta(days=days)
            
            async with aiosqlite.connect(self.db_path) as db:
                async with db.execute("""
                    SELECT session_id, mode, started_at, completed_at, ai_model, 
                           plugins_requested, total_issues, session_duration_seconds
                    FROM sessions 
                    WHERE started_at >= ?
                    ORDER BY started_at DESC
                """, (cutoff_date,)) as cursor:
                    rows = await cursor.fetchall()
                    
            sessions = []
            for row in rows:
                sessions.append(DiagnosticSession(
                    session_id=row[0],
                    mode=row[1], 
                    started_at=datetime.fromisoformat(row[2]),
                    completed_at=datetime.fromisoformat(row[3]) if row[3] else None,
                    ai_model=row[4],
                    plugins_requested=json.loads(row[5]) if row[5] else [],
                    total_issues=row[6],
                    session_duration_seconds=row[7]
                ))
                
            return sessions
            
        except Exception as e:
            self.logger.error(f"Failed to get recent sessions: {e}")
            return []
    
    # Results Storage
    
    async def store_result(self, session_id: str, result: DiagnosticResult) -> bool:
        """Store a diagnostic result."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                # Store main result
                cursor = await db.execute("""
                    INSERT INTO results (
                        session_id, plugin_name, status, execution_time_ms, 
                        issues_count, metadata
                    ) VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    session_id,
                    result.plugin_name,
                    result.status,
                    getattr(result, 'execution_time_ms', None),
                    len(result.issues),
                    json.dumps(getattr(result, 'metadata', {}))
                ))
                
                result_id = cursor.lastrowid
                
                # Store issues
                for issue in result.issues:
                    await db.execute("""
                        INSERT INTO issues (
                            result_id, session_id, category, severity, title, 
                            description, fix_suggestion, metadata
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        result_id,
                        session_id,
                        issue.category,
                        issue.severity,
                        issue.title,
                        issue.description,
                        issue.fix_suggestion,
                        json.dumps(getattr(issue, 'metadata', {}))
                    ))
                
                await db.commit()
                
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to store result: {e}")
            return False
    
    async def get_recent_issues(self, days: int = 7) -> List[DiagnosticIssue]:
        """Get recent diagnostic issues for pattern analysis."""
        try:
            cutoff_date = datetime.now() - timedelta(days=days)
            
            async with aiosqlite.connect(self.db_path) as db:
                async with db.execute("""
                    SELECT category, severity, title, description, fix_suggestion, metadata
                    FROM issues i
                    JOIN sessions s ON i.session_id = s.session_id
                    WHERE s.started_at >= ?
                    ORDER BY i.created_at DESC
                """, (cutoff_date,)) as cursor:
                    rows = await cursor.fetchall()
                    
            issues = []
            for row in rows:
                issues.append(DiagnosticIssue(
                    category=row[0],
                    severity=Severity(row[1]),
                    title=row[2],
                    description=row[3],
                    fix_suggestion=row[4]
                ))
                
            return issues
            
        except Exception as e:
            self.logger.error(f"Failed to get recent issues: {e}")
            return []
    
    # Performance Metrics
    
    async def store_performance_metrics(
        self, 
        session_id: str, 
        metrics: Dict[str, float]
    ) -> bool:
        """Store performance metrics for trend analysis."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                for metric_name, value in metrics.items():
                    # Get baseline for comparison
                    baseline = await self._get_metric_baseline(metric_name)
                    deviation = None
                    
                    if baseline:
                        deviation = ((value - baseline) / baseline) * 100
                    
                    await db.execute("""
                        INSERT INTO performance_metrics (
                            session_id, metric_name, metric_value, 
                            baseline_value, deviation_percent
                        ) VALUES (?, ?, ?, ?, ?)
                    """, (session_id, metric_name, value, baseline, deviation))
                
                await db.commit()
                
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to store metrics: {e}")
            return False
    
    async def _get_metric_baseline(self, metric_name: str) -> Optional[float]:
        """Get baseline value for a performance metric."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                async with db.execute("""
                    SELECT AVG(metric_value)
                    FROM performance_metrics 
                    WHERE metric_name = ? 
                    AND created_at >= datetime('now', '-30 days')
                """, (metric_name,)) as cursor:
                    row = await cursor.fetchone()
                    return row[0] if row and row[0] else None
                    
        except Exception as e:
            self.logger.error(f"Failed to get baseline for {metric_name}: {e}")
            return None
    
    # System Snapshots
    
    async def store_system_snapshot(
        self, 
        session_id: str, 
        snapshot: SystemSnapshot
    ) -> bool:
        """Store system snapshot for correlation analysis."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute("""
                    INSERT INTO system_snapshots (
                        session_id, hostname, os_info, resource_usage,
                        service_states, network_status, active_processes, storage_info
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    session_id,
                    snapshot.hostname,
                    json.dumps(snapshot.os_info),
                    json.dumps(snapshot.resource_usage),
                    json.dumps(snapshot.service_states),
                    json.dumps(snapshot.network_status),
                    json.dumps(snapshot.active_processes),
                    json.dumps(snapshot.storage_info)
                ))
                await db.commit()
                
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to store system snapshot: {e}")
            return False
    
    # AI Analysis Storage
    
    async def store_ai_analysis(
        self,
        session_id: str,
        analysis_type: str,
        ai_model: str,
        confidence_score: float,
        analysis_data: Dict[str, Any],
        processing_time_ms: float
    ) -> bool:
        """Store AI analysis results."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute("""
                    INSERT INTO ai_analysis (
                        session_id, analysis_type, ai_model, confidence_score,
                        analysis_data, processing_time_ms
                    ) VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    session_id, analysis_type, ai_model, confidence_score,
                    json.dumps(analysis_data), processing_time_ms
                ))
                await db.commit()
                
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to store AI analysis: {e}")
            return False
    
    # Trend Analysis
    
    async def calculate_trends(self, metric_name: str, days: int = 30) -> Optional[Dict[str, Any]]:
        """Calculate trends for a specific metric."""
        try:
            cutoff_date = datetime.now() - timedelta(days=days)
            
            async with aiosqlite.connect(self.db_path) as db:
                async with db.execute("""
                    SELECT metric_value, created_at
                    FROM performance_metrics 
                    WHERE metric_name = ? AND created_at >= ?
                    ORDER BY created_at ASC
                """, (metric_name, cutoff_date)) as cursor:
                    rows = await cursor.fetchall()
                    
            if len(rows) < 2:
                return None
                
            values = [row[0] for row in rows]
            timestamps = [datetime.fromisoformat(row[1]) for row in rows]
            
            # Calculate trend metrics
            first_value = values[0]
            last_value = values[-1]
            avg_value = sum(values) / len(values)
            
            trend_direction = "stable"
            if last_value > first_value * 1.1:
                trend_direction = "increasing"
            elif last_value < first_value * 0.9:
                trend_direction = "decreasing"
                
            return {
                "metric_name": metric_name,
                "period_days": days,
                "data_points": len(values),
                "first_value": first_value,
                "last_value": last_value,
                "average_value": avg_value,
                "trend_direction": trend_direction,
                "change_percent": ((last_value - first_value) / first_value) * 100,
                "timestamps": [ts.isoformat() for ts in timestamps],
                "values": values
            }
            
        except Exception as e:
            self.logger.error(f"Failed to calculate trends for {metric_name}: {e}")
            return None
    
    # Utility Methods
    
    async def get_storage_stats(self) -> Dict[str, Any]:
        """Get storage system statistics."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                stats = {}
                
                # Count records in each table
                for table in ["sessions", "results", "issues", "performance_metrics", 
                             "system_snapshots", "ai_analysis", "trends"]:
                    async with db.execute(f"SELECT COUNT(*) FROM {table}") as cursor:
                        row = await cursor.fetchone()
                        stats[f"{table}_count"] = row[0] if row else 0
                
                # Get database file size
                stats["db_size_bytes"] = self.db_path.stat().st_size
                stats["db_size_mb"] = stats["db_size_bytes"] / (1024 * 1024)
                
                # Get oldest and newest records
                async with db.execute("""
                    SELECT MIN(started_at), MAX(started_at) FROM sessions
                """) as cursor:
                    row = await cursor.fetchone()
                    if row and row[0]:
                        stats["oldest_session"] = row[0]
                        stats["newest_session"] = row[1]
                
                return stats
                
        except Exception as e:
            self.logger.error(f"Failed to get storage stats: {e}")
            return {}
    
    async def cleanup_old_data(self, retention_days: int = 90) -> int:
        """Clean up old diagnostic data beyond retention period."""
        try:
            cutoff_date = datetime.now() - timedelta(days=retention_days)
            records_deleted = 0
            
            async with aiosqlite.connect(self.db_path) as db:
                # Get sessions to delete
                async with db.execute("""
                    SELECT session_id FROM sessions WHERE started_at < ?
                """, (cutoff_date,)) as cursor:
                    session_ids = [row[0] for row in await cursor.fetchall()]
                
                if session_ids:
                    # Delete related records
                    for session_id in session_ids:
                        for table in ["ai_analysis", "system_snapshots", 
                                     "performance_metrics", "issues", "results"]:
                            result = await db.execute(f"""
                                DELETE FROM {table} WHERE session_id = ?
                            """, (session_id,))
                            records_deleted += result.rowcount
                    
                    # Delete sessions
                    for session_id in session_ids:
                        result = await db.execute("""
                            DELETE FROM sessions WHERE session_id = ?
                        """, (session_id,))
                        records_deleted += result.rowcount
                
                await db.commit()
                
            self.logger.info(f"Cleaned up {records_deleted} old records (older than {retention_days} days)")
            return records_deleted
            
        except Exception as e:
            self.logger.error(f"Failed to cleanup old data: {e}")
            return 0 