"""
Factory AI adapter - converts Ring format to Factory's droid-based format.

Factory AI uses similar concepts to Ring but with different terminology:
- agents -> droids
- skills -> skills (same)
- commands -> commands (same)
"""

import os
from pathlib import Path
from typing import Dict, Optional, Any
import re

from ring_installer.adapters.base import PlatformAdapter


class FactoryAdapter(PlatformAdapter):
    """
    Platform adapter for Factory AI.

    Factory AI uses "droids" instead of "agents" and has slight differences
    in how components are structured.
    """

    platform_id = "factory"
    platform_name = "Factory AI"

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the Factory AI adapter.

        Args:
            config: Platform-specific configuration from platforms.json
        """
        super().__init__(config)

    def transform_skill(self, skill_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring skill for Factory AI.

        Updates terminology and adjusts frontmatter for Factory compatibility.

        Args:
            skill_content: The original skill content
            metadata: Optional metadata about the skill

        Returns:
            Transformed skill content for Factory AI
        """
        frontmatter, body = self.extract_frontmatter(skill_content)

        # Update frontmatter terminology
        if frontmatter:
            frontmatter = self._transform_frontmatter(frontmatter)

        # Replace agent references with droid references in body
        body = self._replace_agent_references(body)

        # Rebuild the content
        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def transform_agent(self, agent_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring agent to a Factory AI droid.

        Converts agent format to Factory's droid format, updating terminology
        and structure as needed.

        Args:
            agent_content: The original agent content
            metadata: Optional metadata about the agent

        Returns:
            Transformed droid content for Factory AI
        """
        frontmatter, body = self.extract_frontmatter(agent_content)

        # Transform frontmatter
        if frontmatter:
            frontmatter = self._transform_agent_frontmatter(frontmatter)

        # Transform body content
        body = self._transform_agent_body(body)

        # Rebuild the content
        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def transform_command(self, command_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring command for Factory AI.

        Updates terminology and adjusts any agent references to droid references.

        Args:
            command_content: The original command content
            metadata: Optional metadata about the command

        Returns:
            Transformed command content for Factory AI
        """
        frontmatter, body = self.extract_frontmatter(command_content)

        # Update frontmatter terminology
        if frontmatter:
            frontmatter = self._transform_frontmatter(frontmatter)

        # Replace agent references in body
        body = self._replace_agent_references(body)

        # Rebuild the content
        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def get_install_path(self) -> Path:
        """
        Get the installation path for Factory AI.

        Returns:
            Path to ~/.factory directory
        """
        if self._install_path is None:
            env_path = Path(self.config.get("install_path", "~/.factory")).expanduser()
            override = os.environ.get("FACTORY_CONFIG_PATH")
            if override:
                candidate = Path(override).expanduser().resolve()
                home = Path.home().resolve()
                try:
                    candidate.relative_to(home)
                    env_path = candidate
                except ValueError:
                    import logging
                    logging.getLogger(__name__).warning(
                        "FACTORY_CONFIG_PATH=%s ignored: path must be under home", override
                    )
            self._install_path = env_path
        return self._install_path

    def get_component_mapping(self) -> Dict[str, Dict[str, str]]:
        """
        Get the component mapping for Factory AI.

        Returns:
            Mapping of Ring components to Factory AI directories
        """
        return {
            "agents": {
                "target_dir": "droids",
                "extension": ".md"
            },
            "commands": {
                "target_dir": "commands",
                "extension": ".md"
            },
            "skills": {
                "target_dir": "skills",
                "extension": ".md"
            }
        }

    def get_terminology(self) -> Dict[str, str]:
        """
        Get Factory AI terminology.

        Returns:
            Mapping of Ring terms to Factory AI terms
        """
        return {
            "agent": "droid",
            "skill": "skill",
            "command": "command",
            "hook": "trigger"
        }

    def is_native_format(self) -> bool:
        """
        Check if this platform uses Ring's native format.

        Returns:
            False - Factory AI requires transformation
        """
        return False

    def _transform_frontmatter(self, frontmatter: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform frontmatter for Factory AI compatibility.

        Args:
            frontmatter: Original frontmatter dictionary

        Returns:
            Transformed frontmatter dictionary
        """
        result = dict(frontmatter)

        # Rename agent-related fields
        if "agent" in result:
            result["droid"] = result.pop("agent")

        if "agents" in result:
            result["droids"] = result.pop("agents")

        # Update subagent_type references
        if "subagent_type" in result:
            result["subdroid_type"] = result.pop("subagent_type")

        # Transform any string values containing "agent"
        for key, value in result.items():
            if isinstance(value, str):
                result[key] = self._replace_agent_references(value)
            elif isinstance(value, list):
                result[key] = [
                    self._replace_agent_references(v) if isinstance(v, str) else v
                    for v in value
                ]

        return result

    def _transform_agent_frontmatter(self, frontmatter: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform agent-specific frontmatter to droid frontmatter.

        Args:
            frontmatter: Original agent frontmatter

        Returns:
            Transformed droid frontmatter
        """
        result = self._transform_frontmatter(frontmatter)

        # Add Factory-specific droid configuration
        if "type" not in result:
            result["type"] = "droid"

        # Transform model configuration if present
        if "model" in result:
            # Factory might use different model naming
            model = result["model"]
            if model.startswith("claude"):
                result["model"] = model  # Keep as-is, Factory supports Claude models

        return result

    def _transform_agent_body(self, body: str) -> str:
        """
        Transform agent body content to droid format.

        Args:
            body: Original agent body content

        Returns:
            Transformed droid body content
        """
        # Replace terminology
        body = self._replace_agent_references(body)

        # Replace section headers
        replacements = [
            ("# Agent ", "# Droid "),
            ("## Agent ", "## Droid "),
            ("### Agent ", "### Droid "),
        ]

        for old, new in replacements:
            body = body.replace(old, new)

        return body

    def _replace_agent_references(self, text: str) -> str:
        """
        Replace agent references with droid references.

        This function performs selective replacement to avoid replacing
        "agent" in unrelated contexts like "user agent", URLs, or code blocks.

        Args:
            text: Text containing agent references

        Returns:
            Text with droid references
        """
        # First, protect code blocks and URLs from replacement
        protected_regions = []

        # Protect code blocks (fenced)
        code_block_pattern = r'```[\s\S]*?```'
        for match in re.finditer(code_block_pattern, text):
            protected_regions.append((match.start(), match.end()))

        # Protect inline code
        inline_code_pattern = r'`[^`]+`'
        for match in re.finditer(inline_code_pattern, text):
            protected_regions.append((match.start(), match.end()))

        # Protect URLs
        url_pattern = r'https?://[^\s)]+|www\.[^\s)]+'
        for match in re.finditer(url_pattern, text):
            protected_regions.append((match.start(), match.end()))

        def is_protected(pos: int) -> bool:
            """Check if a position is within a protected region."""
            return any(start <= pos < end for start, end in protected_regions)

        # Ring-specific context patterns
        ring_contexts = [
            # Tool references
            (r'"ring:([^"]*)-agent"', r'"ring:\1-droid"'),
            (r"'ring:([^']*)-agent'", r"'ring:\1-droid'"),
            # Subagent references
            (r'\bsubagent_type\b', 'subdroid_type'),
            (r'\bsubagent\b', 'subdroid'),
            (r'\bSubagent\b', 'Subdroid'),
        ]

        result = text
        for pattern, replacement in ring_contexts:
            # Replace only in non-protected regions
            matches = list(re.finditer(pattern, result))
            offset = 0
            for match in matches:
                if not is_protected(match.start() + offset):
                    result = result[:match.start() + offset] + re.sub(pattern, replacement, match.group()) + result[match.end() + offset:]
                    offset += len(re.sub(pattern, replacement, match.group())) - len(match.group())

        # General agent terminology (with exclusions)
        general_replacements = [
            # Skip "user agent" and similar patterns
            (r'\b(?<!user\s)(?<!User\s)(?<!USER\s)agent\b(?!\s+string)(?!\s+header)', 'droid'),
            (r'\b(?<!user\s)(?<!User\s)(?<!USER\s)Agent\b(?!\s+string)(?!\s+header)', 'Droid'),
            (r'\bAGENT\b(?!\s+STRING)(?!\s+HEADER)', 'DROID'),
            (r'\b(?<!user\s)(?<!User\s)(?<!USER\s)agents\b(?!\s+strings)(?!\s+headers)', 'droids'),
            (r'\b(?<!user\s)(?<!User\s)(?<!USER\s)Agents\b(?!\s+strings)(?!\s+headers)', 'Droids'),
            (r'\bAGENTS\b(?!\s+STRINGS)(?!\s+HEADERS)', 'DROIDS'),
        ]

        for pattern, replacement in general_replacements:
            matches = list(re.finditer(pattern, result))
            offset = 0
            for match in matches:
                if not is_protected(match.start() + offset):
                    result = result[:match.start() + offset] + replacement + result[match.end() + offset:]
                    offset += len(replacement) - len(match.group())

        return result

    def get_target_filename(self, source_filename: str, component_type: str) -> str:
        """
        Get the target filename for a component in Factory AI.

        Args:
            source_filename: Original filename
            component_type: Type of component

        Returns:
            Target filename, with agent->droid renaming if applicable
        """
        filename = super().get_target_filename(source_filename, component_type)

        # Rename *-agent.md files to *-droid.md
        if component_type == "agent":
            filename = re.sub(r'-agent\.md$', '-droid.md', filename)
            filename = re.sub(r'_agent\.md$', '_droid.md', filename)

        return filename
