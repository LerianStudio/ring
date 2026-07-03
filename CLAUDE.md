# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **AGENTS.md is a symlink to this file** — edit CLAUDE.md only; changes propagate automatically.

---

## ⛔ CRITICAL RULES (READ FIRST)

### 1. Agent Modification = Mandatory Verification

When creating or modifying any agent in `*/agents/*.md`:

- MUST verify agent has all required sections — see [docs/AGENT_DESIGN.md](docs/AGENT_DESIGN.md#agent-modification-verification-mandatory)
- MUST include positive `<example>` blocks showing correct behavior
- MUST keep agents under 300 lines (implementation) or 200 lines (reviewers)
- MUST use selective standards loading via `index.md` (selective sections only, not monolithic WebFetch).
- If any section is missing → Agent is INCOMPLETE

### 2. Agents are EXECUTORS, Not DECISION-MAKERS

- Agents **VERIFY**, they DO NOT **ASSUME**
- Agents **REPORT** blockers, they DO NOT **SOLVE** ambiguity autonomously
- Agents **FOLLOW** gates, they DO NOT **SKIP** gates
- Agents **ASK** when uncertain, they DO NOT **GUESS**

### 3. Anti-Patterns (MUST NOT do these)

1. **MUST NOT skip ring:using-ring** — mandatory, not optional
2. **MUST NOT run reviewers sequentially** — dispatch in parallel
3. **MUST NOT skip TDD's RED phase** — test must fail before implementation
4. **MUST NOT ignore skill when applicable** — "simple task" is not an excuse
5. **ZERO PANIC POLICY** — `panic()`, `log.Fatal()`, and `Must*` helpers are FORBIDDEN everywhere (including bootstrap/init). Return `(T, error)` instead. Only exception: `regexp.MustCompile()` with compile-time constants.
6. **MUST NOT commit manually** — use `ring:committing-changes` skill
7. **MUST NOT assume compliance** — VERIFY with evidence

### 4. Unified Ring Namespace (MANDATORY)

All Ring components use the unified `ring:` prefix.

- ✅ `ring:code-reviewer`, `ring:backend-go`
- ❌ omitting `ring:` prefix (FORBIDDEN)
- ❌ `ring-default:ring:code-reviewer` (deprecated plugin-specific prefix)

### 5. CLAUDE.md ↔ AGENTS.md Synchronization

**⛔ AGENTS.md IS A SYMLINK TO CLAUDE.md — MUST NOT break:**

- Edit CLAUDE.md — changes automatically appear in AGENTS.md
- MUST NOT delete the AGENTS.md symlink or replace it with a regular file
- If symlink is broken → restore with: `ln -sf CLAUDE.md AGENTS.md`

### 6. Content Duplication Prevention (MUST CHECK)

Before adding any content: **SEARCH FIRST** with `grep -r "keyword" --include="*.md"`.

- If content exists → **REFERENCE it**, DO NOT duplicate
- If adding new content → add to the canonical source

See [docs/WORKFLOWS.md](docs/WORKFLOWS.md#content-duplication-prevention) for canonical source table and shared patterns rule.

### 7. Reviewer-Pool Synchronization (MUST CHECK)

When adding/removing a code review agent in `ring:reviewing-code` pool:

**⛔ SEVEN-FILE UPDATE RULE** (all in same commit) — see [docs/WORKFLOWS.md](docs/WORKFLOWS.md#reviewer-pool-synchronization) for the complete checklist and secondary consumers sweep.

---

## Quick Navigation

| Topic | Location |
|-------|----------|
| Critical Rules | This file (above) |
| Agent verification checklist + example blocks | [docs/AGENT_DESIGN.md](docs/AGENT_DESIGN.md) |
| Frontmatter schema | [docs/FRONTMATTER_SCHEMA.md](docs/FRONTMATTER_SCHEMA.md) |
| Lexical salience, enforcement words, prompt patterns | [docs/PROMPT_ENGINEERING.md](docs/PROMPT_ENGINEERING.md) |
| Reviewer-pool sync, Documentation sync, Content duplication | [docs/WORKFLOWS.md](docs/WORKFLOWS.md) |
| Repository overview, installation, architecture | [README.md](README.md) |
| Architecture diagrams | [ARCHITECTURE.md](ARCHITECTURE.md) |

---

## Architecture (Plugin Summary)

| Plugin           | Path           | Skills | Agents |
| ---------------- | -------------- | ------ | ------ |
| ring-default     | `default/`     | 22     | 2      |
| ring-dev-team    | `dev-team/`    | 35     | 24     |
| ring-pm-team     | `pm-team/`     | 14     | 4      |
| ring-tw-team     | `tw-team/`     | 4      | 3      |

**Total: 75 skills, 33 agents across 4 plugins.** Plugin versions in `.claude-plugin/marketplace.json`.

Each plugin contains: `skills/`, `agents/`, `hooks/`, plus per-harness install manifests `.codex-plugin/`, `.cursor-plugin/`, and `.opencode/` (alongside the marketplace-wide `.claude-plugin/marketplace.json` at repo root). See [README.md](README.md#architecture) for full directory structure.

---

## Key Workflows

| Workflow | Quick Reference |
|----------|-----------------|
| Add skill | Create `*/skills/name/SKILL.md` with frontmatter per [Frontmatter Schema](docs/FRONTMATTER_SCHEMA.md) |
| Add agent | Create `*/agents/name.md` → verify required sections per [Agent Design](docs/AGENT_DESIGN.md) |
| Modify hooks | Edit `*/hooks/hooks.json` → test with `bash */hooks/session-start.sh` |
| Code review | `ring:reviewing-code` dispatches 9 default reviewers plus triggered conditional specialists |
| Pre-dev (small) | `ring:planning-small-features` → 4-gate workflow |
| Pre-dev (large) | `ring:planning-large-features` → 8-gate workflow |
| Dev cycle backend | `ring:running-dev-cycle` → rolling-wave phased cycle (Gate 0 per task, Gate 8/9 per epic, Step 11.5 phase boundary) |
| Dev cycle frontend | `ring:running-dev-cycle-frontend` → rolling-wave phased cycle (Gate 0 per task, Gate 7 per epic, Gate 8 per task, phase boundary) |

See [docs/WORKFLOWS.md](docs/WORKFLOWS.md) for detailed instructions.

---

## Compliance Rules

```text
# TDD compliance (default/skills/test-driven-development/SKILL.md)
- Test file must exist before implementation
- Test must produce failure output (RED)
- Only then write implementation (GREEN)

# Review compliance (default/skills/reviewing-code/SKILL.md)
- All 9 default reviewers must pass; triggered conditional specialists must also pass
- Critical findings = immediate fix required
- Re-run the selected review pool after fixes

# Skill compliance (default/skills/using-ring/SKILL.md)
- Check for applicable skills before any task
- If skill exists for task → MUST use it

# Commit compliance: see default/skills/committing-changes/SKILL.md (canonical source).
- MUST use ring:committing-changes skill for all commits
- MUST NOT write git commit commands manually
```

---

## Session Context

System loads at SessionStart (from `default/` plugin):

1. `default/hooks/session-start.sh` — loads skill quick reference via `generate-skills-ref.py`
2. `ring:using-ring` skill — injected as mandatory workflow

Active branch: `main` | Remote: `github.com/LerianStudio/ring`
