"""
Pytest fixtures for Ring installer tests.

Provides shared fixtures for testing adapters, transformers, utilities, and core functions.
"""

import json
import shutil
from pathlib import Path
from typing import Any, Dict
from unittest.mock import MagicMock, patch

import pytest

# ==============================================================================
# Path Fixtures
# ==============================================================================

@pytest.fixture
def fixtures_path() -> Path:
    """
    Return the path to the test fixtures directory.

    This fixture assumes the standard pytest test layout where fixtures
    are stored in a 'fixtures' subdirectory alongside the test files.

    Expected structure:
        installer/tests/
        ├── conftest.py       <- This file
        ├── fixtures/         <- Fixtures directory
        │   ├── skills/
        │   ├── agents/
        │   ├── commands/
        │   └── hooks/
        └── test_*.py

    Raises:
        FileNotFoundError: If fixtures directory doesn't exist, with
            instructions for creating it.
    """
    fixtures_dir = Path(__file__).parent / "fixtures"

    if not fixtures_dir.exists():
        raise FileNotFoundError(
            f"Test fixtures directory not found: {fixtures_dir}\n"
            f"Expected location: installer/tests/fixtures/\n"
            f"Run 'python -m pytest --collect-only' from installer/ to verify paths."
        )

    return fixtures_dir


@pytest.fixture
def tmp_ring_root(tmp_path: Path, fixtures_path: Path) -> Path:
    """
    Create a temporary Ring source directory with test fixtures.

    This fixture copies the test fixtures to a temporary directory,
    simulating a Ring installation for testing.

    Returns:
        Path to temporary Ring root with test components.
    """
    ring_root = tmp_path / "ring"
    ring_root.mkdir()

    # Create marketplace.json
    marketplace_dir = ring_root / ".claude-plugin"
    marketplace_dir.mkdir()

    marketplace_content = {
        "version": "1.2.3",
        "plugins": [
            {
                "name": "ring-default",
                "description": "Core Ring plugin",
                "version": "1.0.0",
                "source": "./default"
            },
            {
                "name": "ring-test",
                "description": "Test plugin",
                "version": "0.1.0",
                "source": "./test-plugin"
            }
        ]
    }

    with open(marketplace_dir / "marketplace.json", "w") as f:
        json.dump(marketplace_content, f, indent=2)

    # Create default plugin structure
    default_plugin = ring_root / "default"
    default_plugin.mkdir()

    # Copy fixtures to default plugin
    for component_type in ["skills", "agents", "commands", "hooks"]:
        src = fixtures_path / component_type
        if src.exists():
            dst = default_plugin / component_type
            if component_type == "skills":
                # Skills have subdirectories
                shutil.copytree(src, dst)
            else:
                dst.mkdir(parents=True, exist_ok=True)
                for file in src.iterdir():
                    if file.is_file():
                        shutil.copy2(file, dst / file.name)

    # Create test-plugin with minimal structure
    test_plugin = ring_root / "test-plugin"
    test_plugin.mkdir()

    return ring_root


@pytest.fixture
def tmp_install_dir(tmp_path: Path) -> Path:
    """
    Create a temporary installation target directory.

    Returns:
        Path to temporary installation directory.
    """
    install_dir = tmp_path / "install"
    install_dir.mkdir()
    return install_dir


# ==============================================================================
# Content Fixtures
# ==============================================================================

@pytest.fixture
def sample_skill_content(fixtures_path: Path) -> str:
    """
    Load sample skill content from fixtures.

    Returns:
        Content of sample skill markdown file.
    """
    skill_path = fixtures_path / "skills" / "sample-skill" / "SKILL.md"
    return skill_path.read_text(encoding="utf-8")


@pytest.fixture
def sample_agent_content(fixtures_path: Path) -> str:
    """
    Load sample agent content from fixtures.

    Returns:
        Content of sample agent markdown file.
    """
    agent_path = fixtures_path / "agents" / "sample-agent.md"
    return agent_path.read_text(encoding="utf-8")


@pytest.fixture
def sample_command_content(fixtures_path: Path) -> str:
    """
    Load sample command content from fixtures.

    Returns:
        Content of sample command markdown file.
    """
    command_path = fixtures_path / "commands" / "sample-command.md"
    return command_path.read_text(encoding="utf-8")


@pytest.fixture
def sample_hooks_content(fixtures_path: Path) -> str:
    """
    Load sample hooks.json content from fixtures.

    Returns:
        Content of sample hooks.json file.
    """
    hooks_path = fixtures_path / "hooks" / "hooks.json"
    return hooks_path.read_text(encoding="utf-8")


@pytest.fixture
def sample_hooks_dict(fixtures_path: Path) -> Dict[str, Any]:
    """
    Load sample hooks.json as a dictionary.

    Returns:
        Parsed hooks.json content.
    """
    hooks_path = fixtures_path / "hooks" / "hooks.json"
    with open(hooks_path) as f:
        return json.load(f)


# ==============================================================================
# Minimal Content Fixtures (for unit tests)
# ==============================================================================

@pytest.fixture
def minimal_skill_content() -> str:
    """
    Return minimal valid skill content for unit tests.

    Returns:
        Minimal skill markdown with frontmatter.
    """
    return """---
name: minimal-skill
description: A minimal skill for testing.
---

# Minimal Skill

This is a minimal skill.
"""


@pytest.fixture
def minimal_agent_content() -> str:
    """
    Return minimal valid agent content for unit tests.

    Returns:
        Minimal agent markdown with frontmatter.
    """
    return """---
name: minimal-agent
description: A minimal agent for testing.
model: claude-sonnet-4-20250514
---

# Minimal Agent

This is a minimal agent.
"""


@pytest.fixture
def minimal_command_content() -> str:
    """
    Return minimal valid command content for unit tests.

    Returns:
        Minimal command markdown with frontmatter.
    """
    return """---
name: minimal-command
description: A minimal command for testing.
args:
  - name: target
    required: true
---

# Minimal Command

This is a minimal command.
"""


@pytest.fixture
def content_without_frontmatter() -> str:
    """
    Return content without YAML frontmatter.

    Returns:
        Markdown content without frontmatter.
    """
    return """# No Frontmatter Content

This content has no YAML frontmatter.

## Section

Some section content.
"""


@pytest.fixture
def content_with_invalid_frontmatter() -> str:
    """
    Return content with malformed YAML frontmatter.

    Returns:
        Markdown with invalid frontmatter.
    """
    return """---
name: invalid
description: [unclosed bracket
---

# Invalid Frontmatter

The frontmatter YAML is malformed.
"""


# ==============================================================================
# Adapter Fixtures
# ==============================================================================

@pytest.fixture
def mock_platform_adapter():
    """
    Create a mock platform adapter for testing.

    Returns:
        MagicMock configured as a PlatformAdapter.
    """
    adapter = MagicMock()
    adapter.platform_id = "mock"
    adapter.platform_name = "Mock Platform"
    adapter.is_native_format.return_value = False

    adapter.get_install_path.return_value = Path.home() / ".mock"
    adapter.get_component_mapping.return_value = {
        "agents": {"target_dir": "agents", "extension": ".md"},
        "commands": {"target_dir": "commands", "extension": ".md"},
        "skills": {"target_dir": "skills", "extension": ".md"},
        "hooks": {"target_dir": "hooks", "extension": ""},
    }
    adapter.get_terminology.return_value = {
        "agent": "mock-agent",
        "skill": "mock-skill",
        "command": "mock-command",
        "hook": "mock-hook",
    }

    # Passthrough transforms by default
    adapter.transform_skill.side_effect = lambda c, m=None: c
    adapter.transform_agent.side_effect = lambda c, m=None: c
    adapter.transform_command.side_effect = lambda c, m=None: c
    adapter.transform_hook.side_effect = lambda c, m=None: c

    adapter.get_target_filename.side_effect = lambda f, t: f

    return adapter


@pytest.fixture
def claude_adapter_config() -> Dict[str, Any]:
    """
    Return configuration for Claude adapter.

    Returns:
        Claude adapter configuration dictionary.
    """
    return {
        "install_path": "~/.claude",
        "native": True
    }


@pytest.fixture
def factory_adapter_config() -> Dict[str, Any]:
    """
    Return configuration for Factory adapter.

    Returns:
        Factory adapter configuration dictionary.
    """
    return {
        "install_path": "~/.factory",
        "native": False
    }


@pytest.fixture
def cursor_adapter_config() -> Dict[str, Any]:
    """
    Return configuration for Cursor adapter.

    Returns:
        Cursor adapter configuration dictionary.
    """
    return {
        "install_path": "~/.cursor",
        "native": False
    }


@pytest.fixture
def cline_adapter_config() -> Dict[str, Any]:
    """
    Return configuration for Cline adapter.

    Returns:
        Cline adapter configuration dictionary.
    """
    return {
        "install_path": "~/.cline",
        "native": False
    }


@pytest.fixture
def opencode_adapter_config() -> Dict[str, Any]:
    """
    Return configuration for OpenCode adapter.

    Returns:
        OpenCode adapter configuration dictionary.
    """
    return {
        "install_path": "~/.config/opencode",
        "native": True
    }


# ==============================================================================
# Transformer Fixtures
# ==============================================================================

@pytest.fixture
def transform_context():
    """
    Create a factory function for TransformContext.

    Returns:
        Function that creates TransformContext instances.
    """
    from ring_installer.transformers.base import TransformContext

    def _create_context(
        platform: str = "claude",
        component_type: str = "skill",
        source_path: str = "",
        metadata: Dict[str, Any] = None,
        options: Dict[str, Any] = None
    ) -> TransformContext:
        return TransformContext(
            platform=platform,
            component_type=component_type,
            source_path=source_path,
            metadata=metadata or {},
            options=options or {}
        )

    return _create_context


# ==============================================================================
# Platform Detection Fixtures
# ==============================================================================

@pytest.fixture
def mock_platform_detection():
    """
    Mock platform detection functions.

    Yields:
        Dictionary of mocked detection functions.
    """
    with patch("ring_installer.utils.platform_detect._detect_claude") as mock_claude, \
         patch("ring_installer.utils.platform_detect._detect_factory") as mock_factory, \
         patch("ring_installer.utils.platform_detect._detect_cursor") as mock_cursor, \
         patch("ring_installer.utils.platform_detect._detect_cline") as mock_cline, \
         patch("ring_installer.utils.platform_detect._detect_opencode") as mock_opencode:

        from ring_installer.utils.platform_detect import PlatformInfo

        # Default: no platforms installed
        mock_claude.return_value = PlatformInfo(
            platform_id="claude",
            name="Claude Code",
            installed=False
        )
        mock_factory.return_value = PlatformInfo(
            platform_id="factory",
            name="Factory AI",
            installed=False
        )
        mock_cursor.return_value = PlatformInfo(
            platform_id="cursor",
            name="Cursor",
            installed=False
        )
        mock_cline.return_value = PlatformInfo(
            platform_id="cline",
            name="Cline",
            installed=False
        )
        mock_opencode.return_value = PlatformInfo(
            platform_id="opencode",
            name="OpenCode",
            installed=False
        )

        yield {
            "claude": mock_claude,
            "factory": mock_factory,
            "cursor": mock_cursor,
            "cline": mock_cline,
            "opencode": mock_opencode
        }


# ==============================================================================
# Install Manifest Fixtures
# ==============================================================================

@pytest.fixture
def sample_install_manifest() -> Dict[str, Any]:
    """
    Return a sample installation manifest.

    Returns:
        Dictionary representing an install manifest.
    """
    return {
        "version": "1.0.0",
        "installed_at": "2024-01-15T10:30:00",
        "source_path": "/path/to/ring",
        "platform": "claude",
        "plugins": ["default", "test-plugin"],
        "files": {
            "agents/sample-agent.md": "abc123hash",
            "commands/sample-command.md": "def456hash",
            "skills/sample-skill/SKILL.md": "ghi789hash"
        },
        "metadata": {
            "installer_version": "0.1.0"
        }
    }


@pytest.fixture
def create_manifest_file(tmp_path: Path):
    """
    Factory fixture to create manifest files.

    Returns:
        Function to create manifest files in tmp_path.
    """
    def _create(manifest_data: Dict[str, Any], filename: str = ".ring-manifest.json") -> Path:
        manifest_path = tmp_path / filename
        with open(manifest_path, "w") as f:
            json.dump(manifest_data, f, indent=2)
        return manifest_path

    return _create


# ==============================================================================
# Version Fixtures
# ==============================================================================

@pytest.fixture
def version_test_cases() -> list:
    """
    Return version comparison test cases.

    Returns:
        List of (v1, v2, expected_result) tuples.
        expected_result: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
    """
    return [
        # Basic comparisons
        ("1.0.0", "1.0.0", 0),
        ("1.0.0", "1.0.1", -1),
        ("1.0.1", "1.0.0", 1),
        ("1.0.0", "1.1.0", -1),
        ("1.1.0", "1.0.0", 1),
        ("1.0.0", "2.0.0", -1),
        ("2.0.0", "1.0.0", 1),

        # Prerelease versions
        ("1.0.0-alpha", "1.0.0", -1),
        ("1.0.0", "1.0.0-alpha", 1),
        ("1.0.0-alpha", "1.0.0-beta", -1),
        ("1.0.0-beta", "1.0.0-alpha", 1),
        ("1.0.0-alpha.1", "1.0.0-alpha.2", -1),

        # With v prefix
        ("v1.0.0", "1.0.0", 0),
        ("v1.0.0", "v1.0.1", -1),
    ]


# ==============================================================================
# Cleanup Fixtures
# ==============================================================================

@pytest.fixture(autouse=True)
def cleanup_temp_files(tmp_path: Path):
    """
    Automatically clean up temporary files after each test.

    This fixture runs after each test and ensures temp files are removed.
    """
    yield
    # Cleanup happens automatically with tmp_path


# ==============================================================================
# Helper Functions (not fixtures, but available in tests)
# ==============================================================================

def assert_frontmatter_contains(content: str, expected_keys: list) -> None:
    """
    Assert that content has frontmatter containing expected keys.

    Args:
        content: Markdown content with frontmatter
        expected_keys: List of keys that should be present
    """
    import yaml

    assert content.startswith("---"), "Content should start with frontmatter"
    end = content.find("---", 3)
    assert end != -1, "Frontmatter should have closing delimiter"

    yaml_content = content[3:end].strip()
    frontmatter = yaml.safe_load(yaml_content)

    for key in expected_keys:
        assert key in frontmatter, f"Frontmatter should contain '{key}'"


def assert_no_frontmatter(content: str) -> None:
    """
    Assert that content does not have YAML frontmatter.

    Args:
        content: Content to check
    """
    assert not content.startswith("---"), "Content should not have frontmatter"


def assert_contains_terminology(content: str, terms: list) -> None:
    """
    Assert that content contains expected terminology.

    Args:
        content: Content to check
        terms: List of terms that should be present
    """
    for term in terms:
        assert term in content, f"Content should contain '{term}'"


def assert_not_contains_terminology(content: str, terms: list) -> None:
    """
    Assert that content does not contain specified terminology.

    Args:
        content: Content to check
        terms: List of terms that should not be present
    """
    for term in terms:
        assert term not in content, f"Content should not contain '{term}'"
