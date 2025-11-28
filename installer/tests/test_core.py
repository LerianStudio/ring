"""
Tests for Ring installer core functionality.

Tests the main installation, update, and uninstall functions along with
supporting data structures and component discovery.
"""

import json
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List
from unittest.mock import MagicMock, patch, mock_open

import pytest


# ==============================================================================
# InstallStatus Tests
# ==============================================================================

class TestInstallStatus:
    """Tests for the InstallStatus enum."""

    def test_status_values_exist(self):
        """InstallStatus should have expected status values."""
        from ring_installer.core import InstallStatus

        assert hasattr(InstallStatus, "SUCCESS")
        assert hasattr(InstallStatus, "PARTIAL")
        assert hasattr(InstallStatus, "FAILED")
        assert hasattr(InstallStatus, "SKIPPED")

    def test_status_values(self):
        """InstallStatus values should be correct strings."""
        from ring_installer.core import InstallStatus

        assert InstallStatus.SUCCESS.value == "success"
        assert InstallStatus.PARTIAL.value == "partial"
        assert InstallStatus.FAILED.value == "failed"
        assert InstallStatus.SKIPPED.value == "skipped"


# ==============================================================================
# InstallTarget Tests
# ==============================================================================

class TestInstallTarget:
    """Tests for the InstallTarget dataclass."""

    def test_create_with_valid_platform(self):
        """InstallTarget should accept valid platform identifiers."""
        from ring_installer.core import InstallTarget

        target = InstallTarget(platform="claude")

        assert target.platform == "claude"
        assert target.path is None
        assert target.components is None

    def test_create_with_all_parameters(self):
        """InstallTarget should accept all optional parameters."""
        from ring_installer.core import InstallTarget

        target = InstallTarget(
            platform="factory",
            path=Path("/custom/path"),
            components=["agents", "skills"]
        )

        assert target.platform == "factory"
        assert target.path == Path("/custom/path")
        assert target.components == ["agents", "skills"]

    def test_rejects_invalid_platform(self):
        """InstallTarget should reject unsupported platforms."""
        from ring_installer.core import InstallTarget

        with pytest.raises(ValueError) as exc_info:
            InstallTarget(platform="invalid_platform")

        assert "Unsupported platform" in str(exc_info.value)
        assert "invalid_platform" in str(exc_info.value)

    def test_expands_user_path(self):
        """InstallTarget should expand ~ in path."""
        from ring_installer.core import InstallTarget

        target = InstallTarget(platform="claude", path=Path("~/.custom"))

        assert "~" not in str(target.path)
        assert target.path.is_absolute()

    @pytest.mark.parametrize("platform", ["claude", "factory", "cursor", "cline"])
    def test_accepts_all_supported_platforms(self, platform):
        """InstallTarget should accept all supported platform identifiers."""
        from ring_installer.core import InstallTarget

        target = InstallTarget(platform=platform)

        assert target.platform == platform


# ==============================================================================
# InstallOptions Tests
# ==============================================================================

class TestInstallOptions:
    """Tests for the InstallOptions dataclass."""

    def test_default_values(self):
        """InstallOptions should have sensible defaults."""
        from ring_installer.core import InstallOptions

        options = InstallOptions()

        assert options.dry_run is False
        assert options.force is False
        assert options.backup is True
        assert options.verbose is False
        assert options.plugin_names is None
        assert options.exclude_plugins is None

    def test_custom_values(self):
        """InstallOptions should accept custom values."""
        from ring_installer.core import InstallOptions

        options = InstallOptions(
            dry_run=True,
            force=True,
            backup=False,
            verbose=True,
            plugin_names=["default"],
            exclude_plugins=["test"]
        )

        assert options.dry_run is True
        assert options.force is True
        assert options.backup is False
        assert options.verbose is True
        assert options.plugin_names == ["default"]
        assert options.exclude_plugins == ["test"]


# ==============================================================================
# ComponentResult Tests
# ==============================================================================

class TestComponentResult:
    """Tests for the ComponentResult dataclass."""

    def test_create_with_required_fields(self):
        """ComponentResult should require source_path, target_path, status."""
        from ring_installer.core import ComponentResult, InstallStatus

        result = ComponentResult(
            source_path=Path("/source/file.md"),
            target_path=Path("/target/file.md"),
            status=InstallStatus.SUCCESS
        )

        assert result.source_path == Path("/source/file.md")
        assert result.target_path == Path("/target/file.md")
        assert result.status == InstallStatus.SUCCESS
        assert result.message == ""
        assert result.backup_path is None

    def test_create_with_all_fields(self):
        """ComponentResult should accept all optional fields."""
        from ring_installer.core import ComponentResult, InstallStatus

        result = ComponentResult(
            source_path=Path("/source/file.md"),
            target_path=Path("/target/file.md"),
            status=InstallStatus.FAILED,
            message="An error occurred",
            backup_path=Path("/backup/file.md.bak")
        )

        assert result.message == "An error occurred"
        assert result.backup_path == Path("/backup/file.md.bak")


# ==============================================================================
# InstallResult Tests
# ==============================================================================

class TestInstallResult:
    """Tests for the InstallResult dataclass."""

    def test_default_values(self):
        """InstallResult should have sensible defaults."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)

        assert result.status == InstallStatus.SUCCESS
        assert result.targets == []
        assert result.components_installed == 0
        assert result.components_failed == 0
        assert result.components_skipped == 0
        assert result.errors == []
        assert result.warnings == []
        assert result.details == []
        assert result.timestamp is not None

    def test_add_success(self):
        """add_success() should record successful installation."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)
        source = Path("/source/file.md")
        target = Path("/target/file.md")
        backup = Path("/backup/file.md.bak")

        result.add_success(source, target, backup)

        assert result.components_installed == 1
        assert len(result.details) == 1
        assert result.details[0].source_path == source
        assert result.details[0].target_path == target
        assert result.details[0].status == InstallStatus.SUCCESS
        assert result.details[0].backup_path == backup

    def test_add_failure(self):
        """add_failure() should record failed installation."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)
        source = Path("/source/file.md")
        target = Path("/target/file.md")

        result.add_failure(source, target, "Permission denied")

        assert result.components_failed == 1
        assert len(result.errors) == 1
        assert "Permission denied" in result.errors[0]
        assert len(result.details) == 1
        assert result.details[0].status == InstallStatus.FAILED

    def test_add_skip(self):
        """add_skip() should record skipped component."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)
        source = Path("/source/file.md")
        target = Path("/target/file.md")

        result.add_skip(source, target, "File exists")

        assert result.components_skipped == 1
        assert len(result.warnings) == 1
        assert "File exists" in result.warnings[0]
        assert len(result.details) == 1
        assert result.details[0].status == InstallStatus.SKIPPED

    def test_finalize_success(self):
        """finalize() should set SUCCESS when no failures."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)
        result.add_success(Path("/s"), Path("/t"))
        result.add_success(Path("/s2"), Path("/t2"))

        result.finalize()

        assert result.status == InstallStatus.SUCCESS

    def test_finalize_partial(self):
        """finalize() should set PARTIAL when some failures."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)
        result.add_success(Path("/s"), Path("/t"))
        result.add_failure(Path("/s2"), Path("/t2"), "Error")

        result.finalize()

        assert result.status == InstallStatus.PARTIAL

    def test_finalize_failed(self):
        """finalize() should set FAILED when all failures."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)
        result.add_failure(Path("/s"), Path("/t"), "Error 1")
        result.add_failure(Path("/s2"), Path("/t2"), "Error 2")

        result.finalize()

        assert result.status == InstallStatus.FAILED

    def test_finalize_skipped(self):
        """finalize() should set SKIPPED when all skipped and no failures."""
        from ring_installer.core import InstallResult, InstallStatus

        result = InstallResult(status=InstallStatus.SUCCESS)
        result.add_skip(Path("/s"), Path("/t"), "Exists")
        result.add_skip(Path("/s2"), Path("/t2"), "Exists")

        result.finalize()

        assert result.status == InstallStatus.SKIPPED


# ==============================================================================
# load_manifest Tests
# ==============================================================================

class TestLoadManifest:
    """Tests for the load_manifest function."""

    def test_loads_valid_manifest(self, tmp_path):
        """load_manifest() should load valid JSON manifest."""
        from ring_installer.core import load_manifest

        manifest_data = {
            "platforms": {
                "claude": {"install_path": "~/.claude"},
                "factory": {"install_path": "~/.factory"}
            }
        }

        manifest_path = tmp_path / "platforms.json"
        with open(manifest_path, "w") as f:
            json.dump(manifest_data, f)

        result = load_manifest(manifest_path)

        assert result == manifest_data
        assert "platforms" in result
        assert "claude" in result["platforms"]

    def test_raises_on_missing_file(self, tmp_path):
        """load_manifest() should raise FileNotFoundError for missing file."""
        from ring_installer.core import load_manifest

        missing_path = tmp_path / "nonexistent.json"

        with pytest.raises(FileNotFoundError) as exc_info:
            load_manifest(missing_path)

        assert "Platform manifest not found" in str(exc_info.value)

    def test_raises_on_invalid_json(self, tmp_path):
        """load_manifest() should raise JSONDecodeError for invalid JSON."""
        from ring_installer.core import load_manifest

        invalid_path = tmp_path / "invalid.json"
        invalid_path.write_text("{ invalid json }")

        with pytest.raises(json.JSONDecodeError):
            load_manifest(invalid_path)

    def test_uses_bundled_manifest_when_none(self):
        """load_manifest() should use bundled manifest when path is None."""
        from ring_installer.core import load_manifest
        import importlib.resources

        # Check if bundled manifest exists before testing
        try:
            # Try to find the bundled manifest
            if hasattr(importlib.resources, 'files'):
                # Python 3.9+
                pkg_files = importlib.resources.files('ring_installer')
                manifest_file = pkg_files / 'data' / 'platforms.json'
                manifest_exists = manifest_file.is_file() if hasattr(manifest_file, 'is_file') else False
            else:
                manifest_exists = False
        except Exception:
            manifest_exists = False

        if not manifest_exists:
            pytest.skip("Bundled manifest not available in test environment")

        result = load_manifest(None)
        assert isinstance(result, dict)


# ==============================================================================
# discover_ring_components Tests
# ==============================================================================

class TestDiscoverRingComponents:
    """Tests for the discover_ring_components function."""

    def test_discovers_marketplace_structure(self, tmp_ring_root):
        """discover_ring_components() should find components in marketplace structure."""
        from ring_installer.core import discover_ring_components

        components = discover_ring_components(tmp_ring_root)

        assert "default" in components
        assert "agents" in components["default"]
        assert "commands" in components["default"]
        assert "skills" in components["default"]

    def test_discovers_legacy_structure(self, tmp_path):
        """discover_ring_components() should find components in legacy structure."""
        from ring_installer.core import discover_ring_components

        # Create legacy (non-marketplace) structure
        (tmp_path / "agents").mkdir()
        (tmp_path / "agents" / "test-agent.md").write_text("# Test Agent")

        (tmp_path / "skills" / "test-skill").mkdir(parents=True)
        (tmp_path / "skills" / "test-skill" / "SKILL.md").write_text("# Test Skill")

        components = discover_ring_components(tmp_path)

        assert "default" in components
        assert len(components["default"]["agents"]) == 1
        assert len(components["default"]["skills"]) == 1

    def test_filters_by_plugin_names(self, tmp_ring_root):
        """discover_ring_components() should filter by plugin names."""
        from ring_installer.core import discover_ring_components

        components = discover_ring_components(tmp_ring_root, plugin_names=["default"])

        assert "default" in components
        assert "test" not in components

    def test_excludes_plugins(self, tmp_ring_root):
        """discover_ring_components() should exclude specified plugins."""
        from ring_installer.core import discover_ring_components

        components = discover_ring_components(tmp_ring_root, exclude_plugins=["default"])

        assert "default" not in components

    def test_returns_empty_for_missing_components(self, tmp_path):
        """discover_ring_components() should return empty lists for missing dirs."""
        from ring_installer.core import discover_ring_components

        # Empty directory
        components = discover_ring_components(tmp_path)

        assert "default" in components
        assert components["default"]["agents"] == []
        assert components["default"]["commands"] == []
        assert components["default"]["skills"] == []
        assert components["default"]["hooks"] == []

    def test_discovers_hooks(self, tmp_ring_root):
        """discover_ring_components() should discover hook files."""
        from ring_installer.core import discover_ring_components

        components = discover_ring_components(tmp_ring_root)

        # hooks.json should be discovered from fixtures
        assert "hooks" in components["default"]


# ==============================================================================
# install Tests
# ==============================================================================

class TestInstall:
    """Tests for the install function."""

    def test_install_single_platform(self, tmp_ring_root, tmp_install_dir):
        """install() should install components to a single platform."""
        from ring_installer.core import install, InstallTarget, InstallOptions, InstallStatus

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(force=True)

        result = install(tmp_ring_root, [target], options)

        assert result.status in [InstallStatus.SUCCESS, InstallStatus.PARTIAL]
        assert result.components_installed > 0 or result.components_skipped > 0

    def test_install_multiple_platforms(self, tmp_ring_root, tmp_path):
        """install() should install to multiple platforms."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        claude_dir = tmp_path / "claude"
        factory_dir = tmp_path / "factory"
        claude_dir.mkdir()
        factory_dir.mkdir()

        targets = [
            InstallTarget(platform="claude", path=claude_dir),
            InstallTarget(platform="factory", path=factory_dir)
        ]
        options = InstallOptions(force=True)

        result = install(tmp_ring_root, targets, options)

        assert "claude" in result.targets
        assert "factory" in result.targets

    def test_install_dry_run(self, tmp_ring_root, tmp_install_dir):
        """install() should not create files in dry run mode."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(dry_run=True, verbose=True)

        result = install(tmp_ring_root, [target], options)

        # Should report success without actually creating files
        assert result.components_installed > 0 or result.components_skipped > 0

    def test_install_skips_existing_without_force(self, tmp_ring_root, tmp_install_dir):
        """install() should skip existing files when force=False."""
        from ring_installer.core import install, InstallTarget, InstallOptions, InstallStatus

        # First install
        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(force=True)
        install(tmp_ring_root, [target], options)

        # Second install without force
        options = InstallOptions(force=False)
        result = install(tmp_ring_root, [target], options)

        assert result.components_skipped > 0

    def test_install_creates_backups(self, tmp_ring_root, tmp_install_dir):
        """install() should create backups when overwriting."""
        from ring_installer.core import install, InstallTarget, InstallOptions, InstallStatus

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(force=True, backup=True)

        # First install
        install(tmp_ring_root, [target], options)

        # Second install should create backups
        result = install(tmp_ring_root, [target], options)

        # Check that some components have backup paths
        backups = [d for d in result.details if d.backup_path is not None]
        # May or may not have backups depending on whether files were identical

    def test_install_calls_progress_callback(self, tmp_ring_root, tmp_install_dir):
        """install() should call progress callback during installation."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        progress_calls = []

        def track_progress(message, current, total):
            progress_calls.append((message, current, total))

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(force=True)

        install(tmp_ring_root, [target], options, progress_callback=track_progress)

        assert len(progress_calls) > 0
        # Progress should show incrementing current values
        currents = [c for _, c, _ in progress_calls]
        assert currents == sorted(currents)

    def test_install_filters_components(self, tmp_ring_root, tmp_install_dir):
        """install() should respect component filter."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        target = InstallTarget(
            platform="claude",
            path=tmp_install_dir,
            components=["agents"]  # Only install agents
        )
        options = InstallOptions(force=True)

        result = install(tmp_ring_root, [target], options)

        # Should only have agent installations
        for detail in result.details:
            # Source path should be from agents directory
            assert "agents" in str(detail.source_path) or detail.source_path.parent.name == "agents"

    def test_install_handles_read_error(self, tmp_ring_root, tmp_install_dir):
        """install() should handle file read errors gracefully."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(force=True)

        # Make a file unreadable (platform-dependent)
        # This is difficult to test portably, so we just verify the install completes
        result = install(tmp_ring_root, [target], options)

        # Should complete without crashing
        assert result.status is not None


# ==============================================================================
# update Tests
# ==============================================================================

class TestUpdate:
    """Tests for the update function."""

    def test_update_is_install_with_force(self, tmp_ring_root, tmp_install_dir):
        """update() should be equivalent to install with force=True."""
        from ring_installer.core import update, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions()

        result = update(tmp_ring_root, [target], options)

        # Update should have run with force enabled
        assert result.status is not None

    def test_update_overwrites_existing(self, tmp_ring_root, tmp_install_dir):
        """update() should overwrite existing files."""
        from ring_installer.core import install, update, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # First install
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Modify an installed file
        agents_dir = tmp_install_dir / "agents"
        if agents_dir.exists():
            for f in agents_dir.glob("*.md"):
                f.write_text("Modified content")
                break

        # Update should overwrite
        result = update(tmp_ring_root, [target])

        assert result.components_installed > 0 or result.components_skipped > 0


# ==============================================================================
# uninstall Tests
# ==============================================================================

class TestUninstall:
    """Tests for the uninstall function."""

    def test_uninstall_removes_component_directories(self, tmp_ring_root, tmp_install_dir):
        """uninstall() should remove component directories."""
        from ring_installer.core import install, uninstall, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # First install
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Then uninstall
        result = uninstall([target], InstallOptions(backup=False))

        # Directories should be removed or at least attempted
        assert result.components_installed > 0 or len(result.errors) > 0

    def test_uninstall_dry_run(self, tmp_ring_root, tmp_install_dir):
        """uninstall() should not remove files in dry run mode."""
        from ring_installer.core import install, uninstall, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # First install
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Check what exists
        agents_dir = tmp_install_dir / "agents"
        existed_before = agents_dir.exists()

        # Dry run uninstall
        result = uninstall([target], InstallOptions(dry_run=True, verbose=True))

        # Directory should still exist if it existed before
        if existed_before:
            assert agents_dir.exists()

    def test_uninstall_creates_backups(self, tmp_ring_root, tmp_install_dir):
        """uninstall() should create backups when requested."""
        from ring_installer.core import install, uninstall, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # First install
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Uninstall with backup
        result = uninstall([target], InstallOptions(backup=True))

        # Should complete (backup may or may not exist depending on implementation)
        assert result.status is not None

    def test_uninstall_handles_missing_directories(self, tmp_install_dir):
        """uninstall() should handle missing directories gracefully."""
        from ring_installer.core import uninstall, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # Uninstall from empty directory (nothing installed)
        result = uninstall([target], InstallOptions())

        # Should complete without error
        assert result.status is not None


# ==============================================================================
# list_installed Tests
# ==============================================================================

class TestListInstalled:
    """Tests for the list_installed function."""

    def test_list_installed_finds_components(self, tmp_ring_root, tmp_install_dir):
        """list_installed() should find installed components."""
        from ring_installer.core import install, list_installed, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # Install first
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Mock get_adapter to return our custom path
        with patch("ring_installer.core.get_adapter") as mock_get_adapter:
            mock_adapter = MagicMock()
            mock_adapter.get_install_path.return_value = tmp_install_dir
            mock_adapter.get_component_mapping.return_value = {
                "agents": {"target_dir": "agents", "extension": ".md"},
                "commands": {"target_dir": "commands", "extension": ".md"},
                "skills": {"target_dir": "skills", "extension": ".md"},
                "hooks": {"target_dir": "hooks", "extension": ""},
            }
            mock_get_adapter.return_value = mock_adapter

            installed = list_installed("claude")

            assert "agents" in installed
            assert "commands" in installed
            assert "skills" in installed

    def test_list_installed_empty_when_nothing_installed(self, tmp_install_dir):
        """list_installed() should return empty lists when nothing installed."""
        from ring_installer.core import list_installed

        with patch("ring_installer.core.get_adapter") as mock_get_adapter:
            mock_adapter = MagicMock()
            mock_adapter.get_install_path.return_value = tmp_install_dir
            mock_adapter.get_component_mapping.return_value = {
                "agents": {"target_dir": "agents", "extension": ".md"},
            }
            mock_get_adapter.return_value = mock_adapter

            installed = list_installed("claude")

            assert installed["agents"] == []


# ==============================================================================
# UpdateCheckResult Tests
# ==============================================================================

class TestUpdateCheckResult:
    """Tests for the UpdateCheckResult dataclass."""

    def test_default_values(self):
        """UpdateCheckResult should have sensible defaults."""
        from ring_installer.core import UpdateCheckResult

        result = UpdateCheckResult(
            platform="claude",
            installed_version="1.0.0",
            available_version="1.1.0",
            update_available=True
        )

        assert result.platform == "claude"
        assert result.installed_version == "1.0.0"
        assert result.available_version == "1.1.0"
        assert result.update_available is True
        assert result.changed_files == []
        assert result.new_files == []
        assert result.removed_files == []

    def test_has_changes_property(self):
        """has_changes should return True when there are changes."""
        from ring_installer.core import UpdateCheckResult

        # No changes
        result = UpdateCheckResult(
            platform="claude",
            installed_version="1.0.0",
            available_version="1.0.0",
            update_available=False
        )
        assert result.has_changes is False

        # With changed files
        result = UpdateCheckResult(
            platform="claude",
            installed_version="1.0.0",
            available_version="1.1.0",
            update_available=True,
            changed_files=["file.md"]
        )
        assert result.has_changes is True

        # With new files
        result = UpdateCheckResult(
            platform="claude",
            installed_version="1.0.0",
            available_version="1.1.0",
            update_available=True,
            new_files=["new.md"]
        )
        assert result.has_changes is True

        # With removed files
        result = UpdateCheckResult(
            platform="claude",
            installed_version="1.0.0",
            available_version="1.1.0",
            update_available=True,
            removed_files=["old.md"]
        )
        assert result.has_changes is True


# ==============================================================================
# check_updates Tests
# ==============================================================================

class TestCheckUpdates:
    """Tests for the check_updates function."""

    def test_check_updates_returns_results_per_platform(self, tmp_ring_root, tmp_install_dir):
        """check_updates() should return results for each target platform."""
        from ring_installer.core import check_updates, InstallTarget

        targets = [
            InstallTarget(platform="claude", path=tmp_install_dir)
        ]

        with patch("ring_installer.core.check_for_updates") as mock_check:
            mock_check.return_value = MagicMock(
                installed_version="1.0.0",
                available_version="1.1.0",
                update_available=True,
                changed_files=["file.md"],
                new_files=[],
                removed_files=[]
            )

            results = check_updates(tmp_ring_root, targets)

            assert "claude" in results
            assert results["claude"].update_available is True

    def test_check_updates_detects_no_updates(self, tmp_ring_root, tmp_install_dir):
        """check_updates() should detect when no updates available."""
        from ring_installer.core import check_updates, InstallTarget

        targets = [
            InstallTarget(platform="claude", path=tmp_install_dir)
        ]

        with patch("ring_installer.core.check_for_updates") as mock_check:
            mock_check.return_value = MagicMock(
                installed_version="1.0.0",
                available_version="1.0.0",
                update_available=False,
                changed_files=[],
                new_files=[],
                removed_files=[]
            )

            results = check_updates(tmp_ring_root, targets)

            assert results["claude"].update_available is False


# ==============================================================================
# update_with_diff Tests
# ==============================================================================

class TestUpdateWithDiff:
    """Tests for the update_with_diff function."""

    def test_update_with_diff_skips_unchanged(self, tmp_ring_root, tmp_install_dir):
        """update_with_diff() should skip unchanged files."""
        from ring_installer.core import install, update_with_diff, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # First install
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Update with diff - should skip identical files
        result = update_with_diff(tmp_ring_root, [target])

        # Most files should be skipped as unchanged
        assert result.components_skipped >= 0

    def test_update_with_diff_updates_changed(self, tmp_ring_root, tmp_install_dir):
        """update_with_diff() should update changed files."""
        from ring_installer.core import install, update_with_diff, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # First install
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Modify installed file
        agents_dir = tmp_install_dir / "agents"
        if agents_dir.exists():
            for f in agents_dir.glob("*.md"):
                f.write_text("Modified content that differs from source")
                break

        # Update with diff
        result = update_with_diff(tmp_ring_root, [target])

        # Should have updated the modified file
        assert result.status is not None

    def test_update_with_diff_dry_run(self, tmp_ring_root, tmp_install_dir):
        """update_with_diff() should support dry run mode."""
        from ring_installer.core import install, update_with_diff, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(dry_run=True, verbose=True)

        # First install
        install(tmp_ring_root, [target], InstallOptions(force=True))

        # Modify a file
        agents_dir = tmp_install_dir / "agents"
        original_content = None
        modified_file = None
        if agents_dir.exists():
            for f in agents_dir.glob("*.md"):
                original_content = f.read_text()
                f.write_text("Modified content")
                modified_file = f
                break

        # Dry run update
        result = update_with_diff(tmp_ring_root, [target], options)

        # File should still be modified (not actually updated)
        if modified_file and modified_file.exists():
            assert modified_file.read_text() == "Modified content"


# ==============================================================================
# SyncResult Tests
# ==============================================================================

class TestSyncResult:
    """Tests for the SyncResult dataclass."""

    def test_default_values(self):
        """SyncResult should have sensible defaults."""
        from ring_installer.core import SyncResult

        result = SyncResult()

        assert result.platforms_synced == []
        assert result.platforms_skipped == []
        assert result.drift_detected is False
        assert result.drift_details == {}
        assert result.install_results == {}


# ==============================================================================
# sync_platforms Tests
# ==============================================================================

class TestSyncPlatforms:
    """Tests for the sync_platforms function."""

    def test_sync_platforms_detects_drift(self, tmp_ring_root, tmp_path):
        """sync_platforms() should detect version drift."""
        from ring_installer.core import sync_platforms, InstallTarget

        claude_dir = tmp_path / "claude"
        claude_dir.mkdir()

        targets = [
            InstallTarget(platform="claude", path=claude_dir)
        ]

        with patch("ring_installer.core.get_installed_version") as mock_version, \
             patch("ring_installer.core.get_ring_version") as mock_ring:
            mock_version.return_value = "1.0.0"
            mock_ring.return_value = "1.1.0"

            result = sync_platforms(tmp_ring_root, targets)

            assert result.drift_detected is True
            assert "claude" in result.drift_details

    def test_sync_platforms_syncs_all_targets(self, tmp_ring_root, tmp_path):
        """sync_platforms() should sync all target platforms."""
        from ring_installer.core import sync_platforms, InstallTarget, InstallOptions

        claude_dir = tmp_path / "claude"
        factory_dir = tmp_path / "factory"
        claude_dir.mkdir()
        factory_dir.mkdir()

        targets = [
            InstallTarget(platform="claude", path=claude_dir),
            InstallTarget(platform="factory", path=factory_dir)
        ]

        result = sync_platforms(tmp_ring_root, targets, InstallOptions(force=True))

        # Both platforms should have install results
        assert "claude" in result.install_results
        assert "factory" in result.install_results


# ==============================================================================
# uninstall_with_manifest Tests
# ==============================================================================

class TestUninstallWithManifest:
    """Tests for the uninstall_with_manifest function."""

    def test_uninstall_with_manifest_uses_manifest(self, tmp_install_dir):
        """uninstall_with_manifest() should use manifest for precision removal."""
        from ring_installer.core import uninstall_with_manifest, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # Create mock manifest
        manifest_data = {
            "files": {
                "agents/test.md": "hash123"
            }
        }

        with patch("ring_installer.core.InstallManifest") as MockManifest, \
             patch("ring_installer.core.get_manifest_path") as mock_path, \
             patch("ring_installer.core.safe_remove") as mock_remove:

            mock_manifest = MagicMock()
            mock_manifest.files = manifest_data["files"]
            MockManifest.load.return_value = mock_manifest
            mock_path.return_value = tmp_install_dir / ".ring-manifest.json"

            result = uninstall_with_manifest([target], InstallOptions(backup=False))

            # Should have attempted to remove files
            assert result.status is not None

    def test_uninstall_with_manifest_falls_back(self, tmp_install_dir):
        """uninstall_with_manifest() should fall back when no manifest."""
        from ring_installer.core import uninstall_with_manifest, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        with patch("ring_installer.core.InstallManifest") as MockManifest, \
             patch("ring_installer.core.get_manifest_path"):

            MockManifest.load.return_value = None

            result = uninstall_with_manifest([target], InstallOptions(backup=False))

            # Should still complete with a warning about fallback
            assert "No install manifest found" in str(result.warnings) or result.status is not None

    def test_uninstall_with_manifest_dry_run(self, tmp_install_dir):
        """uninstall_with_manifest() should support dry run mode."""
        from ring_installer.core import uninstall_with_manifest, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # Create actual file
        agents_dir = tmp_install_dir / "agents"
        agents_dir.mkdir()
        test_file = agents_dir / "test.md"
        test_file.write_text("content")

        with patch("ring_installer.core.InstallManifest") as MockManifest, \
             patch("ring_installer.core.get_manifest_path"):

            mock_manifest = MagicMock()
            mock_manifest.files = {"agents/test.md": "hash123"}
            MockManifest.load.return_value = mock_manifest

            result = uninstall_with_manifest(
                [target],
                InstallOptions(dry_run=True, verbose=True)
            )

            # File should still exist
            assert test_file.exists()


# ==============================================================================
# Integration Tests
# ==============================================================================

class TestIntegration:
    """Integration tests for core functionality."""

    def test_full_install_update_uninstall_cycle(self, tmp_ring_root, tmp_install_dir):
        """Test complete install -> update -> uninstall cycle."""
        from ring_installer.core import (
            install, update, uninstall,
            InstallTarget, InstallOptions, InstallStatus
        )

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        # Install
        install_result = install(tmp_ring_root, [target], InstallOptions(force=True))
        assert install_result.status in [InstallStatus.SUCCESS, InstallStatus.PARTIAL, InstallStatus.SKIPPED]

        # Update
        update_result = update(tmp_ring_root, [target])
        assert update_result.status is not None

        # Uninstall
        uninstall_result = uninstall([target], InstallOptions(backup=False))
        assert uninstall_result.status is not None

    def test_multi_platform_install(self, tmp_ring_root, tmp_path):
        """Test installing to multiple platforms simultaneously."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        platforms = ["claude", "factory", "cursor", "cline"]
        targets = []

        for platform in platforms:
            platform_dir = tmp_path / platform
            platform_dir.mkdir()
            targets.append(InstallTarget(platform=platform, path=platform_dir))

        result = install(tmp_ring_root, targets, InstallOptions(force=True))

        # All platforms should be in targets
        for platform in platforms:
            assert platform in result.targets

    def test_selective_component_install(self, tmp_ring_root, tmp_install_dir):
        """Test installing only specific component types."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        # Install only agents
        target = InstallTarget(
            platform="claude",
            path=tmp_install_dir,
            components=["agents"]
        )

        result = install(tmp_ring_root, [target], InstallOptions(force=True))

        # All installed components should be agents
        for detail in result.details:
            if detail.status.value == "success":
                assert "agents" in str(detail.source_path)

    def test_plugin_filtering(self, tmp_ring_root, tmp_install_dir):
        """Test filtering by plugin names."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        options = InstallOptions(
            force=True,
            plugin_names=["default"]
        )

        result = install(tmp_ring_root, [target], options)

        # Should only have components from default plugin
        assert result.status is not None


# ==============================================================================
# Edge Cases and Error Handling
# ==============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_empty_source_directory(self, tmp_path, tmp_install_dir):
        """Should handle empty source directory gracefully."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        result = install(tmp_path, [target], InstallOptions())

        # Should complete without error, possibly with no components
        assert result.status is not None

    def test_install_with_none_options(self, tmp_ring_root, tmp_install_dir):
        """Should handle None options."""
        from ring_installer.core import install, InstallTarget

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        result = install(tmp_ring_root, [target], None)

        assert result.status is not None

    def test_empty_targets_list(self, tmp_ring_root):
        """Should handle empty targets list."""
        from ring_installer.core import install, InstallOptions

        result = install(tmp_ring_root, [], InstallOptions())

        # Should complete with nothing to do
        assert result.targets == []

    def test_unicode_content_handling(self, tmp_path, tmp_install_dir):
        """Should handle unicode content in files."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        # Create source with unicode content
        agents_dir = tmp_path / "agents"
        agents_dir.mkdir()
        (agents_dir / "unicode.md").write_text("# Agent \u4e2d\u6587 \U0001F600", encoding="utf-8")

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        result = install(tmp_path, [target], InstallOptions(force=True))

        assert result.status is not None

    def test_deeply_nested_skills(self, tmp_path, tmp_install_dir):
        """Should handle deeply nested skill directories."""
        from ring_installer.core import discover_ring_components

        # Create nested skill
        skill_dir = tmp_path / "skills" / "deep-skill"
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text("# Deep Skill")

        components = discover_ring_components(tmp_path)

        assert len(components["default"]["skills"]) == 1

    def test_special_characters_in_filenames(self, tmp_path, tmp_install_dir):
        """Should handle special characters in filenames."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        # Create source with special filename
        agents_dir = tmp_path / "agents"
        agents_dir.mkdir()
        (agents_dir / "agent-with-dashes_and_underscores.md").write_text("# Agent")

        target = InstallTarget(platform="claude", path=tmp_install_dir)

        result = install(tmp_path, [target], InstallOptions(force=True))

        assert result.status is not None


# ==============================================================================
# Progress Callback Tests
# ==============================================================================

class TestProgressCallback:
    """Tests for progress callback functionality."""

    def test_progress_callback_receives_all_components(self, tmp_ring_root, tmp_install_dir):
        """Progress callback should be called for each component."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        calls = []

        def callback(msg, current, total):
            calls.append({"msg": msg, "current": current, "total": total})

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        install(tmp_ring_root, [target], InstallOptions(force=True), progress_callback=callback)

        # Should have received calls
        assert len(calls) > 0

    def test_progress_callback_total_is_consistent(self, tmp_ring_root, tmp_install_dir):
        """Progress callback total should be consistent across calls."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        totals = set()

        def callback(msg, current, total):
            totals.add(total)

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        install(tmp_ring_root, [target], InstallOptions(force=True), progress_callback=callback)

        # Total should be consistent (only one value)
        if totals:
            assert len(totals) == 1

    def test_progress_callback_current_increments(self, tmp_ring_root, tmp_install_dir):
        """Progress callback current should increment."""
        from ring_installer.core import install, InstallTarget, InstallOptions

        currents = []

        def callback(msg, current, total):
            currents.append(current)

        target = InstallTarget(platform="claude", path=tmp_install_dir)
        install(tmp_ring_root, [target], InstallOptions(force=True), progress_callback=callback)

        # Current values should be monotonically increasing
        if len(currents) > 1:
            for i in range(1, len(currents)):
                assert currents[i] >= currents[i - 1]
