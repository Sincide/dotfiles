#!/usr/bin/env python3
"""
Configuration Manager for GPTDiag

Handles loading, saving, and validating YAML configuration files.
Manages all application settings and provides a central configuration interface.
"""

import os
import yaml
from pathlib import Path
from typing import Dict, Any, Optional, Union
from datetime import datetime

from .defaults import DEFAULT_CONFIG, DEFAULT_AI_CONFIG, DEFAULT_THEMES


class ConfigManager:
    """Manages application configuration files and settings."""
    
    def __init__(self, config_dir: Path):
        """Initialize the configuration manager.
        
        Args:
            config_dir: Path to the configuration directory
        """
        self.config_dir = Path(config_dir)
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        # Configuration file paths
        self.main_config_path = self.config_dir / "config.yaml"
        self.ai_config_path = self.config_dir / "ai_config.yaml"
        self.themes_config_path = self.config_dir / "themes.yaml"
        
        # In-memory configuration storage
        self._main_config: Dict[str, Any] = {}
        self._ai_config: Dict[str, Any] = {}
        self._themes_config: Dict[str, Any] = {}
        
        # Load configurations on initialization
        self.load_all_configs()
    
    def load_all_configs(self) -> None:
        """Load all configuration files."""
        self._main_config = self.load_config(self.main_config_path, DEFAULT_CONFIG)
        self._ai_config = self.load_config(self.ai_config_path, DEFAULT_AI_CONFIG)
        self._themes_config = self.load_config(self.themes_config_path, DEFAULT_THEMES)
    
    def load_config(self, config_path: Path, default_config: Dict[str, Any]) -> Dict[str, Any]:
        """Load a configuration file with fallback to defaults.
        
        Args:
            config_path: Path to the configuration file
            default_config: Default configuration to use if file doesn't exist
            
        Returns:
            Loaded configuration dictionary
        """
        if config_path.exists():
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    loaded_config = yaml.safe_load(f) or {}
                
                # Merge with defaults to ensure all keys exist
                config = self._deep_merge(default_config.copy(), loaded_config)
                return config
                
            except (yaml.YAMLError, IOError) as e:
                print(f"Warning: Failed to load {config_path}: {e}")
                print(f"Using default configuration for {config_path.name}")
                
        # Create config file with defaults if it doesn't exist
        self.save_config(config_path, default_config)
        return default_config.copy()
    
    def save_config(self, config_path: Path, config: Dict[str, Any]) -> bool:
        """Save configuration to file.
        
        Args:
            config_path: Path to save the configuration
            config: Configuration dictionary to save
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Ensure directory exists
            config_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Create backup if file exists
            if config_path.exists():
                backup_path = config_path.with_suffix(f".yaml.backup.{int(datetime.now().timestamp())}")
                config_path.rename(backup_path)
            
            # Write configuration with proper formatting
            with open(config_path, 'w', encoding='utf-8') as f:
                yaml.dump(config, f, default_flow_style=False, indent=2, sort_keys=False)
            
            # Set appropriate permissions (read/write for owner only)
            os.chmod(config_path, 0o600)
            
            return True
            
        except (yaml.YAMLError, IOError) as e:
            print(f"Error: Failed to save {config_path}: {e}")
            return False
    
    def save_all_configs(self) -> bool:
        """Save all configuration files.
        
        Returns:
            True if all files saved successfully, False otherwise
        """
        results = [
            self.save_config(self.main_config_path, self._main_config),
            self.save_config(self.ai_config_path, self._ai_config),
            self.save_config(self.themes_config_path, self._themes_config)
        ]
        return all(results)
    
    def get(self, key: str, default: Any = None, config_type: str = "main") -> Any:
        """Get a configuration value using dot notation.
        
        Args:
            key: Configuration key (supports dot notation, e.g., 'app.update_interval')
            default: Default value if key not found
            config_type: Type of config ('main', 'ai', 'themes')
            
        Returns:
            Configuration value or default
        """
        config_map = {
            "main": self._main_config,
            "ai": self._ai_config,
            "themes": self._themes_config
        }
        
        config = config_map.get(config_type, self._main_config)
        return self._get_nested_value(config, key, default)
    
    def set(self, key: str, value: Any, config_type: str = "main") -> None:
        """Set a configuration value using dot notation.
        
        Args:
            key: Configuration key (supports dot notation)
            value: Value to set
            config_type: Type of config ('main', 'ai', 'themes')
        """
        config_map = {
            "main": self._main_config,
            "ai": self._ai_config,
            "themes": self._themes_config
        }
        
        config = config_map.get(config_type, self._main_config)
        self._set_nested_value(config, key, value)
    
    def get_main_config(self) -> Dict[str, Any]:
        """Get the complete main configuration."""
        return self._main_config.copy()
    
    def get_ai_config(self) -> Dict[str, Any]:
        """Get the complete AI configuration."""
        return self._ai_config.copy()
    
    def get_themes_config(self) -> Dict[str, Any]:
        """Get the complete themes configuration."""
        return self._themes_config.copy()
    
    def update_main_config(self, updates: Dict[str, Any]) -> None:
        """Update main configuration with provided values."""
        self._main_config = self._deep_merge(self._main_config, updates)
    
    def update_ai_config(self, updates: Dict[str, Any]) -> None:
        """Update AI configuration with provided values."""
        self._ai_config = self._deep_merge(self._ai_config, updates)
    
    def update_themes_config(self, updates: Dict[str, Any]) -> None:
        """Update themes configuration with provided values."""
        self._themes_config = self._deep_merge(self._themes_config, updates)
    
    def validate_config(self, config_type: str = "all") -> Dict[str, list]:
        """Validate configuration and return any errors.
        
        Args:
            config_type: Type of config to validate ('main', 'ai', 'themes', 'all')
            
        Returns:
            Dictionary with validation errors for each config type
        """
        errors = {}
        
        if config_type in ["main", "all"]:
            errors["main"] = self._validate_main_config()
        
        if config_type in ["ai", "all"]:
            errors["ai"] = self._validate_ai_config()
        
        if config_type in ["themes", "all"]:
            errors["themes"] = self._validate_themes_config()
        
        return {k: v for k, v in errors.items() if v}
    
    def reset_to_defaults(self, config_type: str = "all") -> None:
        """Reset configuration to defaults.
        
        Args:
            config_type: Type of config to reset ('main', 'ai', 'themes', 'all')
        """
        if config_type in ["main", "all"]:
            self._main_config = DEFAULT_CONFIG.copy()
        
        if config_type in ["ai", "all"]:
            self._ai_config = DEFAULT_AI_CONFIG.copy()
        
        if config_type in ["themes", "all"]:
            self._themes_config = DEFAULT_THEMES.copy()
    
    def get_config_summary(self) -> Dict[str, Any]:
        """Get a summary of current configuration status."""
        return {
            "config_dir": str(self.config_dir),
            "files": {
                "main_config": {
                    "path": str(self.main_config_path),
                    "exists": self.main_config_path.exists(),
                    "size": self.main_config_path.stat().st_size if self.main_config_path.exists() else 0
                },
                "ai_config": {
                    "path": str(self.ai_config_path),
                    "exists": self.ai_config_path.exists(),
                    "size": self.ai_config_path.stat().st_size if self.ai_config_path.exists() else 0
                },
                "themes_config": {
                    "path": str(self.themes_config_path),
                    "exists": self.themes_config_path.exists(),
                    "size": self.themes_config_path.stat().st_size if self.themes_config_path.exists() else 0
                }
            },
            "validation_errors": self.validate_config(),
            "last_modified": {
                "main": self.main_config_path.stat().st_mtime if self.main_config_path.exists() else None,
                "ai": self.ai_config_path.stat().st_mtime if self.ai_config_path.exists() else None,
                "themes": self.themes_config_path.stat().st_mtime if self.themes_config_path.exists() else None
            }
        }
    
    # Private helper methods
    
    def _deep_merge(self, base: Dict[str, Any], updates: Dict[str, Any]) -> Dict[str, Any]:
        """Deep merge two dictionaries."""
        result = base.copy()
        
        for key, value in updates.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result
    
    def _get_nested_value(self, config: Dict[str, Any], key: str, default: Any = None) -> Any:
        """Get a nested value using dot notation."""
        keys = key.split('.')
        value = config
        
        try:
            for k in keys:
                value = value[k]
            return value
        except (KeyError, TypeError):
            return default
    
    def _set_nested_value(self, config: Dict[str, Any], key: str, value: Any) -> None:
        """Set a nested value using dot notation."""
        keys = key.split('.')
        current = config
        
        # Navigate to the parent of the target key
        for k in keys[:-1]:
            if k not in current:
                current[k] = {}
            current = current[k]
        
        # Set the value
        current[keys[-1]] = value
    
    def _validate_main_config(self) -> list:
        """Validate main configuration and return errors."""
        errors = []
        
        # Validate update interval
        update_interval = self.get("app.update_interval", 2.0)
        if not isinstance(update_interval, (int, float)) or update_interval <= 0:
            errors.append("app.update_interval must be a positive number")
        
        # Validate thresholds
        for threshold_key in ["monitoring.cpu_alert_threshold", "monitoring.memory_alert_threshold", "monitoring.disk_alert_threshold"]:
            threshold = self.get(threshold_key, 90)
            if not isinstance(threshold, (int, float)) or not (0 < threshold <= 100):
                errors.append(f"{threshold_key} must be a number between 0 and 100")
        
        # Validate allowed commands
        allowed_commands = self.get("system.allowed_commands", [])
        if not isinstance(allowed_commands, list):
            errors.append("system.allowed_commands must be a list")
        
        return errors
    
    def _validate_ai_config(self) -> list:
        """Validate AI configuration and return errors."""
        errors = []
        
        # Validate provider
        provider = self.get("provider", "", "ai")
        valid_providers = ["openai", "anthropic", "local"]
        if provider and provider not in valid_providers:
            errors.append(f"ai.provider must be one of: {', '.join(valid_providers)}")
        
        # Validate max_tokens
        max_tokens = self.get("max_tokens", 2048, "ai")
        if not isinstance(max_tokens, int) or max_tokens <= 0:
            errors.append("ai.max_tokens must be a positive integer")
        
        # Validate temperature
        temperature = self.get("temperature", 0.3, "ai")
        if not isinstance(temperature, (int, float)) or not (0 <= temperature <= 2):
            errors.append("ai.temperature must be a number between 0 and 2")
        
        return errors
    
    def _validate_themes_config(self) -> list:
        """Validate themes configuration and return errors."""
        errors = []
        
        themes = self.get_themes_config().get("themes", {})
        if not isinstance(themes, dict):
            errors.append("themes.themes must be a dictionary")
            return errors
        
        # Validate color format for each theme
        for theme_name, theme_config in themes.items():
            if not isinstance(theme_config, dict):
                errors.append(f"themes.themes.{theme_name} must be a dictionary")
                continue
            
            required_colors = ["primary", "secondary", "accent", "background", "text"]
            for color_key in required_colors:
                color_value = theme_config.get(color_key)
                if color_value and not self._is_valid_color(color_value):
                    errors.append(f"themes.themes.{theme_name}.{color_key} is not a valid color format")
        
        return errors
    
    def _is_valid_color(self, color: str) -> bool:
        """Validate if a string is a valid color format (hex)."""
        if not isinstance(color, str):
            return False
        
        # Check hex color format
        if color.startswith('#') and len(color) == 7:
            try:
                int(color[1:], 16)
                return True
            except ValueError:
                pass
        
        return False 