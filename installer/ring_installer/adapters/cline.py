"""
Cline adapter - converts Ring format to Cline prompts.

Cline (VS Code extension) uses a prompt-based system where all components
(skills, agents, commands) become prompt files that can be referenced.
"""

import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from ring_installer.adapters.base import PlatformAdapter


class ClineAdapter(PlatformAdapter):
    """
    Platform adapter for Cline.

    Cline uses "prompts" for all component types. Prompts are markdown files
    that can be referenced and composed together.
    """

    platform_id = "cline"
    platform_name = "Cline"

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the Cline adapter.

        Args:
            config: Platform-specific configuration from platforms.json
        """
        super().__init__(config)

    def transform_skill(self, skill_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring skill to a Cline prompt.

        Converts the Ring skill format to Cline's prompt format, which uses
        a simpler structure focused on clear instructions.

        Args:
            skill_content: The original skill content
            metadata: Optional metadata about the skill

        Returns:
            Transformed prompt content for Cline
        """
        frontmatter, body = self.extract_frontmatter(skill_content)

        prompt_parts: List[str] = []

        # Extract metadata
        name = frontmatter.get("name", metadata.get("name", "Untitled") if metadata else "Untitled")
        description = frontmatter.get("description", "")

        # Create prompt header with metadata comment
        prompt_parts.append(f"<!-- Prompt: {name} -->")
        prompt_parts.append("<!-- Type: skill -->")
        if metadata and "source_path" in metadata:
            prompt_parts.append(f"<!-- Source: {metadata['source_path']} -->")
        prompt_parts.append("")

        # Title
        prompt_parts.append(f"# {self._format_title(name)}")
        prompt_parts.append("")

        # Description as summary
        if description:
            clean_desc = self._clean_multiline_string(description)
            prompt_parts.append(f"> {clean_desc}")
            prompt_parts.append("")

        # Trigger conditions as "Use When" section
        trigger = frontmatter.get("trigger", "")
        if trigger:
            prompt_parts.append("## Use This Prompt When")
            prompt_parts.append("")
            self._add_list_items(prompt_parts, trigger)
            prompt_parts.append("")

        # Skip conditions
        skip_when = frontmatter.get("skip_when", "")
        if skip_when:
            prompt_parts.append("## Do Not Use When")
            prompt_parts.append("")
            self._add_list_items(prompt_parts, skip_when)
            prompt_parts.append("")

        # Related prompts
        related = frontmatter.get("related", {})
        if related:
            similar = related.get("similar", [])
            complementary = related.get("complementary", [])
            if similar or complementary:
                prompt_parts.append("## Related Prompts")
                prompt_parts.append("")
                if similar:
                    prompt_parts.append("**Similar:** " + ", ".join(similar))
                if complementary:
                    prompt_parts.append("**Works well with:** " + ", ".join(complementary))
                prompt_parts.append("")

        # Main instructions
        prompt_parts.append("## Instructions")
        prompt_parts.append("")
        prompt_parts.append(self._transform_body_for_cline(body))

        return "\n".join(prompt_parts)

    def transform_agent(self, agent_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring agent to a Cline prompt.

        Converts agent format to Cline's prompt format with role definition
        and capabilities.

        Args:
            agent_content: The original agent content
            metadata: Optional metadata about the agent

        Returns:
            Transformed prompt content for Cline
        """
        frontmatter, body = self.extract_frontmatter(agent_content)

        prompt_parts: List[str] = []

        # Extract metadata
        name = frontmatter.get("name", metadata.get("name", "Untitled Agent") if metadata else "Untitled Agent")
        description = frontmatter.get("description", "")
        model = frontmatter.get("model", "") or "inherit"

        # Create prompt header with metadata comment
        prompt_parts.append(f"<!-- Prompt: {name} -->")
        prompt_parts.append("<!-- Type: agent -->")
        if model:
            prompt_parts.append(f"<!-- Recommended Model: {model} -->")
        if metadata and "source_path" in metadata:
            prompt_parts.append(f"<!-- Source: {metadata['source_path']} -->")
        prompt_parts.append("")

        # Title with role indicator
        prompt_parts.append(f"# {self._format_title(name)} Agent")
        prompt_parts.append("")

        # Role description
        if description:
            clean_desc = self._clean_multiline_string(description)
            prompt_parts.append("## Role")
            prompt_parts.append("")
            prompt_parts.append(clean_desc)
            prompt_parts.append("")

        # Model recommendation
        if model:
            prompt_parts.append(f"**Recommended Model:** `{model}`")
            prompt_parts.append("")

        # Output requirements from schema
        output_schema = frontmatter.get("output_schema", {})
        if output_schema:
            prompt_parts.append("## Expected Output Format")
            prompt_parts.append("")
            output_format = output_schema.get("format", "markdown")
            prompt_parts.append(f"Format: {output_format}")
            prompt_parts.append("")
            required_sections = output_schema.get("required_sections", [])
            if required_sections:
                prompt_parts.append("Required sections:")
                for section in required_sections:
                    section_name = section.get("name", "")
                    if section_name:
                        prompt_parts.append(f"- {section_name}")
                prompt_parts.append("")

        # Behavior and capabilities
        prompt_parts.append("## Behavior")
        prompt_parts.append("")
        prompt_parts.append(self._transform_body_for_cline(body))

        return "\n".join(prompt_parts)

    def transform_command(self, command_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring command to a Cline prompt.

        Commands become action-oriented prompts in Cline.

        Args:
            command_content: The original command content
            metadata: Optional metadata about the command

        Returns:
            Transformed prompt content for Cline
        """
        frontmatter, body = self.extract_frontmatter(command_content)

        prompt_parts: List[str] = []

        # Extract metadata
        name = frontmatter.get("name", metadata.get("name", "Untitled Command") if metadata else "Untitled Command")
        description = frontmatter.get("description", "")

        # Create prompt header with metadata comment
        prompt_parts.append(f"<!-- Prompt: {name} -->")
        prompt_parts.append("<!-- Type: command -->")
        if metadata and "source_path" in metadata:
            prompt_parts.append(f"<!-- Source: {metadata['source_path']} -->")
        prompt_parts.append("")

        # Title
        prompt_parts.append(f"# {self._format_title(name)}")
        prompt_parts.append("")

        # Description
        if description:
            clean_desc = self._clean_multiline_string(description)
            prompt_parts.append(f"> {clean_desc}")
            prompt_parts.append("")

        # Arguments/parameters
        args = frontmatter.get("args", [])
        if args:
            prompt_parts.append("## Parameters")
            prompt_parts.append("")
            for arg in args:
                arg_name = arg.get("name", "")
                arg_desc = arg.get("description", "")
                required = arg.get("required", False)
                default = arg.get("default", "")

                param_line = f"- **{arg_name}**"
                if required:
                    param_line += " (required)"
                else:
                    param_line += " (optional)"
                if arg_desc:
                    param_line += f": {arg_desc}"
                if default:
                    param_line += f" [default: {default}]"
                prompt_parts.append(param_line)
            prompt_parts.append("")

        # Instructions
        prompt_parts.append("## Steps")
        prompt_parts.append("")
        prompt_parts.append(self._transform_body_for_cline(body))

        return "\n".join(prompt_parts)

    def get_install_path(self) -> Path:
        """
        Get the installation path for Cline.

        Returns:
            Path to ~/.cline directory
        """
        if self._install_path is None:
            base_path = self.config.get("install_path", "~/.cline")
            self._install_path = Path(base_path).expanduser()
        return self._install_path

    def get_component_mapping(self) -> Dict[str, Dict[str, str]]:
        """
        Get the component mapping for Cline.

        Returns:
            Mapping of Ring components to Cline directories
        """
        return {
            "agents": {
                "target_dir": "prompts/agents",
                "extension": ".md"
            },
            "commands": {
                "target_dir": "prompts/commands",
                "extension": ".md"
            },
            "skills": {
                "target_dir": "prompts/skills",
                "extension": ".md"
            }
        }

    def get_terminology(self) -> Dict[str, str]:
        """
        Get Cline terminology.

        Returns:
            Mapping of Ring terms to Cline terms
        """
        return {
            "agent": "prompt",
            "skill": "prompt",
            "command": "prompt",
            "hook": "automation"
        }

    def is_native_format(self) -> bool:
        """
        Check if this platform uses Ring's native format.

        Returns:
            False - Cline requires transformation
        """
        return False

    def _format_title(self, name: str) -> str:
        """
        Format a name as a readable title.

        Args:
            name: Component name (may be kebab-case or snake_case)

        Returns:
            Formatted title
        """
        # Replace separators with spaces
        title = name.replace("-", " ").replace("_", " ")
        # Title case
        return title.title()

    def _clean_multiline_string(self, text: str) -> str:
        """
        Clean up YAML multi-line string.

        Args:
            text: YAML string value

        Returns:
            Cleaned string
        """
        # Remove YAML multi-line markers
        text = re.sub(r'^[|>]\s*', '', text)
        # Normalize whitespace
        text = " ".join(text.split())
        return text.strip()

    def _add_list_items(self, parts: List[str], text: str) -> None:
        """
        Add list items from a YAML list or multi-line string.

        Args:
            parts: List to append to
            text: YAML list or multi-line string
        """
        clean_text = self._clean_multiline_string(text)
        for line in clean_text.split("\n"):
            line = line.strip()
            if line:
                if line.startswith("-"):
                    parts.append(line)
                else:
                    parts.append(f"- {line}")

    def _transform_body_for_cline(self, body: str) -> str:
        """
        Transform body content for Cline compatibility.

        Args:
            body: Original body content

        Returns:
            Transformed body content
        """
        result = body

        # Replace Ring-specific terminology with Cline equivalents
        replacements = [
            # Tool references
            ("Task tool", "sub-prompt"),
            ("Skill tool", "prompt reference"),
            ("subagent", "sub-prompt"),
            ("Subagent", "Sub-prompt"),
        ]

        for old, new in replacements:
            result = result.replace(old, new)

        # Transform Ring tool references to Cline prompt references
        result = re.sub(
            r'`ring:([^`]+)`',
            lambda m: f'@{self._format_prompt_reference(m.group(1))}',
            result
        )

        # Transform agent references
        result = re.sub(
            r'"ring:([^"]+)"',
            lambda m: f'"@{self._format_prompt_reference(m.group(1))}"',
            result
        )

        return result

    def _format_prompt_reference(self, name: str) -> str:
        """
        Format a Ring reference as a Cline prompt reference.

        Args:
            name: Ring component name

        Returns:
            Cline prompt reference format
        """
        # Convert kebab-case to path-like format
        # ring:code-reviewer -> code-reviewer
        return name.lower().replace("_", "-")

    def generate_prompt_index(self, prompts: List[Dict[str, str]]) -> str:
        """
        Generate an index file listing all available prompts.

        Args:
            prompts: List of prompt metadata dicts with name, type, description

        Returns:
            Markdown content for the index file
        """
        lines = [
            "# Ring Prompts for Cline",
            "",
            "This directory contains Ring skills, agents, and commands converted to Cline prompts.",
            "",
        ]

        # Group by type
        by_type: Dict[str, List[Dict[str, str]]] = {
            "agents": [],
            "commands": [],
            "skills": []
        }

        for prompt in prompts:
            prompt_type = prompt.get("type", "skills")
            if prompt_type in by_type:
                by_type[prompt_type].append(prompt)

        # Add sections
        for prompt_type, type_prompts in by_type.items():
            if type_prompts:
                lines.append(f"## {prompt_type.title()}")
                lines.append("")
                for prompt in type_prompts:
                    name = prompt.get("name", "")
                    desc = prompt.get("description", "")
                    path = prompt.get("path", "")
                    lines.append(f"- **{self._format_title(name)}** - {desc}")
                    if path:
                        lines.append(f"  - Path: `{path}`")
                lines.append("")

        return "\n".join(lines)

    def get_vscode_settings_path(self) -> Path:
        """
        Get the path to VS Code settings for Cline configuration.

        Returns:
            Path to VS Code settings directory
        """
        import sys

        if sys.platform == "darwin":
            return Path.home() / "Library/Application Support/Code/User"
        elif sys.platform == "win32":
            return Path.home() / "AppData/Roaming/Code/User"
        else:
            return Path.home() / ".config/Code/User"
