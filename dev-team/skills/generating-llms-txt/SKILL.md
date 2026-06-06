---
name: ring:dev-llms-txt
description: |
  Generates or audits llms.txt files for Lerian repositories following the llmstxt.org
  specification. Creates LLM-friendly entry points for AI agents and coding assistants.
  Also generates CLAUDE.md / AGENTS.md when missing.
---

# LLMs.txt & AI Documentation Generator

## When to use
- Creating a new llms.txt for a repository
- Auditing an existing llms.txt for completeness
- Generating CLAUDE.md or AGENTS.md for AI coding agents
- Improving AI readability of a repository

## Skip when
- Repository already has a complete, up-to-date llms.txt
- Task is code implementation with no documentation scope
- Repository is private/internal with no LLM discoverability need

## Related
**Complementary:** ring:dev-cycle, ring:dev-implementation


Generates `llms.txt`, `CLAUDE.md`, and `AGENTS.md` for Lerian repositories.

## Step 1: Analyze Repository

```
1. Read README.md — project name, description, purpose
2. Read CONTRIBUTING.md — build, test, lint instructions (if exists)
3. Read Makefile / package.json / go.mod — build system, language, dependencies
4. Scan /docs/ — available documentation
5. Scan /api/ or OpenAPI specs — API surface
6. Read existing llms.txt / CLAUDE.md / AGENTS.md (if mode=audit)
7. Identify: language, architecture, test framework
```

## Step 2: Generate llms.txt

Follow llmstxt.org specification exactly:

```markdown
# {Project Name}

> {One-line description: language, what it does, license.}

{Optional: architecture, key concepts, domain terminology needed to work with this project.}

## Docs

- [{Doc title}]({url}): {Brief description}

## API Reference

- [{API name}]({url}): {What this covers}

## Code

- [{Key module}]({path}): {What this module does}

## Optional

- [{Secondary resource}]({url}): {Description}
```

**Rules:**
- One H1 (project name), required
- Blockquote summary — required, include language and license
- H2 sections only (no H3+)
- Links: `[title](url): description` format
- File in repo root: `/llms.txt`
- Target: fits in ~2K tokens

**MUST include:** name, architecture overview, key domain concepts, links to README/CONTRIBUTING/API docs/key modules.

**MUST NOT include:** internal-only docs, CI/CD details, issue tracker, full dependency lists, changelog.

## Step 3: Generate CLAUDE.md

Read by Claude Code at session start. Must be actionable with exact commands:

```markdown
# {Project Name}

## Quick Start
{How to build and run locally — exact copy-pasteable commands}

## Testing
{How to run tests — exact commands including single-test}

## Linting & Formatting
{Lint/format commands, CI expectations}

## Architecture
{Brief: layers, key directories, patterns}
e.g., "Business logic in /internal/domain/, HTTP handlers in /internal/adapters/http/"

## Key Conventions
{Naming conventions, error handling, logging patterns with examples}
e.g., "Functions use camelCase: processTransaction()"

## Common Pitfalls
{What trips up new contributors or AI agents}
```

**Rules:**
- Commands must be copy-pasteable (no placeholders)
- Architecture must name actual directories
- Conventions must have inline examples
- Keep under 3K tokens

## Step 4: Generate AGENTS.md

Same structure as CLAUDE.md but vendor-neutral language.
If CLAUDE.md exists: `AGENTS.md` can reference it:

```markdown
# {Project Name} — AI Agent Context

See [CLAUDE.md](./CLAUDE.md) for complete setup and conventions.

## Additional Notes
{Any agent-specific guidance not in CLAUDE.md}
```

## Audit Mode (mode=audit)

For existing files, check:

| Check | Pass Condition |
|-------|----------------|
| llms.txt has H1 + blockquote | Required fields present |
| All links resolve | No 404s |
| Spec compliance | No H3+, no non-list content in sections |
| CLAUDE.md commands valid | All commands runnable, no stale references |
| Under token budget | llms.txt < 2K tokens, CLAUDE.md < 3K tokens |

## Output

```markdown
## LLM Documentation Report

Mode: create | audit | full
Repository: {repo_path}

### Files Generated/Updated
| File | Action | Tokens |
|------|--------|--------|
| llms.txt | Created/Updated/OK | ~{N} |
| CLAUDE.md | Created/Updated/OK | ~{N} |
| AGENTS.md | Created/Updated/OK | ~{N} |

### Audit Results (audit mode)
| Check | Status | Details |
|-------|--------|---------|
```
