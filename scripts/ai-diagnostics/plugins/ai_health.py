"""
AI Health Diagnostic Plugin

Comprehensive testing of AI/LLM system health including:
- Model response time benchmarks
- Accuracy validation tests
- Memory usage monitoring
- Ollama service health
- Model availability and responsiveness
"""

import asyncio
import time
import json
import psutil
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

from ..core.models import DiagnosticResult, DiagnosticIssue, Severity
from ..core.plugin_manager import DiagnosticPlugin, PluginExecutionContext


@dataclass
class ModelBenchmark:
    """Results from model performance benchmark."""
    model_name: str
    response_time_ms: float
    tokens_per_second: float
    memory_usage_mb: float
    accuracy_score: Optional[float] = None
    error_message: Optional[str] = None


class AIHealthPlugin(DiagnosticPlugin):
    """
    AI Health diagnostic plugin for comprehensive LLM system testing.
    
    Features:
    - Model response time benchmarking
    - Accuracy validation with known queries
    - Memory usage and resource monitoring
    - Ollama service health checks
    - Multi-model performance comparison
    """
    
    metadata = {
        "name": "AI Health Check",
        "version": "1.0.0",
        "description": "Comprehensive AI/LLM system health and performance testing",
        "author": "AI Diagnostic System",
        "category": "ai_health",
        "supports_fix": True,
        "execution_time_target": 45.0  # seconds
    }
    
    def __init__(self):
        super().__init__()
        
        # Benchmark test queries for accuracy validation
        self.accuracy_tests = [
            {
                "query": "What is 2 + 2?",
                "expected_keywords": ["4", "four"],
                "category": "basic_math"
            },
            {
                "query": "Name the capital of France.",
                "expected_keywords": ["paris", "Paris"],
                "category": "factual"
            },
            {
                "query": "What operating system uses systemd for service management?",
                "expected_keywords": ["linux", "Linux"],
                "category": "technical"
            }
        ]
        
        # Performance benchmarks
        self.performance_targets = {
            "response_time_ms": 5000,  # 5 seconds max
            "tokens_per_second": 10,   # Minimum acceptable speed
            "memory_usage_mb": 2048,   # 2GB max per model
            "accuracy_threshold": 0.8  # 80% accuracy minimum
        }
    
    async def execute(self, context: PluginExecutionContext) -> DiagnosticResult:
        """Execute AI health diagnostics."""
        self.logger.info("Starting AI Health diagnostics")
        start_time = time.time()
        
        issues = []
        metadata = {
            "benchmarks": [],
            "service_status": {},
            "system_resources": {},
            "timestamp": datetime.now().isoformat()
        }
        
        try:
            # 1. Check Ollama service health
            service_status = await self._check_ollama_service()
            metadata["service_status"] = service_status
            
            if not service_status.get("running", False):
                issues.append(DiagnosticIssue(
                    category="ai_health",
                    severity=Severity.HIGH,
                    title="Ollama Service Not Running",
                    description="Ollama service is not running or not accessible",
                    fix_suggestion="Run: systemctl --user start ollama"
                ))
                
            # 2. Get available models
            available_models = service_status.get("models", [])
            if not available_models:
                issues.append(DiagnosticIssue(
                    category="ai_health", 
                    severity=Severity.HIGH,
                    title="No AI Models Available",
                    description="No LLM models found in Ollama",
                    fix_suggestion="Install models: ollama pull phi4 && ollama pull codellama:7b-instruct"
                ))
                
            # 3. Benchmark each available model
            benchmarks = []
            if available_models:
                for model_name in available_models[:3]:  # Test top 3 models
                    benchmark = await self._benchmark_model(model_name, context)
                    benchmarks.append(benchmark)
                    metadata["benchmarks"].append(benchmark.__dict__)
                    
                    # Check performance against targets
                    model_issues = self._evaluate_model_performance(benchmark)
                    issues.extend(model_issues)
            
            # 4. System resource analysis
            resource_usage = await self._analyze_system_resources()
            metadata["system_resources"] = resource_usage
            
            resource_issues = self._check_resource_constraints(resource_usage)
            issues.extend(resource_issues)
            
            # 5. Overall AI system health assessment
            overall_health = self._assess_overall_health(benchmarks, service_status, resource_usage)
            metadata["overall_health"] = overall_health
            
            execution_time = (time.time() - start_time) * 1000
            
            return DiagnosticResult(
                plugin_name=self.metadata["name"],
                status="success",
                execution_time_ms=execution_time,
                issues=issues,
                metadata=metadata
            )
            
        except Exception as e:
            self.logger.error(f"AI Health check failed: {e}")
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.HIGH,
                title="AI Health Check Failed", 
                description=f"Diagnostic execution error: {str(e)}",
                fix_suggestion="Check logs and retry diagnostic"
            ))
            
            return DiagnosticResult(
                plugin_name=self.metadata["name"],
                status="error",
                execution_time_ms=(time.time() - start_time) * 1000,
                issues=issues,
                metadata=metadata
            )
    
    async def _check_ollama_service(self) -> Dict[str, Any]:
        """Check Ollama service health and get available models."""
        try:
            import ollama
            
            # Test basic connectivity
            start_time = time.time()
            models_response = ollama.list()
            response_time = (time.time() - start_time) * 1000
            
            models = []
            if hasattr(models_response, 'models'):
                for model in models_response.models:
                    model_name = getattr(model, 'model', '')
                    if model_name:
                        models.append(model_name)
                        # Also add base name without tag
                        base_name = model_name.split(':')[0]
                        if base_name not in models:
                            models.append(base_name)
            
            return {
                "running": True,
                "response_time_ms": response_time,
                "models": models,
                "model_count": len(models)
            }
            
        except Exception as e:
            return {
                "running": False,
                "error": str(e),
                "models": [],
                "model_count": 0
            }
    
    async def _benchmark_model(self, model_name: str, context: PluginExecutionContext) -> ModelBenchmark:
        """Benchmark a specific model's performance."""
        self.logger.info(f"Benchmarking model: {model_name}")
        
        try:
            import ollama
            
            # Memory usage before test
            memory_before = self._get_memory_usage()
            
            # 1. Response time test
            start_time = time.time()
            response = ollama.chat(
                model=model_name,
                messages=[{
                    'role': 'user',
                    'content': 'Respond with exactly "OK" to test response time.'
                }],
                options={
                    'temperature': 0.1,
                    'num_predict': 10
                }
            )
            response_time = (time.time() - start_time) * 1000
            
            # Estimate tokens per second (rough approximation)
            response_text = response.get('message', {}).get('content', '')
            estimated_tokens = len(response_text.split())
            tokens_per_second = estimated_tokens / (response_time / 1000) if response_time > 0 else 0
            
            # Memory usage after test
            memory_after = self._get_memory_usage()
            memory_usage = memory_after - memory_before
            
            # 2. Accuracy test
            accuracy_score = await self._test_model_accuracy(model_name)
            
            return ModelBenchmark(
                model_name=model_name,
                response_time_ms=response_time,
                tokens_per_second=tokens_per_second,
                memory_usage_mb=memory_usage,
                accuracy_score=accuracy_score
            )
            
        except Exception as e:
            return ModelBenchmark(
                model_name=model_name,
                response_time_ms=0,
                tokens_per_second=0,
                memory_usage_mb=0,
                error_message=str(e)
            )
    
    async def _test_model_accuracy(self, model_name: str) -> float:
        """Test model accuracy with predefined queries."""
        try:
            import ollama
            
            correct_answers = 0
            total_tests = len(self.accuracy_tests)
            
            for test in self.accuracy_tests:
                try:
                    response = ollama.chat(
                        model=model_name,
                        messages=[{
                            'role': 'user',
                            'content': test["query"]
                        }],
                        options={
                            'temperature': 0.1,
                            'num_predict': 50
                        }
                    )
                    
                    response_text = response.get('message', {}).get('content', '').lower()
                    
                    # Check if any expected keywords are in the response
                    if any(keyword.lower() in response_text for keyword in test["expected_keywords"]):
                        correct_answers += 1
                        
                except Exception as e:
                    self.logger.warning(f"Accuracy test failed for {model_name}: {e}")
                    continue
            
            return correct_answers / total_tests if total_tests > 0 else 0.0
            
        except Exception as e:
            self.logger.error(f"Accuracy testing failed for {model_name}: {e}")
            return 0.0
    
    def _get_memory_usage(self) -> float:
        """Get current memory usage in MB."""
        try:
            process = psutil.Process()
            return process.memory_info().rss / (1024 * 1024)  # Convert to MB
        except:
            return 0.0
    
    async def _analyze_system_resources(self) -> Dict[str, Any]:
        """Analyze system resource usage relevant to AI operations."""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # Memory usage
            memory = psutil.virtual_memory()
            memory_usage = {
                "total_gb": memory.total / (1024**3),
                "available_gb": memory.available / (1024**3),
                "used_percent": memory.percent,
                "free_gb": memory.free / (1024**3)
            }
            
            # Disk usage for data directory
            disk = psutil.disk_usage('/')
            disk_usage = {
                "total_gb": disk.total / (1024**3),
                "free_gb": disk.free / (1024**3),
                "used_percent": (disk.used / disk.total) * 100
            }
            
            # Check for Ollama processes
            ollama_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'memory_info', 'cpu_percent']):
                try:
                    if 'ollama' in proc.info['name'].lower():
                        ollama_processes.append({
                            "pid": proc.info['pid'],
                            "name": proc.info['name'],
                            "memory_mb": proc.info['memory_info'].rss / (1024*1024),
                            "cpu_percent": proc.info['cpu_percent']
                        })
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            return {
                "cpu_percent": cpu_percent,
                "memory": memory_usage,
                "disk": disk_usage,
                "ollama_processes": ollama_processes,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Resource analysis failed: {e}")
            return {}
    
    def _evaluate_model_performance(self, benchmark: ModelBenchmark) -> List[DiagnosticIssue]:
        """Evaluate model performance against targets."""
        issues = []
        
        if benchmark.error_message:
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.HIGH,
                title=f"Model {benchmark.model_name} Failed",
                description=f"Model benchmark failed: {benchmark.error_message}",
                fix_suggestion=f"Check model status: ollama show {benchmark.model_name}"
            ))
            return issues
        
        # Response time check
        if benchmark.response_time_ms > self.performance_targets["response_time_ms"]:
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.MEDIUM,
                title=f"Slow Response Time: {benchmark.model_name}",
                description=f"Response time {benchmark.response_time_ms:.0f}ms exceeds target {self.performance_targets['response_time_ms']}ms",
                fix_suggestion="Consider using a smaller model or optimizing system resources"
            ))
        
        # Tokens per second check
        if benchmark.tokens_per_second < self.performance_targets["tokens_per_second"]:
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.MEDIUM,
                title=f"Low Token Generation Speed: {benchmark.model_name}",
                description=f"Speed {benchmark.tokens_per_second:.1f} tokens/sec below target {self.performance_targets['tokens_per_second']}",
                fix_suggestion="Check CPU/GPU utilization and available memory"
            ))
        
        # Accuracy check
        if benchmark.accuracy_score is not None and benchmark.accuracy_score < self.performance_targets["accuracy_threshold"]:
            issues.append(DiagnosticIssue(
                category="ai_health", 
                severity=Severity.HIGH,
                title=f"Low Accuracy: {benchmark.model_name}",
                description=f"Accuracy {benchmark.accuracy_score:.1%} below threshold {self.performance_targets['accuracy_threshold']:.1%}",
                fix_suggestion="Model may need redownload: ollama pull " + benchmark.model_name
            ))
        
        return issues
    
    def _check_resource_constraints(self, resources: Dict[str, Any]) -> List[DiagnosticIssue]:
        """Check for resource constraints that affect AI performance."""
        issues = []
        
        if not resources:
            return issues
        
        memory = resources.get("memory", {})
        
        # Memory usage check
        if memory.get("used_percent", 0) > 85:
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.HIGH,
                title="High Memory Usage",
                description=f"Memory usage at {memory.get('used_percent', 0):.1f}% may affect AI performance",
                fix_suggestion="Close unnecessary applications or consider adding more RAM"
            ))
        
        # Available memory for AI models
        available_gb = memory.get("available_gb", 0)
        if available_gb < 4:  # Less than 4GB available
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.MEDIUM,
                title="Low Available Memory",
                description=f"Only {available_gb:.1f}GB available - large models may struggle",
                fix_suggestion="Free up memory or use smaller models like qwen3:4b"
            ))
        
        # CPU usage check
        cpu_percent = resources.get("cpu_percent", 0)
        if cpu_percent > 80:
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.MEDIUM,
                title="High CPU Usage",
                description=f"CPU usage at {cpu_percent:.1f}% may slow AI responses",
                fix_suggestion="Reduce system load or wait for CPU utilization to decrease"
            ))
        
        # Disk space check
        disk = resources.get("disk", {})
        if disk.get("used_percent", 0) > 90:
            issues.append(DiagnosticIssue(
                category="ai_health",
                severity=Severity.HIGH,
                title="Low Disk Space",
                description=f"Disk usage at {disk.get('used_percent', 0):.1f}% - models may fail to download",
                fix_suggestion="Free up disk space in root filesystem"
            ))
        
        return issues
    
    def _assess_overall_health(
        self, 
        benchmarks: List[ModelBenchmark], 
        service_status: Dict[str, Any],
        resources: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Assess overall AI system health."""
        
        # Calculate health score (0-100)
        health_score = 100
        
        # Service status impact
        if not service_status.get("running", False):
            health_score -= 50
        
        # Model performance impact
        working_models = [b for b in benchmarks if not b.error_message]
        if not working_models:
            health_score -= 30
        else:
            # Average performance scores
            avg_response_time = sum(b.response_time_ms for b in working_models) / len(working_models)
            if avg_response_time > self.performance_targets["response_time_ms"]:
                health_score -= 20
                
            if working_models and all(b.accuracy_score for b in working_models):
                avg_accuracy = sum(b.accuracy_score for b in working_models) / len(working_models)
                if avg_accuracy < self.performance_targets["accuracy_threshold"]:
                    health_score -= 15
        
        # Resource constraints impact
        memory_percent = resources.get("memory", {}).get("used_percent", 0)
        if memory_percent > 85:
            health_score -= 10
        
        cpu_percent = resources.get("cpu_percent", 0)
        if cpu_percent > 80:
            health_score -= 5
        
        health_score = max(0, health_score)  # Don't go below 0
        
        # Determine health status
        if health_score >= 80:
            status = "excellent"
        elif health_score >= 60:
            status = "good"
        elif health_score >= 40:
            status = "fair"
        elif health_score >= 20:
            status = "poor"
        else:
            status = "critical"
        
        return {
            "health_score": health_score,
            "status": status,
            "working_models": len(working_models),
            "total_models": len(benchmarks),
            "service_running": service_status.get("running", False),
            "assessment_time": datetime.now().isoformat()
        }
    
    async def can_fix(self, issue: DiagnosticIssue) -> bool:
        """Check if this plugin can fix the given issue."""
        fixable_issues = [
            "Ollama Service Not Running",
            "No AI Models Available"
        ]
        return issue.title in fixable_issues and issue.category == "ai_health"
    
    async def apply_fix(self, issue: DiagnosticIssue) -> bool:
        """Apply fix for the given issue."""
        try:
            if issue.title == "Ollama Service Not Running":
                return await self._fix_ollama_service()
            elif issue.title == "No AI Models Available":
                return await self._fix_missing_models()
            
            return False
            
        except Exception as e:
            self.logger.error(f"Fix application failed: {e}")
            return False
    
    async def _fix_ollama_service(self) -> bool:
        """Fix Ollama service startup."""
        try:
            import subprocess
            
            # Try to start user service
            result = subprocess.run(
                ["systemctl", "--user", "start", "ollama"],
                capture_output=True, text=True
            )
            
            if result.returncode == 0:
                # Wait a moment for service to start
                await asyncio.sleep(2)
                
                # Verify it's running
                status = await self._check_ollama_service()
                return status.get("running", False)
            
            return False
            
        except Exception as e:
            self.logger.error(f"Failed to start Ollama service: {e}")
            return False
    
    async def _fix_missing_models(self) -> bool:
        """Fix missing models by suggesting download commands."""
        # This would typically require user interaction
        # For now, just log the suggestion
        self.logger.info("To fix missing models, run: ollama pull phi4 && ollama pull codellama:7b-instruct")
        return False  # Requires manual intervention 