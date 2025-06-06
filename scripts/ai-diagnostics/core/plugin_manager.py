"""
Plugin Manager for AI Diagnostic System

This module handles:
- Auto-discovery of diagnostic plugins in the plugins directory
- Plugin lifecycle management (loading, initialization, execution)
- Plugin metadata validation and dependency checking
- Dynamic plugin registration and user confirmation
- Plugin execution orchestration with error handling

The plugin system allows for extensible diagnostic checks that can be:
- Auto-discovered from the plugins directory
- Manually registered for custom checks
- Executed in parallel or sequential order
- Configured with custom parameters
"""

import asyncio
import importlib.util
import inspect
import logging
import os
import sys
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Dict, List, Optional, Type, Any, Set, Tuple
from dataclasses import dataclass

from .models import DiagnosticResult, DiagnosticIssue, PluginMetadata, CheckStatus
from .llm_engine import LLMEngine, AnalysisContext


class DiagnosticPlugin(ABC):
    """
    Abstract base class for all diagnostic plugins.
    
    All diagnostic plugins must inherit from this class and implement
    the required methods. This ensures consistent interface and allows
    the plugin manager to orchestrate plugin execution properly.
    """
    
    # Plugin metadata - must be defined in each plugin
    metadata: Dict[str, Any] = {
        "name": "Base Plugin",
        "version": "1.0.0", 
        "description": "Base diagnostic plugin",
        "author": "AI Diagnostic System",
        "category": "base",
        "dependencies": [],
        "enabled": True
    }
    
    def __init__(self, llm_engine: Optional[LLMEngine] = None):
        """
        Initialize the diagnostic plugin.
        
        Args:
            llm_engine: Optional LLM engine for AI-powered analysis
        """
        self.llm_engine = llm_engine
        self.logger = logging.getLogger(f"plugin.{self.__class__.__name__}")
        self.config = {}
        self._execution_context = {}
        
    @abstractmethod
    async def execute(self) -> DiagnosticResult:
        """
        Execute the main diagnostic check.
        
        This method contains the core logic for the diagnostic check.
        It should return a DiagnosticResult with findings, metrics,
        and any issues discovered.
        
        Returns:
            DiagnosticResult: Results of the diagnostic check
            
        Raises:
            Exception: If the diagnostic check fails to execute
        """
        pass
    
    async def can_fix(self, issue: DiagnosticIssue) -> bool:
        """
        Check if this plugin can automatically fix the given issue.
        
        Args:
            issue: The diagnostic issue to evaluate
            
        Returns:
            bool: True if this plugin can fix the issue, False otherwise
        """
        return False
    
    async def apply_fix(self, issue: DiagnosticIssue) -> bool:
        """
        Apply an automatic fix for the given issue.
        
        Args:
            issue: The diagnostic issue to fix
            
        Returns:
            bool: True if fix was applied successfully, False otherwise
        """
        return False
    
    async def pre_execute(self) -> bool:
        """
        Pre-execution hook for setup and validation.
        
        Called before execute(). Can be used for:
        - Environment validation
        - Dependency checking
        - Resource allocation
        - Configuration validation
        
        Returns:
            bool: True if pre-execution checks passed, False to skip execution
        """
        return True
    
    async def post_execute(self, result: DiagnosticResult) -> DiagnosticResult:
        """
        Post-execution hook for result processing.
        
        Called after execute() with the result. Can be used for:
        - Result enhancement with AI analysis
        - Metric post-processing
        - Additional validation
        - Result caching
        
        Args:
            result: The result from execute()
            
        Returns:
            DiagnosticResult: Enhanced or modified result
        """
        return result
    
    def configure(self, config: Dict[str, Any]) -> None:
        """
        Configure the plugin with custom settings.
        
        Args:
            config: Configuration dictionary for this plugin
        """
        self.config.update(config)
    
    def get_dependencies(self) -> List[str]:
        """
        Get list of dependencies required by this plugin.
        
        Returns:
            List[str]: List of dependency names
        """
        return self.metadata.get("dependencies", [])
    
    def get_metadata(self) -> PluginMetadata:
        """
        Get plugin metadata as a structured object.
        
        Returns:
            PluginMetadata: Structured metadata for this plugin
        """
        return PluginMetadata(**self.metadata)


@dataclass
class PluginExecutionContext:
    """Context information for plugin execution."""
    session_id: str
    mode: str  # "quick", "deep", "stress"
    parallel_execution: bool = True
    timeout_seconds: int = 300
    ai_analysis_enabled: bool = True
    user_config: Dict[str, Any] = None


class PluginManager:
    """
    Manages diagnostic plugins with auto-discovery and lifecycle control.
    
    The PluginManager handles:
    - Auto-discovery of plugins in the plugins directory
    - Plugin loading and validation
    - Dependency resolution
    - Execution orchestration
    - Error handling and recovery
    - User interaction for plugin confirmation
    """
    
    def __init__(self, plugins_dir: str = "plugins", llm_engine: Optional[LLMEngine] = None):
        """
        Initialize the plugin manager.
        
        Args:
            plugins_dir: Directory path containing plugins
            llm_engine: Optional LLM engine for AI-powered analysis
        """
        self.plugins_dir = Path(plugins_dir)
        self.llm_engine = llm_engine
        self.logger = logging.getLogger(__name__)
        
        # Plugin registry
        self._loaded_plugins: Dict[str, DiagnosticPlugin] = {}
        self._plugin_metadata: Dict[str, PluginMetadata] = {}
        self._execution_order: List[str] = []
        self._dependency_graph: Dict[str, Set[str]] = {}
        
        # Configuration
        self.auto_discover = True
        self.require_user_confirmation = True
        self.parallel_execution = True
        self.max_parallel_plugins = 5
        
    async def initialize(self) -> bool:
        """
        Initialize the plugin manager and discover plugins.
        
        Returns:
            bool: True if initialization successful, False otherwise
        """
        try:
            # Ensure plugins directory exists
            self.plugins_dir.mkdir(exist_ok=True)
            
            # Auto-discover plugins if enabled
            if self.auto_discover:
                await self._discover_plugins()
            
            # Validate dependencies
            if not self._validate_dependencies():
                self.logger.error("Plugin dependency validation failed")
                return False
            
            # Calculate execution order
            self._calculate_execution_order()
            
            self.logger.info(f"Plugin manager initialized with {len(self._loaded_plugins)} plugins")
            return True
            
        except Exception as e:
            self.logger.error(f"Plugin manager initialization failed: {e}")
            return False
    
    async def execute_all_plugins(self, context: PluginExecutionContext) -> List[DiagnosticResult]:
        """
        Execute all loaded plugins with proper orchestration.
        
        Args:
            context: Execution context with configuration
            
        Returns:
            List[DiagnosticResult]: Results from all executed plugins
        """
        self.logger.info(f"Executing {len(self._loaded_plugins)} plugins in {context.mode} mode")
        
        results = []
        
        if context.parallel_execution and self.parallel_execution:
            results = await self._execute_plugins_parallel(context)
        else:
            results = await self._execute_plugins_sequential(context)
        
        # Post-process results with AI analysis if enabled
        if context.ai_analysis_enabled and self.llm_engine:
            results = await self._enhance_results_with_ai(results, context)
        
        return results
    
    async def execute_plugin(self, plugin_name: str, context: PluginExecutionContext) -> Optional[DiagnosticResult]:
        """
        Execute a specific plugin by name.
        
        Args:
            plugin_name: Name of the plugin to execute
            context: Execution context
            
        Returns:
            DiagnosticResult or None if plugin not found or failed
        """
        plugin = self._loaded_plugins.get(plugin_name)
        if not plugin:
            self.logger.error(f"Plugin not found: {plugin_name}")
            return None
        
        return await self._execute_single_plugin(plugin, context)
    
    async def get_available_fixes(self, issue: DiagnosticIssue) -> List[Tuple[str, DiagnosticPlugin]]:
        """
        Find plugins that can fix the given issue.
        
        Args:
            issue: The diagnostic issue to find fixes for
            
        Returns:
            List of tuples containing (plugin_name, plugin_instance) that can fix the issue
        """
        available_fixes = []
        
        for name, plugin in self._loaded_plugins.items():
            try:
                if await plugin.can_fix(issue):
                    available_fixes.append((name, plugin))
            except Exception as e:
                self.logger.error(f"Error checking fix capability for plugin {name}: {e}")
        
        return available_fixes
    
    async def apply_fix(self, plugin_name: str, issue: DiagnosticIssue) -> bool:
        """
        Apply a fix using the specified plugin.
        
        Args:
            plugin_name: Name of the plugin to use for fixing
            issue: The diagnostic issue to fix
            
        Returns:
            bool: True if fix was applied successfully, False otherwise
        """
        plugin = self._loaded_plugins.get(plugin_name)
        if not plugin:
            self.logger.error(f"Plugin not found for fix: {plugin_name}")
            return False
        
        try:
            success = await plugin.apply_fix(issue)
            if success:
                self.logger.info(f"Fix applied successfully by plugin {plugin_name}")
            else:
                self.logger.warning(f"Fix application failed for plugin {plugin_name}")
            return success
        except Exception as e:
            self.logger.error(f"Error applying fix with plugin {plugin_name}: {e}")
            return False
    
    def register_plugin(self, plugin_class: Type[DiagnosticPlugin], enabled: bool = True) -> bool:
        """
        Manually register a plugin class.
        
        Args:
            plugin_class: The plugin class to register
            enabled: Whether the plugin should be enabled by default
            
        Returns:
            bool: True if registration successful, False otherwise
        """
        try:
            plugin_instance = plugin_class(self.llm_engine)
            metadata = plugin_instance.get_metadata()
            metadata.enabled = enabled
            
            plugin_name = metadata.name
            self._loaded_plugins[plugin_name] = plugin_instance
            self._plugin_metadata[plugin_name] = metadata
            
            self.logger.info(f"Manually registered plugin: {plugin_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to register plugin {plugin_class.__name__}: {e}")
            return False
    
    def get_plugin_info(self) -> Dict[str, PluginMetadata]:
        """
        Get information about all loaded plugins.
        
        Returns:
            Dict mapping plugin names to their metadata
        """
        return self._plugin_metadata.copy()
    
    def get_execution_order(self) -> List[str]:
        """
        Get the calculated plugin execution order.
        
        Returns:
            List of plugin names in execution order
        """
        return self._execution_order.copy()
    
    # Private methods for internal functionality
    
    async def _discover_plugins(self) -> None:
        """Auto-discover plugins in the plugins directory."""
        self.logger.info(f"Discovering plugins in {self.plugins_dir}")
        
        discovered_count = 0
        
        # Search for Python files in plugins directory
        for plugin_file in self.plugins_dir.glob("*.py"):
            if plugin_file.name.startswith("__"):
                continue  # Skip __init__.py and similar
                
            try:
                plugin_classes = await self._load_plugin_file(plugin_file)
                
                for plugin_class in plugin_classes:
                    if self.require_user_confirmation:
                        if await self._confirm_plugin_addition(plugin_class):
                            self.register_plugin(plugin_class)
                            discovered_count += 1
                    else:
                        self.register_plugin(plugin_class)
                        discovered_count += 1
                        
            except Exception as e:
                self.logger.error(f"Failed to load plugin from {plugin_file}: {e}")
        
        self.logger.info(f"Discovered and loaded {discovered_count} plugins")
    
    async def _load_plugin_file(self, plugin_file: Path) -> List[Type[DiagnosticPlugin]]:
        """Load plugin classes from a Python file."""
        plugin_classes = []
        
        # Load the module
        spec = importlib.util.spec_from_file_location(plugin_file.stem, plugin_file)
        if not spec or not spec.loader:
            raise ImportError(f"Cannot load module spec for {plugin_file}")
        
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        
        # Find DiagnosticPlugin subclasses
        for name, obj in inspect.getmembers(module, inspect.isclass):
            if (issubclass(obj, DiagnosticPlugin) and 
                obj != DiagnosticPlugin and
                not inspect.isabstract(obj)):
                plugin_classes.append(obj)
        
        return plugin_classes
    
    async def _confirm_plugin_addition(self, plugin_class: Type[DiagnosticPlugin]) -> bool:
        """Ask user for confirmation before adding a discovered plugin."""
        # Create temporary instance to get metadata
        temp_instance = plugin_class()
        metadata = temp_instance.get_metadata()
        
        # For now, return True (auto-accept). In real implementation,
        # this would show a UI prompt to the user
        print(f"Discovered plugin: {metadata.name} - {metadata.description}")
        print(f"Author: {metadata.author}, Version: {metadata.version}")
        
        # TODO: Implement actual user confirmation via UI
        return True
    
    def _validate_dependencies(self) -> bool:
        """Validate that all plugin dependencies are satisfied."""
        for plugin_name, metadata in self._plugin_metadata.items():
            for dependency in metadata.dependencies:
                if dependency not in self._loaded_plugins:
                    self.logger.error(f"Plugin {plugin_name} requires missing dependency: {dependency}")
                    return False
        return True
    
    def _calculate_execution_order(self) -> None:
        """Calculate optimal plugin execution order based on dependencies."""
        # Build dependency graph
        self._dependency_graph = {}
        for plugin_name, metadata in self._plugin_metadata.items():
            self._dependency_graph[plugin_name] = set(metadata.dependencies)
        
        # Topological sort to determine execution order
        self._execution_order = self._topological_sort(self._dependency_graph)
    
    def _topological_sort(self, graph: Dict[str, Set[str]]) -> List[str]:
        """Perform topological sort on dependency graph."""
        # Kahn's algorithm for topological sorting
        in_degree = {node: 0 for node in graph}
        
        # Calculate in-degrees
        for node in graph:
            for dependency in graph[node]:
                if dependency in in_degree:
                    in_degree[dependency] += 1
        
        # Queue nodes with no dependencies
        queue = [node for node, degree in in_degree.items() if degree == 0]
        result = []
        
        while queue:
            node = queue.pop(0)
            result.append(node)
            
            # Update dependencies
            for dependent in graph:
                if node in graph[dependent]:
                    in_degree[dependent] -= 1
                    if in_degree[dependent] == 0:
                        queue.append(dependent)
        
        return result
    
    async def _execute_plugins_parallel(self, context: PluginExecutionContext) -> List[DiagnosticResult]:
        """Execute plugins in parallel with concurrency control."""
        semaphore = asyncio.Semaphore(self.max_parallel_plugins)
        
        async def execute_with_semaphore(plugin: DiagnosticPlugin) -> DiagnosticResult:
            async with semaphore:
                return await self._execute_single_plugin(plugin, context)
        
        # Create tasks for enabled plugins
        tasks = []
        for plugin_name in self._execution_order:
            if self._plugin_metadata[plugin_name].enabled:
                plugin = self._loaded_plugins[plugin_name]
                task = asyncio.create_task(execute_with_semaphore(plugin))
                tasks.append(task)
        
        # Wait for all tasks to complete
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out exceptions and log errors
        valid_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                self.logger.error(f"Plugin execution failed: {result}")
            else:
                valid_results.append(result)
        
        return valid_results
    
    async def _execute_plugins_sequential(self, context: PluginExecutionContext) -> List[DiagnosticResult]:
        """Execute plugins sequentially in dependency order."""
        results = []
        
        for plugin_name in self._execution_order:
            if not self._plugin_metadata[plugin_name].enabled:
                continue
                
            plugin = self._loaded_plugins[plugin_name]
            
            try:
                result = await self._execute_single_plugin(plugin, context)
                results.append(result)
            except Exception as e:
                self.logger.error(f"Plugin {plugin_name} execution failed: {e}")
                # Continue with other plugins
        
        return results
    
    async def _execute_single_plugin(self, plugin: DiagnosticPlugin, context: PluginExecutionContext) -> DiagnosticResult:
        """Execute a single plugin with full lifecycle management."""
        plugin_name = plugin.get_metadata().name
        start_time = asyncio.get_event_loop().time()
        
        try:
            # Pre-execution hook
            if not await plugin.pre_execute():
                self.logger.warning(f"Plugin {plugin_name} pre-execution check failed, skipping")
                return DiagnosticResult(
                    check_id=plugin_name,
                    check_name=plugin_name,
                    status=CheckStatus.SKIPPED,
                    duration_ms=0,
                    timestamp=datetime.now()
                )
            
            # Main execution
            result = await asyncio.wait_for(
                plugin.execute(),
                timeout=context.timeout_seconds
            )
            
            # Post-execution hook
            result = await plugin.post_execute(result)
            
            # Update timing
            end_time = asyncio.get_event_loop().time()
            result.duration_ms = int((end_time - start_time) * 1000)
            result.status = CheckStatus.COMPLETED
            
            self.logger.info(f"Plugin {plugin_name} completed in {result.duration_ms}ms")
            return result
            
        except asyncio.TimeoutError:
            self.logger.error(f"Plugin {plugin_name} timed out after {context.timeout_seconds}s")
            return DiagnosticResult(
                check_id=plugin_name,
                check_name=plugin_name,
                status=CheckStatus.FAILED,
                duration_ms=context.timeout_seconds * 1000,
                timestamp=datetime.now()
            )
        except Exception as e:
            end_time = asyncio.get_event_loop().time()
            duration_ms = int((end_time - start_time) * 1000)
            
            self.logger.error(f"Plugin {plugin_name} failed: {e}")
            return DiagnosticResult(
                check_id=plugin_name,
                check_name=plugin_name,
                status=CheckStatus.FAILED,
                duration_ms=duration_ms,
                timestamp=datetime.now()
            )
    
    async def _enhance_results_with_ai(self, results: List[DiagnosticResult], 
                                     context: PluginExecutionContext) -> List[DiagnosticResult]:
        """Enhance plugin results with AI analysis."""
        if not self.llm_engine:
            return results
        
        enhanced_results = []
        
        for result in results:
            try:
                # Build analysis context for this result
                analysis_context = AnalysisContext(
                    # Add relevant context for AI analysis
                )
                
                # Get AI insights for this result
                if result.issues:
                    for issue in result.issues:
                        enhanced_issue = await self.llm_engine.diagnose_issue(
                            issue.description, analysis_context
                        )
                        # Merge AI insights with original issue
                        issue.ai_analysis = enhanced_issue.ai_analysis
                        issue.ai_confidence = enhanced_issue.ai_confidence
                
                enhanced_results.append(result)
                
            except Exception as e:
                self.logger.error(f"AI enhancement failed for result {result.check_id}: {e}")
                enhanced_results.append(result)  # Keep original result
        
        return enhanced_results 