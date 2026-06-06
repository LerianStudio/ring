# Frontmatter Schema Reference

Canonical source of truth for YAML frontmatter fields in Ring skills, agents, and commands. Aligned with the Anthropic-canonical loader: anything outside the fields documented here is silently ignored at load time.

The validator (`default/hooks/validate-frontmatter.py`) enforces this schema. The session-start hook (`default/hooks/generate-skills-ref.py`) parses skill `name` and `description` to build the skills quick reference.

---

## Skills (`SKILL.md`)

Skills live in `{plugin}/skills/{name}/SKILL.md`.

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Skill identifier. MUST use `ring:` prefix (e.g., `ring:reviewing-code`). Lerian convention is mandatory per CLAUDE.md. |
| `description` | string | WHAT the skill does + WHEN to invoke + WHEN to skip, condensed. Anthropic loader caps `description` at **1,536 characters**. Target ≤500 chars to leave headroom. |

### Optional Fields

Include only if the skill actually uses them.

| Field | Type | Description |
|-------|------|-------------|
| `argument-hint` | string | Short syntax hint shown in the skill picker |
| `allowed-tools` | list | Restricts tool access for the skill invocation |
| `disable-model-invocation` | bool | If true, skill must be explicitly invoked (not auto-selected) |
| `user-invocable` | bool | Marks skills the user can invoke directly via slash command |
| `paths` | list | Path globs scoping the skill to specific files |
| `model` | string | Override model for the skill |

### Removed Fields

Stripped during the 2026-05 Anthropic-canonical refactor. The loader silently ignores them; the validator no longer warns about their absence.

| Field | Migrated To |
|-------|-------------|
| `trigger` | `## When to use` body section |
| `skip_when` | `## Skip when` body section |
| `NOT_skip_when` | `## Skip when` body section (as exception bullets) |
| `prerequisites` | `## Prerequisites` body section |
| `verification` | Body content (typically inside `## Skip when` or step-level checks) |
| `sequence` | `## Sequence` body section |
| `related` | `## Related` body section |
| `type` | Removed entirely (was skill-irrelevant) |
| `tags` | Removed entirely |
| `when_to_use` | Folded into `description` |
| `output_schema` / `input_schema` | Removed (skill-level schemas were unused by the loader) |

---

## Agents (`agents/*.md`)

Agents live in `{plugin}/agents/{name}.md`.

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Agent identifier. MUST use `ring:` prefix (e.g., `ring:code-reviewer`) |
| `description` | string | What the agent does — role and scope |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `model` | string | Override model for this agent |
| `tools` | list | Restricts tool access for the agent invocation |
| `color` | string | Display color in the agent picker |

### Removed Fields

| Field | Notes |
|-------|-------|
| `type` | Was used to label specialist/reviewer/orchestrator. Silently ignored by the loader; removed in the 2026-05 refactor. Express role in `description` instead. |

---

## Commands (`commands/*.md`)

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Command identifier. MUST use `ring:` prefix (e.g., `ring:my-command`) |
| `description` | string | What the command does |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `argument-hint` | string | Short syntax hint |
| `allowed-tools` | list | Restricts tool access |
| `model` | string | Override model |

---

## Validator

`default/hooks/validate-frontmatter.py` checks:

| Condition | Behavior |
|-----------|----------|
| Missing required field (`name`, `description`) | Error |
| Skill `name` missing `ring:` prefix | Error |
| Unknown field | Warning |

The validator was simplified in the 2026-05 refactor to align with Anthropic-canonical fields only — it no longer warns about missing `trigger`/`skip_when`.

---

## Generator

`default/hooks/generate-skills-ref.py` parses skill frontmatter (`name` + `description` only post-refactor) to build the SessionStart skills quick reference. It groups skills into categories from directory name patterns.

---

## Body Section Convention

Trigger-style content that used to live in frontmatter now lives in body markdown sections, immediately after the H1, in this canonical order (omit any section without source content):

```markdown
## When to use
- {bullets describing trigger conditions}

## Skip when
- {bullets describing exclusions}

## Sequence
**Runs before:** ring:foo, ring:bar
**Runs after:** ring:baz

## Related
**Complementary:** ring:x
**Similar:** ring:y
**Skills orchestrated:**
- ring:z

## Prerequisites
{content}
```

If you want to express WHEN/WHEN-NOT/SEQUENCE/RELATED/PREREQUISITE semantics in a skill, put them here — not in frontmatter.

---

## Related Documents

- [CLAUDE.md](../CLAUDE.md) — Main project instructions
- [AGENT_DESIGN.md](AGENT_DESIGN.md) — Agent design and verification checklist
- [WORKFLOWS.md](WORKFLOWS.md) — How to add skills, agents, and commands
- [PROMPT_ENGINEERING.md](PROMPT_ENGINEERING.md) — Language patterns for agent prompts
