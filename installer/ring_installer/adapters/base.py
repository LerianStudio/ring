"""
Base adapter class for platform-specific transformations.

All platform adapters must inherit from PlatformAdapter and implement
the required abstract methods for transforming Ring components.
"""

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Dict, List, Optional, Any
import re


class PlatformAdapter(ABC):
    """
    Abstract base class for platform adapters.

    Each platform adapter handles the transformation of Ring components
    (skills, agents, commands) into the format required by the target platform.
    """

    # Platform identifier (must be set by subclasses)
    platform_id: str = ""
    platform_name: str = ""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the adapter with optional configuration.

        Args:
            config: Platform-specific configuration from platforms.json
        """
        self.config = config or {}
        self._install_path: Optional[Path] = None

    @abstractmethod
    def transform_skill(self, skill_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring skill to the target platform format.

        Args:
            skill_content: The original skill content in Ring format (markdown with YAML frontmatter)
            metadata: Optional metadata about the skill (name, path, etc.)

        Returns:
            Transformed content suitable for the target platform
        """
        pass

    @abstractmethod
    def transform_agent(self, agent_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring agent to the target platform format.

        Args:
            agent_content: The original agent content in Ring format
            metadata: Optional metadata about the agent (name, path, etc.)

        Returns:
            Transformed content suitable for the target platform
        """
        pass

    @abstractmethod
    def transform_command(self, command_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring command to the target platform format.

        Args:
            command_content: The original command content in Ring format
            metadata: Optional metadata about the command (name, path, etc.)

        Returns:
            Transformed content suitable for the target platform
        """
        pass

    @abstractmethod
    def get_install_path(self) -> Path:
        """
        Get the installation path for this platform.

        Returns:
            Path object representing the platform's installation directory
        """
        pass

    @abstractmethod
    def get_component_mapping(self) -> Dict[str, Dict[str, str]]:
        """
        Get the mapping of Ring component types to platform-specific directories.

        Returns:
            Dictionary mapping component types (agents, commands, skills) to
            their target directories and file extensions.

        Example:
            {
                "agents": {"target_dir": "agents", "extension": ".md"},
                "commands": {"target_dir": "commands", "extension": ".md"},
                "skills": {"target_dir": "skills", "extension": ".md"}
            }
        """
        pass

    def transform_hook(self, hook_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring hook to the target platform format.

        Default implementation returns content unchanged. Override if platform
        requires hook transformation.

        Args:
            hook_content: The original hook content
            metadata: Optional metadata about the hook

        Returns:
            Transformed content suitable for the target platform
        """
        return hook_content

    def get_terminology(self) -> Dict[str, str]:
        """
        Get platform-specific terminology mapping.

        Returns:
            Dictionary mapping Ring terms to platform terms.

        Example:
            {"agent": "droid", "skill": "skill", "command": "command"}
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
            True if the platform uses Ring format natively (no transformation needed)
        """
        return False

    def validate_content(self, content: str, component_type: str) -> List[str]:
        """
        Validate content before transformation.

        Args:
            content: The content to validate
            component_type: Type of component (skill, agent, command)

        Returns:
            List of validation error messages (empty if valid)
        """
        errors = []

        if not content.strip():
            errors.append(f"Empty {component_type} content")
            return errors

        # Check for YAML frontmatter
        if content.startswith("---"):
            frontmatter_end = content.find("---", 3)
            if frontmatter_end == -1:
                errors.append("Invalid YAML frontmatter: missing closing ---")

        return errors

    def extract_frontmatter(self, content: str) -> tuple[Dict[str, Any], str]:
        """
        Extract YAML frontmatter from markdown content.

        Args:
            content: Markdown content with optional YAML frontmatter

        Returns:
            Tuple of (frontmatter dict, body content)
        """
        import yaml

        frontmatter: Dict[str, Any] = {}
        body = content

        if content.startswith("---"):
            end_marker = content.find("---", 3)
            if end_marker != -1:
                yaml_content = content[3:end_marker].strip()
                try:
                    frontmatter = yaml.safe_load(yaml_content) or {}
                except yaml.YAMLError:
                    pass
                body = content[end_marker + 3:].strip()

        return frontmatter, body

    def create_frontmatter(self, data: Dict[str, Any]) -> str:
        """
        Create YAML frontmatter string from dictionary.

        Args:
            data: Dictionary to convert to YAML frontmatter

        Returns:
            YAML frontmatter string with --- delimiters
        """
        import yaml

        if not data:
            return ""

        yaml_str = yaml.dump(data, default_flow_style=False, allow_unicode=True)
        return f"---\n{yaml_str}---\n"

    def replace_terminology(self, content: str) -> str:
        """
        Replace Ring terminology with platform-specific terms.

        Args:
            content: Content with Ring terminology

        Returns:
            Content with platform-specific terminology
        """
        terminology = self.get_terminology()
        result = content

        for ring_term, platform_term in terminology.items():
            if ring_term != platform_term:
                # Case-sensitive replacements
                result = result.replace(ring_term, platform_term)
                result = result.replace(ring_term.title(), platform_term.title())
                result = result.replace(ring_term.upper(), platform_term.upper())

        return result

    def get_target_filename(self, source_filename: str, component_type: str) -> str:
        """
        Get the target filename for a component.

        Args:
            source_filename: Original filename
            component_type: Type of component (skill, agent, command)

        Returns:
            Target filename for this platform
        """
        mapping = self.get_component_mapping()
        component_config = mapping.get(f"{component_type}s", {})

        source_path = Path(source_filename)
        target_ext = component_config.get("extension", source_path.suffix)

        return source_path.stem + target_ext

    def supports_component(self, component_type: str) -> bool:
        """
        Check if this platform supports a specific component type.

        Args:
            component_type: Type of component (skills, agents, commands, hooks)

        Returns:
            True if the platform supports this component type
        """
        mapping = self.get_component_mapping()
        return component_type in mapping

    def requires_flat_components(self, component_type: str) -> bool:
        """
        Check if this platform requires flat (non-nested) directory structure for a component type.

        Some platforms (e.g., Factory/Droid) only scan top-level files in their
        component directories and won't discover files in subdirectories.

        Args:
            component_type: Type of component (agents, commands, skills, hooks)

        Returns:
            True if the platform requires flat structure (no subdirectories)
        """
        return False

    def get_flat_filename(self, source_filename: str, component_type: str, plugin_name: str) -> str:
        """
        Get a flattened filename with plugin prefix to avoid collisions.

        Used when requires_flat_components() returns True for multi-plugin installs.

        Args:
            source_filename: Original filename
            component_type: Type of component (agent, command, skill)
            plugin_name: Name of the plugin this component belongs to

        Returns:
            Filename with plugin prefix (e.g., "ring-default-code-reviewer.md")
        """
        base_filename = self.get_target_filename(source_filename, component_type)
        source_path = Path(base_filename)

        # Add plugin prefix for disambiguation
        return f"ring-{plugin_name}-{source_path.stem}{source_path.suffix}"

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(platform_id='{self.platform_id}')"
