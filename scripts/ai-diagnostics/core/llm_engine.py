"""
LLM Engine for AI-Powered Diagnostic System

This module provides deep integration with local LLM models via Ollama for:
- Real-time log analysis and pattern recognition
- Intelligent issue diagnosis and root cause analysis
- Automated fix suggestion generation
- Natural language explanations of technical issues
- Predictive system health analysis

The engine uses a multi-model strategy:
- phi4: Primary reasoning engine for complex analysis
- llama3.2: User-friendly explanations and natural language processing
- Configurable models per diagnostic category
"""

import asyncio
import json
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum

import ollama
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from .models import DiagnosticIssue, DiagnosticResult, Severity, SystemSnapshot


class ModelRole(str, Enum):
    """Defines the role/purpose of different LLM models."""
    PRIMARY = "primary"          # Main reasoning and analysis
    EXPLANATION = "explanation"  # User-facing explanations
    SPECIALIST = "specialist"    # Domain-specific analysis
    VALIDATOR = "validator"      # Result validation and confidence scoring


@dataclass
class ModelConfig:
    """Configuration for a specific LLM model."""
    name: str
    role: ModelRole
    timeout_seconds: int = 30
    temperature: float = 0.1
    max_tokens: int = 2048
    context_length: int = 4096
    system_prompt: str = ""


@dataclass
class AnalysisContext:
    """Context information for AI analysis."""
    system_snapshot: Optional[SystemSnapshot] = None
    recent_logs: List[str] = None
    historical_issues: List[DiagnosticIssue] = None
    performance_metrics: Dict[str, float] = None
    user_environment: Dict[str, str] = None


class LLMEngine:
    """
    Core LLM engine for AI-powered diagnostic analysis.
    
    Provides sophisticated AI integration for:
    - Multi-model orchestration and task distribution
    - Real-time analysis with streaming responses
    - Context-aware diagnosis with historical correlation
    - Intelligent fix generation with confidence scoring
    - Natural language explanation generation
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the LLM engine with configuration.
        
        Args:
            config: Optional configuration dictionary for model settings
        """
        self.console = Console()
        self.logger = logging.getLogger(__name__)
        
        # Default configuration
        self.config = {
            "primary_model": "phi4",
            "explanation_model": "llama3.2", 
            "timeout_seconds": 30,
            "max_context_length": 4096,
            "temperature": 0.1,
            "enable_streaming": True,
            "confidence_threshold": 0.7,
            "max_retries": 3,
        }
        
        if config:
            self.config.update(config)
            
        # Model configurations
        self.models = {
            ModelRole.PRIMARY: ModelConfig(
                name=self.config["primary_model"],
                role=ModelRole.PRIMARY,
                timeout_seconds=self.config["timeout_seconds"],
                temperature=self.config["temperature"],
                system_prompt=self._get_primary_system_prompt()
            ),
            ModelRole.EXPLANATION: ModelConfig(
                name=self.config["explanation_model"], 
                role=ModelRole.EXPLANATION,
                timeout_seconds=self.config["timeout_seconds"],
                temperature=0.3,  # Slightly more creative for explanations
                system_prompt=self._get_explanation_system_prompt()
            )
        }
        
        # Initialize ollama client
        self.client = ollama.Client()
        self._available_models = []
        self._model_health = {}
        
    async def initialize(self) -> bool:
        """
        Initialize the LLM engine and verify model availability.
        
        Returns:
            bool: True if initialization successful, False otherwise
        """
        try:
            # Check ollama service availability
            if not await self._check_ollama_service():
                self.logger.error("Ollama service not available")
                return False
                
            # Discover available models
            await self._discover_models()
            
            # Validate configured models are available
            if not await self._validate_model_availability():
                self.logger.error("Required models not available")
                return False
                
            # Test model responsiveness
            await self._test_model_health()
            
            self.logger.info("LLM engine initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to initialize LLM engine: {e}")
            return False
    
    async def analyze_system_health(self, context: AnalysisContext) -> Dict[str, Any]:
        """
        Perform comprehensive AI analysis of system health.
        
        Args:
            context: System context including snapshots, logs, and metrics
            
        Returns:
            Dict containing health analysis, issues, and recommendations
        """
        self.logger.info("Starting AI-powered system health analysis")
        
        try:
            # Prepare analysis prompt with full context
            analysis_prompt = self._build_health_analysis_prompt(context)
            
            # Execute primary analysis
            primary_analysis = await self._query_model(
                model_role=ModelRole.PRIMARY,
                prompt=analysis_prompt,
                stream=True
            )
            
            if not primary_analysis:
                return {"error": "Primary analysis failed"}
                
            # Parse structured analysis results
            analysis_data = self._parse_analysis_response(primary_analysis)
            
            # Generate user-friendly explanations
            if analysis_data.get("issues"):
                explanations = await self._generate_explanations(
                    analysis_data["issues"], context
                )
                analysis_data["explanations"] = explanations
                
            # Calculate confidence scores
            analysis_data["confidence_score"] = await self._calculate_confidence(
                analysis_data, context
            )
            
            # Generate predictive insights
            analysis_data["predictions"] = await self._generate_predictions(
                context
            )
            
            return analysis_data
            
        except Exception as e:
            self.logger.error(f"System health analysis failed: {e}")
            return {"error": str(e)}
    
    async def diagnose_issue(self, issue_description: str, context: AnalysisContext) -> DiagnosticIssue:
        """
        Use AI to diagnose a specific issue with intelligent analysis.
        
        Args:
            issue_description: Description of the issue to diagnose
            context: System context for informed analysis
            
        Returns:
            DiagnosticIssue with AI-enhanced diagnosis and fix suggestions
        """
        self.logger.info(f"AI diagnosing issue: {issue_description}")
        
        try:
            # Build diagnostic prompt
            diagnostic_prompt = self._build_diagnostic_prompt(issue_description, context)
            
            # Primary diagnosis
            diagnosis = await self._query_model(
                model_role=ModelRole.PRIMARY,
                prompt=diagnostic_prompt
            )
            
            if not diagnosis:
                raise Exception("Primary diagnosis failed")
                
            # Parse diagnosis into structured format
            issue_data = self._parse_diagnostic_response(diagnosis)
            
            # Generate fix suggestions
            fix_suggestions = await self._generate_fix_suggestions(
                issue_data, context
            )
            
            # Get natural language explanation
            explanation = await self._query_model(
                model_role=ModelRole.EXPLANATION,
                prompt=self._build_explanation_prompt(issue_data, context)
            )
            
            # Calculate confidence score
            confidence = await self._assess_diagnostic_confidence(
                issue_data, context
            )
            
            # Create DiagnosticIssue object
            return DiagnosticIssue(
                id=f"ai_{int(time.time())}",
                title=issue_data.get("title", issue_description),
                description=issue_data.get("description", ""),
                severity=Severity(issue_data.get("severity", "warning")),
                category=issue_data.get("category", "unknown"),
                timestamp=datetime.now(),
                affected_components=issue_data.get("affected_components", []),
                fix_available=bool(fix_suggestions),
                fix_command=fix_suggestions.get("command") if fix_suggestions else None,
                fix_description=fix_suggestions.get("description") if fix_suggestions else None,
                ai_analysis=explanation,
                ai_confidence=confidence
            )
            
        except Exception as e:
            self.logger.error(f"Issue diagnosis failed: {e}")
            # Return basic issue object on failure
            return DiagnosticIssue(
                id=f"fallback_{int(time.time())}",
                title=issue_description,
                description="AI diagnosis unavailable",
                severity=Severity.WARNING,
                category="unknown",
                timestamp=datetime.now(),
                ai_confidence=0.0
            )
    
    async def analyze_logs_realtime(self, log_lines: List[str]) -> Dict[str, Any]:
        """
        Perform real-time analysis of log entries for pattern detection.
        
        Args:
            log_lines: Recent log entries to analyze
            
        Returns:
            Dict containing patterns, anomalies, and insights
        """
        if not log_lines:
            return {"patterns": [], "anomalies": [], "insights": []}
            
        try:
            # Build log analysis prompt
            log_prompt = self._build_log_analysis_prompt(log_lines)
            
            # Analyze with primary model
            analysis = await self._query_model(
                model_role=ModelRole.PRIMARY,
                prompt=log_prompt,
                timeout=15  # Shorter timeout for real-time analysis
            )
            
            if analysis:
                return self._parse_log_analysis(analysis)
            else:
                return {"patterns": [], "anomalies": [], "insights": []}
                
        except Exception as e:
            self.logger.error(f"Real-time log analysis failed: {e}")
            return {"error": str(e)}
    
    async def generate_fix_suggestion(self, issue: DiagnosticIssue, context: AnalysisContext) -> Optional[Dict[str, str]]:
        """
        Generate intelligent fix suggestions for a diagnostic issue.
        
        Args:
            issue: The diagnostic issue to generate fixes for
            context: System context for informed fix generation
            
        Returns:
            Dict with fix command, description, and risk assessment
        """
        try:
            fix_prompt = self._build_fix_generation_prompt(issue, context)
            
            fix_response = await self._query_model(
                model_role=ModelRole.PRIMARY,
                prompt=fix_prompt
            )
            
            if fix_response:
                return self._parse_fix_response(fix_response)
            else:
                return None
                
        except Exception as e:
            self.logger.error(f"Fix generation failed: {e}")
            return None
    
    # Private helper methods
    
    async def _check_ollama_service(self) -> bool:
        """Check if Ollama service is running and accessible."""
        try:
            await asyncio.wait_for(
                asyncio.to_thread(self.client.list),
                timeout=5.0
            )
            return True
        except Exception:
            return False
    
    async def _discover_models(self) -> None:
        """Discover available models from Ollama."""
        try:
            models = await asyncio.to_thread(self.client.list)
            self._available_models = [model['name'] for model in models.get('models', [])]
            self.logger.info(f"Discovered models: {self._available_models}")
        except Exception as e:
            self.logger.error(f"Model discovery failed: {e}")
    
    async def _validate_model_availability(self) -> bool:
        """Validate that required models are available."""
        required_models = [
            self.config["primary_model"],
            self.config["explanation_model"]
        ]
        
        for model in required_models:
            if model not in self._available_models:
                self.logger.error(f"Required model not available: {model}")
                return False
        return True
    
    async def _test_model_health(self) -> None:
        """Test responsiveness of configured models."""
        for role, model_config in self.models.items():
            try:
                start_time = time.time()
                response = await self._query_model(
                    model_role=role,
                    prompt="Test message - respond with 'OK'",
                    timeout=10
                )
                response_time = time.time() - start_time
                
                self._model_health[role] = {
                    "available": bool(response),
                    "response_time": response_time,
                    "last_tested": datetime.now()
                }
                
                if response:
                    self.logger.info(f"Model {model_config.name} healthy ({{response_time:.1f}}s)")
                else:
                    self.logger.warning(f"Model {model_config.name} not responding")
                    
            except Exception as e:
                self.logger.error(f"Health test failed for {model_config.name}: {e}")
                self._model_health[role] = {
                    "available": False,
                    "error": str(e),
                    "last_tested": datetime.now()
                }
    
    async def _query_model(self, model_role: ModelRole, prompt: str, 
                          stream: bool = False, timeout: int = None) -> Optional[str]:
        """
        Query a specific model with proper error handling and retries.
        
        Args:
            model_role: Role of the model to query
            prompt: Prompt text to send to the model
            stream: Whether to use streaming response
            timeout: Override default timeout
            
        Returns:
            Model response text or None if failed
        """
        model_config = self.models.get(model_role)
        if not model_config:
            self.logger.error(f"No model configured for role: {model_role}")
            return None
            
        timeout = timeout or model_config.timeout_seconds
        retries = 0
        
        while retries < self.config["max_retries"]:
            try:
                if stream and self.config["enable_streaming"]:
                    return await self._stream_model_response(model_config, prompt, timeout)
                else:
                    return await self._single_model_response(model_config, prompt, timeout)
                    
            except Exception as e:
                retries += 1
                self.logger.warning(f"Model query attempt {retries} failed: {e}")
                if retries >= self.config["max_retries"]:
                    self.logger.error(f"Model query failed after {retries} attempts")
                    return None
                await asyncio.sleep(1 * retries)  # Exponential backoff
        
        return None
    
    async def _stream_model_response(self, model_config: ModelConfig, 
                                   prompt: str, timeout: int) -> str:
        """Handle streaming model response with real-time display."""
        full_response = ""
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=self.console
        ) as progress:
            task = progress.add_task(f"AI analysis with {model_config.name}...", total=None)
            
            async def stream_generator():
                response = await asyncio.to_thread(
                    self.client.chat,
                    model=model_config.name,
                    messages=[{
                        'role': 'system',
                        'content': model_config.system_prompt
                    }, {
                        'role': 'user', 
                        'content': prompt
                    }],
                    stream=True,
                    options={
                        'temperature': model_config.temperature,
                        'num_predict': model_config.max_tokens
                    }
                )
                
                for chunk in response:
                    if chunk.get('message', {}).get('content'):
                        yield chunk['message']['content']
            
            try:
                async for chunk in asyncio.wait_for(stream_generator(), timeout=timeout):
                    full_response += chunk
                    progress.update(task, description=f"AI thinking... ({len(full_response)} chars)")
                    
            except asyncio.TimeoutError:
                self.logger.error(f"Streaming response timed out after {timeout}s")
                if full_response:
                    return full_response  # Return partial response
                raise
                
        return full_response
    
    async def _single_model_response(self, model_config: ModelConfig, 
                                   prompt: str, timeout: int) -> str:
        """Handle single model response without streaming."""
        response = await asyncio.wait_for(
            asyncio.to_thread(
                self.client.chat,
                model=model_config.name,
                messages=[{
                    'role': 'system',
                    'content': model_config.system_prompt
                }, {
                    'role': 'user',
                    'content': prompt
                }],
                options={
                    'temperature': model_config.temperature,
                    'num_predict': model_config.max_tokens
                }
            ),
            timeout=timeout
        )
        
        return response.get('message', {}).get('content', '')
    
    def _get_primary_system_prompt(self) -> str:
        """Get system prompt for primary reasoning model."""
        return """You are an expert Linux system diagnostic AI specializing in AI-enhanced theming systems on Arch Linux with Hyprland.

Your role:
- Analyze system logs, metrics, and configurations for issues
- Identify root causes of theming, AI, and performance problems  
- Detect patterns and correlations across different system components
- Provide structured technical analysis with confidence ratings
- Focus on: Wayland/Hyprland, Waybar, matugen, Ollama, AI models, color generation

Always respond in JSON format with structured analysis. Be precise, technical, and evidence-based."""
    
    def _get_explanation_system_prompt(self) -> str:
        """Get system prompt for explanation model."""
        return """You are a friendly technical assistant that explains complex Linux system issues in clear, understandable language.

Your role:
- Translate technical diagnostics into user-friendly explanations
- Provide step-by-step guidance for fixing issues
- Explain why problems occur and how to prevent them
- Use clear language while maintaining technical accuracy
- Focus on actionable advice for users

Always be helpful, clear, and encouraging. Explain technical concepts in accessible terms."""
    
    def _build_health_analysis_prompt(self, context: AnalysisContext) -> str:
        """Build comprehensive prompt for system health analysis."""
        # This would be a complex prompt builder incorporating all context
        return f"""Analyze the health of this AI theming system:

SYSTEM SNAPSHOT:
{json.dumps(context.system_snapshot.dict() if context.system_snapshot else {}, indent=2)}

RECENT LOGS:
{chr(10).join(context.recent_logs[:20] if context.recent_logs else [])}

HISTORICAL ISSUES:
{len(context.historical_issues or [])} previous issues detected

PERFORMANCE METRICS:
{json.dumps(context.performance_metrics or {}, indent=2)}

Provide JSON analysis with: health_score, critical_issues, warnings, recommendations, trend_analysis."""
    
    def _build_diagnostic_prompt(self, issue_description: str, context: AnalysisContext) -> str:
        """Build focused prompt for specific issue diagnosis."""
        return f"""Diagnose this specific issue in an AI theming system:

ISSUE: {issue_description}

CONTEXT: {json.dumps(context.system_snapshot.dict() if context.system_snapshot else {}, indent=2)}

Provide JSON with: title, description, severity, category, root_cause, affected_components."""
    
    def _build_log_analysis_prompt(self, log_lines: List[str]) -> str:
        """Build prompt for real-time log analysis."""
        return f"""Analyze these log entries for patterns and anomalies:

LOGS:
{chr(10).join(log_lines)}

Provide JSON with: patterns, anomalies, insights, urgency_level."""
    
    def _build_fix_generation_prompt(self, issue: DiagnosticIssue, context: AnalysisContext) -> str:
        """Build prompt for generating fix suggestions."""
        return f"""Generate a fix for this diagnostic issue:

ISSUE: {issue.dict()}
CONTEXT: {json.dumps(context.system_snapshot.dict() if context.system_snapshot else {}, indent=2)}

Provide JSON with: command, description, risk_level, prerequisites, verification_steps."""
    
    def _build_explanation_prompt(self, issue_data: Dict, context: AnalysisContext) -> str:
        """Build prompt for user-friendly explanations."""
        return f"""Explain this technical issue in user-friendly terms:

ISSUE: {json.dumps(issue_data, indent=2)}

Provide a clear explanation of what's wrong, why it happened, and how to fix it."""
    
    # Response parsing methods
    
    def _parse_analysis_response(self, response: str) -> Dict[str, Any]:
        """Parse health analysis response into structured data."""
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            # Fallback parsing for non-JSON responses
            return {"raw_response": response, "parse_error": True}
    
    def _parse_diagnostic_response(self, response: str) -> Dict[str, Any]:
        """Parse diagnostic response into structured data."""
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            return {"title": "Parse Error", "description": response}
    
    def _parse_log_analysis(self, response: str) -> Dict[str, Any]:
        """Parse log analysis response."""
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            return {"patterns": [], "anomalies": [], "insights": [response]}
    
    def _parse_fix_response(self, response: str) -> Dict[str, str]:
        """Parse fix generation response."""
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            return {"description": response}
    
    # Additional helper methods for advanced AI features
    
    async def _generate_explanations(self, issues: List[Dict], context: AnalysisContext) -> List[str]:
        """Generate user-friendly explanations for detected issues."""
        explanations = []
        for issue in issues[:3]:  # Limit to prevent overload
            explanation = await self._query_model(
                model_role=ModelRole.EXPLANATION,
                prompt=self._build_explanation_prompt(issue, context),
                timeout=15
            )
            if explanation:
                explanations.append(explanation)
        return explanations
    
    async def _calculate_confidence(self, analysis_data: Dict, context: AnalysisContext) -> float:
        """Calculate AI confidence score for analysis."""
        # Implement confidence calculation based on various factors
        base_confidence = 0.5
        
        # Boost confidence if we have good context
        if context.system_snapshot:
            base_confidence += 0.2
        if context.recent_logs:
            base_confidence += 0.1
        if context.historical_issues:
            base_confidence += 0.1
            
        # Cap at reasonable maximum
        return min(base_confidence, 0.9)
    
    async def _generate_predictions(self, context: AnalysisContext) -> List[Dict[str, Any]]:
        """Generate predictive insights about system health."""
        if not context.historical_issues:
            return []
            
        prediction_prompt = f"""Based on historical data, predict potential future issues:

HISTORICAL ISSUES: {len(context.historical_issues)} issues in recent history
PERFORMANCE TRENDS: {json.dumps(context.performance_metrics or {}, indent=2)}

Provide JSON array of predictions with: prediction, probability, timeframe, prevention."""
        
        try:
            predictions = await self._query_model(
                model_role=ModelRole.PRIMARY,
                prompt=prediction_prompt,
                timeout=20
            )
            
            if predictions:
                return json.loads(predictions)
        except Exception as e:
            self.logger.error(f"Prediction generation failed: {e}")
            
        return []
    
    async def _generate_fix_suggestions(self, issue_data: Dict, context: AnalysisContext) -> Optional[Dict[str, str]]:
        """Generate fix suggestions for diagnosed issue."""
        fix_prompt = self._build_fix_generation_prompt(
            DiagnosticIssue(**issue_data), context
        )
        
        fix_response = await self._query_model(
            model_role=ModelRole.PRIMARY,
            prompt=fix_prompt
        )
        
        if fix_response:
            return self._parse_fix_response(fix_response)
        return None
    
    async def _assess_diagnostic_confidence(self, issue_data: Dict, context: AnalysisContext) -> float:
        """Assess confidence in diagnostic accuracy."""
        # Implement sophisticated confidence assessment
        base_confidence = 0.6
        
        # Increase confidence based on context quality
        if context.system_snapshot and context.recent_logs:
            base_confidence += 0.2
        if issue_data.get("root_cause"):
            base_confidence += 0.1
        if context.historical_issues:
            base_confidence += 0.1
            
        return min(base_confidence, 0.95)
    
    def get_model_health(self) -> Dict[str, Any]:
        """Get current health status of all configured models."""
        return self._model_health.copy()
    
    def get_available_models(self) -> List[str]:
        """Get list of available models."""
        return self._available_models.copy() 