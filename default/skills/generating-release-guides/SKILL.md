---
name: ring:generating-release-guides
description: "Generating an internal Operations-facing update/migration guide from the git diff between two refs, documenting per-change client impact, deploy ordering, monitoring, and rollback notes in English, pt-br, or both. Use when preparing a version release or recording what changed for the Ops team. Runs read-only by default and previews before writing. Skip with no git repo or a trivial single-file change."
---

# Release Guide — Ops Update Guide Generator

## When to use
- Preparing to release a new version
- Need to document what changed between refs
- Creating operational update guide
- Communicating version updates to Ops team

## Skip when
- No git repository available
- Single file change (too small for formal guide)
- Customer-facing release notes only (use simpler template)

## Inputs
- `BASE_REF` (string, required): e.g. `main`, `v1.0.0`
- `TARGET_REF` (string, required): e.g. `HEAD`, `v1.1.0`
- `VERSION` (string, optional): auto-detected from tags if not provided
- `LANGUAGE` (enum, optional, default `en`): `en`, `pt-br`, `both`
- `MODE` (enum, optional, default `STRICT_NO_TOUCH`): `STRICT_NO_TOUCH`, `TEMP_CLONE_FOR_FRESH_REFS`

Produce an **internal** Operations-facing update/migration guide from git diff analysis.

## Safety Modes

**STRICT_NO_TOUCH (default):** Read-only git commands only. Forbidden: `fetch`, `pull`, `push`, `checkout`, `switch`, `reset`, `commit`, `merge`, `rebase`. If ref doesn't exist locally → STOP and suggest TEMP_CLONE mode.

**TEMP_CLONE_FOR_FRESH_REFS:** Clone to temp dir, fetch refs there, run all analysis in clone, cleanup after. Never touches current repo.

## Process

### Step 0: Execution Location
Determine mode. In TEMP_CLONE mode, create isolated clone before proceeding.

### Step 1: Resolve Refs
```bash
git rev-parse --verify BASE_REF^{commit}   # verify both refs exist
git rev-parse --verify TARGET_REF^{commit}
BASE_SHA=$(git rev-parse --short BASE_REF)
TARGET_SHA=$(git rev-parse --short TARGET_REF)
```

### Step 1.5: Version Detection
```bash
# If TARGET_REF is a tag, extract version
# Note: avoid /i flag (GNU-specific); use explicit case alternation for portability (macOS + Linux)
if git tag -l "$TARGET_REF" | grep -q .; then
    AUTO_VERSION=$(echo "$TARGET_REF" | sed -E 's/^[Vv]//;s/^[Rr]elease[-_]?//;s/^[Vv]ersion[-_]?//')
fi
# Priority: explicit VERSION > auto-detected > none (omit from title)
```

### Step 1.6: Commit Log Analysis
```bash
git log --oneline --no-merges BASE_REF...TARGET_REF
git log --pretty=format:"%h %s%n%b" --no-merges BASE_REF...TARGET_REF
```
Parse commit prefixes: `feat:` → Feature, `fix:` → Bug Fix, `refactor:` → Improvement, `breaking:` / `BREAKING CHANGE:` → Breaking.

### Step 2: Produce Diff
```bash
git diff --find-renames --find-copies --stat BASE_REF...TARGET_REF
git diff --find-renames --find-copies BASE_REF...TARGET_REF
```

### Step 3: Build Change Inventory
From diff, identify: endpoints (new/changed/removed), DB schema/migrations, messaging (topics/payloads), config/env vars, auth changes, performance (timeouts/pools), dependency bumps with runtime impact, observability changes.

### Step 4: Write Guide

Use language-appropriate template based on LANGUAGE parameter.

**English title:** `# Ops Update Guide — <repo> — <VERSION> — <TARGET_SHA>`  
**Portuguese title:** `# Guia de Atualização (Ops) — <repo> — <VERSION> — <TARGET_SHA>`  
(Without version: use `BASE_REF → TARGET_REF` instead of `<VERSION>`)

**Header block:** Mode, Comparison, Base SHA, Target SHA, Date, Source.

**Per section format:** `## N. Descriptive Title [Category Emoji]`

| Category | English | Portuguese | Emoji |
|----------|---------|------------|-------|
| Feature | Feature | Funcionalidade | ✨ |
| Bug Fix | Bug Fix | Correção | 🐛 |
| Improvement | Improvement | Melhoria | 🆙 |
| Breaking | Breaking | Breaking | ⚠️ |
| Infrastructure | Infrastructure | Infra | 🔧 |
| Observability | Observability | Observabilidade | 📊 |
| Data | Data | Dados | 💾 |

**Each section contains (in order):**

1. **Contextual narrative** (1-3 paragraphs) — business/operational context, why this changed
2. **What Changed / O que mudou** — bullet list with file:line references
3. **Why It Changed / Por que mudou** — infer from code; if uncertain mark as **ASSUMPTION** + **HOW TO VALIDATE**
4. **Client Impact / Impacto para clientes** — who's affected, risk level (Low/Medium/High)
5. **Required Client Action / Ação necessária do cliente** — "None" or exact steps
6. **Deploy/Upgrade Notes / Notas de deploy/upgrade** — ordering, rolling deploy safety
7. **Post-Deploy Monitoring / O que monitorar pós-deploy** — logs in table format (Level | Message | Meaning), tracing spans in table format
8. **Rollback** — Safety: Safe/Conditional/Not recommended (or pt-br equivalents) + steps

**Special sections when applicable:**
- `### ⚠️ Attention Point` — confusing but expected behaviors
- Backward compatibility table for data/schema changes

### Step 5: Summary Section

**English:** Summary table (Features/Bug Fixes/Improvements/Data counts) + Rollback Compatibility matrix (`| Item | Rollback | Justification |`).

**Portuguese:** `## Resumo` + `## Análise de Compatibilidade de Rollback` with same structure.

### Step 6: Preview Before Saving (MANDATORY)

Show before writing to disk:
- Repository, comparison range, version detected, language(s), mode
- Change summary table (categories + counts)
- Top 5 key changes
- Output file path(s)

**Wait for user confirmation.**

### Step 7: Save File

Output directory: `notes/releases/`

| Has Version? | LANGUAGE | Filename |
|--------------|----------|----------|
| Yes | `en` | `{DATE}_{REPO}-{VERSION}.md` |
| Yes | `pt-br` | `{DATE}_{REPO}-{VERSION}_pt-br.md` |
| No | `en` | `{DATE}_{REPO}-{BASE}-to-{TARGET}.md` |
| No | `pt-br` | `{DATE}_{REPO}-{BASE}-to-{TARGET}_pt-br.md` |
| Any | `both` | Both files above |

Confirm after saving: file path(s), refs/SHAs used, version, language(s).

## Hard Rules

| Rule | Requirement |
|------|-------------|
| No invented changes | MUST: All changes traceable to diff — nothing invented |
| Uncertain info | MUST: Mark uncertain claims as ASSUMPTION + HOW TO VALIDATE |
| Preview required | MUST: Show preview before saving — never skip |
| User confirmation | MUST: Wait for explicit user confirmation before writing files |
| Special change types | MUST: Explicitly document DB migrations, breaking API, feature flags, security/auth, log level changes |

## Blocker Conditions

| Condition | Action |
|-----------|--------|
| Ref cannot be resolved in STRICT mode | STOP — suggest TEMP_CLONE mode |
| Not in git repository | STOP — skill requires git context |
| diff returns empty | STOP — verify refs have commits between them |
| User declines preview | STOP — ask for corrections or abort confirmation |
