#!/usr/bin/env python3
"""
AI Provider Interface for GPTDiag

Defines the base interface that all AI providers must implement.
Supports multiple AI models with specialized roles for different tasks.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any, AsyncGenerator
from dataclasses import dataclass
from enum import Enum
import asyncio


class ModelRole(Enum):
    """Predefined roles for different AI models."""
    GENERAL = "general"              # General purpose analysis
    DIAGNOSTICS = "diagnostics"      # Fast system diagnostics
    CODING = "coding"               # Code generation and fixes
    VISION = "vision"               # Visual analysis (screenshots, etc.)
    FAST = "fast"                   # Quick responses


@dataclass
class AIRequest:
    """Represents a request to an AI model."""
    prompt: str
    model_role: ModelRole = ModelRole.GENERAL
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None
    context: Optional[Dict[str, Any]] = None
    system_prompt: Optional[str] = None
    stream: bool = False


@dataclass 
class AIResponse:
    """Represents a response from an AI model."""
    content: str
    model_used: str
    tokens_used: Optional[int] = None
    response_time: Optional[float] = None
    cost: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class AIProvider(ABC):
    """Abstract base class for AI providers."""
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize the AI provider with configuration."""
        self.config = config
        self.enabled = config.get("enabled", False)
        self.models = config.get("models", {})
        self.model_configs = config.get("model_configs", {})
        
    @abstractmethod
    async def initialize(self) -> bool:
        """Initialize the provider and check connectivity.
        
        Returns:
            True if initialization successful, False otherwise
        """
        pass
    
    @abstractmethod
    async def is_available(self) -> bool:
        """Check if the provider is available and responsive.
        
        Returns:
            True if provider is available, False otherwise
        """
        pass
    
    @abstractmethod
    async def list_models(self) -> List[str]:
        """Get list of available models.
        
        Returns:
            List of model names
        """
        pass
    
    @abstractmethod
    async def generate(self, request: AIRequest) -> AIResponse:
        """Generate a response from the AI model.
        
        Args:
            request: The AI request containing prompt and parameters
            
        Returns:
            AI response containing generated content
        """
        pass
    
    @abstractmethod
    async def stream_generate(self, request: AIRequest) -> AsyncGenerator[str, None]:
        """Generate a streaming response from the AI model.
        
        Args:
            request: The AI request containing prompt and parameters
            
        Yields:
            Chunks of generated text
        """
        pass
    
    def get_model_for_role(self, role: ModelRole) -> Optional[str]:
        """Get the best model for a specific role.
        
        Args:
            role: The role/task type
            
        Returns:
            Model name or None if no suitable model found
        """
        role_key = role.value
        return self.models.get(role_key)
    
    def get_model_config(self, model_name: str) -> Dict[str, Any]:
        """Get configuration for a specific model.
        
        Args:
            model_name: Name of the model
            
        Returns:
            Model configuration dictionary
        """
        return self.model_configs.get(model_name, {})
    
    def is_model_suitable_for_task(self, model_name: str, task: str) -> bool:
        """Check if a model is suitable for a specific task.
        
        Args:
            model_name: Name of the model
            task: Task type to check
            
        Returns:
            True if model is suitable for the task
        """
        model_config = self.get_model_config(model_name)
        suitable_tasks = model_config.get("use_for", [])
        return task in suitable_tasks
    
    async def health_check(self) -> Dict[str, Any]:
        """Perform a health check on the provider.
        
        Returns:
            Health check results
        """
        try:
            is_available = await self.is_available()
            models = await self.list_models() if is_available else []
            
            return {
                "provider": self.__class__.__name__,
                "available": is_available,
                "enabled": self.enabled,
                "models_count": len(models),
                "models": models,
                "configured_roles": list(self.models.keys())
            }
        except Exception as e:
            return {
                "provider": self.__class__.__name__,
                "available": False,
                "enabled": self.enabled,
                "error": str(e)
            }
    
    async def analyze_system_data(self, 
                                system_data: Dict[str, Any], 
                                analysis_type: str = "general") -> AIResponse:
        """Analyze system data using appropriate AI model.
        
        Args:
            system_data: System information to analyze
            analysis_type: Type of analysis to perform
            
        Returns:
            AI analysis response
        """
        # Determine best model for analysis
        if analysis_type == "quick":
            role = ModelRole.FAST
        elif analysis_type == "diagnostics":
            role = ModelRole.DIAGNOSTICS
        else:
            role = ModelRole.GENERAL
        
        # Format system data for analysis
        prompt = self._format_system_data_prompt(system_data, analysis_type)
        
        request = AIRequest(
            prompt=prompt,
            model_role=role,
            temperature=0.2,  # Lower temperature for more focused analysis
            context={"analysis_type": analysis_type, "system_data": system_data}
        )
        
        return await self.generate(request)
    
    async def generate_fix_suggestion(self, 
                                   issue_description: str, 
                                   system_context: Dict[str, Any]) -> AIResponse:
        """Generate a fix suggestion for a system issue.
        
        Args:
            issue_description: Description of the issue
            system_context: Relevant system context
            
        Returns:
            AI response with fix suggestions
        """
        prompt = f"""System Issue: {issue_description}

System Context:
{self._format_system_context(system_context)}

Provide a safe, step-by-step solution to fix this issue. Include:
1. Root cause analysis
2. Recommended fix commands
3. Risk assessment
4. Verification steps
5. Rollback plan if needed

Focus on Arch Linux commands and best practices."""

        request = AIRequest(
            prompt=prompt,
            model_role=ModelRole.CODING,
            temperature=0.1,  # Very conservative for fixes
            context={"issue": issue_description, "system": system_context}
        )
        
        return await self.generate(request)
    
    def _format_system_data_prompt(self, system_data: Dict[str, Any], analysis_type: str) -> str:
        """Format system data into a prompt for AI analysis."""
        prompt_parts = [f"Perform {analysis_type} analysis of this Linux system:"]
        
        # Add system metrics
        if "cpu" in system_data:
            prompt_parts.append(f"CPU Usage: {system_data['cpu'].get('percent', 0)}%")
        
        if "memory" in system_data:
            mem = system_data['memory']
            prompt_parts.append(f"Memory: {mem.get('percent', 0)}% ({mem.get('used', 0):.1f}GB/{mem.get('total', 0):.1f}GB)")
        
        if "disk" in system_data:
            for disk in system_data.get('disk', []):
                prompt_parts.append(f"Disk {disk.get('device', 'unknown')}: {disk.get('percent', 0)}%")
        
        if "processes" in system_data:
            prompt_parts.append(f"Active Processes: {len(system_data['processes'])}")
        
        if "services" in system_data:
            failed_services = [s for s in system_data['services'] if s.get('status') == 'failed']
            if failed_services:
                prompt_parts.append(f"Failed Services: {len(failed_services)}")
        
        prompt_parts.append("\nProvide analysis, identify issues, and suggest improvements.")
        return "\n".join(prompt_parts)
    
    def _format_system_context(self, context: Dict[str, Any]) -> str:
        """Format system context for prompts."""
        context_parts = []
        
        for key, value in context.items():
            if isinstance(value, dict):
                context_parts.append(f"{key.title()}:")
                for sub_key, sub_value in value.items():
                    context_parts.append(f"  {sub_key}: {sub_value}")
            else:
                context_parts.append(f"{key.title()}: {value}")
        
        return "\n".join(context_parts) 