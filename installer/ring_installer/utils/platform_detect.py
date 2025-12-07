"""
Platform detection utilities for Ring installer.

Provides functions to detect which AI platforms are installed on the system
and retrieve their version information.
"""

import json
import logging
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Any

from ring_installer.adapters import SUPPORTED_PLATFORMS

logger = logging.getLogger(__name__)


@dataclass
class PlatformInfo:
    """Information about an installed platform."""
    platform_id: str
    name: str
    installed: bool
    partial: bool = False
    version: Optional[str] = None
    install_path: Optional[Path] = None
    config_path: Optional[Path] = None
    binary_path: Optional[Path] = None
    details: Dict[str, Any] = field(default_factory=dict)


def detect_installed_platforms() -> List[PlatformInfo]:
    """
    Detect all supported platforms that are installed on the system.

    Returns:
        List of PlatformInfo objects for each detected platform
    """
    platforms = []

    for platform_id in SUPPORTED_PLATFORMS:
        info = _detect_platform(platform_id)
        if info.installed:
            platforms.append(info)

    return platforms


def is_platform_installed(platform_id: str) -> bool:
    """
    Check if a specific platform is installed.

    Args:
        platform_id: Platform identifier (claude, factory, cursor, cline)

    Returns:
        True if the platform is installed
    """
    info = _detect_platform(platform_id)
    return info.installed


def get_platform_version(platform_id: str) -> Optional[str]:
    """
    Get the version of an installed platform.

    Args:
        platform_id: Platform identifier

    Returns:
        Version string, or None if not installed or version unavailable
    """
    info = _detect_platform(platform_id)
    return info.version if info.installed else None


def get_platform_info(platform_id: str) -> PlatformInfo:
    """
    Get detailed information about a platform.

    Args:
        platform_id: Platform identifier

    Returns:
        PlatformInfo object with detection results
    """
    return _detect_platform(platform_id)


def _validate_env_path(env_var: str, candidate: str, default: Path) -> Path:
    """Validate an environment-provided path, falling back to default if unsafe."""
    path = Path(candidate).expanduser().resolve()
    home = Path.home().resolve()

    try:
        path.relative_to(home)
        return path
    except ValueError:
        logger.warning(
            "Ignoring %s=%s: path must be under home directory",
            env_var,
            candidate,
        )
        return Path(default).expanduser().resolve()


def _detect_platform(platform_id: str) -> PlatformInfo:
    """
    Detect a specific platform.

    Args:
        platform_id: Platform identifier

    Returns:
        PlatformInfo with detection results
    """
    detectors = {
        "claude": _detect_claude,
        "factory": _detect_factory,
        "cursor": _detect_cursor,
        "cline": _detect_cline,
    }

    detector = detectors.get(platform_id.lower())
    if detector:
        return detector()

    return PlatformInfo(
        platform_id=platform_id,
        name=platform_id.title(),
        installed=False
    )


# Allowed binary path prefixes for security validation
_ALLOWED_BINARY_PREFIXES = [
    Path("/usr"),
    Path("/opt"),
    Path("/bin"),
    Path("/sbin"),
]


def _is_binary_path_allowed(binary_path: Path) -> bool:
    """
    Validate that a binary path is from an expected location.

    Security: Prevents executing binaries from untrusted locations.

    Args:
        binary_path: Path to the binary to validate

    Returns:
        True if the binary is in an allowed location
    """
    resolved = binary_path.resolve()

    # Check system paths
    for prefix in _ALLOWED_BINARY_PREFIXES:
        if prefix.exists():
            try:
                resolved.relative_to(prefix)
                return True
            except ValueError:
                continue

    # Check user-local paths (common for npm/pip installs)
    home = Path.home()
    allowed_user_paths = [
        home / ".local" / "bin",
        home / ".local" / "share",
        home / "bin",
        home / ".cargo" / "bin",
        home / ".npm-global" / "bin",
    ]

    for user_path in allowed_user_paths:
        if user_path.exists():
            try:
                resolved.relative_to(user_path)
                return True
            except ValueError:
                continue

    # macOS specific paths
    if sys.platform == "darwin":
        macos_paths = [
            Path("/Applications"),
            home / "Applications",
            Path("/Library"),
            home / "Library",
        ]
        for macos_path in macos_paths:
            if macos_path.exists():
                try:
                    resolved.relative_to(macos_path)
                    return True
                except ValueError:
                    continue

    # Windows specific paths
    if sys.platform == "win32":
        local_app_data = os.environ.get("LOCALAPPDATA", "")
        program_files = os.environ.get("PROGRAMFILES", "")
        program_files_x86 = os.environ.get("PROGRAMFILES(X86)", "")

        win_paths = [p for p in [local_app_data, program_files, program_files_x86] if p]
        for win_path in win_paths:
            try:
                resolved.relative_to(Path(win_path))
                return True
            except ValueError:
                continue

    return False


def _detect_generic_cli_platform(
    platform_id: str,
    name: str,
    config_dir_name: str,
    binary_name: Optional[str] = None,
) -> PlatformInfo:
    """
    Generic platform detection for CLI-based platforms.

    Shared logic for platforms that have a config directory and optional CLI binary.

    Args:
        platform_id: Platform identifier (e.g., "claude", "factory")
        name: Human-readable platform name (e.g., "Claude Code")
        config_dir_name: Name of the config directory (e.g., ".claude")
        binary_name: Optional binary name to search in PATH

    Returns:
        PlatformInfo with detection results
    """
    # Allow environment variable override for config path (validated)
    env_var = f"{platform_id.upper()}_CONFIG_PATH"
    env_path = os.environ.get(env_var)

    if env_path:
        config_path = _validate_env_path(env_var, env_path, Path.home() / config_dir_name)
    else:
        config_path = Path.home() / config_dir_name

    info = PlatformInfo(
        platform_id=platform_id,
        name=name,
        installed=False
    )

    # Check config directory
    if config_path.exists():
        info.config_path = config_path
        info.install_path = config_path

    # Check for binary if specified
    if binary_name:
        binary = shutil.which(binary_name)
        if binary:
            binary_path = Path(binary)

            # Security: Validate binary is from allowed location
            if _is_binary_path_allowed(binary_path):
                info.binary_path = binary_path
                info.installed = True

                # Get version using resolved binary path
                try:
                    result = subprocess.run(
                        [binary, "--version"],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if result.returncode == 0:
                        version_match = re.search(r"(\d+\.\d+\.\d+)", result.stdout)
                        if version_match:
                            info.version = version_match.group(1)
                except subprocess.TimeoutExpired:
                    logger.warning("Binary %s timed out during version check", binary)
                except (subprocess.SubprocessError, FileNotFoundError) as e:
                    logger.debug("Binary %s version check failed: %s", binary, e)
            else:
                logger.warning(
                    "Binary %s found at %s but path is not in allowed locations",
                    binary_name, binary_path
                )

    # Config directory without binary indicates partial install
    if not info.installed and config_path.exists():
        info.partial = True
        info.details["note"] = "Config directory exists but binary not found"

    return info


def _detect_claude() -> PlatformInfo:
    """
    Detect Claude Code installation.

    Checks for:
    - ~/.claude directory (or CLAUDE_CONFIG_PATH env var)
    - claude binary in PATH
    """
    return _detect_generic_cli_platform(
        platform_id="claude",
        name="Claude Code",
        config_dir_name=".claude",
        binary_name="claude",
    )


def _detect_factory() -> PlatformInfo:
    """
    Detect Factory AI installation.

    Checks for:
    - ~/.factory directory (or FACTORY_CONFIG_PATH env var)
    - factory binary in PATH
    """
    return _detect_generic_cli_platform(
        platform_id="factory",
        name="Factory AI",
        config_dir_name=".factory",
        binary_name="factory",
    )


def _detect_cursor() -> PlatformInfo:
    """
    Detect Cursor installation.

    Checks for:
    - ~/.cursor directory (or CURSOR_CONFIG_PATH env var)
    - Cursor application in standard locations
    """
    # Allow environment variable override for config path
    env_path = os.environ.get("CURSOR_CONFIG_PATH")
    if env_path:
        config_path = _validate_env_path("CURSOR_CONFIG_PATH", env_path, Path.home() / ".cursor")
    else:
        config_path = Path.home() / ".cursor"

    info = PlatformInfo(
        platform_id="cursor",
        name="Cursor",
        installed=False
    )

    # Check config directory
    if config_path.exists():
        info.config_path = config_path
        info.install_path = config_path

    # Check for application (environment variable override)
    app_paths = _get_cursor_app_paths()
    for app_path in app_paths:
        if app_path.exists():
            info.binary_path = app_path
            info.installed = True

            # Try to get version from package.json or similar
            version = _get_cursor_version(app_path)
            if version:
                info.version = version
            break

    if not info.installed and config_path.exists():
        info.partial = True
        info.details["note"] = "Config directory exists but application not found"

    return info


def _detect_cline() -> PlatformInfo:
    """
    Detect Cline installation.

    Checks for:
    - ~/.cline directory (or CLINE_CONFIG_PATH env var)
    - Cline VS Code extension
    """
    # Allow environment variable override for config path
    env_path = os.environ.get("CLINE_CONFIG_PATH")
    if env_path:
        config_path = _validate_env_path("CLINE_CONFIG_PATH", env_path, Path.home() / ".cline")
    else:
        config_path = Path.home() / ".cline"

    info = PlatformInfo(
        platform_id="cline",
        name="Cline",
        installed=False
    )

    # Check config directory
    if config_path.exists():
        info.config_path = config_path
        info.install_path = config_path
        info.installed = True

    # Check for VS Code extension
    extension_info = _find_vscode_extension("saoudrizwan.claude-dev")
    if extension_info:
        info.installed = True
        info.version = extension_info.get("version")
        info.details["extension_path"] = extension_info.get("path")
        info.details["extension_id"] = "saoudrizwan.claude-dev"

    return info


def _get_cursor_app_paths() -> List[Path]:
    """Get potential Cursor application paths based on platform.

    Supports CURSOR_APP_PATH environment variable override.
    """
    paths: List[Path] = []

    # Allow environment variable override
    env_path = os.environ.get("CURSOR_APP_PATH")
    if env_path:
        paths.append(Path(env_path).expanduser())

    if sys.platform == "darwin":
        paths.extend([
            Path("/Applications/Cursor.app"),
            Path.home() / "Applications/Cursor.app",
        ])
    elif sys.platform == "win32":
        local_app_data = os.environ.get("LOCALAPPDATA", "")
        if local_app_data:
            paths.append(Path(local_app_data) / "Programs/cursor/Cursor.exe")
        paths.append(Path("C:/Program Files/Cursor/Cursor.exe"))
    else:  # Linux
        paths.extend([
            Path("/usr/bin/cursor"),
            Path("/usr/local/bin/cursor"),
            Path.home() / ".local/bin/cursor",
            Path("/opt/Cursor/cursor"),
        ])

    return paths


def _get_cursor_version(app_path: Path) -> Optional[str]:
    """Try to extract Cursor version from application."""
    if sys.platform == "darwin":
        # Try Info.plist
        plist_path = app_path / "Contents/Info.plist"
        if plist_path.exists():
            try:
                import plistlib
                with open(plist_path, "rb") as f:
                    plist = plistlib.load(f)
                    return plist.get("CFBundleShortVersionString")
            except Exception:
                pass

        # Try package.json in resources
        package_json = app_path / "Contents/Resources/app/package.json"
        if package_json.exists():
            try:
                with open(package_json) as f:
                    data = json.load(f)
                    return data.get("version")
            except Exception:
                pass

    elif sys.platform == "win32":
        # Try version from executable (would need win32api)
        # Fall back to checking package.json if available
        pass

    return None


def _find_vscode_extension(extension_id: str) -> Optional[Dict[str, Any]]:
    """
    Find a VS Code extension and get its information.

    Args:
        extension_id: Extension identifier (publisher.name)

    Returns:
        Dictionary with extension info, or None if not found
    """
    extension_paths = _get_vscode_extension_paths()

    for ext_dir in extension_paths:
        if not ext_dir.exists():
            continue

        # Look for extension directory
        for entry in ext_dir.iterdir():
            if entry.is_dir() and entry.name.startswith(extension_id):
                # Found the extension
                package_json = entry / "package.json"
                if package_json.exists():
                    try:
                        with open(package_json) as f:
                            data = json.load(f)
                            return {
                                "path": str(entry),
                                "version": data.get("version"),
                                "name": data.get("displayName", data.get("name")),
                            }
                    except Exception:
                        return {"path": str(entry)}
                return {"path": str(entry)}

    return None


def _get_vscode_extension_paths() -> List[Path]:
    """Get VS Code extension directories based on platform."""
    paths = []

    if sys.platform == "darwin":
        paths.extend([
            Path.home() / ".vscode/extensions",
            Path.home() / ".vscode-insiders/extensions",
        ])
    elif sys.platform == "win32":
        user_profile = os.environ.get("USERPROFILE", "")
        if user_profile:
            paths.extend([
                Path(user_profile) / ".vscode/extensions",
                Path(user_profile) / ".vscode-insiders/extensions",
            ])
    else:  # Linux
        paths.extend([
            Path.home() / ".vscode/extensions",
            Path.home() / ".vscode-insiders/extensions",
            Path.home() / ".vscode-server/extensions",
        ])

    return paths


def get_system_info() -> Dict[str, Any]:
    """
    Get system information relevant to installation.

    Returns:
        Dictionary with system details
    """
    return {
        "platform": sys.platform,
        "python_version": sys.version,
        "home_directory": str(Path.home()),
        "current_directory": str(Path.cwd()),
        "path": os.environ.get("PATH", "").split(os.pathsep),
    }


def print_detection_report() -> None:
    """Print a human-readable report of detected platforms."""
    platforms = detect_installed_platforms()

    print("Ring Installer - Platform Detection Report")
    print("=" * 50)

    if not platforms:
        print("\nNo supported platforms detected.")
        print("\nSupported platforms:")
        for platform_id in SUPPORTED_PLATFORMS:
            print(f"  - {platform_id}")
        return

    print(f"\nDetected {len(platforms)} platform(s):\n")

    for info in platforms:
        print(f"  {info.name} ({info.platform_id})")
        if info.version:
            print(f"    Version: {info.version}")
        if info.install_path:
            print(f"    Install path: {info.install_path}")
        if info.binary_path:
            print(f"    Binary: {info.binary_path}")
        if info.details:
            for key, value in info.details.items():
                print(f"    {key}: {value}")
        print()
