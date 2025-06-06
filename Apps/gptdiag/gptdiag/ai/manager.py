#!/usr/bin/env python3
"""
AI Manager for GPTDiag

Coordinates multiple AI providers and provides a unified interface
for AI-powered system analysis and automation.
"""

import asyncio
from typing import Dict, List, Optional, Any, Union
from datetime import datetime, timedelta
import json

from .providers import AIProvider, AIRequest, AIResponse, ModelRole
from .ollama import OllamaProvider


class AIManager:
    """Manages multiple AI providers and provides unified AI interface."""
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize AI manager with configuration."""
        self.config = config
        self.providers: Dict[str, AIProvider] = {}
        self.primary_provider: Optional[str] = None
        self.fallback_provider: Optional[str] = None
        
        # AI features configuration
        self.features = config.get("features", {})
        self.auto_model_selection = config.get("auto_model_selection", True)
        self.multi_model_consensus = self.features.get("multi_model_consensus", False)
        
        # Analysis history for learning
        self.analysis_history: List[Dict[str, Any]] = []
        self.max_history = 100
        
        # Performance tracking
        self.provider_stats: Dict[str, Dict[str, Any]] = {}
    
    async def initialize(self) -> bool:
        """Initialize all configured AI providers."""
        ai_config = self.config.get("ai", {})
        
        # Initialize Ollama provider (primary)
        if self.config.get("ollama", {}).get("enabled", False):
            try:
                ollama_provider = OllamaProvider(self.config["ollama"])
                if await ollama_provider.initialize():
                    self.providers["ollama"] = ollama_provider
                    self.primary_provider = "ollama"
                    print("✅ Ollama provider initialized")
                else:
                    print("⚠️  Ollama provider failed to initialize")
            except Exception as e:
                print(f"❌ Ollama provider error: {e}")
        
        # TODO: Initialize other providers (OpenAI, Anthropic) as fallbacks
        
        # Set fallback provider
        self.fallback_provider = ai_config.get("fallback_provider")
        
        # Initialize provider statistics
        for provider_name in self.providers:
            self.provider_stats[provider_name] = {
                "requests": 0,
                "successes": 0,
                "failures": 0,
                "avg_response_time": 0.0,
                "total_tokens": 0,
                "last_used": None
            }
        
        return len(self.providers) > 0
    
    async def analyze_system_health(self, system_data: Dict[str, Any]) -> AIResponse:
        """Analyze system health using AI."""
        if not self.providers:
            return AIResponse(
                content="AI analysis unavailable",
                model_used="none",
                error="No AI providers available"
            )
        
        prompt = f"""Analyze this Arch Linux system's health:

System Information:
{self._format_system_data(system_data)}

Identify any critical issues and provide recommendations."""
        
        request = AIRequest(
            prompt=prompt,
            model_role=ModelRole.DIAGNOSTICS,
            temperature=0.2,
            max_tokens=2048
        )
        
        provider = self.providers[self.primary_provider]
        return await provider.generate(request)
    
    async def suggest_performance_improvements(self, system_data: Dict[str, Any]) -> AIResponse:
        """Suggest performance improvements using AI."""
        if not self.is_available():
            return AIResponse(
                content="AI suggestions unavailable - no providers active",
                model_used="none",
                error="No AI providers available"
            )
        
        prompt = self._build_performance_prompt(system_data)
        request = AIRequest(
            prompt=prompt,
            model_role=ModelRole.GENERAL,
            temperature=0.3,
            max_tokens=2048,
            context={
                "analysis_type": "performance_optimization",
                "system_data": system_data
            }
        )
        
        response = await self._generate_with_fallback(request)
        
        if not response.error:
            self._add_to_history("performance_suggestions", request, response, system_data)
        
        return response
    
    async def generate_fix_commands(self, issue: str, context: Dict[str, Any]) -> AIResponse:
        """Generate fix commands for a system issue."""
        if not self.is_available():
            return AIResponse(
                content="AI fix generation unavailable - no providers active",
                model_used="none",
                error="No AI providers available"
            )
        
        prompt = self._build_fix_prompt(issue, context)
        request = AIRequest(
            prompt=prompt,
            model_role=ModelRole.CODING,
            temperature=0.1,  # Very conservative for command generation
            max_tokens=1024,
            context={
                "analysis_type": "fix_generation",
                "issue": issue,
                "context": context
            }
        )
        
        response = await self._generate_with_fallback(request)
        
        if not response.error:
            self._add_to_history("fix_generation", request, response, {"issue": issue, "context": context})
        
        return response
    
    async def analyze_logs(self, log_entries: List[str], max_entries: int = 50) -> AIResponse:
        """Analyze system logs using AI."""
        if not self.is_available():
            return AIResponse(
                content="AI log analysis unavailable - no providers active",
                model_used="none",
                error="No AI providers available"
            )
        
        # Limit log entries to prevent token overflow
        limited_logs = log_entries[-max_entries:] if len(log_entries) > max_entries else log_entries
        
        prompt = self._build_log_analysis_prompt(limited_logs)
        request = AIRequest(
            prompt=prompt,
            model_role=ModelRole.DIAGNOSTICS,
            temperature=0.2,
            max_tokens=1536,
            context={
                "analysis_type": "log_analysis",
                "log_count": len(limited_logs)
            }
        )
        
        response = await self._generate_with_fallback(request)
        
        if not response.error:
            self._add_to_history("log_analysis", request, response, {"log_count": len(limited_logs)})
        
        return response
    
    async def quick_diagnosis(self, metrics: Dict[str, Any]) -> AIResponse:
        """Perform quick AI diagnosis of system metrics."""
        if not self.is_available():
            return AIResponse(
                content="Quick diagnosis unavailable - no providers active",
                model_used="none",
                error="No AI providers available"
            )
        
        prompt = self._build_quick_diagnosis_prompt(metrics)
        request = AIRequest(
            prompt=prompt,
            model_role=ModelRole.FAST,
            temperature=0.2,
            max_tokens=512,  # Quick response
            context={
                "analysis_type": "quick_diagnosis",
                "metrics": metrics
            }
        )
        
        return await self._generate_with_fallback(request)
    
    async def chat_about_system(self, user_message: str, system_context: Dict[str, Any]) -> AIResponse:
        """Chat about system issues with AI assistant."""
        if not self.is_available():
            return AIResponse(
                content="AI chat unavailable - no providers active",
                model_used="none",
                error="No AI providers available"
            )
        
        prompt = self._build_chat_prompt(user_message, system_context)
        request = AIRequest(
            prompt=prompt,
            model_role=ModelRole.GENERAL,
            temperature=0.4,  # More conversational
            max_tokens=1024,
            context={
                "analysis_type": "chat",
                "user_message": user_message,
                "system_context": system_context
            }
        )
        
        return await self._generate_with_fallback(request)
    
    def is_available(self) -> bool:
        """Check if any AI provider is available."""
        return len(self.providers) > 0 and any(
            provider.enabled for provider in self.providers.values()
        )
    
    async def get_provider_status(self) -> Dict[str, Any]:
        """Get status of all AI providers."""
        status = {
            "available": self.is_available(),
            "primary_provider": self.primary_provider,
            "fallback_provider": self.fallback_provider,
            "providers": {},
            "statistics": self.provider_stats.copy(),
            "features": self.features,
            "history_count": len(self.analysis_history)
        }
        
        for name, provider in self.providers.items():
            health = await provider.health_check()
            status["providers"][name] = health
        
        return status
    
    def get_analysis_insights(self) -> Dict[str, Any]:
        """Get insights from analysis history."""
        if not self.analysis_history:
            return {"insights": "No analysis history available"}
        
        # Basic statistics
        total_analyses = len(self.analysis_history)
        analysis_types = {}
        successful_analyses = 0
        
        for entry in self.analysis_history:
            analysis_type = entry.get("type", "unknown")
            analysis_types[analysis_type] = analysis_types.get(analysis_type, 0) + 1
            
            if not entry.get("response", {}).get("error"):
                successful_analyses += 1
        
        success_rate = (successful_analyses / total_analyses) * 100 if total_analyses > 0 else 0
        
        return {
            "total_analyses": total_analyses,
            "success_rate": f"{success_rate:.1f}%",
            "analysis_types": analysis_types,
            "most_common_analysis": max(analysis_types.items(), key=lambda x: x[1])[0] if analysis_types else None,
            "recent_activity": self.analysis_history[-5:] if len(self.analysis_history) >= 5 else self.analysis_history
        }
    
    async def _generate_with_fallback(self, request: AIRequest) -> AIResponse:
        """Generate response with fallback to other providers."""
        # Try primary provider first
        if self.primary_provider and self.primary_provider in self.providers:
            try:
                provider = self.providers[self.primary_provider]
                response = await provider.generate(request)
                self._update_provider_stats(self.primary_provider, response)
                
                if not response.error:
                    return response
                    
            except Exception as e:
                print(f"Primary provider {self.primary_provider} failed: {e}")
        
        # Try fallback provider
        if (self.fallback_provider and 
            self.fallback_provider in self.providers and 
            self.fallback_provider != self.primary_provider):
            try:
                provider = self.providers[self.fallback_provider]
                response = await provider.generate(request)
                self._update_provider_stats(self.fallback_provider, response)
                return response
                
            except Exception as e:
                print(f"Fallback provider {self.fallback_provider} failed: {e}")
        
        # Try any remaining provider
        for name, provider in self.providers.items():
            if name not in [self.primary_provider, self.fallback_provider]:
                try:
                    response = await provider.generate(request)
                    self._update_provider_stats(name, response)
                    return response
                except Exception as e:
                    print(f"Provider {name} failed: {e}")
        
        # All providers failed
        return AIResponse(
            content="",
            model_used="none",
            error="All AI providers failed to respond"
        )
    
    def _update_provider_stats(self, provider_name: str, response: AIResponse):
        """Update statistics for a provider."""
        if provider_name not in self.provider_stats:
            self.provider_stats[provider_name] = {
                "requests": 0, "successes": 0, "failures": 0,
                "avg_response_time": 0.0, "total_tokens": 0, "last_used": None
            }
        
        stats = self.provider_stats[provider_name]
        stats["requests"] += 1
        stats["last_used"] = datetime.now().isoformat()
        
        if response.error:
            stats["failures"] += 1
        else:
            stats["successes"] += 1
            
            if response.response_time:
                # Update average response time
                current_avg = stats["avg_response_time"]
                new_avg = ((current_avg * (stats["successes"] - 1)) + response.response_time) / stats["successes"]
                stats["avg_response_time"] = new_avg
            
            if response.tokens_used:
                stats["total_tokens"] += response.tokens_used
    
    def _add_to_history(self, analysis_type: str, request: AIRequest, response: AIResponse, data: Dict[str, Any]):
        """Add analysis to history."""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "type": analysis_type,
            "request": {
                "model_role": request.model_role.value,
                "prompt_length": len(request.prompt),
                "temperature": request.temperature,
                "max_tokens": request.max_tokens
            },
            "response": {
                "model_used": response.model_used,
                "content_length": len(response.content),
                "tokens_used": response.tokens_used,
                "response_time": response.response_time,
                "error": response.error
            },
            "data_summary": self._summarize_data(data)
        }
        
        self.analysis_history.append(entry)
        
        # Keep only recent history
        if len(self.analysis_history) > self.max_history:
            self.analysis_history = self.analysis_history[-self.max_history:]
    
    def _summarize_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a summary of data for history storage."""
        summary = {}
        
        for key, value in data.items():
            if isinstance(value, dict):
                summary[key] = f"dict with {len(value)} keys"
            elif isinstance(value, list):
                summary[key] = f"list with {len(value)} items"
            elif isinstance(value, str) and len(value) > 100:
                summary[key] = f"string ({len(value)} chars)"
            else:
                summary[key] = str(value)[:50]  # Truncate long values
        
        return summary
    
    # Prompt building methods
    
    def _build_health_analysis_prompt(self, system_data: Dict[str, Any]) -> str:
        """Build prompt for system health analysis."""
        return f"""Analyze this Arch Linux system's health and identify any issues:

System Information:
{self._format_system_data(system_data)}

Provide analysis focusing on:
1. Critical issues requiring immediate attention
2. Performance concerns
3. Security considerations
4. Resource usage patterns
5. Specific recommendations for Arch Linux

Keep the response concise but comprehensive."""
    
    def _build_performance_prompt(self, system_data: Dict[str, Any]) -> str:
        """Build prompt for performance optimization suggestions."""
        return f"""Analyze this Arch Linux system for performance optimization opportunities:

System Data:
{self._format_system_data(system_data)}

Suggest improvements for:
1. CPU performance and utilization
2. Memory management optimization
3. Disk I/O improvements
4. Network performance tuning
5. Arch-specific optimizations (pacman, systemd, etc.)

Provide specific, actionable recommendations with commands when appropriate."""
    
    def _build_fix_prompt(self, issue: str, context: Dict[str, Any]) -> str:
        """Build prompt for fix command generation."""
        return f"""Generate safe bash commands to fix this Arch Linux system issue:

Issue: {issue}

System Context:
{json.dumps(context, indent=2)}

Requirements:
- Use Arch Linux commands (pacman, systemctl, journalctl, etc.)
- Provide safe, well-commented commands
- Explain what each command does
- Include verification steps
- Consider potential risks and rollback options

Generate the fix commands:"""
    
    def _build_log_analysis_prompt(self, log_entries: List[str]) -> str:
        """Build prompt for log analysis."""
        logs_text = "\n".join(log_entries[-20:])  # Last 20 entries
        
        return f"""Analyze these recent system log entries for issues:

Log Entries:
{logs_text}

Focus on:
1. Error messages and failures
2. Security-related events
3. Performance issues
4. Unusual patterns or anomalies
5. Recommended actions

Provide a concise analysis with specific recommendations."""
    
    def _build_quick_diagnosis_prompt(self, metrics: Dict[str, Any]) -> str:
        """Build prompt for quick diagnosis."""
        return f"""Quick diagnosis of these system metrics:

{self._format_system_data(metrics)}

Provide a brief assessment (2-3 sentences) highlighting the most critical issues if any."""
    
    def _build_chat_prompt(self, user_message: str, system_context: Dict[str, Any]) -> str:
        """Build prompt for chat interaction."""
        return f"""You are an expert Arch Linux system administrator assistant. The user is asking about their system.

User Question: {user_message}

Current System Context:
{self._format_system_data(system_context)}

Provide a helpful, informative response about the system. Be conversational but technical when appropriate."""
    
    def _format_system_data(self, data: Dict[str, Any]) -> str:
        """Format system data for prompts."""
        if not data:
            return "No system data available"
        
        formatted_parts = []
        
        for key, value in data.items():
            if isinstance(value, dict):
                formatted_parts.append(f"{key.title()}:")
                for sub_key, sub_value in value.items():
                    formatted_parts.append(f"  {sub_key}: {sub_value}")
            elif isinstance(value, list) and len(value) > 0:
                formatted_parts.append(f"{key.title()}: {len(value)} items")
                if isinstance(value[0], dict):
                    # Show first few items
                    for i, item in enumerate(value[:3]):
                        formatted_parts.append(f"  [{i}]: {item}")
                    if len(value) > 3:
                        formatted_parts.append(f"  ... and {len(value) - 3} more")
            else:
                formatted_parts.append(f"{key.title()}: {value}")
        
        return "\n".join(formatted_parts)
    
    async def close(self):
        """Close all AI providers."""
        for provider in self.providers.values():
            if hasattr(provider, 'close'):
                await provider.close() 