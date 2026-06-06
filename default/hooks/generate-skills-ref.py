#!/usr/bin/env python3
"""
Generate skills quick reference from skill frontmatter.
Scans skills/ directory and extracts metadata from SKILL.md files.

Anthropic-canonical schema:
- name: Skill identifier
- description: WHAT the skill does and WHEN to use it (the description
  itself self-contains the trigger essence)

Output: one line per skill, grouped by category. Each line is
"- **name**: description" with the description condensed to a single
line (whitespace collapsed).
"""

import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

# Plugin directories to scan.
# MUST stay in sync with validate-frontmatter.py:ALL_PLUGINS
ALL_PLUGINS = ["default", "dev-team", "pm-team", "tw-team"]

# Category = plugin display name. Gerund skill names share no common prefixes,
# so pattern-based categorization is structurally unworkable; the scanner
# already knows which plugin directory it is iterating, so we key off that.
# MUST stay in sync with generate-skills-ref.sh PLUGIN_CATEGORIES + categorize_skill.
PLUGIN_CATEGORIES = {
    "default": "Core Workflow",
    "dev-team": "Development",
    "pm-team": "Pre-Dev Planning",
    "tw-team": "Technical Writing",
}

# Single directory-name override: cross-cutting meta skills (using-*) are
# grouped together regardless of which plugin ships them.
META_SKILL_PATTERN = r"^using-"

# Deterministic category display order. Plugin categories first (in plugin
# order), then Meta Skills, then the Other fallback.
CATEGORY_ORDER = list(PLUGIN_CATEGORIES.values()) + ["Meta Skills", "Other"]

try:
    import yaml

    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    print("Warning: pyyaml not installed, using fallback parser", file=sys.stderr)


class Skill:
    """Represents a skill with its metadata."""

    def __init__(
        self,
        name: str,
        description: str,
        directory: str,
        plugin: str,
    ):
        self.name = name
        self.description = description
        self.directory = directory
        self.plugin = plugin
        self.category = self._categorize()

    def _categorize(self) -> str:
        """Category is the plugin display name, with one directory-name
        override: ``using-*`` meta skills are grouped together.
        """
        if re.search(META_SKILL_PATTERN, self.directory):
            return "Meta Skills"
        return PLUGIN_CATEGORIES.get(self.plugin, "Other")

    def __repr__(self):
        return f"Skill(name={self.name}, category={self.category})"


def condense_description(text: str) -> str:
    """Collapse a (possibly multi-line block-scalar) description into a
    single readable line for the quick reference.
    """
    if not text:
        return ""
    # Replace newlines with spaces, then collapse runs of whitespace.
    one_line = re.sub(r"\s+", " ", text.replace("\n", " ")).strip()
    return one_line


def parse_frontmatter_yaml(content: str) -> Optional[Dict[str, Any]]:
    """Parse YAML frontmatter using pyyaml library."""
    if not YAML_AVAILABLE:
        return None

    # Extract frontmatter between --- delimiters
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not match:
        return None

    try:
        frontmatter = yaml.safe_load(match.group(1))
        return frontmatter if isinstance(frontmatter, dict) else None
    except yaml.YAMLError as e:
        print(f"Warning: YAML parse error: {e}", file=sys.stderr)
        return None


def parse_frontmatter_fallback(content: str) -> Optional[Dict[str, Any]]:
    """Fallback parser using regex when pyyaml unavailable.

    Handles:
    - Simple scalar fields: name, description
    - Multi-line block scalars (|) for description
    """
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not match:
        return None

    frontmatter_text = match.group(1)

    # Size guard: prevent pathological regex backtracking on oversized frontmatter
    if len(frontmatter_text) > 10000:
        print(
            "Warning: Oversized frontmatter, skipping fallback parse", file=sys.stderr
        )
        return None

    result = {}

    # Known top-level field names — Anthropic-canonical schema for skills.
    simple_fields = ["name", "description"]
    fields_pattern = "|".join(simple_fields)

    for field in simple_fields:
        # Match field: value OR field: | followed by indented content
        # Capture until next known top-level field or end of frontmatter
        pattern = rf"^{field}:\s*\|?\s*\n?(.*?)(?=^(?:{fields_pattern}):|\Z)"
        field_match = re.search(pattern, frontmatter_text, re.MULTILINE | re.DOTALL)
        if field_match:
            raw_value = field_match.group(1).strip()
            if raw_value:
                # Extract lines, clean indentation
                lines = []
                for line in raw_value.split("\n"):
                    cleaned = line.strip()
                    # Remove list marker prefix for cleaner display
                    if cleaned.startswith("- "):
                        cleaned = cleaned[2:]
                    if cleaned and not cleaned.startswith("#"):
                        lines.append(cleaned)
                if lines:
                    # For description, join all lines with spaces (block scalar);
                    # for name, the first line is the value.
                    if field == "description":
                        value = " ".join(lines)
                    else:
                        value = lines[0]
                    result[field] = _strip_quotes(value)

    return result if result else None


def _strip_quotes(value: str) -> str:
    """Strip a single pair of surrounding double or single quotes.

    Descriptions are now double-quoted single-line YAML strings; pyyaml
    unquotes them automatically, but the regex fallback must do it itself.
    """
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
        return value[1:-1]
    return value


def parse_skill_file(skill_path: Path, plugin: str = "") -> Optional[Skill]:
    """Parse a SKILL.md file and extract metadata.

    `plugin` is the owning plugin directory name and determines the skill's
    category (see Skill._categorize).
    """
    try:
        with open(skill_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Try YAML parser first, fall back to regex
        frontmatter = parse_frontmatter_yaml(content)
        if not frontmatter:
            frontmatter = parse_frontmatter_fallback(content)

        if not frontmatter or "name" not in frontmatter:
            print(f"Warning: Missing name in {skill_path}", file=sys.stderr)
            return None

        description = frontmatter.get("description", "") or ""

        directory = skill_path.parent.name
        return Skill(
            name=frontmatter["name"],
            description=description,
            directory=directory,
            plugin=plugin,
        )

    except Exception as e:
        print(f"Warning: Error parsing {skill_path}: {e}", file=sys.stderr)
        return None


def scan_skills_directory(skills_dir: Path, plugin: str = "") -> List[Skill]:
    """Scan skills directory and parse all SKILL.md files.

    `plugin` is the owning plugin directory name, threaded through so each
    skill is categorized by the plugin that ships it.
    """
    skills = []

    if not skills_dir.exists():
        print(f"Error: Skills directory not found: {skills_dir}", file=sys.stderr)
        return skills

    for skill_dir in sorted(skills_dir.iterdir()):
        if not skill_dir.is_dir():
            continue

        if skill_dir.name == "shared-patterns":
            continue

        skill_file = skill_dir / "SKILL.md"
        if not skill_file.exists():
            print(f"Warning: No SKILL.md in {skill_dir.name}", file=sys.stderr)
            continue

        skill = parse_skill_file(skill_file, plugin=plugin)
        if skill:
            skills.append(skill)

    return skills


def generate_markdown(skills: List[Skill]) -> str:
    """Generate markdown quick reference from skills list.

    Single-line per skill: `- **name**: description`. The description
    self-contains the trigger essence in the Anthropic-canonical schema.
    """
    if not skills:
        return "# Ring Skills Quick Reference\n\n**No skills found.**\n"

    # Group skills by category
    categorized: Dict[str, List[Skill]] = {}
    for skill in skills:
        category = skill.category
        if category not in categorized:
            categorized[category] = []
        categorized[category].append(skill)

    # Sort categories (predefined order, then Other)
    sorted_categories = [cat for cat in CATEGORY_ORDER if cat in categorized]

    # Build markdown
    lines = ["# Ring Skills Quick Reference\n"]

    for category in sorted_categories:
        category_skills = categorized[category]
        lines.append(f"## {category} ({len(category_skills)} skills)\n")

        for skill in sorted(category_skills, key=lambda s: s.name):
            desc = condense_description(skill.description)
            lines.append(f"- **{skill.name}**: {desc}")

        lines.append("")  # Blank line between categories

    # Add usage section
    lines.append("## Usage\n")
    lines.append("To use a skill: Use the Skill tool with skill name")
    lines.append("Example: `ring:using-ring`")

    return "\n".join(lines)


def scan_all_plugins(repo_root: Path, plugins: List[str]) -> List[Skill]:
    """Aggregate skills across every plugin in `plugins`.

    Plugin directories without a `skills/` subdirectory are skipped silently
    (matches validate-frontmatter.py behavior).
    """
    aggregated: List[Skill] = []
    for plugin in plugins:
        skills_dir = repo_root / plugin / "skills"
        if not skills_dir.is_dir():
            continue
        aggregated.extend(scan_skills_directory(skills_dir, plugin=plugin))
    return aggregated


def main():
    """Main entry point."""
    # This script lives in default/hooks/, so the marketplace root is two up.
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent

    # Scan and parse skills across every active plugin
    skills = scan_all_plugins(repo_root, ALL_PLUGINS)

    if not skills:
        print("Error: No valid skills found", file=sys.stderr)
        sys.exit(1)

    # Generate and output markdown
    markdown = generate_markdown(skills)
    print(markdown)

    # Report statistics to stderr
    print(f"Generated reference for {len(skills)} skills", file=sys.stderr)


if __name__ == "__main__":
    main()
