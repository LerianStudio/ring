"""
Ring Installer CLI - Multi-platform AI agent skill installer.

Usage:
    python -m ring_installer install [--platforms PLATFORMS] [--dry-run] [--force] [--verbose]
    python -m ring_installer update [--platforms PLATFORMS] [--dry-run] [--verbose]
    python -m ring_installer uninstall [--platforms PLATFORMS] [--dry-run] [--force]
    python -m ring_installer list [--platform PLATFORM]
    python -m ring_installer detect

Examples:
    # Install to all detected platforms
    python -m ring_installer install

    # Install to specific platforms
    python -m ring_installer install --platforms claude,cursor

    # Dry run to see what would be done
    python -m ring_installer install --dry-run --verbose

    # Update existing installation
    python -m ring_installer update

    # List installed components
    python -m ring_installer list --platform claude

    # Detect installed platforms
    python -m ring_installer detect
"""

import argparse
import sys
from pathlib import Path
from typing import List, Optional

from ring_installer import __version__
from ring_installer.adapters import SUPPORTED_PLATFORMS, list_platforms
from ring_installer.core import (
    InstallTarget,
    InstallOptions,
    InstallResult,
    InstallStatus,
    UpdateCheckResult,
    SyncResult,
    install,
    update,
    uninstall,
    list_installed,
    check_updates,
    update_with_diff,
    sync_platforms,
    uninstall_with_manifest,
)
from ring_installer.utils.platform_detect import (
    detect_installed_platforms,
    print_detection_report,
    get_platform_info,
)


def print_version() -> None:
    """Print version information."""
    print(f"Ring Installer v{__version__}")


def print_result(result: InstallResult, verbose: bool = False) -> None:
    """Print installation result summary."""
    status_symbols = {
        InstallStatus.SUCCESS: "[OK]",
        InstallStatus.PARTIAL: "[PARTIAL]",
        InstallStatus.FAILED: "[FAILED]",
        InstallStatus.SKIPPED: "[SKIPPED]",
    }

    print(f"\n{status_symbols.get(result.status, '[?]')} Installation {result.status.value}")
    print(f"  Targets: {', '.join(result.targets)}")
    print(f"  Installed: {result.components_installed}")
    print(f"  Skipped: {result.components_skipped}")
    print(f"  Failed: {result.components_failed}")

    if result.errors:
        print("\nErrors:")
        for error in result.errors:
            print(f"  - {error}")

    if verbose and result.warnings:
        print("\nWarnings:")
        for warning in result.warnings:
            print(f"  - {warning}")

    if verbose and result.details:
        print("\nDetails:")
        for detail in result.details:
            status_sym = {
                InstallStatus.SUCCESS: "+",
                InstallStatus.FAILED: "x",
                InstallStatus.SKIPPED: "-",
            }.get(detail.status, "?")
            print(f"  [{status_sym}] {detail.source_path.name} -> {detail.target_path}")


def progress_callback(message: str, current: int, total: int) -> None:
    """Display progress information.

    Args:
        message: Current operation message
        current: Current progress count
        total: Total work items (must be > 0 for percentage display)
    """
    if total > 0:
        # Ensure current doesn't exceed total for percentage calculation
        safe_current = min(max(current, 0), total)
        percent = (safe_current / total) * 100
    else:
        percent = 0
    print(f"\r[{percent:5.1f}%] {message[:60]:<60}", end="", flush=True)


def find_ring_source() -> Optional[Path]:
    """
    Find the Ring source directory.

    Looks in these locations:
    1. Current directory (if it's a Ring repo)
    2. Parent directory (if running from installer/)
    3. ~/ring
    4. ~/.ring
    """
    candidates = [
        Path.cwd(),
        Path.cwd().parent,
        Path.home() / "ring",
        Path.home() / ".ring",
    ]

    for candidate in candidates:
        # Check for Ring markers
        if (candidate / ".claude-plugin").exists():
            return candidate
        if (candidate / "default" / "skills").exists():
            return candidate

    return None


def parse_platforms(platforms_str: Optional[str]) -> List[str]:
    """Parse comma-separated platform string."""
    if not platforms_str:
        return []
    return [p.strip().lower() for p in platforms_str.split(",") if p.strip()]


def validate_platforms(platforms: List[str]) -> List[str]:
    """Validate platform identifiers and return valid ones."""
    valid = []
    invalid = []

    for platform in platforms:
        if platform in SUPPORTED_PLATFORMS:
            valid.append(platform)
        else:
            invalid.append(platform)

    if invalid:
        print(f"Warning: Ignoring unsupported platforms: {', '.join(invalid)}")
        print(f"Supported platforms: {', '.join(SUPPORTED_PLATFORMS)}")

    return valid


def cmd_install(args: argparse.Namespace) -> int:
    """Handle install command."""
    # Find Ring source
    source_path = Path(args.source).expanduser() if args.source else find_ring_source()

    if not source_path or not source_path.exists():
        print("Error: Could not find Ring source directory.")
        print("Please specify with --source or run from Ring directory.")
        return 1

    print(f"Ring source: {source_path}")

    # Determine target platforms
    if args.platforms:
        platforms = validate_platforms(parse_platforms(args.platforms))
        if not platforms:
            return 1
    else:
        # Auto-detect installed platforms
        detected = detect_installed_platforms()
        if detected:
            platforms = [p.platform_id for p in detected]
            print(f"Auto-detected platforms: {', '.join(platforms)}")
        else:
            # Default to claude if nothing detected
            platforms = ["claude"]
            print("No platforms detected, defaulting to: claude")

    # Build targets
    targets = [InstallTarget(platform=p) for p in platforms]

    # Build options
    options = InstallOptions(
        dry_run=args.dry_run,
        force=args.force,
        backup=not args.no_backup,
        verbose=args.verbose,
        plugin_names=parse_platforms(args.plugins) if args.plugins else None,
        exclude_plugins=parse_platforms(args.exclude) if args.exclude else None,
    )

    if args.dry_run:
        print("\n[DRY RUN] No changes will be made.\n")

    # Run installation
    callback = progress_callback if not args.quiet and not args.verbose else None
    result = install(source_path, targets, options, callback)

    if callback:
        print()  # New line after progress

    print_result(result, args.verbose)

    return 0 if result.status in [InstallStatus.SUCCESS, InstallStatus.SKIPPED] else 1


def cmd_update(args: argparse.Namespace) -> int:
    """Handle update command."""
    # Find Ring source
    source_path = Path(args.source).expanduser() if args.source else find_ring_source()

    if not source_path or not source_path.exists():
        print("Error: Could not find Ring source directory.")
        return 1

    print(f"Ring source: {source_path}")

    # Determine target platforms
    if args.platforms:
        platforms = validate_platforms(parse_platforms(args.platforms))
        if not platforms:
            return 1
    else:
        detected = detect_installed_platforms()
        if detected:
            platforms = [p.platform_id for p in detected]
        else:
            platforms = ["claude"]

    print(f"Updating platforms: {', '.join(platforms)}")

    # Build targets
    targets = [InstallTarget(platform=p) for p in platforms]

    # Build options
    options = InstallOptions(
        dry_run=args.dry_run,
        force=True,
        backup=not args.no_backup,
        verbose=args.verbose,
        plugin_names=parse_platforms(args.plugins) if args.plugins else None,
        exclude_plugins=parse_platforms(args.exclude) if args.exclude else None,
    )

    if args.dry_run:
        print("\n[DRY RUN] No changes will be made.\n")

    callback = progress_callback if not args.quiet and not args.verbose else None

    # Use smart update if --smart flag is set
    if getattr(args, 'smart', False):
        result = update_with_diff(source_path, targets, options, callback)
    else:
        result = update(source_path, targets, options, callback)

    if callback:
        print()

    print_result(result, args.verbose)

    return 0 if result.status in [InstallStatus.SUCCESS, InstallStatus.SKIPPED] else 1


def cmd_check(args: argparse.Namespace) -> int:
    """Handle check command - check for available updates."""
    # Find Ring source
    source_path = Path(args.source).expanduser() if args.source else find_ring_source()

    if not source_path or not source_path.exists():
        print("Error: Could not find Ring source directory.")
        return 1

    print(f"Ring source: {source_path}")

    # Determine target platforms
    if args.platforms:
        platforms = validate_platforms(parse_platforms(args.platforms))
        if not platforms:
            return 1
    else:
        detected = detect_installed_platforms()
        if detected:
            platforms = [p.platform_id for p in detected]
        else:
            platforms = ["claude"]

    # Build targets
    targets = [InstallTarget(platform=p) for p in platforms]

    print(f"\nChecking updates for: {', '.join(platforms)}\n")

    # Check for updates
    results = check_updates(source_path, targets)

    # Display results
    any_updates = False
    for platform, result in results.items():
        print(f"{platform.title()}:")
        print(f"  Installed: {result.installed_version or 'Not installed'}")
        print(f"  Available: {result.available_version or 'Unknown'}")

        if result.update_available:
            any_updates = True
            print("  Status: UPDATE AVAILABLE")
        elif result.installed_version and result.available_version:
            print("  Status: Up to date")
        else:
            print("  Status: Unknown")

        if result.has_changes:
            print(f"  Changed files: {len(result.changed_files)}")
            print(f"  New files: {len(result.new_files)}")
            print(f"  Removed files: {len(result.removed_files)}")

        print()

    if any_updates:
        print("Run 'ring-installer update' to apply updates.")
        return 0
    else:
        print("All platforms are up to date.")
        return 0


def cmd_sync(args: argparse.Namespace) -> int:
    """Handle sync command - sync components across platforms."""
    # Find Ring source
    source_path = Path(args.source).expanduser() if args.source else find_ring_source()

    if not source_path or not source_path.exists():
        print("Error: Could not find Ring source directory.")
        return 1

    print(f"Ring source: {source_path}")

    # Determine target platforms
    if args.platforms:
        platforms = validate_platforms(parse_platforms(args.platforms))
        if not platforms:
            return 1
    else:
        detected = detect_installed_platforms()
        if detected:
            platforms = [p.platform_id for p in detected]
        else:
            print("No platforms detected. Specify with --platforms.")
            return 1

    if len(platforms) < 2:
        print("Sync requires at least 2 platforms.")
        print("Specify platforms with --platforms (e.g., --platforms claude,cursor)")
        return 1

    print(f"Syncing platforms: {', '.join(platforms)}")

    # Build targets
    targets = [InstallTarget(platform=p) for p in platforms]

    # Build options
    options = InstallOptions(
        dry_run=args.dry_run,
        force=True,
        backup=not args.no_backup,
        verbose=args.verbose,
        plugin_names=parse_platforms(args.plugins) if args.plugins else None,
        exclude_plugins=parse_platforms(args.exclude) if args.exclude else None,
    )

    if args.dry_run:
        print("\n[DRY RUN] No changes will be made.\n")

    callback = progress_callback if not args.quiet and not args.verbose else None

    # Sync platforms
    sync_result = sync_platforms(source_path, targets, options, callback)

    if callback:
        print()

    # Display results
    print("\nSync Results:")
    print("-" * 40)

    if sync_result.drift_detected:
        print("\nDrift detected between platforms:")
        for platform, details in sync_result.drift_details.items():
            print(f"  {platform}:")
            for detail in details:
                print(f"    - {detail}")

    print(f"\nPlatforms synced: {', '.join(sync_result.platforms_synced) or 'None'}")
    if sync_result.platforms_skipped:
        print(f"Platforms skipped: {', '.join(sync_result.platforms_skipped)}")

    # Show per-platform results
    if args.verbose:
        for platform, result in sync_result.install_results.items():
            print(f"\n{platform}:")
            print_result(result, verbose=True)

    success = len(sync_result.platforms_skipped) == 0
    return 0 if success else 1


def cmd_uninstall(args: argparse.Namespace) -> int:
    """Handle uninstall command."""
    # Determine target platforms
    if args.platforms:
        platforms = validate_platforms(parse_platforms(args.platforms))
        if not platforms:
            return 1
    else:
        detected = detect_installed_platforms()
        if detected:
            platforms = [p.platform_id for p in detected]
        else:
            print("No platforms detected. Specify with --platforms.")
            return 1

    print(f"Uninstalling from: {', '.join(platforms)}")

    if not args.force:
        confirm = input("Are you sure? This will remove all Ring components. [y/N] ")
        if confirm.lower() != "y":
            print("Aborted.")
            return 0

    targets = [InstallTarget(platform=p) for p in platforms]

    options = InstallOptions(
        dry_run=args.dry_run,
        force=args.force,
        backup=not args.no_backup,
        verbose=args.verbose,
    )

    if args.dry_run:
        print("\n[DRY RUN] No changes will be made.\n")

    callback = progress_callback if not args.quiet and not args.verbose else None

    # Use manifest-based uninstall if --precise flag is set
    if getattr(args, 'precise', False):
        result = uninstall_with_manifest(targets, options, callback)
    else:
        result = uninstall(targets, options, callback)

    if callback:
        print()

    print_result(result, args.verbose)

    return 0 if result.status in [InstallStatus.SUCCESS, InstallStatus.SKIPPED] else 1


def cmd_list(args: argparse.Namespace) -> int:
    """Handle list command."""
    if args.platform:
        platforms = [args.platform]
    else:
        detected = detect_installed_platforms()
        if detected:
            platforms = [p.platform_id for p in detected]
        else:
            print("No platforms detected. Specify with --platform.")
            return 1

    for platform in platforms:
        print(f"\n{platform.title()} - Installed Components:")
        print("-" * 40)

        try:
            installed = list_installed(platform)
            total = 0

            for component_type, components in installed.items():
                if components:
                    print(f"\n  {component_type.title()}:")
                    for component in components:
                        print(f"    - {component}")
                    total += len(components)

            if total == 0:
                print("  (no components installed)")
            else:
                print(f"\n  Total: {total} components")

        except Exception as e:
            print(f"  Error: {e}")

    return 0


def cmd_detect(args: argparse.Namespace) -> int:
    """Handle detect command."""
    if args.json:
        import json
        platforms = detect_installed_platforms()
        data = []
        for p in platforms:
            data.append({
                "platform_id": p.platform_id,
                "name": p.name,
                "version": p.version,
                "install_path": str(p.install_path) if p.install_path else None,
                "binary_path": str(p.binary_path) if p.binary_path else None,
                "details": p.details,
            })
        print(json.dumps(data, indent=2))
    else:
        print_detection_report()

    return 0


def cmd_platforms(args: argparse.Namespace) -> int:
    """Handle platforms command - list all supported platforms."""
    print("Supported Platforms:")
    print("-" * 50)

    for platform_info in list_platforms():
        native = "(native)" if platform_info["native_format"] else ""
        print(f"\n  {platform_info['name']} ({platform_info['id']}) {native}")
        print(f"    Components: {', '.join(platform_info['components'])}")

        terminology = platform_info["terminology"]
        if any(k != v for k, v in terminology.items()):
            print("    Terminology:")
            for ring_term, platform_term in terminology.items():
                if ring_term != platform_term:
                    print(f"      {ring_term} -> {platform_term}")

    return 0


def main() -> int:
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(
        prog="ring-installer",
        description="Ring multi-platform AI agent skill installer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s install                    Install to all detected platforms
  %(prog)s install --platforms claude Install to Claude Code only
  %(prog)s install --dry-run          Show what would be installed
  %(prog)s update                     Update existing installation
  %(prog)s list --platform claude     List installed components
  %(prog)s detect                     Detect installed platforms
        """
    )

    parser.add_argument(
        "--version", "-V",
        action="version",
        version=f"%(prog)s {__version__}"
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Install command
    install_parser = subparsers.add_parser("install", help="Install Ring components")
    install_parser.add_argument(
        "--source", "-s",
        help="Path to Ring source directory"
    )
    install_parser.add_argument(
        "--platforms", "-p",
        help="Comma-separated list of target platforms"
    )
    install_parser.add_argument(
        "--plugins",
        help="Comma-separated list of plugins to install"
    )
    install_parser.add_argument(
        "--exclude",
        help="Comma-separated list of plugins to exclude"
    )
    install_parser.add_argument(
        "--dry-run", "-n",
        action="store_true",
        help="Show what would be done without making changes"
    )
    install_parser.add_argument(
        "--force", "-f",
        action="store_true",
        help="Overwrite existing files"
    )
    install_parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Don't create backups before overwriting"
    )
    install_parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show detailed output"
    )
    install_parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Suppress progress output"
    )

    # Update command
    update_parser = subparsers.add_parser("update", help="Update Ring components")
    update_parser.add_argument("--source", "-s", help="Path to Ring source directory")
    update_parser.add_argument("--platforms", "-p", help="Comma-separated list of target platforms")
    update_parser.add_argument("--plugins", help="Comma-separated list of plugins to update")
    update_parser.add_argument("--exclude", help="Comma-separated list of plugins to exclude")
    update_parser.add_argument("--dry-run", "-n", action="store_true", help="Show what would be done")
    update_parser.add_argument("--no-backup", action="store_true", help="Don't create backups")
    update_parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output")
    update_parser.add_argument("--quiet", "-q", action="store_true", help="Suppress progress output")
    update_parser.add_argument("--smart", action="store_true", help="Only update changed files")

    # Check command
    check_parser = subparsers.add_parser("check", help="Check for available updates")
    check_parser.add_argument("--source", "-s", help="Path to Ring source directory")
    check_parser.add_argument("--platforms", "-p", help="Comma-separated list of target platforms")

    # Sync command
    sync_parser = subparsers.add_parser("sync", help="Sync Ring components across platforms")
    sync_parser.add_argument("--source", "-s", help="Path to Ring source directory")
    sync_parser.add_argument("--platforms", "-p", help="Comma-separated list of platforms to sync")
    sync_parser.add_argument("--plugins", help="Comma-separated list of plugins to sync")
    sync_parser.add_argument("--exclude", help="Comma-separated list of plugins to exclude")
    sync_parser.add_argument("--dry-run", "-n", action="store_true", help="Show what would be done")
    sync_parser.add_argument("--no-backup", action="store_true", help="Don't create backups")
    sync_parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output")
    sync_parser.add_argument("--quiet", "-q", action="store_true", help="Suppress progress output")

    # Uninstall command
    uninstall_parser = subparsers.add_parser("uninstall", help="Remove Ring components")
    uninstall_parser.add_argument("--platforms", "-p", help="Comma-separated list of target platforms")
    uninstall_parser.add_argument("--dry-run", "-n", action="store_true", help="Show what would be done")
    uninstall_parser.add_argument("--force", "-f", action="store_true", help="Don't prompt for confirmation")
    uninstall_parser.add_argument("--no-backup", action="store_true", help="Don't create backups")
    uninstall_parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output")
    uninstall_parser.add_argument("--quiet", "-q", action="store_true", help="Suppress progress output")
    uninstall_parser.add_argument("--precise", action="store_true", help="Use manifest for precise removal")

    # List command
    list_parser = subparsers.add_parser("list", help="List installed components")
    list_parser.add_argument("--platform", help="Platform to list components for")

    # Detect command
    detect_parser = subparsers.add_parser("detect", help="Detect installed platforms")
    detect_parser.add_argument("--json", action="store_true", help="Output as JSON")

    # Platforms command
    platforms_parser = subparsers.add_parser("platforms", help="List supported platforms")

    # Parse arguments
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 0

    # Dispatch to command handler
    commands = {
        "install": cmd_install,
        "update": cmd_update,
        "check": cmd_check,
        "sync": cmd_sync,
        "uninstall": cmd_uninstall,
        "list": cmd_list,
        "detect": cmd_detect,
        "platforms": cmd_platforms,
    }

    handler = commands.get(args.command)
    if handler:
        try:
            return handler(args)
        except KeyboardInterrupt:
            print("\nAborted.")
            return 130
        except Exception as e:
            print(f"Error: {e}")
            if hasattr(args, "verbose") and args.verbose:
                import traceback
                traceback.print_exc()
            return 1
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
