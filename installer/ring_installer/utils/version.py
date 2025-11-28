"""
Version management utilities for Ring installer.

Provides semver comparison, version detection, and update checking.
"""

import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# Maximum allowed version string length to prevent DoS attacks
MAX_VERSION_LENGTH = 100


@dataclass
class Version:
    """
    Semantic version representation.

    Supports comparison operations and parsing from string.
    """
    major: int
    minor: int
    patch: int
    prerelease: str = ""
    build: str = ""

    @classmethod
    def parse(cls, version_str: str) -> "Version":
        """
        Parse a version string into a Version object.

        Args:
            version_str: Version string (e.g., "1.2.3", "1.2.3-beta.1", "1.2.3+build.123")

        Returns:
            Version object

        Raises:
            ValueError: If version string is invalid or too long
        """
        # Security: Validate version string length to prevent DoS
        if len(version_str) > MAX_VERSION_LENGTH:
            raise ValueError(
                f"Version string too long (max {MAX_VERSION_LENGTH} chars, got {len(version_str)})"
            )

        # Strip leading 'v' if present
        version_str = version_str.lstrip("v")

        # Regex for semver: major.minor.patch[-prerelease][+build]
        pattern = r'^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9.-]+))?(?:\+([a-zA-Z0-9.-]+))?$'
        match = re.match(pattern, version_str)

        if not match:
            raise ValueError(f"Invalid version string: '{version_str}'")

        return cls(
            major=int(match.group(1)),
            minor=int(match.group(2)),
            patch=int(match.group(3)),
            prerelease=match.group(4) or "",
            build=match.group(5) or ""
        )

    def __str__(self) -> str:
        """Convert to version string."""
        result = f"{self.major}.{self.minor}.{self.patch}"
        if self.prerelease:
            result += f"-{self.prerelease}"
        if self.build:
            result += f"+{self.build}"
        return result

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Version):
            return NotImplemented
        return (
            self.major == other.major and
            self.minor == other.minor and
            self.patch == other.patch and
            self.prerelease == other.prerelease
        )

    def __lt__(self, other: "Version") -> bool:
        # Compare major.minor.patch
        if (self.major, self.minor, self.patch) != (other.major, other.minor, other.patch):
            return (self.major, self.minor, self.patch) < (other.major, other.minor, other.patch)

        # Prerelease versions have lower precedence
        if self.prerelease and not other.prerelease:
            return True
        if not self.prerelease and other.prerelease:
            return False

        # Compare prereleases
        return self._compare_prerelease(self.prerelease, other.prerelease) < 0

    def __le__(self, other: "Version") -> bool:
        return self == other or self < other

    def __gt__(self, other: "Version") -> bool:
        return not self <= other

    def __ge__(self, other: "Version") -> bool:
        return not self < other

    def _compare_prerelease(self, a: str, b: str) -> int:
        """Compare prerelease identifiers."""
        if not a and not b:
            return 0
        if not a:
            return 1
        if not b:
            return -1

        a_parts = a.split(".")
        b_parts = b.split(".")

        for i in range(max(len(a_parts), len(b_parts))):
            a_part = a_parts[i] if i < len(a_parts) else ""
            b_part = b_parts[i] if i < len(b_parts) else ""

            # Try numeric comparison
            try:
                a_num = int(a_part)
                b_num = int(b_part)
                if a_num != b_num:
                    return a_num - b_num
            except ValueError:
                # Alphanumeric comparison
                if a_part != b_part:
                    return -1 if a_part < b_part else 1

        return 0

    def is_prerelease(self) -> bool:
        """Check if this is a prerelease version."""
        return bool(self.prerelease)

    def bump_major(self) -> "Version":
        """Return a new version with major incremented."""
        return Version(self.major + 1, 0, 0)

    def bump_minor(self) -> "Version":
        """Return a new version with minor incremented."""
        return Version(self.major, self.minor + 1, 0)

    def bump_patch(self) -> "Version":
        """Return a new version with patch incremented."""
        return Version(self.major, self.minor, self.patch + 1)


@dataclass
class InstallManifest:
    """
    Manifest tracking installed Ring components.

    Stored in the installation directory to track versions and files.
    """
    version: str
    installed_at: str
    source_path: str
    platform: str
    plugins: List[str]
    files: Dict[str, str]  # path -> hash
    metadata: Dict[str, Any]

    @classmethod
    def create(
        cls,
        version: str,
        source_path: str,
        platform: str,
        plugins: Optional[List[str]] = None,
        files: Optional[Dict[str, str]] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> "InstallManifest":
        """Create a new install manifest."""
        return cls(
            version=version,
            installed_at=datetime.now().isoformat(),
            source_path=source_path,
            platform=platform,
            plugins=plugins or [],
            files=files or {},
            metadata=metadata or {}
        )

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "version": self.version,
            "installed_at": self.installed_at,
            "source_path": self.source_path,
            "platform": self.platform,
            "plugins": self.plugins,
            "files": self.files,
            "metadata": self.metadata
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "InstallManifest":
        """Create from dictionary."""
        return cls(
            version=data.get("version", "0.0.0"),
            installed_at=data.get("installed_at", ""),
            source_path=data.get("source_path", ""),
            platform=data.get("platform", ""),
            plugins=data.get("plugins", []),
            files=data.get("files", {}),
            metadata=data.get("metadata", {})
        )

    def save(self, path: Path) -> None:
        """Save manifest to file."""
        path = Path(path).expanduser()
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(self.to_dict(), f, indent=2)

    @classmethod
    def load(cls, path: Path) -> Optional["InstallManifest"]:
        """Load manifest from file."""
        path = Path(path).expanduser()
        if not path.exists():
            return None
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return cls.from_dict(data)
        except (json.JSONDecodeError, KeyError):
            return None


def compare_versions(v1: str, v2: str) -> int:
    """
    Compare two version strings.

    Args:
        v1: First version string
        v2: Second version string

    Returns:
        -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
    """
    ver1 = Version.parse(v1)
    ver2 = Version.parse(v2)

    if ver1 < ver2:
        return -1
    elif ver1 > ver2:
        return 1
    return 0


def is_update_available(installed: str, available: str) -> bool:
    """
    Check if an update is available.

    Args:
        installed: Currently installed version
        available: Available version

    Returns:
        True if available > installed
    """
    return compare_versions(installed, available) < 0


def get_ring_version(ring_path: Path) -> Optional[str]:
    """
    Get the Ring version from a Ring installation.

    Looks for version in:
    1. .claude-plugin/marketplace.json
    2. VERSION file
    3. package.json

    Args:
        ring_path: Path to Ring installation

    Returns:
        Version string or None if not found
    """
    ring_path = Path(ring_path).expanduser()

    # Check marketplace.json
    marketplace_path = ring_path / ".claude-plugin" / "marketplace.json"
    if marketplace_path.exists():
        try:
            with open(marketplace_path) as f:
                data = json.load(f)
            version = data.get("version")
            if version:
                return version
        except (json.JSONDecodeError, KeyError):
            pass

    # Check VERSION file
    version_file = ring_path / "VERSION"
    if version_file.exists():
        try:
            return version_file.read_text().strip()
        except Exception:
            pass

    # Check package.json (if exists)
    package_json = ring_path / "package.json"
    if package_json.exists():
        try:
            with open(package_json) as f:
                data = json.load(f)
            return data.get("version")
        except (json.JSONDecodeError, KeyError):
            pass

    return None


def get_installed_version(install_path: Path, platform: str) -> Optional[str]:
    """
    Get the installed Ring version for a platform.

    Args:
        install_path: Platform installation path
        platform: Platform identifier

    Returns:
        Installed version or None
    """
    install_path = Path(install_path).expanduser()
    manifest_path = install_path / ".ring-manifest.json"

    manifest = InstallManifest.load(manifest_path)
    if manifest:
        return manifest.version

    return None


def get_manifest_path(install_path: Path) -> Path:
    """Get the path to the install manifest."""
    return Path(install_path).expanduser() / ".ring-manifest.json"


@dataclass
class UpdateInfo:
    """Information about available updates."""
    installed_version: Optional[str]
    available_version: Optional[str]
    update_available: bool
    is_newer: bool
    is_downgrade: bool
    changed_files: List[str]
    new_files: List[str]
    removed_files: List[str]

    @property
    def has_changes(self) -> bool:
        """Check if there are any changes."""
        return bool(self.changed_files or self.new_files or self.removed_files)


def check_for_updates(
    source_path: Path,
    install_path: Path,
    platform: str
) -> UpdateInfo:
    """
    Check for available updates.

    Args:
        source_path: Path to Ring source
        install_path: Platform installation path
        platform: Platform identifier

    Returns:
        UpdateInfo with details about available updates
    """
    source_path = Path(source_path).expanduser()
    install_path = Path(install_path).expanduser()

    # Get versions
    available = get_ring_version(source_path)
    installed = get_installed_version(install_path, platform)

    # Determine update status
    update_available = False
    is_newer = False
    is_downgrade = False

    if available and installed:
        cmp = compare_versions(installed, available)
        update_available = cmp < 0
        is_newer = cmp < 0
        is_downgrade = cmp > 0
    elif available and not installed:
        update_available = True
        is_newer = True

    # Check for file changes
    manifest = InstallManifest.load(get_manifest_path(install_path))

    changed_files: List[str] = []
    new_files: List[str] = []
    removed_files: List[str] = []

    if manifest:
        # Compare installed files with source
        from ring_installer.utils.fs import get_file_hash

        for file_path, file_hash in manifest.files.items():
            full_path = install_path / file_path
            if full_path.exists():
                current_hash = get_file_hash(full_path)
                if current_hash != file_hash:
                    changed_files.append(file_path)
            else:
                removed_files.append(file_path)

    return UpdateInfo(
        installed_version=installed,
        available_version=available,
        update_available=update_available,
        is_newer=is_newer,
        is_downgrade=is_downgrade,
        changed_files=changed_files,
        new_files=new_files,
        removed_files=removed_files
    )


def save_install_manifest(
    install_path: Path,
    source_path: Path,
    platform: str,
    version: str,
    plugins: List[str],
    installed_files: Dict[str, str]
) -> InstallManifest:
    """
    Save an installation manifest.

    Args:
        install_path: Platform installation path
        source_path: Ring source path
        platform: Platform identifier
        version: Installed version
        plugins: List of installed plugins
        installed_files: Dict of file paths to hashes

    Returns:
        The created manifest
    """
    manifest = InstallManifest.create(
        version=version,
        source_path=str(source_path),
        platform=platform,
        plugins=plugins,
        files=installed_files
    )

    manifest_path = get_manifest_path(install_path)
    manifest.save(manifest_path)

    return manifest
