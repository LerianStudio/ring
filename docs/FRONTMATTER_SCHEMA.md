# Frontmatter Schema Reference

Canonical source of truth for YAML frontmatter fields in Ring skills, commands, and agents. The validator script (`default/hooks/validate-frontmatter.py`) checks against this schema.

All frontmatter uses standard YAML between `---` delimiters at the top of each `.md` file. The session-start hook (`default/hooks/generate-skills-ref.py`) parses skill frontmatter at load time to build the skills quick reference.

---

## Skills (`SKILL.md`)

Skills live in `{plugin}/skills/{name}/SKILL.md`.

### Required Fields

| Field | Type | Parsed by Hooks | Description |
|-------|------|-----------------|-------------|
| `name` | string | YES | Skill identifier. MUST use `ring:` prefix (e.g., `ring:brainstorm`) |
| `description` | string | YES | What the skill does -- method or technique. Supports block scalar (`\|`) |

### Recommended Fields

Parsed by hooks and used for skill discovery/routing. Skills should define these.

| Field | Type | Parsed by Hooks | Description |
|-------|------|-----------------|-------------|
| `trigger` | string | YES | WHEN to use this skill -- primary decision field. Replaces deprecated `when_to_use` |
| `skip_when` | string | YES | WHEN NOT to use -- differentiates from similar skills |
| `NOT_skip_when` | string | YES | Override for `skip_when` -- cases where the skill MUST still be used despite skip signals |
| `prerequisites` | string/list | YES | What must be true before using this skill (e.g., test framework installed) |
| `verification` | string | YES | How to verify the skill's gate passed (e.g., coverage thresholds, build success) |

### Optional Fields (Parsed by Hooks)

| Field | Type | Parsed by Hooks | Description |
|-------|------|-----------------|-------------|
| `when_to_use` | string | YES | **DEPRECATED** -- use `trigger` instead. Kept for backward compatibility; hook falls back to this if `trigger` is absent |
| `sequence.after` | list | YES | Skills that should come before this one (e.g., `[ring:dev-implementation]`) |
| `sequence.before` | list | YES | Skills that typically follow this one (e.g., `[ring:write-plan]`) |
| `related.similar` | list | YES | Skills that seem similar but differ (helps differentiation) |
| `related.complementary` | list | YES | Skills that pair well with this one |

### Optional Fields (Not Parsed by Hooks)

These are defined in skill frontmatter but not read by `generate-skills-ref.py`. They serve as structured metadata for agents and validation tooling.

| Field | Type | Description |
|-------|------|-------------|
| `compliance_rules` | list of objects | Validation rules with `id`, `description`, `check_type`, `pattern`, `severity`, `failure_message` |
| `composition` | object | How the skill works with others: `works_well_with`, `conflicts_with`, `typical_workflow` |
| `input_schema` | object | Expected input context: `required` and `optional` fields with `name`, `type`, `description` |
| `output_schema` | object | Expected output format: `format` (always `"markdown"`), `required_sections` with `name`, `pattern`, `required` |

### Explicitly NOT Valid for Skills

| Field | Reason |
|-------|--------|
| `version` | Use git history for versioning |
| `allowed-tools` | Define tool access in the skill body, not frontmatter |
| `examples` | Include examples in the skill body |
| `category` | Not part of the schema -- categories are derived by hooks from directory name patterns |
| `tier` | Not part of the schema |
| `slug` | Not part of the schema |
| `user_invocable` | Not part of the schema -- invocability is implicit from skill structure |
| `title` | Not part of the schema -- use `name` |
| `type` | Not part of the schema for skills -- `type` is an agent-only field |
| `role` | Not part of the schema -- define role context in the skill body |
| `dependencies` | Not part of the schema -- use `prerequisites` for preconditions |
| `author` | Not part of the schema -- use git history |
| `license` | Not part of the schema -- repo-level license applies |
| `compatibility` | Not part of the schema |
| `metadata` | Not part of the schema -- use specific top-level fields instead |
| `agent_selection` | Not part of the schema -- define agent routing in the skill body |
| `tdd_policy` | Not part of the schema -- TDD is enforced by workflow, not frontmatter |
| `research_modes` | Not part of the schema -- define modes in the skill body |
| `trigger_when` | Not part of the schema -- use `trigger` |

---

## Commands (Removed)

Commands have been removed from Ring. All workflows are now invoked via skills.

---

## Agents (`*.md` in `agents/`)

Agents live in `{plugin}/agents/{name}.md`.

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Agent identifier. MUST use `ring:` prefix (e.g., `ring:code-reviewer`) |
| `description` | string | What the agent does -- role and scope |
| `type` | enum | Agent classification. Values in use: `specialist`, `reviewer`, `orchestrator`, `planning`, `exploration`, `analyst`, `calculator` |
| `output_schema` | object | Defines required output sections (see sub-fields below) |

**`output_schema` sub-fields:**

| Sub-field | Type | Required | Description |
|-----------|------|----------|-------------|
| `output_schema.format` | string | YES | Always `"markdown"` |
| `output_schema.required_sections` | list | YES | List of section definitions |
| `output_schema.required_sections[].name` | string | YES | Section display name |
| `output_schema.required_sections[].pattern` | string | YES | Regex pattern to match the section heading |
| `output_schema.required_sections[].required` | boolean | YES | Whether the section is mandatory |
| `output_schema.required_sections[].description` | string | no | When/why this section is needed |
| `output_schema.required_sections[].required_when` | object | no | Conditional requirement (e.g., `invocation_context`, `prompt_contains`) |
| `output_schema.verdict_values` | list | no | Valid verdict values for reviewer agents (e.g., `["PASS", "FAIL", "NEEDS_DISCUSSION"]`) |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `input_schema` | object | Expected input context with `required` and `optional` sub-fields, each a list of `{name, type, description}` |

### Explicitly NOT Valid for Agents

| Field | Reason |
|-------|--------|
| `version` | Use git history |
| `color` | Not part of the schema |
| `project_rules_integration` | Not part of the schema |
| `allowed-tools` | Define tool access in the agent body, not frontmatter |
| `tools` | Not part of the schema -- define tool access in the agent body, not frontmatter |

---

## Deprecated Fields

| Deprecated Field | Replaced By | Migration |
|------------------|-------------|-----------|
| `when_to_use` | `trigger` | Rename field. Hook falls back to `when_to_use` if `trigger` is absent, but new skills MUST use `trigger` |
| `prerequisite` (singular) | `prerequisites` (plural) | Rename to plural form |
| `arguments` | `argument-hint` | Use `argument-hint` for syntax hint; document full argument details in the command body |

---

## Validation

**Validator script:** `default/hooks/validate-frontmatter.py`

| Condition | Validator Behavior |
|-----------|--------------------|
| Missing required field (`name`, `description`) | Error |
| Unknown/unrecognized field | Warning |
| Deprecated field present | Warning with migration guidance |
| Skill missing `trigger` | Warning (recommended field) |
| Agent missing `type` or `output_schema` | Error |

**Parser script:** `default/hooks/generate-skills-ref.py`

- Tries `pyyaml` first, falls back to regex parser
- Extracts first meaningful line from block scalars for quick reference display
- Groups skills into categories based on directory name patterns
- Handles backward compatibility: `when_to_use` -> `trigger` -> `description` fallback chain

---

## Related Documents

- [CLAUDE.md](../CLAUDE.md) -- Main project instructions
- [AGENT_DESIGN.md](AGENT_DESIGN.md) -- Agent output schema archetypes and standards compliance
- [WORKFLOWS.md](WORKFLOWS.md) -- How to add skills, agents, and commands
- [PROMPT_ENGINEERING.md](PROMPT_ENGINEERING.md) -- Language patterns for agent prompts
