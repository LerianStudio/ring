"""
OpenCode adapter - converts Ring format to OpenCode's format.

OpenCode (OhMyOpenCode) is a Claude Code-compatible AI agent platform.
It uses similar concepts to Ring/Claude Code with minor directory differences:
- agents -> agent (singular directory name)
- commands -> command (singular directory name)
- skills -> skill (singular directory name)
- hooks -> integrated into config or via plugins
"""

import json
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from ring_installer.adapters.base import PlatformAdapter


class OpenCodeAdapter(PlatformAdapter):
    """
    Platform adapter for OpenCode (OhMyOpenCode).

    OpenCode uses a format very similar to Claude Code with these differences:
    - Install path: ~/.config/opencode/ (user) or .opencode/ (project)
    - Directory names: singular (agent/, command/, skill/) not plural
    - Hooks: Merged into opencode.json config or handled via plugins
    - Config: opencode.json or opencode.jsonc instead of settings.json

    Key OpenCode features:
    - Agent modes: primary, subagent, all
    - Tools: bash, read, write, edit, list, glob, grep, webfetch, task, todowrite, todoread
    - Model format: provider/model-id (e.g., anthropic/claude-sonnet-4-5)
    """

    platform_id = "opencode"
    platform_name = "OpenCode"

    # OpenCode tool name mappings (Claude Code -> OpenCode)
    _OPENCODE_TOOL_NAME_MAP: Dict[str, str] = {
        # Claude Code uses capitalized, OpenCode uses lowercase
        "Bash": "bash",
        "Read": "read",
        "Write": "write",
        "Edit": "edit",
        "List": "list",
        "Glob": "glob",
        "Grep": "grep",
        "WebFetch": "webfetch",
        "Task": "task",
        "TodoWrite": "todowrite",
        "TodoRead": "todoread",
        # Aliases
        "MultiEdit": "edit",
        "NotebookEdit": "edit",
        "BrowseURL": "webfetch",
        "FetchURL": "webfetch",
    }

    # Model shorthand to OpenCode model ID mapping
    _OPENCODE_MODEL_MAP: Dict[str, str] = {
        "opus": "anthropic/claude-opus-4-5",
        "sonnet": "anthropic/claude-sonnet-4-5",
        "haiku": "anthropic/claude-haiku-4-5",
        "inherit": "inherit",
    }

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the OpenCode adapter.

        Args:
            config: Platform-specific configuration from platforms.json
        """
        super().__init__(config)

    def transform_skill(self, skill_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring skill for OpenCode.

        OpenCode uses the same markdown + YAML frontmatter format as Ring/Claude Code.
        Transformation is mostly passthrough with tool name normalization.

        Args:
            skill_content: The original skill content
            metadata: Optional metadata about the skill

        Returns:
            Transformed skill content for OpenCode
        """
        frontmatter, body = self.extract_frontmatter(skill_content)

        if frontmatter:
            frontmatter = self._transform_frontmatter(frontmatter)

        body = self._normalize_tool_references(body)

        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def transform_agent(self, agent_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring agent for OpenCode.

        OpenCode agents support:
        - mode: primary, subagent, all
        - model: provider/model-id format
        - tools: object or array of tool names
        - description, hidden, subtask flags

        Args:
            agent_content: The original agent content
            metadata: Optional metadata about the agent

        Returns:
            Transformed agent content for OpenCode
        """
        frontmatter, body = self.extract_frontmatter(agent_content)

        if frontmatter:
            frontmatter = self._transform_agent_frontmatter(frontmatter)

        body = self._normalize_tool_references(body)

        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def transform_command(self, command_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring command for OpenCode.

        OpenCode commands support:
        - description: Brief description
        - model: Override model for this command
        - subtask: Mark as subtask command
        - argument-hint: Usage hint for arguments

        Args:
            command_content: The original command content
            metadata: Optional metadata about the command

        Returns:
            Transformed command content for OpenCode
        """
        frontmatter, body = self.extract_frontmatter(command_content)

        if frontmatter:
            frontmatter = self._transform_command_frontmatter(frontmatter)

        body = self._normalize_tool_references(body)

        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def transform_hook(self, hook_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Transform a Ring hook for OpenCode.

        OpenCode handles hooks differently - they're typically integrated into
        the opencode.json config or handled via plugins. This transforms
        hook paths for OpenCode's directory structure.

        Args:
            hook_content: The original hook content (JSON or script)
            metadata: Optional metadata about the hook

        Returns:
            Transformed hook content for OpenCode
        """
        result = hook_content.replace("${CLAUDE_PLUGIN_ROOT}/hooks/", "bash ~/.config/opencode/hook/")
        result = result.replace("$CLAUDE_PLUGIN_ROOT/hooks/", "bash ~/.config/opencode/hook/")
        result = result.replace("${CLAUDE_PLUGIN_ROOT}", "~/.config/opencode")
        result = result.replace("$CLAUDE_PLUGIN_ROOT", "~/.config/opencode")

        return result

    def get_install_path(self) -> Path:
        """
        Get the installation path for OpenCode.

        Returns:
            Path to ~/.config/opencode directory
        """
        if self._install_path is None:
            env_path = Path(self.config.get("install_path", "~/.config/opencode")).expanduser()
            override = os.environ.get("OPENCODE_CONFIG_PATH")
            if override:
                candidate = Path(override).expanduser().resolve()
                home = Path.home().resolve()
                try:
                    candidate.relative_to(home)
                    env_path = candidate
                except ValueError:
                    import logging
                    logging.getLogger(__name__).warning(
                        "OPENCODE_CONFIG_PATH=%s ignored: path must be under home", override
                    )
            self._install_path = env_path
        return self._install_path

    def get_component_mapping(self) -> Dict[str, Dict[str, str]]:
        """
        Get the component mapping for OpenCode.

        Note: OpenCode uses singular directory names (agent/, command/, skill/)
        unlike Claude Code which uses plural (agents/, commands/, skills/).

        Returns:
            Mapping of Ring components to OpenCode directories
        """
        return {
            "agents": {
                "target_dir": "agent",  # Singular in OpenCode
                "extension": ".md"
            },
            "commands": {
                "target_dir": "command",  # Singular in OpenCode
                "extension": ".md"
            },
            "skills": {
                "target_dir": "skill",  # Singular in OpenCode
                "extension": ".md"
            },
            "hooks": {
                "target_dir": "hook",  # Singular in OpenCode
                "extension": ""  # Multiple extensions supported
            }
        }

    def get_terminology(self) -> Dict[str, str]:
        """
        Get OpenCode terminology.

        OpenCode uses the same terminology as Claude Code/Ring.

        Returns:
            Identity mapping since OpenCode uses Ring terminology
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
            True - OpenCode uses a very similar format to Ring (near-native)
        """
        return True  # Close enough to native that minimal transformation is needed

    def requires_hooks_in_settings(self) -> bool:
        """
        Check if this platform requires hooks to be merged into settings.

        OpenCode can handle hooks via the opencode.json config file,
        but also supports hook files in the hook/ directory.

        Returns:
            False - OpenCode supports standalone hook files
        """
        return False

    def _transform_frontmatter(self, frontmatter: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform frontmatter for OpenCode compatibility.

        Args:
            frontmatter: Original frontmatter dictionary

        Returns:
            Transformed frontmatter dictionary
        """
        result = dict(frontmatter)

        if "model" in result:
            model = result["model"]
            if model in self._OPENCODE_MODEL_MAP:
                result["model"] = self._OPENCODE_MODEL_MAP[model]
            elif "/" not in str(model) and model != "inherit":
                result["model"] = f"anthropic/{model}"

        if "tools" in result:
            result["tools"] = self._transform_tools_for_opencode(result["tools"])

        return result

    def _transform_agent_frontmatter(self, frontmatter: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform agent-specific frontmatter for OpenCode.

        OpenCode agent frontmatter fields:
        - mode: primary, subagent, all
        - model: provider/model-id
        - tools: object or array
        - description: Brief description
        - hidden: Hide from agent list
        - subtask: Mark as subtask agent
        - temperature: Response randomness
        - maxSteps: Max agentic iterations

        Args:
            frontmatter: Original agent frontmatter

        Returns:
            Transformed OpenCode agent frontmatter
        """
        result = self._transform_frontmatter(frontmatter)

        if "type" in result:
            agent_type = result.pop("type")
            if agent_type == "subagent" and "mode" not in result:
                result["mode"] = "subagent"
            elif agent_type == "primary" and "mode" not in result:
                result["mode"] = "primary"

        for field in ["version", "last_updated", "changelog", "output_schema"]:
            result.pop(field, None)

        return result

    def _transform_command_frontmatter(self, frontmatter: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform command frontmatter for OpenCode.

        OpenCode command frontmatter:
        - description: Shown in slash suggestions
        - model: Override model for command
        - subtask: Mark as subtask command
        - argument-hint: Usage hint

        Args:
            frontmatter: Original command frontmatter

        Returns:
            Transformed OpenCode command frontmatter
        """
        result = self._transform_frontmatter(frontmatter)

        if "args" in result and "argument-hint" not in result:
            result["argument-hint"] = result.pop("args")
        elif "arguments" in result and "argument-hint" not in result:
            result["argument-hint"] = result.pop("arguments")

        for field in ["name", "version", "type", "tags"]:
            result.pop(field, None)

        return result

    def _transform_tools_for_opencode(self, tools: Any) -> Any:
        """
        Normalize tool names for OpenCode.

        OpenCode uses lowercase tool names and supports both array and object formats.

        Args:
            tools: Tool specification (list or dict)

        Returns:
            Normalized tools specification
        """
        if isinstance(tools, dict):
            normalized: Dict[str, Any] = {}
            for tool, enabled in tools.items():
                if isinstance(tool, str):
                    mapped = self._OPENCODE_TOOL_NAME_MAP.get(tool, tool.lower())
                    normalized[mapped] = enabled
            return normalized

        if isinstance(tools, list):
            normalized_list: List[str] = []
            for tool in tools:
                if isinstance(tool, str):
                    mapped = self._OPENCODE_TOOL_NAME_MAP.get(tool, tool.lower())
                    if mapped not in normalized_list:
                        normalized_list.append(mapped)
                else:
                    normalized_list.append(tool)
            return normalized_list

        return tools

    def _normalize_tool_references(self, text: str) -> str:
        """
        Normalize tool name references in content.

        Converts Claude Code capitalized tool names to OpenCode lowercase.

        Args:
            text: Text containing tool references

        Returns:
            Text with normalized tool names
        """
        result = text
        for claude_name, opencode_name in self._OPENCODE_TOOL_NAME_MAP.items():
            result = re.sub(
                rf'\b{claude_name}\b(?=\s+tool|\s+command)',
                opencode_name,
                result,
                flags=re.IGNORECASE
            )
        return result

    def get_target_filename(self, source_filename: str, component_type: str) -> str:
        """
        Get the target filename for a component in OpenCode.

        Args:
            source_filename: Original filename
            component_type: Type of component

        Returns:
            Target filename (unchanged for OpenCode)
        """
        return super().get_target_filename(source_filename, component_type)

    def get_config_path(self) -> Path:
        """
        Get the path to OpenCode's config file.

        Returns:
            Path to opencode.json or opencode.jsonc
        """
        install_path = self.get_install_path()
        jsonc_path = install_path / "opencode.jsonc"
        json_path = install_path / "opencode.json"

        if jsonc_path.exists():
            return jsonc_path
        return json_path

    def merge_hooks_to_config(
        self,
        hooks_config: Dict[str, Any],
        dry_run: bool = False,
        install_path: Optional[Path] = None
    ) -> bool:
        """
        Merge hooks configuration into OpenCode's config file.

        OpenCode can optionally have hooks defined in opencode.json.
        This method handles merging Ring hooks into that config.

        Args:
            hooks_config: The hooks configuration to merge
            dry_run: If True, don't actually write the file
            install_path: Optional custom install path

        Returns:
            True if successful, False otherwise
        """
        import logging

        logger = logging.getLogger(__name__)
        base_path = install_path or self.get_install_path()
        config_path = base_path / "opencode.json"

        existing_config: Dict[str, Any] = {}
        if config_path.exists():
            try:
                content = config_path.read_text(encoding="utf-8")
                lines = []
                for line in content.split("\n"):
                    stripped = line.strip()
                    if not stripped.startswith("//"):
                        lines.append(line)
                clean_content = "\n".join(lines)
                existing_config = json.loads(clean_content) if clean_content.strip() else {}
            except Exception as e:
                logger.warning(f"Failed to read opencode.json: {e}")

        if "hooks" not in existing_config:
            existing_config["hooks"] = {}

        hooks_to_merge = hooks_config.get("hooks", hooks_config)
        for event_name, event_hooks in hooks_to_merge.items():
            if event_name not in existing_config["hooks"]:
                existing_config["hooks"][event_name] = []
            existing_config["hooks"][event_name].extend(event_hooks)

        if dry_run:
            logger.info(f"[DRY RUN] Would merge hooks into {config_path}")
            return True

        try:
            config_path.parent.mkdir(parents=True, exist_ok=True)
            config_path.write_text(
                json.dumps(existing_config, indent=2),
                encoding="utf-8"
            )
            return True
        except Exception as e:
            logger.error(f"Failed to write opencode.json: {e}")
            return False
