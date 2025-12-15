"""
Factory AI adapter - converts Ring format to Factory's droid-based format.

Factory AI uses similar concepts to Ring but with different terminology:
- agents -> droids
- skills -> skills (same)
- commands -> commands (same)
"""

import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from ring_installer.adapters.base import PlatformAdapter


class FactoryAdapter(PlatformAdapter):
    """
    Platform adapter for Factory AI.

    Factory AI uses "droids" instead of "agents" and has slight differences
    in how components are structured.
    """

    platform_id = "factory"
    platform_name = "Factory AI"

    _FACTORY_TOOL_NAME_MAP: Dict[str, str] = {
        # Factory tool names
        "WebFetch": "FetchUrl",
        "FetchURL": "FetchUrl",
        "Bash": "Execute",
        # Context7 tool names (Factory uses triple-underscore namespace)
        "mcp__context7__resolve-library-id": "context7___resolve-library-id",
        "mcp__context7__get-library-docs": "context7___get-library-docs",
    }

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
        body = self._replace_factory_tool_references(body)

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
            frontmatter = self._qualify_droid_name(frontmatter, metadata)

        # Transform body content
        body = self._transform_agent_body(body)

        # Rebuild the content
        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def _qualify_droid_name(
        self,
        frontmatter: Dict[str, Any],
        metadata: Optional[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Qualify droid name with plugin namespace.

        Factory installs droids into a single flat directory. To avoid name collisions
        across plugins and to match Ring's fully-qualified invocation format, droids
        MUST be addressable as:

            ring-<plugin>:<name>

        Example:
            plugin=default, name=code-reviewer -> ring-default:code-reviewer
        """
        result = dict(frontmatter)

        plugin = (metadata or {}).get("plugin")
        if not isinstance(plugin, str) or not plugin:
            return result

        plugin_id = plugin if plugin.startswith("ring-") else f"ring-{plugin}"

        name = result.get("name")
        if not isinstance(name, str) or not name:
            fallback_name = (metadata or {}).get("name")
            if isinstance(fallback_name, str) and fallback_name:
                name = fallback_name
            else:
                return result

        # Already qualified
        if ":" in name:
            return result

        result["name"] = f"{plugin_id}:{name}"
        return result

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
        body = self._replace_factory_tool_references(body)

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
            # Prefer `droid_type` for Factory invocation, but keep `subdroid_type`
            # as a backward-compatible alias.
            value = result.pop("subagent_type")
            result["droid_type"] = value
            result.setdefault("subdroid_type", value)

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

        # Transform tools list for Factory compatibility
        if "tools" in result:
            result["tools"] = self._transform_tools_for_factory(result["tools"])

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
        body = self._replace_factory_tool_references(body)

        # Replace section headers
        replacements = [
            ("# Agent ", "# Droid "),
            ("## Agent ", "## Droid "),
            ("### Agent ", "### Droid "),
        ]

        for old, new in replacements:
            body = body.replace(old, new)

        return body

    def _transform_tools_for_factory(self, tools: Any) -> Any:
        """Normalize tool names in frontmatter for Factory.

        Factory validates the `tools:` list strictly; invalid entries cause the
        droid to be rejected during load.
        """
        if not isinstance(tools, list):
            return tools

        normalized: List[Any] = []
        for tool in tools:
            if not isinstance(tool, str):
                normalized.append(tool)
                continue

            # Droids cannot spawn other droids.
            if tool == "Task":
                continue

            normalized.append(self._FACTORY_TOOL_NAME_MAP.get(tool, tool))

        return normalized

    def _replace_factory_tool_references(self, text: str) -> str:
        """Replace tool references in content so installed droids' instructions match Factory."""
        result = text
        for old, new in self._FACTORY_TOOL_NAME_MAP.items():
            result = result.replace(old, new)
        return result

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
        # Protect code blocks, inline code, and URLs from replacement
        protected_regions: List[Tuple[int, int]] = []

        patterns = [
            r"```[\s\S]*?```",  # fenced code blocks
            r"`[^`]+`",  # inline code
            r"https?://[^\s)]+|www\.[^\s)]+",  # URLs
        ]

        for pattern in patterns:
            for match in re.finditer(pattern, text):
                protected_regions.append((match.start(), match.end()))

        if protected_regions:
            protected_regions.sort()
            merged: List[List[int]] = []
            for start, end in protected_regions:
                if not merged or start > merged[-1][1]:
                    merged.append([start, end])
                else:
                    merged[-1][1] = max(merged[-1][1], end)

            placeholders: List[str] = []
            parts: List[str] = []
            last = 0
            for i, (start, end) in enumerate(merged):
                parts.append(text[last:start])
                placeholders.append(text[start:end])
                parts.append(f"\x00RING_PROTECTED_{i}\x00")
                last = end
            parts.append(text[last:])
            masked = "".join(parts)
        else:
            placeholders = []
            masked = text

        # Ring-specific context patterns
        ring_contexts = [
            # Tool references
            (r'"ring:([^"]*)-agent"', r'"ring:\1-droid"'),
            (r"'ring:([^']*)-agent'", r"'ring:\1-droid'"),
            # Subagent references
            (r"\bsubagent_type\b", "droid_type"),
            (r'\bsubagent\b', 'subdroid'),
            (r'\bSubagent\b', 'Subdroid'),
        ]

        result = masked
        for pattern, replacement in ring_contexts:
            result = re.sub(pattern, replacement, result)

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
            result = re.sub(pattern, replacement, result)

        # Restore protected regions
        for i, original in enumerate(placeholders):
            result = result.replace(f"\x00RING_PROTECTED_{i}\x00", original)

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

    def requires_flat_components(self, component_type: str) -> bool:
        """
        Check if Factory requires flat directory structure for a component type.

        Factory/Droid only scans top-level .md files in ~/.factory/droids/
        and won't discover droids in subdirectories.

        Args:
            component_type: Type of component (agents, commands, skills, hooks)

        Returns:
            True for agents (droids) since Factory requires flat structure
        """
        # Factory scans droids as a flat list and expects skills at skills/<name>/SKILL.md.
        return component_type in {"agents", "skills"}

    def get_flat_filename(self, source_filename: str, component_type: str, plugin_name: str) -> str:
        """
        Get a flattened filename with plugin prefix for Factory.

        Factory requires droids to be in top-level ~/.factory/droids/ directory.
        When installing multiple plugins, we prefix filenames to avoid collisions.

        Args:
            source_filename: Original filename
            component_type: Type of component (agent, command, skill)
            plugin_name: Name of the plugin this component belongs to

        Returns:
            Filename with plugin prefix and droid suffix
            (e.g., "code-reviewer.md" from "default" plugin -> "ring-default-code-reviewer-droid.md")
        """
        from pathlib import Path

        source_path = Path(source_filename)
        stem = source_path.stem

        # For agents/droids, apply the agent->droid transformation and add prefix
        if component_type == "agent":
            # Remove -agent suffix if present before adding -droid
            stem = re.sub(r'-agent$', '', stem)
            stem = re.sub(r'_agent$', '', stem)
            return f"ring-{plugin_name}-{stem}-droid.md"

        # For other component types, just add prefix
        return f"ring-{plugin_name}-{stem}{source_path.suffix}"
