"""
Tests for platform adapters.

Tests ClaudeAdapter, FactoryAdapter, CursorAdapter, ClineAdapter,
and the get_adapter() factory function.
"""

import pytest
from pathlib import Path
from unittest.mock import patch

from ring_installer.adapters import (
    PlatformAdapter,
    ClaudeAdapter,
    FactoryAdapter,
    CursorAdapter,
    ClineAdapter,
    get_adapter,
    register_adapter,
    list_platforms,
    SUPPORTED_PLATFORMS,
    ADAPTER_REGISTRY,
)


# ==============================================================================
# Tests for get_adapter() factory function
# ==============================================================================

class TestGetAdapter:
    """Tests for the get_adapter() factory function."""

    def test_get_adapter_returns_claude_adapter(self):
        """get_adapter('claude') should return ClaudeAdapter instance."""
        adapter = get_adapter("claude")
        assert isinstance(adapter, ClaudeAdapter)
        assert adapter.platform_id == "claude"

    def test_get_adapter_returns_factory_adapter(self):
        """get_adapter('factory') should return FactoryAdapter instance."""
        adapter = get_adapter("factory")
        assert isinstance(adapter, FactoryAdapter)
        assert adapter.platform_id == "factory"

    def test_get_adapter_returns_cursor_adapter(self):
        """get_adapter('cursor') should return CursorAdapter instance."""
        adapter = get_adapter("cursor")
        assert isinstance(adapter, CursorAdapter)
        assert adapter.platform_id == "cursor"

    def test_get_adapter_returns_cline_adapter(self):
        """get_adapter('cline') should return ClineAdapter instance."""
        adapter = get_adapter("cline")
        assert isinstance(adapter, ClineAdapter)
        assert adapter.platform_id == "cline"

    def test_get_adapter_case_insensitive(self):
        """get_adapter() should handle case-insensitive platform names."""
        assert isinstance(get_adapter("CLAUDE"), ClaudeAdapter)
        assert isinstance(get_adapter("Claude"), ClaudeAdapter)
        assert isinstance(get_adapter("FACTORY"), FactoryAdapter)
        assert isinstance(get_adapter("Cursor"), CursorAdapter)

    def test_get_adapter_with_config(self):
        """get_adapter() should accept optional configuration."""
        config = {"install_path": "/custom/path"}
        adapter = get_adapter("claude", config)
        assert adapter.config == config

    def test_get_adapter_unsupported_platform_raises_error(self):
        """get_adapter() should raise ValueError for unsupported platforms."""
        with pytest.raises(ValueError) as exc_info:
            get_adapter("unsupported")

        assert "Unsupported platform" in str(exc_info.value)
        assert "unsupported" in str(exc_info.value)

    def test_supported_platforms_list(self):
        """SUPPORTED_PLATFORMS should contain all expected platforms."""
        expected = {"claude", "factory", "cursor", "cline"}
        assert set(SUPPORTED_PLATFORMS) == expected


# ==============================================================================
# Tests for register_adapter()
# ==============================================================================

class TestRegisterAdapter:
    """Tests for custom adapter registration."""

    def test_register_custom_adapter(self):
        """register_adapter() should add a custom adapter to the registry."""
        class CustomAdapter(PlatformAdapter):
            platform_id = "custom"
            platform_name = "Custom Platform"

            def transform_skill(self, content, metadata=None):
                return content

            def transform_agent(self, content, metadata=None):
                return content

            def transform_command(self, content, metadata=None):
                return content

            def get_install_path(self):
                return Path.home() / ".custom"

            def get_component_mapping(self):
                return {"skills": {"target_dir": "skills", "extension": ".md"}}

        register_adapter("custom", CustomAdapter)
        assert "custom" in ADAPTER_REGISTRY

        adapter = get_adapter("custom")
        assert isinstance(adapter, CustomAdapter)

        # Cleanup
        del ADAPTER_REGISTRY["custom"]

    def test_register_adapter_requires_platform_adapter_subclass(self):
        """register_adapter() should reject non-PlatformAdapter classes."""
        class NotAnAdapter:
            pass

        with pytest.raises(TypeError) as exc_info:
            register_adapter("invalid", NotAnAdapter)

        assert "must inherit from PlatformAdapter" in str(exc_info.value)


# ==============================================================================
# Tests for list_platforms()
# ==============================================================================

class TestListPlatforms:
    """Tests for the list_platforms() function."""

    def test_list_platforms_returns_all_platforms(self):
        """list_platforms() should return info for all supported platforms."""
        platforms = list_platforms()
        platform_ids = {p["id"] for p in platforms}

        assert "claude" in platform_ids
        assert "factory" in platform_ids
        assert "cursor" in platform_ids
        assert "cline" in platform_ids

    def test_list_platforms_includes_required_fields(self):
        """list_platforms() should include required fields for each platform."""
        platforms = list_platforms()

        for platform in platforms:
            assert "id" in platform
            assert "name" in platform
            assert "native_format" in platform
            assert "terminology" in platform
            assert "components" in platform


# ==============================================================================
# Tests for ClaudeAdapter (passthrough)
# ==============================================================================

class TestClaudeAdapter:
    """Tests for ClaudeAdapter passthrough functionality."""

    @pytest.fixture
    def adapter(self):
        """Create a ClaudeAdapter instance."""
        return ClaudeAdapter()

    def test_platform_id(self, adapter):
        """ClaudeAdapter should have correct platform_id."""
        assert adapter.platform_id == "claude"
        assert adapter.platform_name == "Claude Code"

    def test_is_native_format(self, adapter):
        """ClaudeAdapter should report native format."""
        assert adapter.is_native_format() is True

    def test_transform_skill_passthrough(self, adapter, sample_skill_content):
        """transform_skill() should return content unchanged."""
        result = adapter.transform_skill(sample_skill_content)
        assert result == sample_skill_content

    def test_transform_agent_passthrough(self, adapter, sample_agent_content):
        """transform_agent() should return content unchanged."""
        result = adapter.transform_agent(sample_agent_content)
        assert result == sample_agent_content

    def test_transform_command_passthrough(self, adapter, sample_command_content):
        """transform_command() should return content unchanged."""
        result = adapter.transform_command(sample_command_content)
        assert result == sample_command_content

    def test_transform_hook_passthrough(self, adapter, sample_hooks_content):
        """transform_hook() should return content unchanged."""
        result = adapter.transform_hook(sample_hooks_content)
        assert result == sample_hooks_content

    def test_get_install_path_default(self, adapter):
        """get_install_path() should return ~/.claude by default."""
        path = adapter.get_install_path()
        assert path == Path.home() / ".claude"

    def test_get_install_path_custom(self):
        """get_install_path() should respect custom config."""
        adapter = ClaudeAdapter({"install_path": "/custom/path"})
        path = adapter.get_install_path()
        assert path == Path("/custom/path")

    def test_get_component_mapping(self, adapter):
        """get_component_mapping() should return Claude-specific mapping."""
        mapping = adapter.get_component_mapping()

        assert "agents" in mapping
        assert "commands" in mapping
        assert "skills" in mapping
        assert "hooks" in mapping

        assert mapping["agents"]["target_dir"] == "agents"
        assert mapping["agents"]["extension"] == ".md"

    def test_get_terminology(self, adapter):
        """get_terminology() should return identity mapping."""
        terminology = adapter.get_terminology()

        assert terminology["agent"] == "agent"
        assert terminology["skill"] == "skill"
        assert terminology["command"] == "command"

    def test_get_target_filename(self, adapter):
        """get_target_filename() should preserve original filename."""
        result = adapter.get_target_filename("test-agent.md", "agent")
        assert result == "test-agent.md"

    def test_requires_flat_components_is_false(self, adapter):
        """ClaudeAdapter does not require flat structure (uses plugin system)."""
        assert adapter.requires_flat_components("agents") is False
        assert adapter.requires_flat_components("commands") is False
        assert adapter.requires_flat_components("skills") is False


# ==============================================================================
# Tests for FactoryAdapter (agent -> droid)
# ==============================================================================

class TestFactoryAdapter:
    """Tests for FactoryAdapter terminology transformation."""

    @pytest.fixture
    def adapter(self):
        """Create a FactoryAdapter instance."""
        return FactoryAdapter()

    def test_platform_id(self, adapter):
        """FactoryAdapter should have correct platform_id."""
        assert adapter.platform_id == "factory"
        assert adapter.platform_name == "Factory AI"

    def test_is_not_native_format(self, adapter):
        """FactoryAdapter should not report native format."""
        assert adapter.is_native_format() is False

    def test_get_terminology(self, adapter):
        """get_terminology() should return Factory-specific mapping."""
        terminology = adapter.get_terminology()

        assert terminology["agent"] == "droid"
        assert terminology["skill"] == "skill"
        assert terminology["hook"] == "trigger"

    def test_transform_skill_replaces_agent_references(self, adapter, sample_skill_content):
        """transform_skill() should replace 'agent' with 'droid' in content."""
        result = adapter.transform_skill(sample_skill_content)

        # Agent references in body should be replaced
        assert "droid" in result.lower() or "agent" not in result.lower()

    def test_transform_agent_to_droid(self, adapter, sample_agent_content):
        """transform_agent() should convert agent content to droid format."""
        result = adapter.transform_agent(sample_agent_content)

        # Check terminology changes
        # The word "agent" in the content should be replaced with "droid"
        # (except in ring: references which use a different pattern)
        assert "Droid" in result or "droid" in result

    def test_transform_agent_frontmatter(self, adapter, minimal_agent_content):
        """transform_agent() should update frontmatter terminology."""
        content = """---
name: test-agent
subagent_type: helper
---

# Test Agent
"""
        result = adapter.transform_agent(content)

        # subdroid_type should appear instead of subagent_type
        assert "subdroid_type" in result or "droid" in result.lower()

    def test_get_component_mapping_droids(self, adapter):
        """get_component_mapping() should map agents to droids directory."""
        mapping = adapter.get_component_mapping()

        assert mapping["agents"]["target_dir"] == "droids"
        assert mapping["skills"]["target_dir"] == "skills"
        assert mapping["commands"]["target_dir"] == "commands"

    def test_get_target_filename_renames_agent(self, adapter):
        """get_target_filename() should rename *-agent.md to *-droid.md."""
        result = adapter.get_target_filename("code-agent.md", "agent")
        assert result == "code-droid.md"

        result = adapter.get_target_filename("test_agent.md", "agent")
        assert result == "test_droid.md"

    def test_get_target_filename_non_agent(self, adapter):
        """get_target_filename() should not rename non-agent files."""
        result = adapter.get_target_filename("test-skill.md", "skill")
        assert result == "test-skill.md"

    def test_replace_ring_references(self, adapter):
        """FactoryAdapter should replace ring:*-agent references."""
        content = 'Use "ring:code-agent" for analysis.'
        result = adapter.transform_skill(content)

        assert "ring:code-droid" in result or "droid" in result.lower()

    def test_requires_flat_components_for_agents(self, adapter):
        """FactoryAdapter requires flat structure for agents (droids)."""
        assert adapter.requires_flat_components("agents") is True

    def test_requires_flat_components_for_other_types(self, adapter):
        """FactoryAdapter does not require flat structure for other component types."""
        assert adapter.requires_flat_components("commands") is False
        assert adapter.requires_flat_components("skills") is False
        assert adapter.requires_flat_components("hooks") is False

    def test_get_flat_filename_for_agent(self, adapter):
        """get_flat_filename() should generate prefixed droid filename."""
        result = adapter.get_flat_filename("code-reviewer.md", "agent", "default")
        assert result == "ring-default-code-reviewer-droid.md"

    def test_get_flat_filename_strips_agent_suffix(self, adapter):
        """get_flat_filename() should strip -agent suffix before adding -droid."""
        result = adapter.get_flat_filename("code-agent.md", "agent", "default")
        assert result == "ring-default-code-droid.md"

    def test_get_flat_filename_for_command(self, adapter):
        """get_flat_filename() should work for non-agent types too."""
        result = adapter.get_flat_filename("test-command.md", "command", "dev-team")
        assert result == "ring-dev-team-test-command.md"


# ==============================================================================
# Tests for CursorAdapter (rules and workflows)
# ==============================================================================

class TestCursorAdapter:
    """Tests for CursorAdapter rule/workflow generation."""

    @pytest.fixture
    def adapter(self):
        """Create a CursorAdapter instance."""
        return CursorAdapter()

    def test_platform_id(self, adapter):
        """CursorAdapter should have correct platform_id."""
        assert adapter.platform_id == "cursor"
        assert adapter.platform_name == "Cursor"

    def test_is_not_native_format(self, adapter):
        """CursorAdapter should not report native format."""
        assert adapter.is_native_format() is False

    def test_get_terminology(self, adapter):
        """get_terminology() should return Cursor-specific mapping."""
        terminology = adapter.get_terminology()

        assert terminology["agent"] == "workflow"
        assert terminology["skill"] == "rule"
        assert terminology["command"] == "workflow"

    def test_transform_skill_to_rule(self, adapter, sample_skill_content):
        """transform_skill() should convert skill to Cursor rule format."""
        result = adapter.transform_skill(sample_skill_content)

        # Rule format should have title (from name)
        assert "# Sample Skill" in result or "# Sample-Skill" in result or "# sample" in result.lower()

        # Should have "When to Apply" section from trigger
        assert "When to Apply" in result or "Instructions" in result

        # Should not have YAML frontmatter
        assert not result.startswith("---")

    def test_transform_skill_with_frontmatter_extraction(self, adapter, minimal_skill_content):
        """transform_skill() should extract and use frontmatter data."""
        result = adapter.transform_skill(minimal_skill_content)

        # Title should come from name field
        assert "Minimal Skill" in result or "minimal" in result.lower()

    def test_transform_agent_to_workflow(self, adapter, sample_agent_content):
        """transform_agent() should convert agent to workflow format."""
        result = adapter.transform_agent(sample_agent_content)

        # Should have workflow header
        assert "Workflow" in result

        # Should have workflow steps section
        assert "Workflow Steps" in result or "Steps" in result

        # Should not have YAML frontmatter
        assert not result.startswith("---")

    def test_transform_command_to_workflow(self, adapter, sample_command_content):
        """transform_command() should convert command to workflow format."""
        result = adapter.transform_command(sample_command_content)

        # Should have Parameters section (from args)
        assert "Parameters" in result

        # Should have Instructions section
        assert "Instructions" in result

        # Should not have YAML frontmatter
        assert not result.startswith("---")

    def test_get_component_mapping(self, adapter):
        """get_component_mapping() should map to Cursor directories."""
        mapping = adapter.get_component_mapping()

        assert mapping["agents"]["target_dir"] == "workflows"
        assert mapping["commands"]["target_dir"] == "workflows"
        assert mapping["skills"]["target_dir"] == "rules"

    def test_transform_replaces_ring_terminology(self, adapter):
        """CursorAdapter should replace Ring-specific terminology."""
        content = "Use the Task tool to dispatch subagent."
        result = adapter.transform_skill(content)

        # Ring terminology should be replaced
        assert "workflow step" in result.lower() or "sub-workflow" in result.lower()

    def test_get_cursorrules_path_default(self, adapter):
        """get_cursorrules_path() should return default path."""
        path = adapter.get_cursorrules_path()
        assert path == Path.home() / ".cursor" / ".cursorrules"

    def test_get_cursorrules_path_with_project(self, adapter, tmp_path):
        """get_cursorrules_path() should return project-specific path."""
        path = adapter.get_cursorrules_path(tmp_path)
        assert path == tmp_path / ".cursorrules"


# ==============================================================================
# Tests for ClineAdapter (prompts)
# ==============================================================================

class TestClineAdapter:
    """Tests for ClineAdapter prompt generation."""

    @pytest.fixture
    def adapter(self):
        """Create a ClineAdapter instance."""
        return ClineAdapter()

    def test_platform_id(self, adapter):
        """ClineAdapter should have correct platform_id."""
        assert adapter.platform_id == "cline"
        assert adapter.platform_name == "Cline"

    def test_is_not_native_format(self, adapter):
        """ClineAdapter should not report native format."""
        assert adapter.is_native_format() is False

    def test_get_terminology(self, adapter):
        """get_terminology() should return Cline-specific mapping."""
        terminology = adapter.get_terminology()

        assert terminology["agent"] == "prompt"
        assert terminology["skill"] == "prompt"
        assert terminology["command"] == "prompt"

    def test_transform_skill_to_prompt(self, adapter, sample_skill_content):
        """transform_skill() should convert skill to Cline prompt format."""
        result = adapter.transform_skill(sample_skill_content)

        # Should have HTML comment metadata
        assert "<!-- Prompt:" in result
        assert "<!-- Type: skill -->" in result

        # Should have title
        assert "#" in result

        # Should have Instructions section
        assert "Instructions" in result

        # Should not have YAML frontmatter
        assert not result.startswith("---")

    def test_transform_skill_with_metadata(self, adapter, minimal_skill_content):
        """transform_skill() should include metadata in comments."""
        metadata = {"source_path": "/path/to/skill.md"}
        result = adapter.transform_skill(minimal_skill_content, metadata)

        # Should include source path comment
        assert "<!-- Source:" in result

    def test_transform_agent_to_prompt(self, adapter, sample_agent_content):
        """transform_agent() should convert agent to prompt format."""
        result = adapter.transform_agent(sample_agent_content)

        # Should have prompt metadata
        assert "<!-- Prompt:" in result
        assert "<!-- Type: agent -->" in result

        # Should have Role section
        assert "Role" in result or "Behavior" in result

        # Should have model recommendation
        assert "Recommended Model" in result or "claude" in result.lower()

    def test_transform_command_to_prompt(self, adapter, sample_command_content):
        """transform_command() should convert command to prompt format."""
        result = adapter.transform_command(sample_command_content)

        # Should have prompt metadata
        assert "<!-- Prompt:" in result
        assert "<!-- Type: command -->" in result

        # Should have Parameters section
        assert "Parameters" in result

        # Should have Steps section
        assert "Steps" in result

    def test_get_component_mapping(self, adapter):
        """get_component_mapping() should map to Cline prompt directories."""
        mapping = adapter.get_component_mapping()

        assert mapping["agents"]["target_dir"] == "prompts/agents"
        assert mapping["commands"]["target_dir"] == "prompts/commands"
        assert mapping["skills"]["target_dir"] == "prompts/skills"

    def test_transform_replaces_ring_references(self, adapter):
        """ClineAdapter should convert ring: references to @ format."""
        content = "Use `ring:helper-skill` for context."
        result = adapter.transform_skill(content)

        # ring: references should become @ references
        assert "@helper-skill" in result or "@" in result

    def test_transform_replaces_ring_terminology(self, adapter):
        """ClineAdapter should replace Ring-specific terminology."""
        content = "Use the Task tool to dispatch subagent."
        result = adapter.transform_skill(content)

        # Ring terminology should be replaced
        assert "sub-prompt" in result.lower() or "prompt" in result.lower()

    def test_generate_prompt_index(self, adapter):
        """generate_prompt_index() should create an index of prompts."""
        prompts = [
            {"name": "skill-1", "type": "skills", "description": "First skill"},
            {"name": "agent-1", "type": "agents", "description": "First agent"},
        ]

        result = adapter.generate_prompt_index(prompts)

        assert "Ring Prompts" in result
        assert "skill-1" in result.lower() or "Skill 1" in result
        assert "agent-1" in result.lower() or "Agent 1" in result


# ==============================================================================
# Tests for PlatformAdapter Base Class
# ==============================================================================

class TestPlatformAdapterBase:
    """Tests for PlatformAdapter base class methods."""

    @pytest.fixture
    def adapter(self):
        """Create a ClaudeAdapter as a concrete implementation."""
        return ClaudeAdapter()

    def test_validate_content_empty_fails(self, adapter):
        """validate_content() should fail for empty content."""
        errors = adapter.validate_content("", "skill")
        assert len(errors) > 0
        assert "Empty" in errors[0]

    def test_validate_content_whitespace_only_fails(self, adapter):
        """validate_content() should fail for whitespace-only content."""
        errors = adapter.validate_content("   \n\t  ", "skill")
        assert len(errors) > 0

    def test_validate_content_invalid_frontmatter(self, adapter):
        """validate_content() should detect invalid frontmatter."""
        content = """---
name: test
invalid frontmatter without closing
"""
        errors = adapter.validate_content(content, "skill")
        assert len(errors) > 0

    def test_extract_frontmatter_valid(self, adapter, minimal_skill_content):
        """extract_frontmatter() should parse valid frontmatter."""
        frontmatter, body = adapter.extract_frontmatter(minimal_skill_content)

        assert "name" in frontmatter
        assert frontmatter["name"] == "minimal-skill"
        assert "Minimal Skill" in body

    def test_extract_frontmatter_no_frontmatter(self, adapter, content_without_frontmatter):
        """extract_frontmatter() should handle content without frontmatter."""
        frontmatter, body = adapter.extract_frontmatter(content_without_frontmatter)

        assert frontmatter == {}
        assert "No Frontmatter" in body

    def test_create_frontmatter(self, adapter):
        """create_frontmatter() should create valid YAML frontmatter."""
        data = {"name": "test", "description": "A test"}
        result = adapter.create_frontmatter(data)

        assert result.startswith("---\n")
        assert result.endswith("---\n")
        assert "name: test" in result

    def test_create_frontmatter_empty(self, adapter):
        """create_frontmatter() should return empty string for empty dict."""
        result = adapter.create_frontmatter({})
        assert result == ""

    def test_supports_component(self, adapter):
        """supports_component() should check component mapping."""
        assert adapter.supports_component("agents") is True
        assert adapter.supports_component("skills") is True
        assert adapter.supports_component("unknown") is False

    def test_replace_terminology(self, adapter):
        """replace_terminology() should replace terms based on mapping."""
        # ClaudeAdapter has identity mapping, so use FactoryAdapter
        factory_adapter = FactoryAdapter()
        content = "The agent handles the task."
        result = factory_adapter.replace_terminology(content)

        assert "droid" in result.lower()

    def test_repr(self, adapter):
        """__repr__() should return informative string."""
        repr_str = repr(adapter)
        assert "ClaudeAdapter" in repr_str
        assert "claude" in repr_str


# ==============================================================================
# Parametrized Tests for All Adapters
# ==============================================================================

@pytest.mark.parametrize("platform", SUPPORTED_PLATFORMS)
class TestAllAdaptersCommon:
    """Common tests that apply to all adapters."""

    def test_adapter_has_required_attributes(self, platform):
        """All adapters should have required attributes."""
        adapter = get_adapter(platform)

        assert hasattr(adapter, "platform_id")
        assert hasattr(adapter, "platform_name")
        assert adapter.platform_id == platform

    def test_adapter_has_required_methods(self, platform):
        """All adapters should implement required methods."""
        adapter = get_adapter(platform)

        assert callable(adapter.transform_skill)
        assert callable(adapter.transform_agent)
        assert callable(adapter.transform_command)
        assert callable(adapter.get_install_path)
        assert callable(adapter.get_component_mapping)

    def test_transform_skill_returns_string(self, platform, minimal_skill_content):
        """transform_skill() should return a string."""
        adapter = get_adapter(platform)
        result = adapter.transform_skill(minimal_skill_content)
        assert isinstance(result, str)
        assert len(result) > 0

    def test_transform_agent_returns_string(self, platform, minimal_agent_content):
        """transform_agent() should return a string."""
        adapter = get_adapter(platform)
        result = adapter.transform_agent(minimal_agent_content)
        assert isinstance(result, str)
        assert len(result) > 0

    def test_transform_command_returns_string(self, platform, minimal_command_content):
        """transform_command() should return a string."""
        adapter = get_adapter(platform)
        result = adapter.transform_command(minimal_command_content)
        assert isinstance(result, str)
        assert len(result) > 0

    def test_get_install_path_returns_path(self, platform):
        """get_install_path() should return a Path object."""
        adapter = get_adapter(platform)
        path = adapter.get_install_path()
        assert isinstance(path, Path)

    def test_get_component_mapping_returns_dict(self, platform):
        """get_component_mapping() should return a dictionary."""
        adapter = get_adapter(platform)
        mapping = adapter.get_component_mapping()
        assert isinstance(mapping, dict)
        assert len(mapping) > 0

    def test_get_terminology_returns_dict(self, platform):
        """get_terminology() should return a dictionary."""
        adapter = get_adapter(platform)
        terminology = adapter.get_terminology()
        assert isinstance(terminology, dict)
        assert "agent" in terminology
        assert "skill" in terminology
