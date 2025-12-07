"""
Claude Code adapter - native Ring format (passthrough).

Claude Code is the primary target platform for Ring, so this adapter
performs minimal transformation (essentially a passthrough).
"""

import os
from pathlib import Path
from typing import Dict, Optional, Any

from ring_installer.adapters.base import PlatformAdapter


class ClaudeAdapter(PlatformAdapter):
    """
    Platform adapter for Claude Code.

    Claude Code uses Ring's native format, so transformations are minimal.
    This adapter primarily handles path resolution and file organization.
    """

    platform_id = "claude"
    platform_name = "Claude Code"

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the Claude Code adapter.

        Args:
            config: Platform-specific configuration from platforms.json
        """
        super().__init__(config)

    def transform_skill(self, skill_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring skill for Claude Code.

        Since Claude Code uses Ring's native format, this is a passthrough.

        Args:
            skill_content: The original skill content
            metadata: Optional metadata about the skill

        Returns:
            The skill content unchanged
        """
        return skill_content

    def transform_agent(self, agent_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring agent for Claude Code.

        Since Claude Code uses Ring's native format, this is a passthrough.

        Args:
            agent_content: The original agent content
            metadata: Optional metadata about the agent

        Returns:
            The agent content unchanged
        """
        return agent_content

    def transform_command(self, command_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring command for Claude Code.

        Since Claude Code uses Ring's native format, this is a passthrough.

        Args:
            command_content: The original command content
            metadata: Optional metadata about the command

        Returns:
            The command content unchanged
        """
        return command_content

    def transform_hook(self, hook_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring hook for Claude Code.

        Since Claude Code uses Ring's native format, this is a passthrough.

        Args:
            hook_content: The original hook content
            metadata: Optional metadata about the hook

        Returns:
            The hook content unchanged
        """
        return hook_content

    def get_install_path(self) -> Path:
        """
        Get the installation path for Claude Code.

        Returns:
            Path to ~/.claude directory
        """
        if self._install_path is None:
            env_path = Path(
                self.config.get("install_path", "~/.claude")
            ).expanduser()
            override = os.environ.get("CLAUDE_CONFIG_PATH")
            if override:
                candidate = Path(override).expanduser().resolve()
                home = Path.home().resolve()
                try:
                    candidate.relative_to(home)
                    env_path = candidate
                except ValueError:
                    import logging
                    logging.getLogger(__name__).warning(
                        "CLAUDE_CONFIG_PATH=%s ignored: path must be under home", override
                    )
            self._install_path = env_path
        return self._install_path

    def get_component_mapping(self) -> Dict[str, Dict[str, str]]:
        """
        Get the component mapping for Claude Code.

        Returns:
            Mapping of Ring components to Claude Code directories
        """
        return {
            "agents": {
                "target_dir": "agents",
                "extension": ".md"
            },
            "commands": {
                "target_dir": "commands",
                "extension": ".md"
            },
            "skills": {
                "target_dir": "skills",
                "extension": ".md"
            },
            "hooks": {
                "target_dir": "hooks",
                "extension": ""  # Multiple extensions supported
            }
        }

    def get_terminology(self) -> Dict[str, str]:
        """
        Get Claude Code terminology (same as Ring).

        Returns:
            Identity mapping since Claude Code uses Ring terminology
        """
        return {
            "agent": "agent",
            "skill": "skill",
            "command": "command",
            "hook": "hook"
        }

    def is_native_format(self) -> bool:
        """
        Check if this platform uses Ring's native format.

        Returns:
            True - Claude Code is the native platform
        """
        return True

    def get_plugin_structure(self) -> Dict[str, Any]:
        """
        Get the expected plugin directory structure for Claude Code.

        Returns:
            Dictionary describing the plugin structure
        """
        return {
            "root": ".claude-plugin",
            "manifest": "plugin.json",
            "directories": ["agents", "commands", "skills", "hooks", "docs"],
            "optional": ["docs"]
        }

    def validate_plugin_manifest(self, manifest_path: Path) -> tuple[bool, list[str]]:
        """
        Validate a Claude Code plugin manifest.

        Args:
            manifest_path: Path to plugin.json

        Returns:
            Tuple of (is_valid, list of error messages)
        """
        import json

        errors = []

        if not manifest_path.exists():
            return False, ["plugin.json not found"]

        try:
            with open(manifest_path) as f:
                manifest = json.load(f)
        except json.JSONDecodeError as e:
            return False, [f"Invalid JSON: {e}"]

        required_fields = ["name", "description", "version"]
        for field in required_fields:
            if field not in manifest:
                errors.append(f"Missing required field: {field}")

        return len(errors) == 0, errors
