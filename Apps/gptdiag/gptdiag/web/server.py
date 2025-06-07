#!/usr/bin/env python3
"""
GPTDiag FastAPI Web Server

Modern web backend that wraps the existing core engine (SystemInfo, AIManager, etc.)
providing REST API endpoints and WebSocket real-time updates.

Reuses 90% of existing code - no rework needed for core functionality.
"""

import asyncio
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse
from pydantic import BaseModel, Field

# Import existing core engine (90% code reuse!)
from ..utils.system import SystemInfo
from ..ai.manager import AIManager
from ..config.manager import ConfigManager
from ..diagnostics.runner import DiagnosticRunner


# Pydantic models for API responses
class SystemSummaryResponse(BaseModel):
    """Quick system summary response."""
    cpu_percent: float
    memory_percent: float
    disk_percent: float
    process_count: int
    load_avg: float
    timestamp: str  # Changed to string since SystemInfo returns ISO string
    status: str = "healthy"
    alerts: List[str] = []


class SystemDetailedResponse(BaseModel):
    """Detailed system information response."""
    timestamp: str  # Changed to string since SystemInfo returns ISO string
    cpu: Dict[str, Any]
    memory: Dict[str, Any]
    disk: List[Dict[str, Any]]  # Changed to List since SystemInfo returns a list of disks
    processes: List[Dict[str, Any]]
    services: List[Dict[str, Any]]
    uptime: Dict[str, Any]
    load_avg: Dict[str, Any]


class AIAnalysisRequest(BaseModel):
    """AI analysis request model."""
    system_data: Optional[Dict[str, Any]] = None
    custom_prompt: Optional[str] = None
    model_role: str = "diagnostics"  # diagnostics, general, fast


class AIAnalysisResponse(BaseModel):
    """AI analysis response model."""
    analysis: str
    model_used: str
    tokens_used: int
    processing_time: float
    timestamp: datetime
    status: str = "success"
    error: Optional[str] = None


# WebSocket connection manager
class ConnectionManager:
    """Manages WebSocket connections for real-time updates."""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
    
    async def send_to_all(self, message: dict):
        """Send message to all connected clients."""
        if not self.active_connections:
            return
            
        # Send to all connections, remove disconnected ones
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(json.dumps(message))
            except Exception:
                disconnected.append(connection)
        
        # Clean up disconnected connections
        for conn in disconnected:
            self.disconnect(conn)


# Global state
app_state = {
    "system_info": None,
    "ai_manager": None,
    "config_manager": None,
    "diagnostic_runner": None,
    "connection_manager": ConnectionManager(),
    "update_interval": 5.0,  # seconds
    "last_update": None,
    "background_task": None
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize and cleanup application state."""
    # Startup
    await initialize_app_state()
    
    # Start background task for real-time updates
    app_state["background_task"] = asyncio.create_task(background_update_loop())
    
    yield
    
    # Cleanup
    if app_state["background_task"]:
        app_state["background_task"].cancel()
        try:
            await app_state["background_task"]
        except asyncio.CancelledError:
            pass


# Create FastAPI app
app = FastAPI(
    title="GPTDiag Web API",
    description="Modern web backend for GPTDiag system monitoring and AI analysis",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
static_dir = Path(__file__).parent / "static"
if static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")


async def initialize_app_state():
    """Initialize all core components (reusing existing code)."""
    try:
        # Initialize configuration manager
        config_dir = Path.home() / ".config" / "gptdiag"
        config_manager = ConfigManager(config_dir)
        app_state["config_manager"] = config_manager
        
        # Initialize system info (existing code)
        app_state["system_info"] = SystemInfo()
        
        # Initialize AI manager (existing code)
        ai_config = config_manager.get_ai_config()
        ai_manager = AIManager(ai_config)
        if await ai_manager.initialize():
            app_state["ai_manager"] = ai_manager
            logging.info("AI Manager initialized successfully")
        else:
            logging.warning("AI Manager initialization failed")
        
        # Initialize diagnostic runner
        app_state["diagnostic_runner"] = DiagnosticRunner(config_manager)
        
        logging.info("GPTDiag web backend initialized successfully")
        
    except Exception as e:
        logging.error(f"Failed to initialize app state: {e}")
        raise


async def background_update_loop():
    """Background task for real-time system updates via WebSocket."""
    while True:
        try:
            if app_state["system_info"] and app_state["connection_manager"].active_connections:
                # Get system summary for real-time updates
                summary = app_state["system_info"].get_quick_summary()
                
                # Add timestamp
                summary["timestamp"] = datetime.now().isoformat()
                app_state["last_update"] = datetime.now()
                
                # Send to all WebSocket clients
                await app_state["connection_manager"].send_to_all({
                    "type": "system_update",
                    "data": summary
                })
            
            await asyncio.sleep(app_state["update_interval"])
            
        except Exception as e:
            logging.error(f"Background update error: {e}")
            await asyncio.sleep(5)  # Wait before retrying


# API Routes

@app.get("/")
async def dashboard():
    """Serve the main dashboard page."""
    static_dir = Path(__file__).parent / "static"
    index_file = static_dir / "index.html"
    
    if index_file.exists():
        return FileResponse(str(index_file))
    else:
        # Fallback to API response if no frontend
        return {
            "service": "GPTDiag Web API",
            "version": "1.0.0",
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "ai_available": app_state["ai_manager"] is not None,
            "last_update": app_state["last_update"].isoformat() if app_state["last_update"] else None
        }

@app.get("/health")
async def health_check():
    """API health check endpoint."""
    return {
        "service": "GPTDiag Web API",
        "version": "1.0.0",
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "ai_available": app_state["ai_manager"] is not None,
        "last_update": app_state["last_update"].isoformat() if app_state["last_update"] else None
    }


@app.get("/api/system/summary", response_model=SystemSummaryResponse)
async def get_system_summary():
    """Get quick system summary (existing get_quick_summary())."""
    if not app_state["system_info"]:
        raise HTTPException(status_code=503, detail="System info not available")
    
    try:
        # Use existing SystemInfo.get_quick_summary() method
        summary = app_state["system_info"].get_quick_summary()
        
        # Add additional fields for web API
        summary["status"] = "healthy"
        
        # Generate alerts based on thresholds
        alerts = []
        if summary["cpu_percent"] > 80:
            alerts.append(f"High CPU usage: {summary['cpu_percent']:.1f}%")
        if summary["memory_percent"] > 85:
            alerts.append(f"High memory usage: {summary['memory_percent']:.1f}%")
        if summary["disk_percent"] > 90:
            alerts.append(f"High disk usage: {summary['disk_percent']:.1f}%")
        
        summary["alerts"] = alerts
        
        return SystemSummaryResponse(**summary)
        
    except Exception as e:
        logging.error(f"System summary error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/system/detailed", response_model=SystemDetailedResponse)
async def get_system_detailed():
    """Get detailed system information (existing get_async_info())."""
    if not app_state["system_info"]:
        raise HTTPException(status_code=503, detail="System info not available")
    
    try:
        # Use existing SystemInfo.get_async_info() method
        detailed_info = await app_state["system_info"].get_async_info()
        
        return SystemDetailedResponse(**detailed_info)
        
    except Exception as e:
        logging.error(f"Detailed system info error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/ai/analyze", response_model=AIAnalysisResponse)
async def analyze_system_with_ai(request: AIAnalysisRequest, background_tasks: BackgroundTasks):
    """AI-powered system analysis (existing analyze_system_health())."""
    if not app_state["ai_manager"]:
        raise HTTPException(status_code=503, detail="AI analysis not available")
    
    try:
        start_time = datetime.now()
        
        # Get system data if not provided
        if not request.system_data:
            request.system_data = await app_state["system_info"].get_async_info()
        
        # Use existing AIManager.analyze_system_health() method
        if request.custom_prompt:
            # For custom prompts, use the chat_about_system method instead
            response = await app_state["ai_manager"].chat_about_system(
                request.custom_prompt,
                request.system_data
            )
        else:
            # Use the standard health analysis
            response = await app_state["ai_manager"].analyze_system_health(request.system_data)
        
        processing_time = (datetime.now() - start_time).total_seconds()
        
        if response.error:
            return AIAnalysisResponse(
                analysis="",
                model_used="unknown",
                tokens_used=0,
                processing_time=processing_time,
                timestamp=datetime.now(),
                status="error",
                error=response.error
            )
        
        return AIAnalysisResponse(
            analysis=response.content,
            model_used=response.model_used or "unknown",
            tokens_used=response.tokens_used,
            processing_time=processing_time,
            timestamp=datetime.now(),
            status="success"
        )
        
    except Exception as e:
        logging.error(f"AI analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.websocket("/ws/updates")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time system updates."""
    await app_state["connection_manager"].connect(websocket)
    
    try:
        # Send initial system data
        if app_state["system_info"]:
            summary = app_state["system_info"].get_quick_summary()
            summary["timestamp"] = datetime.now().isoformat()
            await websocket.send_text(json.dumps({
                "type": "initial_data",
                "data": summary
            }))
        
        # Keep connection alive
        while True:
            # Wait for messages from client (heartbeat, commands, etc.)
            try:
                message = await websocket.receive_text()
                data = json.loads(message)
                
                # Handle different message types
                if data.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                elif data.get("type") == "request_update":
                    # Send immediate update
                    if app_state["system_info"]:
                        summary = app_state["system_info"].get_quick_summary()
                        summary["timestamp"] = datetime.now().isoformat()
                        await websocket.send_text(json.dumps({
                            "type": "system_update",
                            "data": summary
                        }))
                        
            except asyncio.TimeoutError:
                # Keep connection alive
                pass
                
    except WebSocketDisconnect:
        app_state["connection_manager"].disconnect(websocket)
    except Exception as e:
        logging.error(f"WebSocket error: {e}")
        app_state["connection_manager"].disconnect(websocket)


# Development server function
def run_server(host: str = "127.0.0.1", port: int = 8000, debug: bool = False):
    """Run the development server."""
    import uvicorn
    
    # Configure logging
    log_level = "debug" if debug else "info"
    logging.basicConfig(level=logging.DEBUG if debug else logging.INFO)
    
    print(f"🚀 Starting GPTDiag Web Server on http://{host}:{port}")
    print("📊 Dashboard will be available at http://localhost:8000")
    print("🤖 AI analysis endpoint: http://localhost:8000/api/ai/analyze")
    print("📡 WebSocket updates: ws://localhost:8000/ws/updates")
    
    uvicorn.run(
        "gptdiag.web.server:app",
        host=host,
        port=port,
        log_level=log_level,
        reload=debug
    )


if __name__ == "__main__":
    # For development
    run_server(debug=True) 