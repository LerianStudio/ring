#!/usr/bin/env python3
"""
Generate skills quick reference from skill frontmatter.
Scans skills/ directory and extracts metadata from SKILL.md files.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Category patterns for grouping skills
CATEGORIES = {
    'Pre-Dev Workflow': [r'^pre-dev-'],
    'Testing & Debugging': [r'^test-', r'-debugging$', r'^condition-', r'^defense-'],
    'Collaboration': [r'-review$', r'^dispatching-', r'^sharing-'],
    'Planning & Execution': [r'^brainstorming$', r'^writing-plans$', r'^executing-plans$', r'-worktrees$'],
    'Meta Skills': [r'^using-ring$', r'^writing-skills$', r'^testing-skills'],
}

try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    print("Warning: pyyaml not installed, using fallback parser", file=sys.stderr)


class Skill:
    """Represents a skill with its metadata."""

    def __init__(self, name: str, description: str, directory: str):
        self.name = name
        self.description = description
        self.directory = directory
        self.category = self._categorize()

    def _categorize(self) -> str:
        """Determine skill category based on directory name."""
        for category, patterns in CATEGORIES.items():
            for pattern in patterns:
                if re.search(pattern, self.directory):
                    return category
        return 'Other'

    def __repr__(self):
        return f"Skill(name={self.name}, category={self.category})"


def parse_frontmatter_yaml(content: str) -> Optional[Dict[str, str]]:
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


def parse_frontmatter_fallback(content: str) -> Optional[Dict[str, str]]:
    """Fallback parser using regex when pyyaml unavailable."""
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match:
        return None

    frontmatter_text = match.group(1)
    result = {}

    # Extract name
    name_match = re.search(r'^name:\s*(.+)$', frontmatter_text, re.MULTILINE)
    if name_match:
        result['name'] = name_match.group(1).strip()

    # Extract description (may span multiple lines)
    desc_match = re.search(r'^description:\s*(.+?)(?=^[a-z_]+:|$)',
                          frontmatter_text, re.MULTILINE | re.DOTALL)
    if desc_match:
        # Clean up multi-line description
        desc = desc_match.group(1).strip()
        desc = re.sub(r'\s+', ' ', desc)  # Collapse whitespace
        result['description'] = desc

    return result if result else None


def parse_skill_file(skill_path: Path) -> Optional[Skill]:
    """Parse a SKILL.md file and extract metadata."""
    try:
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Try YAML parser first, fall back to regex
        frontmatter = parse_frontmatter_yaml(content)
        if not frontmatter:
            frontmatter = parse_frontmatter_fallback(content)

        if not frontmatter or 'name' not in frontmatter or 'description' not in frontmatter:
            print(f"Warning: Missing name/description in {skill_path}", file=sys.stderr)
            return None

        directory = skill_path.parent.name
        return Skill(
            name=frontmatter['name'],
            description=frontmatter['description'],
            directory=directory
        )

    except Exception as e:
        print(f"Warning: Error parsing {skill_path}: {e}", file=sys.stderr)
        return None


def scan_skills_directory(skills_dir: Path) -> List[Skill]:
    """Scan skills directory and parse all SKILL.md files."""
    skills = []

    if not skills_dir.exists():
        print(f"Error: Skills directory not found: {skills_dir}", file=sys.stderr)
        return skills

    for skill_dir in sorted(skills_dir.iterdir()):
        if not skill_dir.is_dir():
            continue

        skill_file = skill_dir / 'SKILL.md'
        if not skill_file.exists():
            print(f"Warning: No SKILL.md in {skill_dir.name}", file=sys.stderr)
            continue

        skill = parse_skill_file(skill_file)
        if skill:
            skills.append(skill)

    return skills


def generate_markdown(skills: List[Skill]) -> str:
    """Generate markdown quick reference from skills list."""
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
    category_order = list(CATEGORIES.keys()) + ['Other']
    sorted_categories = [cat for cat in category_order if cat in categorized]

    # Build markdown
    lines = ['# Ring Skills Quick Reference\n']

    for category in sorted_categories:
        category_skills = categorized[category]
        lines.append(f'## {category} ({len(category_skills)} skills)\n')

        for skill in sorted(category_skills, key=lambda s: s.name):
            lines.append(f'- **{skill.name}**: {skill.description}')

        lines.append('')  # Blank line between categories

    # Add usage section
    lines.append('## Usage\n')
    lines.append('To use a skill: Use the Skill tool with skill name')
    lines.append('Example: `ring:brainstorming`')

    return '\n'.join(lines)


def main():
    """Main entry point."""
    # Determine plugin root (parent of hooks directory)
    script_dir = Path(__file__).parent.resolve()
    plugin_root = script_dir.parent
    skills_dir = plugin_root / 'skills'

    # Scan and parse skills
    skills = scan_skills_directory(skills_dir)

    if not skills:
        print("Error: No valid skills found", file=sys.stderr)
        sys.exit(1)

    # Generate and output markdown
    markdown = generate_markdown(skills)
    print(markdown)

    # Report statistics to stderr
    print(f"Generated reference for {len(skills)} skills", file=sys.stderr)


if __name__ == '__main__':
    main()
