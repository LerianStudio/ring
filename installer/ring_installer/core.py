"""
Core installation logic for Ring multi-platform installer.

This module provides the main installation, update, and uninstall functions
along with supporting data structures.
"""

import json
import logging
import shutil
import traceback
import warnings
import os
import tempfile
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable

from ring_installer.adapters import get_adapter, SUPPORTED_PLATFORMS, PlatformAdapter
from ring_installer.utils.version import (
    check_for_updates as _check_for_updates,
    get_installed_version as _get_installed_version,
    get_ring_version as _get_ring_version,
    get_manifest_path as _get_manifest_path,
    InstallManifest as _InstallManifest,
)
from ring_installer.utils.fs import safe_remove as _safe_remove

# Re-export for compatibility with tests/patching
check_for_updates = _check_for_updates
get_installed_version = _get_installed_version
InstallManifest = _InstallManifest
get_ring_version = _get_ring_version
get_manifest_path = _get_manifest_path
safe_remove = _safe_remove

logger = logging.getLogger(__name__)

# Maximum file size to read (10MB)
MAX_FILE_SIZE = 10 * 1024 * 1024


class InstallStatus(Enum):
    """Status of an installation operation."""
    SUCCESS = "success"
    PARTIAL = "partial"
    FAILED = "failed"
    SKIPPED = "skipped"


@dataclass
class InstallTarget:
    """
    Represents a target platform for installation.

    Attributes:
        platform: Platform identifier (claude, factory, cursor, cline)
        path: Optional custom installation path (uses default if None)
        components: List of component types to install (agents, commands, skills)
                   If None, installs all components.
    """
    platform: str
    path: Optional[Path] = None
    components: Optional[List[str]] = None

    def __post_init__(self):
        """Validate the target configuration."""
        if self.platform not in SUPPORTED_PLATFORMS:
            raise ValueError(
                f"Unsupported platform: '{self.platform}'. "
                f"Supported: {', '.join(SUPPORTED_PLATFORMS)}"
            )
        if self.path is not None:
            self.path = Path(self.path).expanduser().resolve()
            # Validate path is within expected boundaries
            home = Path.home()
            try:
                self.path.relative_to(home)
            except ValueError:
                # Path not under home - check if it's a reasonable location
                allowed = [Path("/opt"), Path("/usr/local"), Path(tempfile.gettempdir()).resolve()]
                if not any(
                    self.path.is_relative_to(p) for p in allowed if p.exists()
                ):
                    warnings.warn(
                        f"Install path is outside recommended locations: {self.path}",
                        RuntimeWarning,
                        stacklevel=2,
                    )


@dataclass
class InstallOptions:
    """
    Options controlling the installation behavior.

    Attributes:
        dry_run: If True, show what would be done without making changes
        force: If True, overwrite existing files without prompting
        backup: If True, create backups before overwriting
        verbose: If True, output detailed progress information
        plugin_names: List of plugin names to install (None = all)
        exclude_plugins: List of plugin names to exclude
        rollback_on_failure: If True, remove files written in a failed install pass
    """
    dry_run: bool = False
    force: bool = False
    backup: bool = True
    verbose: bool = False
    plugin_names: Optional[List[str]] = None
    exclude_plugins: Optional[List[str]] = None
    rollback_on_failure: bool = True


@dataclass(slots=True)
class ComponentResult:
    """Result of installing a single component."""
    source_path: Path
    target_path: Path
    status: InstallStatus
    message: str = ""
    backup_path: Optional[Path] = None
    traceback_str: Optional[str] = None


@dataclass
class InstallResult:
    """
    Result of an installation operation.

    Attributes:
        status: Overall status of the installation
        targets: List of platforms that were targeted
        components_installed: Count of successfully installed components
        components_failed: Count of failed component installations
        components_skipped: Count of skipped components
        components_removed: Count of removed components (for uninstall operations)
        errors: List of error messages
        warnings: List of warning messages
        details: Detailed results per component
        timestamp: When the installation was performed
    """
    status: InstallStatus
    targets: List[str] = field(default_factory=list)
    components_installed: int = 0
    components_failed: int = 0
    components_skipped: int = 0
    components_removed: int = 0
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    details: List[ComponentResult] = field(default_factory=list)
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())

    def add_success(self, source: Path, target: Path, backup: Optional[Path] = None) -> None:
        """Record a successful component installation."""
        self.components_installed += 1
        self.details.append(ComponentResult(
            source_path=source,
            target_path=target,
            status=InstallStatus.SUCCESS,
            backup_path=backup
        ))

    def add_failure(
        self,
        source: Path,
        target: Path,
        message: str,
        exc_info: Optional[BaseException] = None,
        include_traceback: bool = True
    ) -> None:
        """Record a failed component installation.

        Args:
            source: Source file path
            target: Target file path
            message: Error message
            exc_info: Optional exception for context preservation
            include_traceback: Whether to include traceback in details
        """
        self.components_failed += 1
        self.errors.append(f"{source}: {message}")

        traceback_str = None
        if exc_info is not None and include_traceback:
            traceback_str = "".join(
                traceback.format_exception(type(exc_info), exc_info, exc_info.__traceback__)
            )

        self.details.append(ComponentResult(
            source_path=source,
            target_path=target,
            status=InstallStatus.FAILED,
            message=message,
            traceback_str=traceback_str
        ))

    def add_skip(self, source: Path, target: Path, message: str) -> None:
        """Record a skipped component."""
        self.components_skipped += 1
        self.warnings.append(f"{source}: {message}")
        self.details.append(ComponentResult(
            source_path=source,
            target_path=target,
            status=InstallStatus.SKIPPED,
            message=message
        ))

    def add_removal(self, target: Path, message: str = "") -> None:
        """Record a successful component removal."""
        self.components_removed += 1
        self.details.append(ComponentResult(
            source_path=Path(""),  # No source for removals
            target_path=target,
            status=InstallStatus.SUCCESS,
            message=message or "Removed"
        ))

    def finalize(self) -> None:
        """Set the overall status based on component results."""
        total_success = self.components_installed + self.components_removed
        if self.components_failed == 0 and total_success > 0:
            self.status = InstallStatus.SUCCESS
        elif total_success > 0:
            self.status = InstallStatus.PARTIAL
        elif self.components_skipped > 0 and self.components_failed == 0:
            self.status = InstallStatus.SKIPPED
        else:
            self.status = InstallStatus.FAILED


def _validate_marketplace_schema(
    marketplace: Dict[str, Any],
    marketplace_path: Path,
    ring_path: Path
) -> None:
    """
    Validate the marketplace.json schema.

    Security: Ensures plugin sources don't escape the ring directory.

    Args:
        marketplace: Parsed marketplace JSON
        marketplace_path: Path to marketplace.json
        ring_path: Root path of the Ring installation

    Raises:
        ValueError: If schema validation fails
    """
    # Validate plugins is a list
    plugins = marketplace.get("plugins")
    if plugins is not None and not isinstance(plugins, list):
        raise ValueError(
            f"Invalid marketplace.json: 'plugins' must be a list, got {type(plugins).__name__}"
        )

    if not plugins:
        return

    ring_path_resolved = ring_path.resolve()

    for i, plugin in enumerate(plugins):
        if not isinstance(plugin, dict):
            raise ValueError(
                f"Invalid marketplace.json: plugin at index {i} must be an object"
            )

        # Required fields
        if "name" not in plugin:
            raise ValueError(
                f"Invalid marketplace.json: plugin at index {i} missing required 'name' field"
            )
        if "source" not in plugin:
            raise ValueError(
                f"Invalid marketplace.json: plugin '{plugin.get('name', i)}' missing required 'source' field"
            )

        # Security: Validate source path doesn't escape ring directory
        source = plugin["source"]
        if source.startswith("./"):
            source_path = ring_path / source[2:]
        else:
            source_path = ring_path / source

        try:
            source_resolved = source_path.resolve()
            source_resolved.relative_to(ring_path_resolved)
        except ValueError:
            raise ValueError(
                f"Invalid marketplace.json: plugin '{plugin.get('name')}' source path "
                f"'{source}' escapes ring directory (path traversal detected)"
            )


def _sanitize_path_for_display(path: Path, base_path: Optional[Path] = None) -> str:
    """
    Sanitize a path for display in error messages.

    In non-verbose mode, shows only relative paths to avoid exposing
    full filesystem structure.

    Args:
        path: Path to sanitize
        base_path: Optional base path to make path relative to

    Returns:
        Sanitized path string
    """
    if base_path is not None:
        try:
            return str(path.relative_to(base_path))
        except ValueError:
            pass
    return path.name


def load_manifest(manifest_path: Optional[Path] = None) -> Dict[str, Any]:
    """
    Load the platform manifest configuration.

    Args:
        manifest_path: Path to platforms.json. If None, uses the bundled manifest.

    Returns:
        Dictionary containing platform configurations

    Raises:
        FileNotFoundError: If the manifest file doesn't exist
        json.JSONDecodeError: If the manifest is invalid JSON
    """
    if manifest_path is None:
        # Use bundled manifest
        manifest_path = Path(__file__).parent / "manifests" / "platforms.json"

    if not manifest_path.exists():
        raise FileNotFoundError(f"Platform manifest not found: {manifest_path}")

    with open(manifest_path, "r", encoding="utf-8") as f:
        return json.load(f)


def _verify_marketplace_integrity(ring_path: Path) -> None:
    """Optionally verify marketplace.json integrity when checksum is provided.

    Priority: (1) .claude-plugin/marketplace.sha256 file if present, (2) env
    variable MARKETPLACE_JSON_SHA256. If provided and mismatch occurs, raise
    ValueError. If neither present, emit a warning (no verification).
    """
    expected_hash = None
    checksum_file = ring_path / ".claude-plugin" / "marketplace.sha256"
    if checksum_file.exists():
        try:
            expected_hash = checksum_file.read_text(encoding="utf-8").strip().split()[0]
        except Exception:
            warnings.warn("Failed to read marketplace.sha256; skipping integrity check")

    if expected_hash is None:
        expected_hash = os.environ.get("MARKETPLACE_JSON_SHA256")

    marketplace_path = ring_path / ".claude-plugin" / "marketplace.json"
    if not marketplace_path.exists():
        warnings.warn("marketplace.json not found for integrity check")
        return

    if not expected_hash:
        warnings.warn("No marketplace checksum provided; integrity not verified")
        return

    from ring_installer.utils.fs import get_file_hash

    actual_hash = get_file_hash(marketplace_path, algorithm="sha256")
    if actual_hash != expected_hash:
        raise ValueError(
            f"marketplace.json integrity check failed. Expected {expected_hash}, got {actual_hash}"
        )


def discover_ring_components(ring_path: Path, plugin_names: Optional[List[str]] = None,
                             exclude_plugins: Optional[List[str]] = None) -> Dict[str, Dict[str, List[Path]]]:
    """
    Discover Ring components (skills, agents, commands) from a Ring installation.

    Args:
        ring_path: Path to Ring repository/installation
        plugin_names: Optional list of plugin names to include
        exclude_plugins: Optional list of plugin names to exclude

    Returns:
        Dictionary mapping plugin names to their components:
        {
            "default": {
                "agents": [Path(...), ...],
                "commands": [Path(...), ...],
                "skills": [Path(...), ...],
                "hooks": [Path(...), ...]
            },
            ...
        }
    """
    components: Dict[str, Dict[str, List[Path]]] = {}

    # Check for marketplace structure
    marketplace_path = ring_path / ".claude-plugin" / "marketplace.json"
    if marketplace_path.exists():
        with open(marketplace_path) as f:
            marketplace = json.load(f)

        # Validate marketplace schema
        _validate_marketplace_schema(marketplace, marketplace_path, ring_path)

        # Validate marketplace has plugins
        if not marketplace.get("plugins"):
            warnings.warn(f"marketplace.json contains no plugins at {marketplace_path}")
            return {}

        # Process each plugin in marketplace
        for plugin in marketplace.get("plugins", []):
            name = plugin.get("name", "")
            # Only strip "ring-" prefix, not from anywhere in the string
            plugin_name = name[5:] if name.startswith("ring-") else name
            source = plugin.get("source", "")

            # Check filters
            if plugin_names and plugin_name not in plugin_names:
                continue
            if exclude_plugins and plugin_name in exclude_plugins:
                continue

            # Resolve plugin path
            if source.startswith("./"):
                plugin_path = ring_path / source[2:]
            else:
                plugin_path = ring_path / source

            if plugin_path.exists():
                components[plugin_name] = _discover_plugin_components(plugin_path)
    else:
        # Single plugin structure (legacy or simple install)
        components["default"] = _discover_plugin_components(ring_path)

    return components


def _discover_plugin_components(plugin_path: Path) -> Dict[str, List[Path]]:
    """
    Discover components within a single plugin directory.

    Args:
        plugin_path: Path to the plugin directory

    Returns:
        Dictionary mapping component types to file paths
    """
    result: Dict[str, List[Path]] = {
        "agents": [],
        "commands": [],
        "skills": [],
        "hooks": []
    }

    # Discover agents
    agents_dir = plugin_path / "agents"
    if agents_dir.exists():
        result["agents"] = list(agents_dir.glob("*.md"))

    # Discover commands
    commands_dir = plugin_path / "commands"
    if commands_dir.exists():
        result["commands"] = list(commands_dir.glob("*.md"))

    # Discover skills (in subdirectories with SKILL.md)
    skills_dir = plugin_path / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir():
                skill_file = skill_dir / "SKILL.md"
                if skill_file.exists():
                    result["skills"].append(skill_file)

    # Discover hooks
    hooks_dir = plugin_path / "hooks"
    if hooks_dir.exists():
        for ext in ["*.json", "*.sh", "*.py"]:
            result["hooks"].extend(hooks_dir.glob(ext))

    return result


def install(
    source_path: Path,
    targets: List[InstallTarget],
    options: Optional[InstallOptions] = None,
    progress_callback: Optional[Callable[[str, int, int], None]] = None
) -> InstallResult:
    """
    Install Ring components to one or more target platforms.

    Args:
        source_path: Path to the Ring repository/installation
        targets: List of installation targets
        options: Installation options
        progress_callback: Optional callback for progress updates
                          Called with (message, current, total)

    Returns:
        InstallResult with details about what was installed
    """
    from ring_installer.utils.fs import copy_with_transform, backup_existing, ensure_directory, safe_remove

    options = options or InstallOptions()
    result = InstallResult(status=InstallStatus.SUCCESS, targets=[t.platform for t in targets])

    # Optional integrity check for marketplace metadata
    _verify_marketplace_integrity(source_path)

    # Load manifest
    manifest = load_manifest()

    # Discover components
    components = discover_ring_components(
        source_path,
        plugin_names=options.plugin_names,
        exclude_plugins=options.exclude_plugins
    )

    # Calculate total work
    total_components = sum(
        len(files) for plugin_components in components.values()
        for files in plugin_components.values()
    ) * len(targets)

    current = 0

    # Process each target platform
    for target in targets:
        target_failures_before = result.components_failed
        installed_paths: List[Path] = []
        adapter = get_adapter(target.platform, manifest.get("platforms", {}).get(target.platform))
        install_path = target.path or adapter.get_install_path()
        component_mapping = adapter.get_component_mapping()

        # Process each plugin
        for plugin_name, plugin_components in components.items():
            # Process each component type
            for component_type, files in plugin_components.items():
                # Skip if component type not supported by platform
                if component_type not in component_mapping:
                    continue

                # Skip if not in target's component list
                if target.components and component_type not in target.components:
                    continue

                target_config = component_mapping[component_type]
                target_dir = install_path / target_config["target_dir"]

                # Check if platform requires flat structure for this component type
                requires_flat = adapter.requires_flat_components(component_type)

                # For multi-plugin installs, add plugin subdirectory UNLESS platform requires flat structure
                if len(components) > 1 and not requires_flat:
                    target_dir = target_dir / plugin_name

                # Ensure target directory exists
                if not options.dry_run:
                    ensure_directory(target_dir)

                # Process each file
                for source_file in files:
                    current += 1

                    if progress_callback:
                        progress_callback(
                            f"Installing {source_file.name} to {target.platform}",
                            current,
                            total_components
                        )

                    # Determine target filename
                    if component_type == "skills":
                        # Skills use their directory name
                        skill_name = source_file.parent.name
                        target_file = target_dir / skill_name / source_file.name
                    elif requires_flat and len(components) > 1:
                        # Platform requires flat structure - use prefixed filename
                        target_filename = adapter.get_flat_filename(
                            source_file.name,
                            component_type.rstrip("s"),  # agents -> agent
                            plugin_name
                        )
                        target_file = target_dir / target_filename
                    else:
                        target_filename = adapter.get_target_filename(
                            source_file.name,
                            component_type.rstrip("s")  # agents -> agent
                        )
                        target_file = target_dir / target_filename

                    # Check if target exists
                    if target_file.exists() and not options.force:
                        result.add_skip(
                            source_file,
                            target_file,
                            "File exists (use --force to overwrite)"
                        )
                        continue

                    # Create backup if needed
                    backup_path = None
                    if target_file.exists() and options.backup and not options.dry_run:
                        backup_path = backup_existing(target_file)

                    # Read source content with size validation
                    try:
                        file_size = source_file.stat().st_size
                        if file_size > MAX_FILE_SIZE:
                            result.add_failure(
                                source_file,
                                target_file,
                                f"File too large ({file_size} bytes, max {MAX_FILE_SIZE})"
                            )
                            continue

                        with open(source_file, "r", encoding="utf-8") as f:
                            content = f.read()
                    except Exception as e:
                        result.add_failure(source_file, target_file, f"Read error: {e}", exc_info=e)
                        continue

                    # Transform content
                    try:
                        metadata = {
                            "name": source_file.stem,
                            "source_path": str(source_file),
                            "plugin": plugin_name
                        }

                        if component_type == "agents":
                            transformed = adapter.transform_agent(content, metadata)
                        elif component_type == "commands":
                            transformed = adapter.transform_command(content, metadata)
                        elif component_type == "skills":
                            transformed = adapter.transform_skill(content, metadata)
                        elif component_type == "hooks":
                            transformed = adapter.transform_hook(content, metadata)
                        else:
                            transformed = content
                    except Exception as e:
                        result.add_failure(source_file, target_file, f"Transform error: {e}", exc_info=e)
                        continue

                    # Write transformed content
                    if options.dry_run:
                        if options.verbose:
                            result.warnings.append(
                                f"[DRY RUN] Would install {source_file} -> {target_file}"
                            )
                        result.add_success(source_file, target_file)
                    else:
                        try:
                            copy_with_transform(
                                source_file,
                                target_file,
                                transform_func=lambda _: transformed
                            )
                            result.add_success(source_file, target_file, backup_path)
                            installed_paths.append(target_file)
                        except Exception as e:
                            result.add_failure(source_file, target_file, f"Write error: {e}", exc_info=e)

        # Roll back partial target installs when failures occur
        if not options.dry_run and options.rollback_on_failure:
            if result.components_failed > target_failures_before and installed_paths:
                for path in installed_paths:
                    try:
                        safe_remove(path, missing_ok=True)
                    except Exception as e:
                        logger.warning("Rollback failed for %s: %s", path, e)
                result.warnings.append(
                    f"Rolled back partial install for {target.platform} after failures"
                )

    result.finalize()
    return result


def update(
    source_path: Path,
    targets: List[InstallTarget],
    options: Optional[InstallOptions] = None,
    progress_callback: Optional[Callable[[str, int, int], None]] = None
) -> InstallResult:
    """
    Update Ring components on target platforms.

    This is equivalent to install with force=True.

    Args:
        source_path: Path to the Ring repository/installation
        targets: List of installation targets
        options: Installation options
        progress_callback: Optional callback for progress updates

    Returns:
        InstallResult with details about what was updated
    """
    options = options or InstallOptions()
    options.force = True
    return install(source_path, targets, options, progress_callback)


def uninstall(
    targets: List[InstallTarget],
    options: Optional[InstallOptions] = None,
    progress_callback: Optional[Callable[[str, int, int], None]] = None
) -> InstallResult:
    """
    Remove Ring components from target platforms.

    Args:
        targets: List of platforms to uninstall from
        options: Uninstall options
        progress_callback: Optional callback for progress updates

    Returns:
        InstallResult with details about what was removed
    """
    options = options or InstallOptions()
    result = InstallResult(status=InstallStatus.SUCCESS, targets=[t.platform for t in targets])

    platform_manifest = load_manifest()

    for target in targets:
        adapter = get_adapter(target.platform, platform_manifest.get("platforms", {}).get(target.platform))
        install_path = target.path or adapter.get_install_path()
        component_mapping = adapter.get_component_mapping()

        # Remove each component directory
        for component_type, config in component_mapping.items():
            target_dir = install_path / config["target_dir"]

            if not target_dir.exists():
                continue

            if options.dry_run:
                if options.verbose:
                    result.warnings.append(f"[DRY RUN] Would remove {target_dir}")
                continue

            try:
                # Create backup if requested
                if options.backup:
                    from ring_installer.utils.fs import backup_existing
                    backup_existing(target_dir)

                # Remove directory
                shutil.rmtree(target_dir)
                result.add_removal(target_dir)
                result.components_installed += 1
            except Exception as e:
                result.errors.append(f"Failed to remove {target_dir}: {e}")
                result.components_failed += 1

    result.finalize()
    return result


def list_installed(platform: str) -> Dict[str, List[str]]:
    """
    List Ring components installed on a platform.

    Args:
        platform: Platform identifier

    Returns:
        Dictionary mapping component types to lists of installed component names
    """
    adapter = get_adapter(platform)
    install_path = adapter.get_install_path()
    component_mapping = adapter.get_component_mapping()

    installed: Dict[str, List[str]] = {}

    for component_type, config in component_mapping.items():
        target_dir = install_path / config["target_dir"]
        installed[component_type] = []

        if target_dir.exists():
            extension = config.get("extension", ".md")
            if extension:
                for file in target_dir.glob(f"*{extension}"):
                    installed[component_type].append(file.stem)
            else:
                # Multiple extensions (hooks)
                for file in target_dir.iterdir():
                    if file.is_file():
                        installed[component_type].append(file.name)

    return installed


@dataclass
class UpdateCheckResult:
    """
    Result of checking for updates.

    Attributes:
        platform: Platform identifier
        installed_version: Currently installed version
        available_version: Available version in source
        update_available: Whether an update is available
        changed_files: Files that have changed
        new_files: New files to be added
        removed_files: Files to be removed
    """
    platform: str
    installed_version: Optional[str]
    available_version: Optional[str]
    update_available: bool
    changed_files: List[str] = field(default_factory=list)
    new_files: List[str] = field(default_factory=list)
    removed_files: List[str] = field(default_factory=list)

    @property
    def has_changes(self) -> bool:
        """Check if there are any changes."""
        return bool(self.changed_files or self.new_files or self.removed_files)


def check_updates(
    source_path: Path,
    targets: List[InstallTarget]
) -> Dict[str, UpdateCheckResult]:
    """
    Check for available updates on target platforms.

    Args:
        source_path: Path to Ring source
        targets: List of platforms to check

    Returns:
        Dictionary mapping platform names to UpdateCheckResult
    """
    results: Dict[str, UpdateCheckResult] = {}
    manifest = load_manifest()

    for target in targets:
        adapter = get_adapter(target.platform, manifest.get("platforms", {}).get(target.platform))
        install_path = target.path or adapter.get_install_path()

        update_info = check_for_updates(source_path, install_path, target.platform)

        results[target.platform] = UpdateCheckResult(
            platform=target.platform,
            installed_version=update_info.installed_version,
            available_version=update_info.available_version,
            update_available=update_info.update_available,
            changed_files=update_info.changed_files,
            new_files=update_info.new_files,
            removed_files=update_info.removed_files,
        )

    return results


def update_with_diff(
    source_path: Path,
    targets: List[InstallTarget],
    options: Optional[InstallOptions] = None,
    progress_callback: Optional[Callable[[str, int, int], None]] = None
) -> InstallResult:
    """
    Update Ring components, only updating changed files.

    This is a smarter update that compares installed files with source
    and only updates files that have changed.

    Args:
        source_path: Path to the Ring repository/installation
        targets: List of installation targets
        options: Installation options
        progress_callback: Optional callback for progress updates

    Returns:
        InstallResult with details about what was updated
    """
    from ring_installer.utils.fs import (
        copy_with_transform,
        backup_existing,
        ensure_directory,
        get_file_hash,
    )
    from ring_installer.utils.version import (
        get_ring_version,
        get_manifest_path,
        InstallManifest,
        save_install_manifest,
    )

    options = options or InstallOptions()
    result = InstallResult(status=InstallStatus.SUCCESS, targets=[t.platform for t in targets])

    manifest = load_manifest()
    source_version = get_ring_version(source_path) or "0.0.0"

    # Discover components
    components = discover_ring_components(
        source_path,
        plugin_names=options.plugin_names,
        exclude_plugins=options.exclude_plugins
    )

    # Process each target
    for target in targets:
        adapter = get_adapter(target.platform, manifest.get("platforms", {}).get(target.platform))
        install_path = target.path or adapter.get_install_path()
        component_mapping = adapter.get_component_mapping()

        # Load existing manifest
        existing_manifest = InstallManifest.load(get_manifest_path(install_path))
        existing_files = existing_manifest.files if existing_manifest else {}

        # Track installed files for new manifest
        installed_files: Dict[str, str] = {}
        installed_plugins: List[str] = []

        # Process each plugin
        for plugin_name, plugin_components in components.items():
            installed_plugins.append(plugin_name)

            # Process each component type
            for component_type, files in plugin_components.items():
                if component_type not in component_mapping:
                    continue

                if target.components and component_type not in target.components:
                    continue

                target_config = component_mapping[component_type]
                target_dir = install_path / target_config["target_dir"]

                # Check if platform requires flat structure for this component type
                requires_flat = adapter.requires_flat_components(component_type)

                # For multi-plugin installs, add plugin subdirectory UNLESS platform requires flat structure
                if len(components) > 1 and not requires_flat:
                    target_dir = target_dir / plugin_name

                if not options.dry_run:
                    ensure_directory(target_dir)

                for source_file in files:
                    if progress_callback:
                        progress_callback(
                            f"Checking {source_file.name}",
                            result.components_installed + result.components_skipped,
                            sum(len(f) for pc in components.values() for f in pc.values())
                        )

                    # Determine target path
                    if component_type == "skills":
                        skill_name = source_file.parent.name
                        target_file = target_dir / skill_name / source_file.name
                    elif requires_flat and len(components) > 1:
                        # Platform requires flat structure - use prefixed filename
                        target_filename = adapter.get_flat_filename(
                            source_file.name,
                            component_type.rstrip("s"),
                            plugin_name
                        )
                        target_file = target_dir / target_filename
                    else:
                        target_filename = adapter.get_target_filename(
                            source_file.name,
                            component_type.rstrip("s")
                        )
                        target_file = target_dir / target_filename

                    # Compute source hash
                    try:
                        source_hash = get_file_hash(source_file)
                    except Exception as e:
                        result.add_failure(source_file, target_file, f"Hash error: {e}")
                        continue

                    # Check if update needed by comparing source hash with manifest
                    relative_path = str(target_file.relative_to(install_path))
                    target_exists = target_file.exists()
                    target_hash: Optional[str] = None
                    user_modified = False
                    if target_exists:
                        try:
                            target_hash = get_file_hash(target_file)
                            stored_hash = existing_files.get(relative_path, "")
                            if target_hash not in {stored_hash, source_hash} and stored_hash:
                                user_modified = True
                        except Exception as e:
                            result.add_failure(source_file, target_file, f"Target hash error: {e}")
                            continue

                    # Get stored source hash from manifest (backward compatible)
                    stored_source_hash = existing_files.get(relative_path, "")

                    if target_exists and stored_source_hash:
                        # Compare current source hash with stored source hash
                        if source_hash == stored_source_hash:
                            # Source file unchanged since last install, skip
                            installed_files[relative_path] = source_hash
                            result.add_skip(source_file, target_file, "No changes")
                            continue
                    elif target_exists and not stored_source_hash:
                        # Old manifest without source hashes - always update for safety
                        # This ensures first run after upgrade updates everything
                        pass

                    # File needs update
                    try:
                        with open(source_file, "r", encoding="utf-8") as f:
                            content = f.read()
                    except Exception as e:
                        result.add_failure(source_file, target_file, f"Read error: {e}")
                        continue

                    # Transform content
                    try:
                        metadata = {
                            "name": source_file.stem,
                            "source_path": str(source_file),
                            "plugin": plugin_name
                        }

                        if component_type == "agents":
                            transformed = adapter.transform_agent(content, metadata)
                        elif component_type == "commands":
                            transformed = adapter.transform_command(content, metadata)
                        elif component_type == "skills":
                            transformed = adapter.transform_skill(content, metadata)
                        elif component_type == "hooks":
                            transformed = adapter.transform_hook(content, metadata)
                        else:
                            transformed = content
                    except Exception as e:
                        result.add_failure(source_file, target_file, f"Transform error: {e}")
                        continue

                    # Write file
                    if options.dry_run:
                        if options.verbose:
                            action = "update" if target_exists else "install"
                            result.warnings.append(
                                f"[DRY RUN] Would {action} {source_file} -> {target_file}"
                            )
                        result.add_success(source_file, target_file)
                    else:
                        try:
                            backup_path = None
                            if target_exists and options.backup:
                                backup_path = backup_existing(target_file)

                            if user_modified:
                                result.warnings.append(
                                    f"User modifications detected in {target_file}; overwriting with backup"
                                )

                            copy_with_transform(
                                source_file,
                                target_file,
                                transform_func=lambda _: transformed
                            )
                            result.add_success(source_file, target_file, backup_path)
                        except Exception as e:
                            result.add_failure(source_file, target_file, f"Write error: {e}")
                            continue

                    installed_files[relative_path] = source_hash

        # Save updated manifest
        if not options.dry_run:
            save_install_manifest(
                install_path=install_path,
                source_path=source_path,
                platform=target.platform,
                version=source_version,
                plugins=installed_plugins,
                installed_files=installed_files
            )

    result.finalize()
    return result


@dataclass
class SyncResult:
    """
    Result of syncing platforms.

    Attributes:
        platforms_synced: List of platforms that were synced
        platforms_skipped: List of platforms that were skipped
        drift_detected: Whether drift was detected between platforms
        drift_details: Details about drift per platform
    """
    platforms_synced: List[str] = field(default_factory=list)
    platforms_skipped: List[str] = field(default_factory=list)
    drift_detected: bool = False
    drift_details: Dict[str, List[str]] = field(default_factory=dict)
    install_results: Dict[str, InstallResult] = field(default_factory=dict)


def sync_platforms(
    source_path: Path,
    targets: List[InstallTarget],
    options: Optional[InstallOptions] = None,
    progress_callback: Optional[Callable[[str, int, int], None]] = None
) -> SyncResult:
    """
    Sync Ring components across multiple platforms.

    Ensures all target platforms have consistent Ring installations
    by detecting drift and re-applying transformations.

    Args:
        source_path: Path to Ring source
        targets: List of platforms to sync
        options: Sync options
        progress_callback: Optional progress callback

    Returns:
        SyncResult with details about the sync operation
    """
    options = options or InstallOptions()
    sync_result = SyncResult()

    manifest = load_manifest()
    source_version = get_ring_version(source_path) or "0.0.0"

    # Check each platform for drift
    platform_versions: Dict[str, Optional[str]] = {}

    for target in targets:
        adapter = get_adapter(target.platform, manifest.get("platforms", {}).get(target.platform))
        install_path = target.path or adapter.get_install_path()

        installed_version = get_installed_version(install_path, target.platform)
        platform_versions[target.platform] = installed_version

        # Check for drift from source
        if installed_version != source_version:
            sync_result.drift_detected = True
            sync_result.drift_details[target.platform] = [
                f"Version mismatch: installed={installed_version}, source={source_version}"
            ]

    # Sync each platform
    for target in targets:
        if progress_callback:
            progress_callback(
                f"Syncing {target.platform}",
                targets.index(target),
                len(targets)
            )

        # Use update_with_diff for smart syncing
        install_result = update_with_diff(
            source_path,
            [target],
            options,
            progress_callback
        )

        sync_result.install_results[target.platform] = install_result

        if install_result.status in [InstallStatus.SUCCESS, InstallStatus.SKIPPED]:
            sync_result.platforms_synced.append(target.platform)
        else:
            sync_result.platforms_skipped.append(target.platform)

    return sync_result


def uninstall_with_manifest(
    targets: List[InstallTarget],
    options: Optional[InstallOptions] = None,
    progress_callback: Optional[Callable[[str, int, int], None]] = None
) -> InstallResult:
    """
    Remove Ring components using the install manifest for precision.

    Only removes files that were installed by Ring, preserving
    user modifications outside the manifest.

    Args:
        targets: List of platforms to uninstall from
        options: Uninstall options
        progress_callback: Optional progress callback

    Returns:
        InstallResult with details about what was removed
    """
    from ring_installer.utils.fs import safe_remove, backup_existing
    options = options or InstallOptions()
    result = InstallResult(status=InstallStatus.SUCCESS, targets=[t.platform for t in targets])

    manifest = load_manifest()

    for target in targets:
        adapter = get_adapter(target.platform, manifest.get("platforms", {}).get(target.platform))
        install_path = target.path or adapter.get_install_path()

        # Load install manifest
        install_manifest = InstallManifest.load(get_manifest_path(install_path))

        if not install_manifest:
            result.warnings.append(
                f"No install manifest found for {target.platform}, "
                "falling back to directory removal"
            )
            # Fall back to regular uninstall
            component_mapping = adapter.get_component_mapping()
            for component_type, config in component_mapping.items():
                target_dir = install_path / config["target_dir"]
                if target_dir.exists():
                    if options.dry_run:
                        if options.verbose:
                            result.warnings.append(f"[DRY RUN] Would remove {target_dir}")
                        result.add_removal(target_dir, "Would remove")
                    else:
                        try:
                            if options.backup:
                                from ring_installer.utils.fs import backup_existing
                                backup_existing(target_dir)
                            shutil.rmtree(target_dir)
                            result.add_removal(target_dir)
                        except Exception as e:
                            result.errors.append(f"Failed to remove {target_dir}: {e}")
                            result.components_failed += 1
            continue

        # Remove files from manifest
        for file_path in install_manifest.files.keys():
            full_path = install_path / file_path

            if progress_callback:
                progress_callback(
                    f"Removing {file_path}",
                    list(install_manifest.files.keys()).index(file_path),
                    len(install_manifest.files)
                )

            if options.dry_run:
                if options.verbose:
                    result.warnings.append(f"[DRY RUN] Would remove {full_path}")
                result.components_installed += 1
                continue

            if not full_path.exists():
                result.warnings.append(f"File already removed: {full_path}")
                continue

            try:
                if options.backup:
                    from ring_installer.utils.fs import backup_existing
                    backup_existing(full_path)

                safe_remove(full_path)
                result.add_removal(full_path)
                result.components_installed += 1
            except Exception as e:
                result.errors.append(f"Failed to remove {full_path}: {e}")
                result.components_failed += 1

        # Remove install manifest
        if not options.dry_run:
            manifest_path = get_manifest_path(install_path)
            if options.backup:
                backup_existing(manifest_path)
            safe_remove(manifest_path, missing_ok=True)

    result.finalize()
    return result
