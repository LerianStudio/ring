#!/usr/bin/env python3
"""
Generate skills quick reference from skill frontmatter.
Scans skills/ directory and extracts metadata from SKILL.md files.

New schema fields:
- name: Skill identifier
- description: WHAT the skill does (method/technique)
- trigger: WHEN to use (specific conditions) - primary decision field
- skip_when: WHEN NOT to use (exclusions) - differentiation field
- sequence.after: Skills that should come before
- sequence.before: Skills that typically follow
- related.similar: Skills that seem similar but differ
- related.complementary: Skills that pair well
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any

# Category patterns for grouping skills
CATEGORIES = {
    'Pre-Dev Workflow': [r'^pre-dev-'],
    'Testing & Debugging': [r'^test-', r'-debugging$', r'^condition-', r'^defense-', r'^root-cause'],
    'Collaboration': [r'-review$', r'^dispatching-', r'^sharing-'],
    'Planning & Execution': [r'^brainstorming$', r'^writing-plans$', r'^executing-plans$', r'-worktrees$', r'^subagent-driven'],
    'Meta Skills': [r'^using-', r'^writing-skills$', r'^testing-skills', r'^testing-agents'],
}

try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    print("Warning: pyyaml not installed, using fallback parser", file=sys.stderr)


class Skill:
    """Represents a skill with its metadata."""

    def __init__(self, name: str, description: str, directory: str,
                 trigger: str = "", skip_when: str = "",
                 sequence: Optional[Dict[str, List[str]]] = None,
                 related: Optional[Dict[str, List[str]]] = None):
        self.name = name
        self.description = description
        self.directory = directory
        self.trigger = trigger
        self.skip_when = skip_when
        self.sequence = sequence or {}
        self.related = related or {}
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


def first_line(text: str) -> str:
    """Extract first meaningful line from multi-line text."""
    if not text:
        return ""
    # Remove leading/trailing whitespace, take first line
    lines = text.strip().split('\n')
    for line in lines:
        line = line.strip()
        # Skip list markers and empty lines
        if line and not line.startswith('-'):
            return line
        elif line.startswith('- '):
            return line[2:]  # Return first list item without marker
    return lines[0].strip() if lines else ""


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
    """Fallback parser using regex when pyyaml unavailable.

    Handles:
    - Simple scalar fields: name, description, trigger, skip_when, when_to_use
    - Multi-line block scalars (|) - extracts first meaningful line
    - Nested structures: sequence, related - parses sub-fields with arrays
    """
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match:
        return None

    frontmatter_text = match.group(1)
    result = {}

    # Extract simple/block scalar fields
    # Known top-level field names (prevents false matches on "error:" etc in values)
    simple_fields = ['name', 'description', 'trigger', 'skip_when', 'when_to_use']
    all_fields = simple_fields + ['sequence', 'related']
    fields_pattern = '|'.join(all_fields)

    for field in simple_fields:
        # Match field: value OR field: | followed by indented content
        # Capture until next known top-level field or end of frontmatter
        # Using explicit field list prevents matching "error:" inside values
        pattern = rf'^{field}:\s*\|?\s*\n?(.*?)(?=^(?:{fields_pattern}):|\Z)'
        field_match = re.search(pattern, frontmatter_text, re.MULTILINE | re.DOTALL)
        if field_match:
            raw_value = field_match.group(1).strip()
            if raw_value:
                # Extract lines, clean indentation
                lines = []
                for line in raw_value.split('\n'):
                    cleaned = line.strip()
                    # Remove list marker prefix for cleaner display
                    if cleaned.startswith('- '):
                        cleaned = cleaned[2:]
                    if cleaned and not cleaned.startswith('#'):
                        lines.append(cleaned)
                if lines:
                    # For quick reference, use first meaningful line
                    result[field] = lines[0]

    # Handle nested structures: sequence and related
    for nested_field in ['sequence', 'related']:
        # Match the nested block (indented content under field:)
        pattern = rf'^{nested_field}:\s*\n((?:[ \t]+[^\n]*\n?)+)'
        nested_match = re.search(pattern, frontmatter_text, re.MULTILINE)
        if nested_match:
            nested_text = nested_match.group(1)
            result[nested_field] = {}

            # Parse sub-fields: after, before, similar, complementary
            # Format: subfield: [item1, item2] or subfield: [item1]
            subfields = ['after', 'before', 'similar', 'complementary']
            for subfield in subfields:
                # Match: subfield: [contents]
                sub_pattern = rf'^\s*{subfield}:\s*\[([^\]]*)\]'
                sub_match = re.search(sub_pattern, nested_text, re.MULTILINE)
                if sub_match:
                    items_str = sub_match.group(1)
                    # Parse comma-separated items, strip whitespace
                    items = [s.strip() for s in items_str.split(',') if s.strip()]
                    if items:
                        result[nested_field][subfield] = items

            # Remove empty nested dicts
            if not result[nested_field]:
                del result[nested_field]

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

        if not frontmatter or 'name' not in frontmatter:
            print(f"Warning: Missing name in {skill_path}", file=sys.stderr)
            return None

        # Handle backward compatibility: use when_to_use as trigger if trigger not set
        trigger = frontmatter.get('trigger', '')
        if not trigger:
            trigger = frontmatter.get('when_to_use', '')
        if not trigger:
            # Fall back to description for old-style skills
            trigger = frontmatter.get('description', '')

        # Get description - prefer dedicated description field
        description = frontmatter.get('description', '')

        directory = skill_path.parent.name
        return Skill(
            name=frontmatter['name'],
            description=description,
            directory=directory,
            trigger=trigger,
            skip_when=frontmatter.get('skip_when', ''),
            sequence=frontmatter.get('sequence', {}),
            related=frontmatter.get('related', {})
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
    """Generate markdown quick reference from skills list.

    New format is decision-focused:
    - Shows trigger (WHEN to use) as primary decision criteria
    - Shows skip_when to differentiate from similar skills
    - Shows sequence for workflow ordering
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
    category_order = list(CATEGORIES.keys()) + ['Other']
    sorted_categories = [cat for cat in category_order if cat in categorized]

    # Build markdown
    lines = ['# Ring Skills Quick Reference\n']

    for category in sorted_categories:
        category_skills = categorized[category]
        lines.append(f'## {category} ({len(category_skills)} skills)\n')

        for skill in sorted(category_skills, key=lambda s: s.name):
            # Skill name and description
            lines.append(f'- **{skill.name}**: {first_line(skill.description)}')

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
