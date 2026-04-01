"""Codex adapter - installs Ring skills into Codex's skills directory."""

from __future__ import annotations

import os
import re
from pathlib import Path
from typing import Any, Dict, Optional

from ring_installer.adapters.base import PlatformAdapter


class CodexAdapter(PlatformAdapter):
    """
    Platform adapter for OpenAI Codex CLI.

    Installation model:
    - skills -> ~/.codex/skills/<generated-name>/SKILL.md
    - hooks -> unsupported
    """

    platform_id = "codex"
    platform_name = "Codex"

    def transform_skill(self, skill_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """Transform a Ring skill into a Codex skill."""
        frontmatter, body = self.extract_frontmatter(skill_content)
        skill_name = self._resolve_codex_name(frontmatter, metadata, "skill")

        description = self._string_field(frontmatter, "description")
        transformed_frontmatter = self._build_skill_frontmatter(
            name=skill_name,
            description=description or self._fallback_description("skill", metadata),
            metadata=metadata,
        )

        body = self._rewrite_ring_references(body, metadata)

        return self.create_frontmatter(transformed_frontmatter) + "\n" + body.strip() + "\n"

    def transform_agent(self, agent_content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """Agents are not installed for Codex; keep content unchanged if called directly."""
        return agent_content

    def transform_command(
        self, command_content: str, metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """Commands are not installed for Codex; keep content unchanged if called directly."""
        return command_content

    def get_install_path(self) -> Path:
        """Get the installation path for Codex."""
        if self._install_path is None:
            env_path = Path(self.config.get("install_path", "~/.codex")).expanduser()
            override = os.environ.get("CODEX_CONFIG_PATH")
            if override:
                candidate = Path(override).expanduser().resolve()
                home = Path.home().resolve()
                try:
                    candidate.relative_to(home)
                    env_path = candidate
                except ValueError:
                    import logging

                    logging.getLogger(__name__).warning(
                        "CODEX_CONFIG_PATH=%s ignored: path must be under home", override
                    )
            self._install_path = env_path
        return self._install_path

    def get_component_mapping(self) -> Dict[str, Dict[str, str]]:
        """Install supported Ring abilities into Codex's skills tree."""
        return {"skills": {"target_dir": "skills", "extension": ".md"}}

    def is_native_format(self) -> bool:
        """Codex requires Ring content to be repackaged as skills."""
        return False

    def requires_flat_components(self, component_type: str) -> bool:
        """Codex skills keep package directories; no flat component mode is needed."""
        return False

    def get_flat_filename(self, source_filename: str, component_type: str, plugin_name: str) -> str:
        """Return the generated Codex component name."""
        generated_name = self._build_generated_name(plugin_name, component_type, source_filename)
        return generated_name

    def _build_generated_name(self, plugin_name: str, component_type: str, source_filename: str) -> str:
        stem = Path(source_filename).stem
        if stem.upper() == "SKILL":
            stem = Path(source_filename).parent.name or stem
        return self._sanitize_name(f"ring-{plugin_name}-{stem}")

    def _build_component_frontmatter(
        self,
        *,
        name: str,
        description: str,
        metadata: Optional[Dict[str, Any]],
    ) -> Dict[str, Any]:
        plugin = metadata.get("plugin") if metadata else None
        component_type = metadata.get("component_type") if metadata else None
        source_name = self._source_component_name(metadata)

        return {
            "name": name,
            "description": description.strip(),
            "metadata": {
                "ring-platform": "codex",
                "ring-plugin": plugin,
                "ring-component-type": component_type,
                "ring-source-name": source_name,
            },
        }

    def _build_skill_frontmatter(
        self,
        *,
        name: str,
        description: str,
        metadata: Optional[Dict[str, Any]],
    ) -> Dict[str, Any]:
        return self._build_component_frontmatter(
            name=name,
            description=description,
            metadata=metadata,
        )

    def _rewrite_ring_references(self, content: str, metadata: Optional[Dict[str, Any]]) -> str:
        alias_map = (metadata or {}).get("codex_alias_map", {})
        plugin = metadata.get("plugin") if metadata else "default"
        logical_name = self._source_component_name(metadata)
        component_type = metadata.get("component_type") if metadata else "skill"

        def replace_plain(match: re.Match[str]) -> str:
            key = match.group(1)
            return alias_map.get(key, match.group(0))

        def replace_slash(match: re.Match[str]) -> str:
            key = match.group(1)
            return f"`{alias_map[key]}`" if key in alias_map else match.group(0)

        replacements = {
            "../skills/shared-patterns/": f"../../ring/{plugin}/skills/shared-patterns/",
            "../shared-patterns/": f"../../ring/{plugin}/skills/shared-patterns/",
            "../docs/": f"../../ring/{plugin}/docs/",
            "../../docs/": f"../../ring/{plugin}/docs/",
            "../../default/skills/shared-patterns/": "../../ring/default/skills/shared-patterns/",
            "../../default/docs/": "../../ring/default/docs/",
            "../skills/": f"../../ring/{plugin}/skills/",
        }
        for old, new in replacements.items():
            content = content.replace(old, new)

        if logical_name and logical_name != "unknown":
            ref_path = f"../../ring/{plugin}/{component_type}s/{logical_name}/references/"
            content = re.sub(
                r"(?<![A-Za-z0-9._/-])references/",
                ref_path,
                content,
            )

        content = re.sub(r"ring:([a-zA-Z0-9._-]+)", replace_plain, content)
        content = re.sub(r"/ring:([a-zA-Z0-9._-]+)", replace_slash, content)
        return content

    @staticmethod
    def _sanitize_name(value: str) -> str:
        value = value.lower().replace(":", "-")
        value = re.sub(r"[^a-z0-9._-]+", "-", value)
        value = re.sub(r"-{2,}", "-", value)
        return value.strip("-")

    @staticmethod
    def _string_field(frontmatter: Dict[str, Any], key: str) -> str:
        value = frontmatter.get(key)
        return value.strip() if isinstance(value, str) else ""

    @staticmethod
    def _source_component_name(metadata: Optional[Dict[str, Any]]) -> str:
        if not metadata:
            return "unknown"
        name = metadata.get("name")
        return name if isinstance(name, str) and name else "unknown"

    def _fallback_description(self, component_type: str, metadata: Optional[Dict[str, Any]]) -> str:
        logical_name = self._source_component_name(metadata)
        return f"Ring {component_type} `{self._ring_reference(logical_name)}` packaged for Codex."

    @staticmethod
    def _ring_reference(logical_name: str) -> str:
        return logical_name if logical_name.startswith("ring:") else f"ring:{logical_name}"

    def _resolve_codex_name(
        self,
        frontmatter: Dict[str, Any],
        metadata: Optional[Dict[str, Any]],
        component_type: str,
    ) -> str:
        if metadata and isinstance(metadata.get("codex_name"), str) and metadata["codex_name"]:
            return metadata["codex_name"]

        plugin = metadata.get("plugin") if metadata else "default"
        logical_name = (
            self._string_field(frontmatter, "name")
            or self._source_component_name(metadata)
            or component_type
        )
        return self._sanitize_name(f"ring-{plugin}-{logical_name}")
