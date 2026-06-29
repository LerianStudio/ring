#!/usr/bin/env python3
"""Tests for generate-skills-ref.py frontmatter parsing and markdown generation."""

from pathlib import Path

import pytest

# We need to import the module by its filename (contains hyphens in concept but not in actual name)
import importlib.util

spec = importlib.util.spec_from_file_location(
    "generate_skills_ref",
    Path(__file__).parent.parent / "generate-skills-ref.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

Skill = mod.Skill
condense_description = mod.condense_description
parse_frontmatter_yaml = mod.parse_frontmatter_yaml
parse_frontmatter_fallback = mod.parse_frontmatter_fallback
parse_skill_file = mod.parse_skill_file
scan_skills_directory = mod.scan_skills_directory
generate_markdown = mod.generate_markdown
scan_all_plugins = mod.scan_all_plugins
scan_installed_cache = mod.scan_installed_cache
_max_version_dir = mod._max_version_dir


# ---------------------------------------------------------------------------
# condense_description()
# ---------------------------------------------------------------------------


class TestCondenseDescription:
    def test_empty_string(self):
        assert condense_description("") == ""

    def test_single_line_unchanged(self):
        assert condense_description("hello world") == "hello world"

    def test_multiline_collapsed(self):
        assert condense_description("hello\nworld") == "hello world"

    def test_collapses_runs_of_whitespace(self):
        assert condense_description("hello   \n   world") == "hello world"

    def test_strips_outer_whitespace(self):
        assert condense_description("  hello world  ") == "hello world"

    def test_none_input(self):
        # None must be treated as empty (`not text` falsy guard).
        assert condense_description(None) == ""


# ---------------------------------------------------------------------------
# parse_frontmatter_yaml()
# ---------------------------------------------------------------------------


class TestParseFrontmatterYaml:
    def test_valid_frontmatter(self):
        pytest.importorskip("yaml")
        content = "---\nname: test\ndescription: desc\n---\n# Body\n"
        result = parse_frontmatter_yaml(content)
        assert result["name"] == "test"

    def test_no_frontmatter(self):
        assert parse_frontmatter_yaml("# Just markdown") is None


# ---------------------------------------------------------------------------
# parse_frontmatter_fallback()
# ---------------------------------------------------------------------------


class TestParseFrontmatterFallback:
    def test_valid_frontmatter(self):
        content = "---\nname: test\ndescription: A skill\n---\n# Body\n"
        result = parse_frontmatter_fallback(content)
        assert result is not None
        assert result["name"] == "test"
        assert result["description"] == "A skill"

    def test_no_frontmatter(self):
        assert parse_frontmatter_fallback("# Just markdown") is None

    def test_double_quoted_single_line_description_unquoted(self):
        # Descriptions are now double-quoted single-line YAML strings; the
        # fallback parser must strip the surrounding quotes.
        content = (
            '---\n'
            'name: ring:test\n'
            'description: "Doing a thing and then another thing."\n'
            '---\n# Body\n'
        )
        result = parse_frontmatter_fallback(content)
        assert result is not None
        assert result["description"] == "Doing a thing and then another thing."

    def test_single_quoted_description_unquoted(self):
        content = (
            "---\n"
            "name: ring:test\n"
            "description: 'Doing a thing.'\n"
            "---\n# Body\n"
        )
        result = parse_frontmatter_fallback(content)
        assert result is not None
        assert result["description"] == "Doing a thing."

    def test_unbalanced_quote_preserved(self):
        # A leading quote with no matching trailing quote is left untouched.
        content = (
            '---\n'
            'name: ring:test\n'
            'description: "Quoted start no end\n'
            '---\n# Body\n'
        )
        result = parse_frontmatter_fallback(content)
        assert result is not None
        assert result["description"] == '"Quoted start no end'

    def test_block_scalar_description_joined(self):
        content = (
            "---\n"
            "name: test\n"
            "description: |\n"
            "  Line one of description.\n"
            "  Line two of description.\n"
            "---\n"
        )
        result = parse_frontmatter_fallback(content)
        assert result is not None
        assert "Line one" in result["description"]
        assert "Line two" in result["description"]

    def test_oversized_frontmatter_rejected(self):
        """Size guard: frontmatter > 10KB should return None."""
        huge = "---\nname: test\ndescription: " + "x" * 11000 + "\n---\n"
        result = parse_frontmatter_fallback(huge)
        assert result is None


# ---------------------------------------------------------------------------
# Skill constructor
# ---------------------------------------------------------------------------


class TestSkillConstructor:
    def test_basic_construction(self):
        s = Skill(
            name="ring:test", description="d", directory="test", plugin="default"
        )
        assert s.name == "ring:test"
        assert s.description == "d"
        assert s.directory == "test"
        assert s.plugin == "default"

    def test_categorize_default_plugin_is_core_workflow(self):
        s = Skill(
            name="x", description="d", directory="reviewing-code", plugin="default"
        )
        assert s.category == "Core Workflow"

    def test_categorize_dev_team_plugin_is_development(self):
        s = Skill(
            name="x", description="d", directory="implementing-tasks", plugin="dev-team"
        )
        assert s.category == "Development"

    def test_categorize_pm_team_plugin_is_pre_dev_planning(self):
        s = Skill(
            name="x", description="d", directory="writing-prds", plugin="pm-team"
        )
        assert s.category == "Pre-Dev Planning"

    def test_categorize_tw_team_plugin_is_technical_writing(self):
        s = Skill(
            name="x", description="d", directory="reviewing-docs", plugin="tw-team"
        )
        assert s.category == "Technical Writing"

    def test_categorize_using_prefix_overrides_plugin(self):
        # using-* meta skills are grouped together regardless of plugin.
        s = Skill(
            name="x", description="d", directory="using-ring", plugin="default"
        )
        assert s.category == "Meta Skills"

    def test_categorize_using_prefix_overrides_dev_team_plugin(self):
        s = Skill(
            name="x",
            description="d",
            directory="using-lib-commons",
            plugin="dev-team",
        )
        assert s.category == "Meta Skills"

    def test_categorize_unknown_plugin_is_other(self):
        s = Skill(
            name="x", description="d", directory="random-thing", plugin="mystery"
        )
        assert s.category == "Other"


# ---------------------------------------------------------------------------
# generate_markdown() — integration
# ---------------------------------------------------------------------------


class TestGenerateMarkdown:
    def test_empty_skills_list(self):
        result = generate_markdown([])
        assert "No skills found" in result

    def test_single_skill_basic(self):
        s = Skill(
            name="ring:test",
            description="Test skill",
            directory="test",
            plugin="default",
        )
        result = generate_markdown([s])
        assert "ring:test" in result
        assert "Test skill" in result

    def test_multiline_description_condensed(self):
        s = Skill(
            name="ring:test",
            description="First line.\nSecond line.",
            directory="test",
            plugin="default",
        )
        result = generate_markdown([s])
        assert "First line. Second line." in result

    def test_skills_grouped_by_category(self):
        skills = [
            Skill(
                name="ring:a", description="d", directory="writing-prds", plugin="pm-team"
            ),
            Skill(
                name="ring:b", description="d", directory="using-ring", plugin="default"
            ),
        ]
        result = generate_markdown(skills)
        assert "Pre-Dev Planning" in result
        assert "Meta Skills" in result

    def test_skill_count_in_category_heading(self):
        skills = [
            Skill(
                name="ring:a", description="d", directory="using-x", plugin="default"
            ),
            Skill(
                name="ring:b", description="d", directory="using-y", plugin="dev-team"
            ),
        ]
        result = generate_markdown(skills)
        assert "Meta Skills (2 skills)" in result

    def test_category_order_follows_plugin_order(self):
        # Categories render in CATEGORY_ORDER: Core Workflow, Development,
        # Pre-Dev Planning, Technical Writing, Meta Skills, Other.
        skills = [
            Skill(name="ring:tw", description="d", directory="reviewing-docs", plugin="tw-team"),
            Skill(name="ring:core", description="d", directory="committing-changes", plugin="default"),
            Skill(name="ring:dev", description="d", directory="implementing-tasks", plugin="dev-team"),
        ]
        result = generate_markdown(skills)
        core_idx = result.index("Core Workflow")
        dev_idx = result.index("Development")
        tw_idx = result.index("Technical Writing")
        assert core_idx < dev_idx < tw_idx


# ---------------------------------------------------------------------------
# scan_all_plugins() — multi-plugin aggregation
# ---------------------------------------------------------------------------


class TestScanAllPlugins:
    def test_aggregates_across_plugins(self, tmp_path):
        """Skills from multiple plugin directories are aggregated."""
        # Plugin A
        skill_a = tmp_path / "default" / "skills" / "skill-a"
        skill_a.mkdir(parents=True)
        (skill_a / "SKILL.md").write_text(
            "---\nname: ring:skill-a\ndescription: First skill\n---\n# Body\n"
        )
        # Plugin B
        skill_b = tmp_path / "dev-team" / "skills" / "skill-b"
        skill_b.mkdir(parents=True)
        (skill_b / "SKILL.md").write_text(
            "---\nname: ring:skill-b\ndescription: Second skill\n---\n# Body\n"
        )
        # Missing plugin C is skipped silently
        result = scan_all_plugins(tmp_path, ["default", "dev-team", "pm-team"])
        names = sorted(s.name for s in result)
        assert names == ["ring:skill-a", "ring:skill-b"]


# ---------------------------------------------------------------------------
# _max_version_dir() — newest cached version selection
# ---------------------------------------------------------------------------


class TestMaxVersionDir:
    def test_numeric_not_lexical(self, tmp_path):
        # Lexically "1.4.0" > "1.39.0"; numerically 1.39.0 wins.
        for name in ("1.4.0", "1.39.0", "1.5.0"):
            (tmp_path / name).mkdir()
        dirs = [d for d in tmp_path.iterdir() if d.is_dir()]
        assert _max_version_dir(dirs).name == "1.39.0"

    def test_real_dev_team_spread(self, tmp_path):
        for name in ("1.81.0", "1.81.1", "1.81.2", "1.82.0", "1.85.0"):
            (tmp_path / name).mkdir()
        dirs = [d for d in tmp_path.iterdir() if d.is_dir()]
        assert _max_version_dir(dirs).name == "1.85.0"


# ---------------------------------------------------------------------------
# scan_installed_cache() — flattened plugin-cache layout
# ---------------------------------------------------------------------------


def _write_skill(skills_dir: Path, name: str, desc: str = "d") -> None:
    d = skills_dir / name.split(":")[-1]
    d.mkdir(parents=True)
    (d / "SKILL.md").write_text(f"---\nname: {name}\ndescription: {desc}\n---\n# Body\n")


class TestScanInstalledCache:
    def test_aggregates_across_flattened_plugins(self, tmp_path):
        """Plugins live in ring-<plugin>/<version>/skills, not as siblings."""
        _write_skill(tmp_path / "ring-default" / "1.42.0" / "skills", "ring:a")
        _write_skill(tmp_path / "ring-dev-team" / "1.85.0" / "skills", "ring:b")
        result = scan_installed_cache(tmp_path, ["default", "dev-team", "pm-team"])
        assert sorted(s.name for s in result) == ["ring:a", "ring:b"]

    def test_uses_only_newest_version_no_duplicates(self, tmp_path):
        # Two cached versions of dev-team; the skill must appear exactly once,
        # sourced from the newest version.
        _write_skill(
            tmp_path / "ring-dev-team" / "1.84.0" / "skills", "ring:x", "old"
        )
        _write_skill(
            tmp_path / "ring-dev-team" / "1.85.0" / "skills", "ring:x", "new"
        )
        result = scan_installed_cache(tmp_path, ["dev-team"])
        assert [s.name for s in result] == ["ring:x"]
        assert result[0].description == "new"

    def test_categorizes_by_plugin(self, tmp_path):
        _write_skill(tmp_path / "ring-pm-team" / "0.32.1" / "skills", "ring:p")
        result = scan_installed_cache(tmp_path, ["pm-team"])
        assert result[0].category == "Pre-Dev Planning"

    def test_missing_plugin_skipped(self, tmp_path):
        _write_skill(tmp_path / "ring-default" / "1.42.0" / "skills", "ring:a")
        # dev-team has no cache dir at all → silently skipped.
        result = scan_installed_cache(tmp_path, ["default", "dev-team"])
        assert [s.name for s in result] == ["ring:a"]


# ---------------------------------------------------------------------------
# scan_skills_directory() — filesystem scan
# ---------------------------------------------------------------------------


class TestScanSkillsDirectory:
    def test_skips_shared_patterns(self, tmp_path):
        # Real skill should be picked up; shared-patterns/ must be skipped
        # even when it contains a file named SKILL.md.
        real = tmp_path / "real-skill"
        real.mkdir()
        (real / "SKILL.md").write_text(
            "---\nname: ring:real\ndescription: real\n---\n"
        )
        shared = tmp_path / "shared-patterns"
        shared.mkdir()
        (shared / "SKILL.md").write_text(
            "---\nname: ring:should-not-appear\ndescription: nope\n---\n"
        )

        skills = scan_skills_directory(tmp_path)

        names = [s.name for s in skills]
        assert "ring:real" in names
        assert "ring:should-not-appear" not in names

    def test_skips_dirs_without_skill_md(self, tmp_path, capsys):
        # Subdirectories lacking SKILL.md are warned about and skipped.
        (tmp_path / "incomplete").mkdir()
        good = tmp_path / "good"
        good.mkdir()
        (good / "SKILL.md").write_text(
            "---\nname: ring:good\ndescription: ok\n---\n"
        )
        skills = scan_skills_directory(tmp_path)
        captured = capsys.readouterr()
        assert "Warning: No SKILL.md" in captured.err
        assert "incomplete" in captured.err
        assert [s.name for s in skills] == ["ring:good"]


# ---------------------------------------------------------------------------
# parse_skill_file() — edge cases
# ---------------------------------------------------------------------------


class TestParseSkillFileEdgeCases:
    def test_empty_frontmatter_returns_none(self, tmp_path):
        # Empty frontmatter (no name, no description) → None per contract.
        p = tmp_path / "SKILL.md"
        p.write_text("---\n---\n")
        assert parse_skill_file(p) is None

    def test_frontmatter_without_name_returns_none(self, tmp_path):
        # Missing required `name` → None.
        p = tmp_path / "SKILL.md"
        p.write_text("---\ndescription: only desc\n---\n")
        assert parse_skill_file(p) is None

    def test_frontmatter_without_description_defaults_empty(self, tmp_path):
        # Missing description is permitted at parse time; defaults to "".
        # (validate-frontmatter.py handles the schema-level error.)
        p = tmp_path / "SKILL.md"
        p.write_text("---\nname: ring:t\n---\n")
        s = parse_skill_file(p)
        assert s is not None
        assert s.name == "ring:t"
        assert s.description == ""

    def test_utf8_in_name_and_description_preserved(self, tmp_path):
        p = tmp_path / "SKILL.md"
        p.write_text(
            '---\nname: ring:t\ndescription: "Olá, ção, 中文, 🌟"\n---\n',
            encoding="utf-8",
        )
        s = parse_skill_file(p)
        assert s is not None
        assert s.name == "ring:t"
        assert s.description == "Olá, ção, 中文, 🌟"

    def test_returns_none_for_directory_passed_as_skill_md(self, tmp_path):
        # Passing a directory where SKILL.md is expected exercises the
        # broad except handler (open() on a directory raises IsADirectoryError).
        fake = tmp_path / "broken_skill"
        fake.mkdir()
        skill_md = fake / "SKILL.md"
        skill_md.mkdir()  # directory, not file
        result = parse_skill_file(skill_md)
        assert result is None
