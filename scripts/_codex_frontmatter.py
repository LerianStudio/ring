#!/usr/bin/env python3
"""Transform a source SKILL.md into the codex-flavored variant.

Stdlib only. Invoked per-skill by install-symlinks.sh (build subcommand).

Usage:
  python3 scripts/_codex_frontmatter.py \
    --source <path> --dest <path> \
    --team <team> --skill-name <name> --lookup <lookup.json>

Or, to build the lookup map once and cache it:
  python3 scripts/_codex_frontmatter.py --build-lookup <repo-root> --lookup-out <path>

Or, to rewrite markdown link paths in an accessory (non-SKILL.md) file:
  python3 scripts/_codex_frontmatter.py --rewrite-paths \
    --source <path> --dest <path> --team <team> --lookup <lookup.json>

Or, to emit a slash-command shim for an opencode skill so it appears in the
TUI's `/` autocomplete (which silently filters source="skill" entries):
  python3 scripts/_codex_frontmatter.py --emit-opencode-skill-shim \
    --source <path-to-SKILL.md> --dest <path-to-shim.md>
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

FM_DELIM = "---"
RING_REF_RE = re.compile(r"\bring:([a-z0-9][a-z0-9-]*)\b")
# Markdown inline link: ](path) — capture path inside parens.
LINK_RE = re.compile(r"\]\(([^)\s]+)(\s+\"[^\"]*\")?\)")


def _split_frontmatter(text: str, src_path: str) -> tuple[list[str], str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != FM_DELIM:
        raise ValueError("missing opening frontmatter delimiter: " + src_path)
    for i in range(1, len(lines)):
        if lines[i].strip() == FM_DELIM:
            body_start = i + 1
            # preserve trailing newline if present in original
            body = "\n".join(lines[body_start:])
            if text.endswith("\n") and not body.endswith("\n"):
                body += "\n"
            return lines[1:i], body
    raise ValueError("missing closing frontmatter delimiter: " + src_path)


def _read_top_level_name(fm_lines: list[str]) -> str | None:
    # cheap top-level scan: line starting with "name:" at column 0
    for line in fm_lines:
        if line.startswith("name:"):
            value = line.split(":", 1)[1].strip()
            # strip surrounding quotes
            if (value.startswith('"') and value.endswith('"')) or (
                value.startswith("'") and value.endswith("'")
            ):
                value = value[1:-1]
            if value.startswith("ring:"):
                value = value[len("ring:") :]
            return value
    return None


def build_lookup(repo_root: Path) -> dict[str, str]:
    teams = ("default", "dev-team", "pm-team", "tw-team")
    lookup: dict[str, str] = {}
    for team in teams:
        skills_dir = repo_root / team / "skills"
        if not skills_dir.is_dir():
            continue
        for skill_dir in sorted(skills_dir.iterdir()):
            skill_md = skill_dir / "SKILL.md"
            if not skill_md.is_file():
                continue
            text = skill_md.read_text(encoding="utf-8")
            try:
                fm_lines, _ = _split_frontmatter(text, str(skill_md))
            except ValueError:
                continue
            name = _read_top_level_name(fm_lines)
            if name:
                lookup[name] = team
    return lookup


def _parse_top_level_keys(fm_lines: list[str]) -> list[tuple[str, list[str]]]:
    """Group frontmatter lines by top-level key.

    Returns ordered list of (key, raw_lines_including_key_line).
    A "top-level key" is a line matching '^[A-Za-z_][A-Za-z0-9_-]*:' at col 0.
    Lines that don't start with a key (continuations, list items, blank lines)
    are appended to the most recent key's lines.
    """
    groups: list[tuple[str, list[str]]] = []
    key_re = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):")
    current_key: str | None = None
    current_lines: list[str] = []
    for line in fm_lines:
        m = key_re.match(line)
        if m and not line.startswith(" ") and not line.startswith("\t"):
            if current_key is not None:
                groups.append((current_key, current_lines))
            current_key = m.group(1)
            current_lines = [line]
        else:
            if current_key is None:
                # stray prelude — attach to a synthetic empty key so we don't lose it
                current_key = ""
                current_lines = [line]
            else:
                current_lines.append(line)
    if current_key is not None:
        groups.append((current_key, current_lines))
    return groups


def _extract_description(group_lines: list[str]) -> str:
    """Collapse a description value (possibly folded/literal/multiline) to one line."""
    first = group_lines[0]
    _, _, after_colon = first.partition(":")
    after_colon = after_colon.strip()
    if after_colon in ("|", ">", "|-", ">-", "|+", ">+"):
        # block scalar — gather indented continuation
        parts: list[str] = []
        for cont in group_lines[1:]:
            if cont.strip() == "":
                parts.append("")
            else:
                parts.append(cont.lstrip())
        text = " ".join(p for p in parts)
    elif after_colon == "":
        # value on following lines (rare); join continuations
        parts = [c.strip() for c in group_lines[1:] if c.strip()]
        text = " ".join(parts)
    else:
        # inline value; may still have continuation lines (folded without |)
        parts = [after_colon]
        for cont in group_lines[1:]:
            parts.append(cont.strip())
        text = " ".join(p for p in parts if p)
        # strip optional surrounding quotes
        if (text.startswith('"') and text.endswith('"')) or (
            text.startswith("'") and text.endswith("'")
        ):
            text = text[1:-1]
    # normalize whitespace
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _yaml_inline_string(s: str) -> str:
    """Emit a YAML scalar safely on one line. Quote if needed."""
    if s == "":
        return "''"
    # characters / patterns that force quoting
    needs_quote = False
    if s[0] in "!&*[]{}|>%@`#," or s[0] in " '\"":
        needs_quote = True
    if ": " in s or s.endswith(":"):
        needs_quote = True
    if " #" in s:
        needs_quote = True
    if any(c in s for c in "\n\t"):
        needs_quote = True
    if s.lower() in ("true", "false", "null", "yes", "no", "on", "off", "~"):
        needs_quote = True
    if re.fullmatch(r"-?\d+(\.\d+)?", s):
        needs_quote = True
    if not needs_quote:
        return s
    # prefer single quotes unless string contains single quote
    if "'" not in s:
        return "'" + s + "'"
    # double-quote with escapes
    escaped = s.replace("\\", "\\\\").replace('"', '\\"')
    return '"' + escaped + '"'


def _emit_metadata_block(metadata: dict[str, str]) -> list[str]:
    out = ["metadata:"]
    for k, v in metadata.items():
        out.append("  " + k + ": " + _yaml_inline_string(v))
    return out


def _merge_metadata(existing_lines: list[str], overrides: dict[str, str]) -> list[str]:
    """Merge override keys into an existing metadata: block, preserving other keys.

    Only handles the simple shape: 'metadata:' followed by '  key: value' lines.
    Nested structures under metadata are preserved verbatim where possible.
    """
    # parse existing into ordered list of (key, [lines])
    merged: list[tuple[str, list[str]]] = []
    sub_re = re.compile(r"^  ([A-Za-z_][A-Za-z0-9_-]*):")
    current_sub: str | None = None
    current_sub_lines: list[str] = []
    for line in existing_lines[1:]:
        m = sub_re.match(line)
        if m:
            if current_sub is not None:
                merged.append((current_sub, current_sub_lines))
            current_sub = m.group(1)
            current_sub_lines = [line]
        else:
            if current_sub is None:
                continue
            current_sub_lines.append(line)
    if current_sub is not None:
        merged.append((current_sub, current_sub_lines))

    # apply overrides: replace existing or append
    seen: set[str] = set()
    final_groups: list[tuple[str, list[str]]] = []
    for key, lines in merged:
        if key in overrides:
            final_groups.append(
                (key, ["  " + key + ": " + _yaml_inline_string(overrides[key])])
            )
            seen.add(key)
        else:
            final_groups.append((key, lines))
    for key, value in overrides.items():
        if key not in seen:
            final_groups.append((key, ["  " + key + ": " + _yaml_inline_string(value)]))

    out = ["metadata:"]
    for _, lines in final_groups:
        out.extend(lines)
    return out


def _rewrite_ring_tokens(body: str, lookup: dict[str, str]) -> str:
    def sub(match: re.Match[str]) -> str:
        name = match.group(1)
        team = lookup.get(name)
        if not team:
            return match.group(0)
        return "ring-" + team + "-" + name

    return RING_REF_RE.sub(sub, body)


def _rewrite_link_paths(body: str, lookup: dict[str, str], team: str) -> str:
    """Rewrite markdown link paths so they resolve inside the codex skills tree.

    Two transforms:
      1. ../<other-skill>/  ->  ../ring-<team-of-other>-<other-skill>/
         (covers SKILL.md and shared-patterns/* refs to sibling skills)
      2. ../../../../<plug>/skills/shared-patterns/X  ->  ../../<plug>/shared-patterns/X
         (covers default/skills/reviewing-code/reviewers/* and similar cross-plugin refs)
      3. ../../../../skills/shared-patterns/X         ->  ../../shared-patterns/X
         (handles the malformed default/skills/.../dimensions/* link variant
          if it happens to resolve in the mirrored layout)
    The relative-depth math is independent of the file's actual location:
    these transforms preserve directional intent across the renamed codex tree.
    """

    def sub(match: re.Match[str]) -> str:
        path = match.group(1)
        title = match.group(2) or ""
        new_path = _rewrite_one_path(path, lookup, team)
        if new_path == path:
            return match.group(0)
        return "](" + new_path + title + ")"

    return LINK_RE.sub(sub, body)


_SIBLING_SKILL_RE = re.compile(r"^\.\./([a-z0-9][a-z0-9-]*)(/|$)")
_DEEP_CROSS_PLUGIN_RE = re.compile(
    r"^\.\./\.\./\.\./\.\./([a-z0-9][a-z0-9-]+)/skills/(shared-patterns/.+)$"
)
_DEEP_REPO_ROOT_RE = re.compile(r"^\.\./\.\./\.\./\.\./skills/(shared-patterns/.+)$")


def _rewrite_one_path(path: str, lookup: dict[str, str], team: str) -> str:
    # leave absolute, URL-ish, and fragment-only paths alone
    if not path or path.startswith(("http://", "https://", "mailto:", "/", "#")):
        return path

    # split off optional fragment
    if "#" in path:
        base, frag = path.split("#", 1)
        frag = "#" + frag
    else:
        base, frag = path, ""

    # transform 2: ../../../../<plug>/skills/shared-patterns/X
    # Source layout has 4 levels up from <plug>/skills/<skill>/<sub>/<file>:
    #   <file> -> <sub> -> <skill> -> skills -> <plug> -> repo-root, then down.
    # Codex layout reaches the codex skills root in 3 ups from a sub-dir of a
    # renamed skill dir:
    #   <file> -> <sub> -> ring-<plug>-<skill> -> <plug> -> skills-root, then down.
    # Drop the "skills/" segment from the path and remove one level of "../".
    m = _DEEP_CROSS_PLUGIN_RE.match(base)
    if m:
        plug, rest = m.group(1), m.group(2)
        return "../../../" + plug + "/" + rest + frag

    # transform 3: ../../../../skills/shared-patterns/X (repo-root variant,
    # rare/likely broken in source); same one-level reduction.
    m = _DEEP_REPO_ROOT_RE.match(base)
    if m:
        return "../../../" + m.group(1) + frag

    # transform 1: ../<skill>/  -> ../ring-<team>-<skill>/
    m = _SIBLING_SKILL_RE.match(base)
    if m:
        candidate = m.group(1)
        # only rewrite if the candidate is a known skill name in OUR team
        target_team = lookup.get(candidate)
        if target_team == team and candidate not in ("shared-patterns", "docs"):
            new_prefix = "../ring-" + team + "-" + candidate
            return new_prefix + base[len("../" + candidate) :] + frag

    return path


def transform(
    source: Path,
    dest: Path,
    team: str,
    skill_name: str,
    lookup: dict[str, str],
) -> None:
    text = source.read_text(encoding="utf-8")
    fm_lines, body = _split_frontmatter(text, str(source))
    groups = _parse_top_level_keys(fm_lines)

    new_name = "ring-" + team + "-" + skill_name
    metadata_overrides = {
        "ring-component-type": "skill",
        "ring-platform": "codex",
        "ring-plugin": team,
        "ring-source-name": skill_name,
    }

    out_lines: list[str] = ["---"]
    saw_name = False
    saw_description = False
    saw_metadata = False

    for key, lines in groups:
        if key == "name":
            out_lines.append("name: " + _yaml_inline_string(new_name))
            saw_name = True
        elif key == "description":
            desc = _extract_description(lines)
            out_lines.append("description: " + _yaml_inline_string(desc))
            saw_description = True
        elif key == "metadata":
            out_lines.extend(_merge_metadata(lines, metadata_overrides))
            saw_metadata = True
        elif key == "":
            # stray prelude; keep verbatim
            out_lines.extend(lines)
        else:
            out_lines.extend(lines)

    if not saw_name:
        out_lines.append("name: " + _yaml_inline_string(new_name))
    if not saw_description:
        out_lines.append("description: ''")
    if not saw_metadata:
        out_lines.extend(_emit_metadata_block(metadata_overrides))

    out_lines.append("---")
    rewritten_body = _rewrite_ring_tokens(body, lookup)
    rewritten_body = _rewrite_link_paths(rewritten_body, lookup, team)
    output = "\n".join(out_lines) + "\n" + rewritten_body
    if not output.endswith("\n"):
        output += "\n"

    tmp = dest.with_suffix(dest.suffix + ".tmp")
    tmp.parent.mkdir(parents=True, exist_ok=True)
    tmp.write_text(output, encoding="utf-8")
    os.replace(tmp, dest)


def rewrite_accessory(
    source: Path, dest: Path, team: str, lookup: dict[str, str]
) -> None:
    """Apply link-path rewrites to an accessory .md file (no frontmatter transform)."""
    text = source.read_text(encoding="utf-8")
    rewritten = _rewrite_link_paths(text, lookup, team)
    tmp = dest.with_suffix(dest.suffix + ".tmp")
    tmp.parent.mkdir(parents=True, exist_ok=True)
    tmp.write_text(rewritten, encoding="utf-8")
    os.replace(tmp, dest)


def emit_opencode_skill_shim(source: Path, dest: Path) -> None:
    """Emit an opencode slash-command shim for a Ring skill.

    The opencode TUI silently filters commands whose source is "skill" out
    of the `/` autocomplete (see packages/opencode/src/cli/cmd/tui/component/
    prompt/autocomplete.tsx). Skills only appear when also registered as a
    real command-source file. This writes a minimal shim that delegates to
    the skill tool so the user can invoke it via `/ring:<skill-name>`.
    """
    text = source.read_text(encoding="utf-8")
    fm_lines, _ = _split_frontmatter(text, str(source))
    groups = {key: lines for key, lines in _parse_top_level_keys(fm_lines)}

    name_group = groups.get("name")
    if not name_group:
        raise ValueError("missing 'name' in frontmatter: " + str(source))
    # Reuse description-collapsing logic to normalize 'name' (always inline in
    # Ring skills, but the helper handles quoting/whitespace defensively).
    name = _extract_description(name_group)

    description_group = groups.get("description")
    description = _extract_description(description_group) if description_group else ""

    shim = (
        "---\n"
        f"name: {_yaml_inline_string(name)}\n"
        f"description: {_yaml_inline_string(description)}\n"
        "---\n"
        "\n"
        f"Invoke the `{name}` skill via the Skill tool. Arguments: $ARGUMENTS\n"
    )

    tmp = dest.with_suffix(dest.suffix + ".tmp")
    tmp.parent.mkdir(parents=True, exist_ok=True)
    tmp.write_text(shim, encoding="utf-8")
    os.replace(tmp, dest)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--build-lookup", type=Path, default=None)
    p.add_argument("--lookup-out", type=Path, default=None)
    p.add_argument("--source", type=Path, default=None)
    p.add_argument("--dest", type=Path, default=None)
    p.add_argument("--team", default=None)
    p.add_argument("--skill-name", default=None)
    p.add_argument("--lookup", type=Path, default=None)
    p.add_argument(
        "--rewrite-paths",
        action="store_true",
        help="Rewrite link paths in an accessory .md file only",
    )
    p.add_argument(
        "--emit-opencode-skill-shim",
        action="store_true",
        help="Emit an opencode slash-command shim for a Ring skill",
    )
    args = p.parse_args(argv)

    if args.build_lookup is not None:
        if args.lookup_out is None:
            print("--lookup-out required with --build-lookup", file=sys.stderr)
            return 2
        lookup = build_lookup(args.build_lookup)
        args.lookup_out.parent.mkdir(parents=True, exist_ok=True)
        tmp = args.lookup_out.with_suffix(args.lookup_out.suffix + ".tmp")
        tmp.write_text(json.dumps(lookup, sort_keys=True, indent=2), encoding="utf-8")
        os.replace(tmp, args.lookup_out)
        return 0

    if args.rewrite_paths:
        required = (
            ("--source", args.source),
            ("--dest", args.dest),
            ("--team", args.team),
            ("--lookup", args.lookup),
        )
        missing = [n for n, v in required if v is None]
        if missing:
            print("missing required args: " + ", ".join(missing), file=sys.stderr)
            return 2
        lookup = json.loads(args.lookup.read_text(encoding="utf-8"))
        rewrite_accessory(args.source, args.dest, args.team, lookup)
        return 0

    if args.emit_opencode_skill_shim:
        required = (("--source", args.source), ("--dest", args.dest))
        missing = [n for n, v in required if v is None]
        if missing:
            print("missing required args: " + ", ".join(missing), file=sys.stderr)
            return 2
        emit_opencode_skill_shim(args.source, args.dest)
        return 0

    missing = [
        n
        for n, v in (
            ("--source", args.source),
            ("--dest", args.dest),
            ("--team", args.team),
            ("--skill-name", args.skill_name),
            ("--lookup", args.lookup),
        )
        if v is None
    ]
    if missing:
        print("missing required args: " + ", ".join(missing), file=sys.stderr)
        return 2

    lookup = json.loads(args.lookup.read_text(encoding="utf-8"))
    transform(args.source, args.dest, args.team, args.skill_name, lookup)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
