"""
OpenCode adapter - converts Ring format to OpenCode's format.

OpenCode (OhMyOpenCode) is a Claude Code-compatible AI agent platform.
It uses similar concepts to Ring/Claude Code with minor directory differences:
- agents -> agent (singular directory name)
- commands -> command (singular directory name)
- skills -> skill (singular directory name)
- hooks -> NOT SUPPORTED (OpenCode uses plugin-based hooks)

IMPORTANT: OpenCode hooks are plugin-based (tool.execute.before, etc.) which are
incompatible with Ring's file-based hooks. Ring hooks CANNOT be installed on OpenCode.
"""

import json
import logging
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from ring_installer.adapters.base import PlatformAdapter

logger = logging.getLogger(__name__)


class OpenCodeAdapter(PlatformAdapter):
    """
    Platform adapter for OpenCode (OhMyOpenCode).

    OpenCode uses a format very similar to Claude Code with these differences:
    - Install path: ~/.config/opencode/ (user) or .opencode/ (project)
    - Directory names: singular (agent/, command/, skill/) not plural
    - Hooks: NOT SUPPORTED - OpenCode uses plugin-based hooks incompatible with Ring
    - Config: opencode.json or opencode.jsonc instead of settings.json

    Key OpenCode features:
    - Agent modes: primary, subagent, all
    - Tools: bash, read, write, edit, list, glob, grep, webfetch, task, todowrite, todoread
    - Model format: provider/model-id (e.g., anthropic/claude-sonnet-4-5)
    - Permissions: edit/bash with ask/allow/deny values

    Limitations:
    - Hooks are NOT supported (OpenCode uses plugin-based hooks)
    - Command argument-hint field is NOT supported
    - Some Ring-specific frontmatter fields are stripped
    """

    platform_id = "opencode"
    platform_name = "OpenCode"

    # Flag indicating hooks are not supported on this platform
    supports_hooks = False

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

    # OpenCode skill allowed frontmatter fields
    # Reference: OpenCode skill schema - only these fields are recognized
    # All other fields (model, tools, version, etc.) are stripped during transformation
    _OPENCODE_SKILL_ALLOWED_FIELDS: List[str] = [
        "name",  # Required: skill identifier
        "description",  # Optional: displayed in skill list
    ]

    # OpenCode agent allowed frontmatter fields
    # Reference: OpenCode agent schema - defines agent behavior and capabilities
    _OPENCODE_AGENT_ALLOWED_FIELDS: List[str] = [
        "name",  # Required: agent identifier
        "description",  # Optional: shown in agent selection
        "mode",  # Optional: "primary", "subagent", or "all"
        "model",  # Optional: "provider/model-id" format
        "tools",  # Optional: tool access configuration
        "hidden",  # Optional: hide from agent list
        "subtask",  # Optional: mark as subtask-only agent
        "temperature",  # Optional: response randomness (0.0-1.0)
        "maxSteps",  # Optional: max agentic iterations
        "permission",  # Optional: {edit: ask|allow|deny, bash: ask|allow|deny}
    ]

    # OpenCode command allowed frontmatter fields
    # Reference: OpenCode command schema
    # Note: argument-hint is NOT supported - use $ARGUMENTS in template body
    _OPENCODE_COMMAND_ALLOWED_FIELDS: List[str] = [
        "name",  # Optional: override filename-based name
        "description",  # Optional: shown in slash command suggestions
        "model",  # Optional: override model for this command
        "subtask",  # Optional: mark as subtask command
        "agent",  # Optional: which agent executes this command
    ]

    # OpenCode permission values
    # Used for edit and bash permission configuration
    _OPENCODE_PERMISSION_VALUES: List[str] = ["ask", "allow", "deny"]

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
        Transformation includes:
        - Tool name normalization (capitalized -> lowercase)
        - Frontmatter filtering (only allowed fields kept)
        - Inline resolution of shared-patterns and docs references

        OpenCode skill frontmatter only supports: name, description, license,
        compatibility, metadata. All other fields are stripped.

        Args:
            skill_content: The original skill content
            metadata: Optional metadata about the skill

        Returns:
            Transformed skill content for OpenCode
        """
        frontmatter, body = self.extract_frontmatter(skill_content)

        if frontmatter:
            frontmatter = self._transform_skill_frontmatter(frontmatter)

        body = self._normalize_tool_references(body)

        # Inline shared-patterns and docs references
        source_path = metadata.get("source_path") if metadata else None
        body = self._resolve_inline_references(body, source_path)

        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def _transform_skill_frontmatter(self, frontmatter: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform skill frontmatter for OpenCode compatibility.

        Filters frontmatter to only include fields supported by OpenCode:
        name, description, license, compatibility, metadata.

        Note: Unlike agents/commands, skills don't need model/tools transformation
        since those fields aren't in the allowed list anyway. We filter directly
        from the original frontmatter for efficiency.

        Args:
            frontmatter: Original skill frontmatter

        Returns:
            Filtered frontmatter with only OpenCode-supported fields
        """
        # Filter directly to allowed fields (no need for base transformation
        # since model/tools aren't in skill allowed fields anyway)
        filtered = {
            key: value
            for key, value in frontmatter.items()
            if key in self._OPENCODE_SKILL_ALLOWED_FIELDS
        }

        # Log count of stripped fields for debugging (not field names for security)
        stripped_count = len(frontmatter) - len(filtered)
        if stripped_count > 0:
            logger.debug("Stripped %d unsupported skill frontmatter field(s)", stripped_count)

        return filtered

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
        body = self._strip_model_requirement_section(body)

        # Inline shared-patterns and docs references
        source_path = metadata.get("source_path") if metadata else None
        body = self._resolve_inline_references(body, source_path)

        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def _strip_model_requirement_section(self, body: str) -> str:
        """
        Remove Claude-specific model requirement sections from agent body.

        Ring agents include self-verification sections that check if the model
        is Claude Opus 4.5+. These sections cause agents to refuse execution
        on non-Claude models. Since OpenCode supports multiple providers,
        we strip these sections to allow model flexibility.

        Args:
            body: The agent markdown body

        Returns:
            Body with model requirement sections removed
        """
        # Pattern matches the entire Model Requirement section including:
        # - The warning header (## ⚠️ Model Requirement...)
        # - The self-verification instructions
        # - The orchestrator requirement code block
        # - The trailing horizontal rule (---) separator
        pattern = r"## ⚠️ Model Requirement[^\n]*\n.*?\n---\n"
        result = re.sub(pattern, "", body, flags=re.DOTALL)

        # Clean up any resulting double blank lines
        result = re.sub(r"\n{3,}", "\n\n", result)

        return result.strip() + "\n"

    def transform_command(
        self, command_content: str, metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Transform a Ring command for OpenCode.

        OpenCode commands support:
        - description: Brief description
        - model: Override model for this command
        - subtask: Mark as subtask command
        - agent: Which agent executes this command

        Note:
            OpenCode does NOT support argument-hint. Arguments should be
            handled in the command template body using $ARGUMENTS placeholder.

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

        # Inline shared-patterns and docs references
        source_path = metadata.get("source_path") if metadata else None
        body = self._resolve_inline_references(body, source_path)

        if frontmatter:
            return self.create_frontmatter(frontmatter) + "\n" + body
        return body

    def transform_hook(
        self, hook_content: str, metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[str]:
        """
        Transform a Ring hook for OpenCode.

        IMPORTANT: OpenCode does NOT support file-based hooks. OpenCode uses a
        plugin-based hook system (tool.execute.before, tool.execute.after, etc.)
        which is incompatible with Ring's file-based hooks.

        This method returns None to indicate hooks should not be installed.

        Args:
            hook_content: The original hook content (JSON or script)
            metadata: Optional metadata about the hook

        Returns:
            None - hooks are not supported on OpenCode

        Note:
            Logs a warning instead of raising an exception.
        """
        hook_name = metadata.get("name", "unknown") if metadata else "unknown"
        logger.warning(
            "Hook '%s' cannot be installed: OpenCode uses plugin-based hooks "
            "(tool.execute.before, tool.execute.after, etc.) which are incompatible with "
            "Ring's file-based hooks. This hook will be skipped.",
            hook_name,
        )
        return None

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
                    logger.warning(
                        "OPENCODE_CONFIG_PATH=%s ignored: path must be under home", override
                    )
            self._install_path = env_path
        return self._install_path

    def get_component_mapping(self) -> Dict[str, Dict[str, str]]:
        """
        Get the component mapping for OpenCode.

        Note: OpenCode uses singular directory names (agent/, command/, skill/)
        unlike Claude Code which uses plural (agents/, commands/, skills/).

        IMPORTANT: Hooks are NOT included because OpenCode uses plugin-based hooks
        which are incompatible with Ring's file-based hooks.

        Returns:
            Mapping of Ring components to OpenCode directories (excludes hooks)
        """
        return {
            "agents": {
                "target_dir": "agent",  # Singular in OpenCode
                "extension": ".md",
            },
            "commands": {
                "target_dir": "command",  # Singular in OpenCode
                "extension": ".md",
            },
            "skills": {
                "target_dir": "skill",  # Singular in OpenCode
                "extension": ".md",
            },
            # NOTE: hooks intentionally excluded - OpenCode uses plugin-based hooks
        }

    def supports_component(self, component_type: str) -> bool:
        """
        Check if this platform supports a specific component type.

        OpenCode supports agents, commands, and skills but NOT hooks.
        OpenCode uses plugin-based hooks (tool.execute.before, etc.) which are
        incompatible with Ring's file-based hooks.

        Note: This explicit override exists for two reasons:
        1. Fast short-circuit for hooks checks without mapping lookup
        2. Clear documentation that hooks are intentionally unsupported
        The base class would also return False (hooks not in mapping), but
        this explicit check makes the intent clearer and avoids dict lookup.

        Args:
            component_type: Type of component (skills, agents, commands, hooks)

        Returns:
            True for skills/agents/commands, False for hooks
        """
        if component_type == "hooks":
            return False  # OpenCode uses plugin-based hooks, not file-based
        return super().supports_component(component_type)

    def get_terminology(self) -> Dict[str, str]:
        """
        Get OpenCode terminology.

        OpenCode uses the same terminology as Claude Code/Ring for supported
        components. Note: hooks are intentionally excluded since OpenCode
        does not support Ring's file-based hooks.

        Returns:
            Mapping for supported components only (excludes hooks)
        """
        return {
            "agent": "agent",
            "skill": "skill",
            "command": "command",
            # NOTE: hook excluded - OpenCode uses plugin-based hooks, not file-based
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

        IMPORTANT: OpenCode does NOT support Ring's file-based hooks at all.
        OpenCode uses a plugin-based hook system (tool.execute.before, etc.)
        which cannot be configured through settings.

        Returns:
            False - hooks are not supported on OpenCode
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
        - permission: {edit: ask|allow|deny, bash: ask|allow|deny}

        Args:
            frontmatter: Original agent frontmatter

        Returns:
            Transformed OpenCode agent frontmatter
        """
        result = self._transform_frontmatter(frontmatter)

        # Convert Ring 'type' field to OpenCode 'mode' field
        if "type" in result:
            agent_type = result.pop("type")
            if agent_type == "subagent" and "mode" not in result:
                result["mode"] = "subagent"
            elif agent_type == "primary" and "mode" not in result:
                result["mode"] = "primary"

        # Transform permissions if present
        if "permissions" in result or "permission" in result:
            result["permission"] = self._transform_permissions(
                result.pop("permissions", result.pop("permission", None))
            )

        # Filter to only allowed fields
        filtered = {
            key: value
            for key, value in result.items()
            if key in self._OPENCODE_AGENT_ALLOWED_FIELDS
        }

        # Log count of stripped fields for debugging (not field names for security)
        stripped_count = len(result) - len(filtered)
        if stripped_count > 0:
            logger.debug("Stripped %d unsupported agent frontmatter field(s)", stripped_count)

        return filtered

    def _transform_permissions(self, permissions: Any) -> Optional[Dict[str, str]]:
        """
        Transform Ring permissions to OpenCode permission format.

        OpenCode permissions format:
        {
            "edit": "ask|allow|deny",
            "bash": "ask|allow|deny"
        }

        Args:
            permissions: Ring permission data (dict, list, or string)

        Returns:
            OpenCode-formatted permission dict, or None if invalid
        """
        if permissions is None:
            return None

        # Declare result once to avoid variable shadowing
        result: Dict[str, str] = {}

        # If already in OpenCode format
        if isinstance(permissions, dict):
            for key in ["edit", "bash"]:
                if key in permissions:
                    value = str(permissions[key]).lower()
                    # Validate value
                    if value in self._OPENCODE_PERMISSION_VALUES:
                        result[key] = value
                    elif value in ["true", "1", "yes"]:
                        result[key] = "allow"
                    elif value in ["false", "0", "no"]:
                        result[key] = "deny"
                    else:
                        result[key] = "ask"  # Default to ask for unknown values
            return result if result else None

        # If it's a list of permission names (Ring format)
        if isinstance(permissions, list):
            for perm in permissions:
                perm_str = str(perm).lower()
                if "edit" in perm_str:
                    result["edit"] = "allow"
                if "bash" in perm_str or "shell" in perm_str:
                    result["bash"] = "allow"
            return result if result else None

        # If it's a string
        if isinstance(permissions, str):
            perm_lower = permissions.lower()
            if perm_lower in self._OPENCODE_PERMISSION_VALUES:
                # Apply same permission to both
                return {"edit": perm_lower, "bash": perm_lower}

        return None

    def _transform_command_frontmatter(self, frontmatter: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform command frontmatter for OpenCode.

        OpenCode command frontmatter (supported fields only):
        - name: Command name
        - description: Shown in slash suggestions
        - model: Override model for command
        - subtask: Mark as subtask command

        NOTE: OpenCode does NOT support argument-hint field. Arguments should be
        handled in the command template body using $ARGUMENTS placeholder.

        Args:
            frontmatter: Original command frontmatter

        Returns:
            Transformed OpenCode command frontmatter (filtered to valid fields)
        """
        result = self._transform_frontmatter(frontmatter)

        # Log if argument hints are being dropped
        dropped_args = []
        for arg_field in ["args", "arguments", "argument-hint", "allowed_args"]:
            if arg_field in result:
                dropped_args.append(arg_field)
                result.pop(arg_field, None)

        if dropped_args:
            logger.debug(
                "Dropped unsupported argument fields: %s. "
                "OpenCode doesn't support argument-hint. Use $ARGUMENTS in template body.",
                dropped_args,
            )

        # Filter to only allowed fields
        filtered = {
            key: value
            for key, value in result.items()
            if key in self._OPENCODE_COMMAND_ALLOWED_FIELDS
        }

        # Log count of stripped fields for debugging (not field names for security)
        stripped_count = len(result) - len(filtered)
        if stripped_count > 0:
            logger.debug("Stripped %d unsupported command frontmatter field(s)", stripped_count)

        return filtered

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
            # OpenCode requires tools as object with boolean values, not array
            normalized_obj: Dict[str, Any] = {}
            for tool in tools:
                if isinstance(tool, str):
                    mapped = self._OPENCODE_TOOL_NAME_MAP.get(tool, tool.lower())
                    normalized_obj[mapped] = True
                else:
                    normalized_obj[str(tool)] = True
            return normalized_obj

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
                rf"\b{claude_name}\b(?=\s+tool|\s+command)",
                opencode_name,
                result,
                flags=re.IGNORECASE,
            )
        return result

    # --- Inline Reference Resolution ---
    # Patterns for files that should be inlined when referenced via relative paths.
    # These directories contain shared content (anti-rationalization tables, pressure
    # resistance, standards, etc.) that agents/skills reference but that won't exist
    # at the installed location due to directory hierarchy inversion.
    _INLINE_PATH_PATTERNS = [
        "shared-patterns/",
        "docs/standards/",
        "docs/regulatory/",
        "docs/infrastructure",
    ]

    # Maximum file size to inline (256KB) — prevents accidental inclusion of huge files
    _MAX_INLINE_SIZE = 256 * 1024

    # Track already-inlined files per transform call to prevent infinite recursion
    # when inlined files themselves reference other files.
    _MAX_INLINE_DEPTH = 2

    def _resolve_inline_references(
        self,
        body: str,
        source_path: Optional[str],
        depth: int = 0,
    ) -> str:
        """
        Resolve relative-path markdown references by inlining the referenced file content.

        Finds markdown links like [text](../shared-patterns/foo.md) where the target
        is a shared-pattern or docs file, reads the source file from the Ring repo,
        and replaces the link with the actual content. This makes each installed
        component self-contained — no broken references at runtime.

        Only resolves references to paths matching _INLINE_PATH_PATTERNS.
        Skips URLs (http/https), anchors (#), and already-inlined content.

        Args:
            body: The markdown body content
            source_path: Absolute path to the original source file in the Ring repo.
                         Used to resolve relative references.
            depth: Current recursion depth (prevents infinite loops)

        Returns:
            Body with resolvable references replaced by inlined content
        """
        if not source_path or depth >= self._MAX_INLINE_DEPTH:
            return body

        source_dir = Path(source_path).parent

        # Match markdown links: [text](path)
        # Capture: full match, link text, link path
        link_pattern = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")

        def _should_inline(link_path: str) -> bool:
            """Check if a link path should be inlined."""
            # Skip URLs, anchors, and non-file references
            if link_path.startswith(("http://", "https://", "#", "mailto:")):
                return False
            # Only inline paths matching our patterns
            return any(pat in link_path for pat in self._INLINE_PATH_PATTERNS)

        def _read_referenced_file(link_path: str) -> Optional[str]:
            """Resolve and read a referenced file relative to the source."""
            try:
                resolved = (source_dir / link_path).resolve()
                # Safety: must exist and be a file
                if not resolved.is_file():
                    return None
                # Safety: don't inline huge files
                if resolved.stat().st_size > self._MAX_INLINE_SIZE:
                    logger.warning(
                        "Skipping inline for %s: file too large (%d bytes)",
                        link_path,
                        resolved.stat().st_size,
                    )
                    return None
                content = resolved.read_text(encoding="utf-8")
                # Recursively resolve references in the inlined content
                if depth + 1 < self._MAX_INLINE_DEPTH:
                    content = self._resolve_inline_references(content, str(resolved), depth + 1)
                return content
            except (OSError, UnicodeDecodeError) as e:
                logger.debug("Could not inline %s: %s", link_path, e)
                return None

        lines = body.split("\n")
        result_lines: List[str] = []
        inlined_count = 0

        for line in lines:
            matches = list(link_pattern.finditer(line))
            if not matches:
                result_lines.append(line)
                continue

            # Check if any link on this line should be inlined
            inlined_this_line = False
            for match in matches:
                link_text = match.group(1)
                link_path = match.group(2)

                if not _should_inline(link_path):
                    continue

                content = _read_referenced_file(link_path)
                if content is None:
                    continue

                # Determine replacement strategy based on line context
                stripped = line.strip()
                full_match = match.group(0)

                # Case 1: Line is ONLY the link (possibly with "See " prefix)
                # e.g., "See [foo.md](../shared-patterns/foo.md)"
                # Replace entire line with inlined content
                is_standalone = (
                    stripped == full_match
                    or stripped.startswith(("See ", "see ", "Refer to ", "Reference: "))
                    and full_match in stripped
                    and len(stripped) - len(full_match) < 30
                )

                if is_standalone:
                    # Replace the entire line with the file content
                    # Add a subtle marker for debugging
                    file_name = Path(link_path).name
                    result_lines.append(f"<!-- inlined: {file_name} -->")
                    result_lines.append(content.rstrip())
                    inlined_this_line = True
                    inlined_count += 1
                    break  # Only one inline per line
                else:
                    # Case 2: Link is embedded in a larger sentence
                    # Append the content after the line
                    result_lines.append(line)
                    file_name = Path(link_path).name
                    result_lines.append("")
                    result_lines.append(f"<!-- inlined: {file_name} -->")
                    result_lines.append(content.rstrip())
                    inlined_this_line = True
                    inlined_count += 1
                    break

            if not inlined_this_line:
                result_lines.append(line)

        if inlined_count > 0:
            logger.debug("Inlined %d reference(s) from %s", inlined_count, source_path)

        return "\n".join(result_lines)

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

    def _get_plugin_config_path(self, install_path: Optional[Path] = None) -> Path:
        """Return existing OpenCode config path, preferring jsonc for new files."""
        base_path = install_path or self.get_install_path()
        jsonc_path = base_path / "opencode.jsonc"
        json_path = base_path / "opencode.json"

        if jsonc_path.exists():
            return jsonc_path
        if json_path.exists():
            return json_path
        return jsonc_path

    def _strip_jsonc_comments(self, content: str) -> str:
        """Strip JSONC comments without treating comment markers inside strings as comments."""
        result: List[str] = []
        in_string = False
        escape = False
        line_comment = False
        block_comment = False
        i = 0

        while i < len(content):
            char = content[i]
            next_char = content[i + 1] if i + 1 < len(content) else ""

            if line_comment:
                if char == "\n":
                    line_comment = False
                    result.append(char)
                i += 1
                continue

            if block_comment:
                if char == "*" and next_char == "/":
                    block_comment = False
                    i += 2
                    continue
                if char == "\n":
                    result.append(char)
                i += 1
                continue

            if in_string:
                result.append(char)
                if escape:
                    escape = False
                elif char == "\\":
                    escape = True
                elif char == '"':
                    in_string = False
                i += 1
                continue

            if char == '"':
                in_string = True
                result.append(char)
            elif char == "/" and next_char == "/":
                line_comment = True
                i += 1
            elif char == "/" and next_char == "*":
                block_comment = True
                i += 1
            else:
                result.append(char)
            i += 1

        return "".join(result)

    def register_local_plugin(
        self,
        plugin_path: Path,
        dry_run: bool = False,
        install_path: Optional[Path] = None,
    ) -> Optional[str]:
        """
        Register a local OpenCode plugin file or package directory under the config ``plugin`` array.

        Returns:
            Warning message when registration cannot be completed safely, else None.
        """
        config_path = self._get_plugin_config_path(install_path)
        expanded_plugin_path = Path(plugin_path).expanduser()
        if not expanded_plugin_path.is_absolute():
            expanded_plugin_path = expanded_plugin_path.resolve()
        plugin_uri = expanded_plugin_path.as_uri()
        config: Dict[str, Any] = {}

        if config_path.exists():
            try:
                content = config_path.read_text(encoding="utf-8")
                if content.strip():
                    config = json.loads(self._strip_jsonc_comments(content))
            except Exception as e:
                return f"Failed to read {config_path}: {e}"

        if not isinstance(config, dict):
            return f"OpenCode config {config_path} is not a JSON object; plugin not registered"

        plugins = config.get("plugin", [])
        if not isinstance(plugins, list):
            return f"OpenCode config {config_path} has non-list 'plugin'; plugin not registered"

        def is_legacy_ring_telemetry_plugin(value: Any) -> bool:
            if not isinstance(value, str):
                return False
            return value == "plugins/ring-telemetry.mjs" or value.endswith("/ring-telemetry.mjs")

        plugins = [plugin for plugin in plugins if not is_legacy_ring_telemetry_plugin(plugin)]

        if plugin_uri in plugins:
            config["plugin"] = plugins
            if not dry_run:
                try:
                    config_path.parent.mkdir(parents=True, exist_ok=True)
                    config_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
                except Exception as e:
                    return f"Failed to write {config_path}: {e}"
            return None

        plugins.append(plugin_uri)
        config["plugin"] = plugins

        if dry_run:
            logger.info(
                "[DRY RUN] Would register OpenCode plugin %s in %s", plugin_uri, config_path
            )
            return None

        try:
            config_path.parent.mkdir(parents=True, exist_ok=True)
            config_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
        except Exception as e:
            return f"Failed to write {config_path}: {e}"

        return None

    def merge_hooks_to_config(
        self,
        hooks_config: Dict[str, Any],
        dry_run: bool = False,
        install_path: Optional[Path] = None,
    ) -> bool:
        """
        Merge hooks configuration into OpenCode's config file.

        IMPORTANT: This method is a NO-OP for OpenCode because OpenCode does NOT
        support Ring's file-based hooks. OpenCode uses a plugin-based hook system
        (tool.execute.before, tool.execute.after, etc.) which cannot be configured
        through simple JSON merging.

        Ring hooks require:
        - Session start/stop scripts
        - Prompt submission handlers
        - File-based execution

        OpenCode hooks are:
        - Plugin-based (Go/TypeScript plugins)
        - Event-driven (tool.execute.*, session.*, etc.)
        - Registered programmatically

        These systems are fundamentally incompatible.

        Args:
            hooks_config: The hooks configuration to merge (ignored)
            dry_run: If True, don't actually write the file (ignored)
            install_path: Optional custom install path (ignored)

        Returns:
            True - always returns True but performs no action
        """
        if hooks_config:
            hook_count = len(hooks_config.get("hooks", hooks_config))
            logger.warning(
                "Cannot merge %d hook(s) to OpenCode config: "
                "OpenCode uses plugin-based hooks (tool.execute.before, etc.) "
                "which are incompatible with Ring's file-based hooks. "
                "Hooks will not be installed.",
                hook_count,
            )
        return True
