#!/usr/bin/env python3
"""
Generic reference generator for Ring plugins.
Scans directories for .md files and extracts YAML frontmatter.

Usage:
  generate-reference.py agents <agents-dir>    # Generate agent reference
  generate-reference.py skills <skills-dir>    # Generate skills reference
  generate-reference.py commands <commands-dir> # Generate commands reference

Security:
  - Directory validation: Only allows paths within the monorepo root to prevent
    path traversal attacks (e.g., '../../../etc/passwd').
  - Symlink exclusion: All symlinks (files and directories) are skipped during
    scanning to prevent following malicious links that could point outside the
    repository or to sensitive files. Warnings are emitted for skipped symlinks.
  - Error messages use relative paths to avoid exposing full filesystem paths.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any

try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    print("Warning: pyyaml not installed, using fallback parser", file=sys.stderr)


class Item:
    """Represents an agent, skill, or command with metadata."""

    def __init__(self, name: str, description: str, item_type: str,
                 file_path: str, **kwargs):
        self.name = name
        self.description = description
        self.item_type = item_type  # 'agent', 'skill', 'command'
        self.file_path = file_path
        self.metadata = kwargs  # Store additional fields like type, model, etc.

    def __repr__(self):
        return f"Item(name={self.name}, type={self.item_type})"


# Module-level variable for monorepo root (set in main)
_monorepo_root: Optional[Path] = None


def relative_path(file_path: Path) -> str:
    """Get path relative to monorepo root for cleaner error messages.

    Args:
        file_path: The absolute file path

    Returns:
        Relative path string if within monorepo, otherwise just the filename
    """
    if _monorepo_root is not None:
        try:
            return str(file_path.relative_to(_monorepo_root))
        except ValueError:
            pass
    return file_path.name


def validate_directory(directory: Path, monorepo_root: Path) -> Path:
    """Validate directory is within monorepo root to prevent path traversal.

    Security: Prevents attackers from using paths like '../../../etc/passwd'
    or absolute paths outside the repository boundary.

    Args:
        directory: The directory path to validate
        monorepo_root: The root of the monorepo (security boundary)

    Returns:
        Resolved absolute path if valid

    Raises:
        SystemExit: If path is outside monorepo root
    """
    try:
        resolved = directory.resolve()
        root_resolved = monorepo_root.resolve()
        # Ensure path is within monorepo (raises ValueError if not)
        resolved.relative_to(root_resolved)
        return resolved
    except ValueError:
        print(f"Error: Directory {directory} is outside monorepo root", file=sys.stderr)
        sys.exit(1)


def parse_frontmatter_yaml(content: str) -> Optional[Dict[str, Any]]:
    """Parse YAML frontmatter using pyyaml library."""
    if not YAML_AVAILABLE:
        return None

    # Extract frontmatter between --- delimiters
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match:
        return None

    try:
        frontmatter = yaml.safe_load(match.group(1))
        return frontmatter if isinstance(frontmatter, dict) else None
    except yaml.YAMLError as e:
        print(f"Warning: YAML parse error: {e}", file=sys.stderr)
        return None


def parse_frontmatter_fallback(content: str) -> Optional[Dict[str, Any]]:
    """Fallback parser using regex when pyyaml unavailable."""
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match:
        return None

    frontmatter_text = match.group(1)
    result = {}

    # Parse simple key: value pairs
    for line in frontmatter_text.split('\n'):
        line = line.strip()
        if ':' in line and not line.startswith('#'):
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"\'')

            # Handle multi-line values (|)
            if value == '|':
                continue

            result[key] = value

    return result if result else None


def parse_item_file(file_path: Path, item_type: str) -> Optional[Item]:
    """Parse a .md file and extract metadata."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Try YAML parser first, fallback to regex
        frontmatter = parse_frontmatter_yaml(content) or parse_frontmatter_fallback(content)

        if not frontmatter or 'name' not in frontmatter:
            print(f"Warning: No valid frontmatter in {relative_path(file_path)}", file=sys.stderr)
            return None

        name = frontmatter.get('name', file_path.stem)
        description = frontmatter.get('description', '').strip()

        # Extract first sentence for brevity (split on '. ')
        if '. ' in description:
            description = description.split('. ')[0] + '.'
        # Also handle newlines
        elif '\n' in description:
            description = description.split('\n')[0].strip()

        return Item(
            name=name,
            description=description,
            item_type=item_type,
            file_path=str(file_path),
            **{k: v for k, v in frontmatter.items() if k not in ['name', 'description']}
        )

    except Exception as e:
        print(f"Error parsing {relative_path(file_path)}: {e}", file=sys.stderr)
        return None


def scan_directory(directory: Path, pattern: str, item_type: str) -> List[Item]:
    """Scan directory for files matching pattern and parse them.

    Security: Skips symlinks to prevent following malicious links that could
    point outside the repository or to sensitive files.
    """
    items = []

    if not directory.exists():
        print(f"Error: Directory {relative_path(directory)} does not exist", file=sys.stderr)
        return items

    # Security: Skip if directory itself is a symlink
    if directory.is_symlink():
        print(f"Warning: Skipping symlink directory {relative_path(directory)}", file=sys.stderr)
        return items

    # For agents: scan *.md directly in directory
    # For skills/commands: scan subdirs for SKILL.md or *.md
    if item_type == 'agent':
        for file_path in sorted(directory.glob('*.md')):
            # Security: Skip symlinks to prevent following malicious links
            if file_path.is_symlink():
                print(f"Warning: Skipping symlink {relative_path(file_path)}", file=sys.stderr)
                continue
            item = parse_item_file(file_path, item_type)
            if item:
                items.append(item)
    else:
        # Skills: look for SKILL.md in subdirectories
        # Commands: look for *.md in directory
        if item_type == 'skill':
            for subdir in sorted(directory.iterdir()):
                # Security: Skip symlink directories
                if subdir.is_symlink():
                    print(f"Warning: Skipping symlink directory {relative_path(subdir)}", file=sys.stderr)
                    continue
                if subdir.is_dir():
                    skill_file = subdir / 'SKILL.md'
                    # Security: Skip symlink files
                    if skill_file.exists() and not skill_file.is_symlink():
                        item = parse_item_file(skill_file, item_type)
                        if item:
                            items.append(item)
                    elif skill_file.is_symlink():
                        print(f"Warning: Skipping symlink {relative_path(skill_file)}", file=sys.stderr)
        else:  # commands
            for file_path in sorted(directory.glob('*.md')):
                # Security: Skip symlinks
                if file_path.is_symlink():
                    print(f"Warning: Skipping symlink {relative_path(file_path)}", file=sys.stderr)
                    continue
                item = parse_item_file(file_path, item_type)
                if item:
                    items.append(item)

    return items


def format_agents_table(items: List[Item]) -> str:
    """Format agents as markdown table grouped by type."""
    if not items:
        return "No agents found"

    # Group by type if available
    backend = [i for i in items if 'backend' in i.name.lower()]
    frontend = [i for i in items if 'frontend' in i.name.lower()]
    infra = [i for i in items if i not in backend and i not in frontend]

    output = []

    if backend:
        output.append("**Backend Engineers:**")
        output.append("| Agent | Expertise |")
        output.append("|-------|-----------|")
        for item in backend:
            output.append(f"| `{item.name}` | {item.description} |")
        output.append("")

    if frontend:
        output.append("**Frontend Engineers:**")
        output.append("| Agent | Expertise |")
        output.append("|-------|-----------|")
        for item in frontend:
            output.append(f"| `{item.name}` | {item.description} |")
        output.append("")

    if infra:
        output.append("**Infrastructure & Quality:**")
        output.append("| Agent | Expertise |")
        output.append("|-------|-----------|")
        for item in infra:
            output.append(f"| `{item.name}` | {item.description} |")

    return "\n".join(output)


def format_skills_list(items: List[Item]) -> str:
    """Format skills as categorized list."""
    if not items:
        return "No skills found"

    output = []
    for item in items:
        output.append(f"- `{item.name}`: {item.description}")

    return "\n".join(output)


def format_commands_list(items: List[Item]) -> str:
    """Format commands as table."""
    if not items:
        return "No commands found"

    output = ["| Command | Purpose |", "|---------|---------|"]
    for item in items:
        output.append(f"| `{item.name}` | {item.description} |")

    return "\n".join(output)


def main():
    if len(sys.argv) < 3:
        print("Usage: generate-reference.py <type> <directory>", file=sys.stderr)
        print("  type: agents, skills, or commands", file=sys.stderr)
        sys.exit(1)

    item_type = sys.argv[1]

    if item_type not in ['agents', 'skills', 'commands']:
        print(f"Error: Invalid type '{item_type}'. Must be agents, skills, or commands", file=sys.stderr)
        sys.exit(1)

    # Security: Validate directory is within monorepo root
    global _monorepo_root
    script_dir = Path(__file__).parent.resolve()
    _monorepo_root = script_dir.parent.parent  # shared/lib -> shared -> monorepo
    directory = validate_directory(Path(sys.argv[2]), _monorepo_root)

    # Normalize to singular
    item_type_singular = item_type.rstrip('s')

    # Scan directory
    items = scan_directory(directory, '*.md', item_type_singular)

    if not items:
        print(f"No {item_type} found in {relative_path(directory)}", file=sys.stderr)
        sys.exit(1)

    # Format output based on type
    if item_type == 'agents':
        print(format_agents_table(items))
    elif item_type == 'skills':
        print(format_skills_list(items))
    else:  # commands
        print(format_commands_list(items))


if __name__ == '__main__':
    main()
