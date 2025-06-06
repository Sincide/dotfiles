#!/usr/bin/env python3
"""
Ollama Provider for GPTDiag

Implements AI provider interface for Ollama local models.
Connects to localhost:11434 and supports the user's available models.
"""

import json
import time
import asyncio
from typing import Dict, List, Optional, Any, AsyncGenerator
import aiohttp
from aiohttp import ClientTimeout, ClientError

from .providers import AIProvider, AIRequest, AIResponse, ModelRole


class OllamaProvider(AIProvider):
    """Ollama local model provider implementation."""
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize Ollama provider with configuration."""
        super().__init__(config)
        
        # Ollama-specific configuration
        self.base_url = config.get("base_url", "http://localhost:11434")
        self.timeout = config.get("timeout", 45)
        self.keep_alive = config.get("keep_alive", "5m")
        
        # HTTP session for connection pooling
        self._session: Optional[aiohttp.ClientSession] = None
        self._connected_models: List[str] = []
    
    async def initialize(self) -> bool:
        """Initialize the Ollama provider and verify connectivity."""
        try:
            # Create HTTP session with timeout
            timeout = ClientTimeout(total=self.timeout)
            self._session = aiohttp.ClientSession(timeout=timeout)
            
            # Test connection and get available models
            available = await self.is_available()
            if available:
                self._connected_models = await self.list_models()
                print(f"✅ Ollama connected: {len(self._connected_models)} models available")
                return True
            else:
                print("❌ Ollama connection failed")
                return False
                
        except Exception as e:
            print(f"❌ Ollama initialization error: {e}")
            return False
    
    async def is_available(self) -> bool:
        """Check if Ollama is available and responsive."""
        if not self._session:
            return False
            
        try:
            async with self._session.get(f"{self.base_url}/api/tags") as response:
                return response.status == 200
        except Exception:
            return False
    
    async def list_models(self) -> List[str]:
        """Get list of available models from Ollama."""
        if not self._session:
            return []
        
        try:
            async with self._session.get(f"{self.base_url}/api/tags") as response:
                if response.status == 200:
                    data = await response.json()
                    models = [model["name"] for model in data.get("models", [])]
                    return models
                return []
        except Exception as e:
            print(f"Error listing Ollama models: {e}")
            return []
    
    async def generate(self, request: AIRequest) -> AIResponse:
        """Generate a response using Ollama."""
        start_time = time.time()
        
        try:
            # Select appropriate model for the request
            model_name = self._select_model_for_request(request)
            if not model_name:
                return AIResponse(
                    content="",
                    model_used="none",
                    error="No suitable model available for this request"
                )
            
            # Prepare request payload
            payload = self._build_request_payload(request, model_name)
            
            # Make request to Ollama
            async with self._session.post(
                f"{self.base_url}/api/generate",
                json=payload
            ) as response:
                
                if response.status != 200:
                    error_text = await response.text()
                    return AIResponse(
                        content="",
                        model_used=model_name,
                        error=f"Ollama API error: {response.status} - {error_text}"
                    )
                
                # Collect response chunks
                content_parts = []
                total_tokens = 0
                
                async for line in response.content:
                    if line:
                        try:
                            chunk = json.loads(line.decode('utf-8'))
                            
                            if chunk.get("response"):
                                content_parts.append(chunk["response"])
                            
                            if chunk.get("eval_count"):
                                total_tokens += chunk["eval_count"]
                            
                            # Check if generation is complete
                            if chunk.get("done", False):
                                break
                                
                        except json.JSONDecodeError:
                            continue
                
                response_time = time.time() - start_time
                content = "".join(content_parts)
                
                return AIResponse(
                    content=content,
                    model_used=model_name,
                    tokens_used=total_tokens,
                    response_time=response_time,
                    metadata={
                        "provider": "ollama",
                        "role": request.model_role.value,
                        "temperature": payload.get("options", {}).get("temperature"),
                        "context_length": len(request.prompt)
                    }
                )
                
        except Exception as e:
            response_time = time.time() - start_time
            return AIResponse(
                content="",
                model_used=model_name if 'model_name' in locals() else "unknown",
                response_time=response_time,
                error=f"Generation error: {str(e)}"
            )
    
    async def stream_generate(self, request: AIRequest) -> AsyncGenerator[str, None]:
        """Generate a streaming response using Ollama."""
        try:
            # Select appropriate model for the request
            model_name = self._select_model_for_request(request)
            if not model_name:
                yield f"Error: No suitable model available for this request"
                return
            
            # Prepare request payload with streaming enabled
            payload = self._build_request_payload(request, model_name)
            payload["stream"] = True
            
            # Make streaming request to Ollama
            async with self._session.post(
                f"{self.base_url}/api/generate",
                json=payload
            ) as response:
                
                if response.status != 200:
                    error_text = await response.text()
                    yield f"Error: Ollama API error: {response.status} - {error_text}"
                    return
                
                # Stream response chunks
                async for line in response.content:
                    if line:
                        try:
                            chunk = json.loads(line.decode('utf-8'))
                            
                            if chunk.get("response"):
                                yield chunk["response"]
                            
                            # Check if generation is complete
                            if chunk.get("done", False):
                                break
                                
                        except json.JSONDecodeError:
                            continue
                            
        except Exception as e:
            yield f"Error: Streaming generation failed: {str(e)}"
    
    async def chat_with_context(self, 
                              messages: List[Dict[str, str]], 
                              model_role: ModelRole = ModelRole.GENERAL) -> AIResponse:
        """Chat with context using Ollama's chat API."""
        start_time = time.time()
        
        try:
            model_name = self.get_model_for_role(model_role)
            if not model_name:
                return AIResponse(
                    content="",
                    model_used="none",
                    error="No suitable model available for chat"
                )
            
            # Prepare chat payload
            payload = {
                "model": model_name,
                "messages": messages,
                "stream": False,
                "keep_alive": self.keep_alive
            }
            
            # Add model-specific options
            model_config = self.get_model_config(model_name)
            if model_config:
                options = {}
                if "temperature" in model_config:
                    options["temperature"] = model_config["temperature"]
                if "max_tokens" in model_config:
                    options["num_predict"] = model_config["max_tokens"]
                
                if options:
                    payload["options"] = options
            
            # Make chat request
            async with self._session.post(
                f"{self.base_url}/api/chat",
                json=payload
            ) as response:
                
                if response.status != 200:
                    error_text = await response.text()
                    return AIResponse(
                        content="",
                        model_used=model_name,
                        error=f"Ollama chat API error: {response.status} - {error_text}"
                    )
                
                data = await response.json()
                response_time = time.time() - start_time
                
                return AIResponse(
                    content=data.get("message", {}).get("content", ""),
                    model_used=model_name,
                    tokens_used=data.get("eval_count", 0),
                    response_time=response_time,
                    metadata={
                        "provider": "ollama",
                        "role": model_role.value,
                        "api_type": "chat",
                        "messages_count": len(messages)
                    }
                )
                
        except Exception as e:
            response_time = time.time() - start_time
            return AIResponse(
                content="",
                model_used=model_name if 'model_name' in locals() else "unknown",
                response_time=response_time,
                error=f"Chat error: {str(e)}"
            )
    
    async def analyze_system_metrics(self, metrics: Dict[str, Any]) -> AIResponse:
        """Analyze system metrics using the diagnostics model."""
        # Use fast diagnostics model for quick analysis
        request = AIRequest(
            prompt=self._format_metrics_prompt(metrics),
            model_role=ModelRole.DIAGNOSTICS,
            temperature=0.2,
            max_tokens=1024,
            context={"type": "system_metrics", "data": metrics}
        )
        
        return await self.generate(request)
    
    async def suggest_optimization(self, system_data: Dict[str, Any]) -> AIResponse:
        """Suggest system optimizations using the general model."""
        request = AIRequest(
            prompt=self._format_optimization_prompt(system_data),
            model_role=ModelRole.GENERAL,
            temperature=0.3,
            max_tokens=2048,
            context={"type": "optimization", "data": system_data}
        )
        
        return await self.generate(request)
    
    async def generate_fix_commands(self, issue: str, context: Dict[str, Any]) -> AIResponse:
        """Generate fix commands using the coding model."""
        request = AIRequest(
            prompt=self._format_fix_prompt(issue, context),
            model_role=ModelRole.CODING,
            temperature=0.1,  # Very conservative for command generation
            max_tokens=1024,
            context={"type": "fix_generation", "issue": issue, "context": context}
        )
        
        return await self.generate(request)
    
    async def close(self):
        """Close the HTTP session."""
        if self._session:
            await self._session.close()
            self._session = None
    
    def _select_model_for_request(self, request: AIRequest) -> Optional[str]:
        """Select the best available model for a request."""
        # First, try to get model by role
        model_name = self.get_model_for_role(request.model_role)
        
        # Check if the model is available
        if model_name and model_name in self._connected_models:
            return model_name
        
        # Fallback to any available model from our configured models
        for role_model in self.models.values():
            if role_model in self._connected_models:
                return role_model
        
        # Last resort: use any available model
        if self._connected_models:
            return self._connected_models[0]
        
        return None
    
    def _build_request_payload(self, request: AIRequest, model_name: str) -> Dict[str, Any]:
        """Build the request payload for Ollama API."""
        payload = {
            "model": model_name,
            "prompt": request.prompt,
            "stream": False,
            "keep_alive": self.keep_alive
        }
        
        # Add system prompt if provided
        if request.system_prompt:
            payload["system"] = request.system_prompt
        
        # Add model-specific options
        options = {}
        model_config = self.get_model_config(model_name)
        
        # Use request parameters or fall back to model config
        if request.temperature is not None:
            options["temperature"] = request.temperature
        elif "temperature" in model_config:
            options["temperature"] = model_config["temperature"]
        
        if request.max_tokens is not None:
            options["num_predict"] = request.max_tokens
        elif "max_tokens" in model_config:
            options["num_predict"] = model_config["max_tokens"]
        
        if options:
            payload["options"] = options
        
        return payload
    
    def _format_metrics_prompt(self, metrics: Dict[str, Any]) -> str:
        """Format system metrics into a prompt for analysis."""
        prompt_parts = ["Analyze these system metrics and identify any issues:"]
        
        if "cpu" in metrics:
            prompt_parts.append(f"CPU: {metrics['cpu']}%")
        
        if "memory" in metrics:
            mem = metrics["memory"]
            if isinstance(mem, dict):
                prompt_parts.append(f"Memory: {mem.get('percent', 0)}% used")
            else:
                prompt_parts.append(f"Memory: {mem}%")
        
        if "disk" in metrics:
            disk = metrics["disk"]
            if isinstance(disk, list):
                for d in disk:
                    prompt_parts.append(f"Disk {d.get('device', 'unknown')}: {d.get('percent', 0)}%")
            else:
                prompt_parts.append(f"Disk: {disk}%")
        
        if "load" in metrics:
            prompt_parts.append(f"Load Average: {metrics['load']}")
        
        prompt_parts.append("\nProvide a brief analysis and highlight any concerns.")
        return "\n".join(prompt_parts)
    
    def _format_optimization_prompt(self, system_data: Dict[str, Any]) -> str:
        """Format system data into an optimization prompt."""
        return f"""Analyze this Arch Linux system and suggest optimizations:

System Data:
{json.dumps(system_data, indent=2)}

Focus on:
1. Performance improvements
2. Resource optimization  
3. Arch-specific recommendations
4. Security enhancements
5. Maintenance suggestions

Provide specific, actionable recommendations."""
    
    def _format_fix_prompt(self, issue: str, context: Dict[str, Any]) -> str:
        """Format an issue into a fix generation prompt."""
        return f"""Generate safe bash commands to fix this Arch Linux system issue:

Issue: {issue}

System Context:
{json.dumps(context, indent=2)}

Requirements:
- Use Arch Linux commands (pacman, systemctl, etc.)
- Provide safe, well-commented commands
- Explain what each command does
- Include verification steps
- Consider rollback options

Generate the fix commands:"""

    async def __aenter__(self):
        """Async context manager entry."""
        await self.initialize()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.close()