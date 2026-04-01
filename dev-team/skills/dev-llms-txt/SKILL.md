---
name: ring:dev-llms-txt
description: |
  Generates or audits llms.txt files for Lerian repositories following the llmstxt.org
  specification. Creates LLM-friendly entry points that help AI agents, coding assistants,
  and chat models understand a project quickly without parsing full HTML docs.
  Also generates CLAUDE.md / AGENTS.md when missing.

trigger: |
  - Creating a new llms.txt for a repository
  - Auditing an existing llms.txt for completeness
  - Generating CLAUDE.md or AGENTS.md for AI coding agents
  - Improving AI readability of a repository

related:
  complementary: [ring:dev-cycle, ring:dev-implementation]

input_schema:
  required:
    - name: repo_path
      type: string
      description: "Path to the repository root"
  optional:
    - name: mode
      type: string
      enum: [create, audit, full]
      default: full
      description: "create = generate missing files, audit = check existing, full = both"
    - name: repo_url
      type: string
      description: "Public URL of the repository (e.g., https://github.com/LerianStudio/midaz)"
    - name: docs_url
      type: string
      description: "Public documentation URL if separate from repo"

output_schema:
  format: markdown
  required_sections:
    - name: "Audit Results"
      pattern: "^## Audit Results"
      required: true
    - name: "Files Generated"
      pattern: "^## Files Generated"
      required: true
    - name: "Next Steps"
      pattern: "^## Next Steps"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, PARTIAL, FAIL]
    - name: files_created
      type: integer
    - name: files_audited
      type: integer
---

# llms.txt Generator

## Overview

This skill generates AI-friendly entry point files for Lerian repositories:

- **llms.txt** — universal LLM entry point (llmstxt.org spec)
- **CLAUDE.md** — instructions for Claude Code / Anthropic coding agents
- **AGENTS.md** — instructions for any AI coding agent (OpenCode, Codex, Cursor, etc.)

These files solve different problems:

| File | Audience | Purpose |
|------|----------|---------|
| llms.txt | Any LLM (ChatGPT, Gemini, Perplexity, coding agents) | Structured overview: what the project is, key docs, API refs |
| CLAUDE.md | Claude Code, Anthropic agents | How to work in the codebase: build, test, lint, conventions |
| AGENTS.md | Any coding agent | Same as CLAUDE.md but vendor-neutral |

## Step 1: Analyze Repository

Scan the repository to gather context:

```text
1. Read README.md — project name, description, purpose
2. Read CONTRIBUTING.md — build, test, lint instructions (if exists)
3. Read Makefile / package.json / go.mod — build system, language, dependencies
4. Scan /docs/ or /documentation/ — available documentation
5. Scan /api/ or OpenAPI specs — API surface
6. Read existing llms.txt / CLAUDE.md / AGENTS.md (if mode=audit)
7. Identify: language, architecture pattern (DDD, hexagonal, etc.), test framework
```

## Step 2: Generate llms.txt

MUST follow the llmstxt.org specification exactly:

```markdown
# {Project Name}

> {One-line description. Key information: language, what it does, license.}

{Optional paragraph with more detail — architecture, key concepts, domain terminology
that an LLM needs to understand to work with this project.}

## Docs

- [{Doc title}]({url}): {Brief description of what this doc covers}
- [{Doc title}]({url}): {Brief description}

## API Reference

- [{API name}]({url}): {What this API covers}

## Code

- [{Key module}]({path or url}): {What this module does}
- [{Key module}]({path or url}): {What this module does}

## Optional

- [{Secondary resource}]({url}): {Description}
```

### llms.txt Rules

| Rule | Detail |
|------|--------|
| H1 is project name | REQUIRED. Only one H1. |
| Blockquote is summary | REQUIRED. One paragraph, concise. Must include language and license. |
| Sections are H2 | Each H2 contains a list of links with optional descriptions |
| Links are markdown | `[title](url): description` format |
| Optional section | URLs here can be skipped for shorter context windows |
| No H3+ headings | Spec only allows H1, H2, and content between them |
| File must be in repo root | `/llms.txt` path |
| Keep it concise | Target: fits in ~2K tokens. Not a full docs dump. |

### Content Selection

MUST include:
- Project name and what it does (H1 + blockquote)
- Architecture overview (if the project has a specific pattern like DDD, hexagonal)
- Key domain concepts (for domain-heavy projects like ledgers, reconciliation)
- Links to: README, CONTRIBUTING (if exists), API docs, key source modules

MUST NOT include:
- Internal-only documentation links
- CI/CD pipeline details
- Issue tracker links
- Full dependency lists
- Changelog or release notes

## Step 3: Generate CLAUDE.md

CLAUDE.md is read by Claude Code at session start. It must be actionable:

```markdown
# {Project Name}

## Quick Start

{How to build and run locally — exact commands}

## Testing

{How to run tests — exact commands, including single-test commands}

## Linting & Formatting

{Lint/format commands. CI expectations.}

## Architecture

{Brief architecture description: layers, key directories, patterns used}

## Key Conventions

{Naming conventions, error handling patterns, logging patterns, etc.}

## Common Pitfalls

{Things that trip up new contributors or AI agents}
```

### CLAUDE.md Rules

| Rule | Detail |
|------|--------|
| Commands must be copy-pasteable | No placeholders, no "run your test framework" |
| Architecture must name directories | "Business logic in `/internal/domain/`" not "business logic layer" |
| Conventions must have examples | "Functions use camelCase: `processTransaction`" not "use camelCase" |
| Keep it under 3K tokens | Agent context is expensive — be dense, not verbose |

## Step 4: Generate AGENTS.md

AGENTS.md is identical in structure to CLAUDE.md but uses vendor-neutral language.
If the project already has CLAUDE.md, AGENTS.md can reference it:

```markdown
# {Project Name} — Agent Instructions

See [CLAUDE.md](./CLAUDE.md) for full development instructions.

## Additional Notes

{Any agent-specific notes not in CLAUDE.md}
```

If no CLAUDE.md exists, AGENTS.md follows the same template as Step 3.

## Step 5: Audit Existing Files

When mode=audit or mode=full, check existing files against these criteria:

### llms.txt Audit

| Check | Pass Criteria |
|-------|---------------|
| Exists at repo root | `/llms.txt` present |
| Has H1 | Project name as H1 |
| Has blockquote summary | `>` block after H1 |
| Has at least one H2 section | With linked resources |
| Links are valid | URLs resolve (non-404) |
| Concise | Under ~2K tokens |
| Accurate | Description matches current state of the project |

### CLAUDE.md / AGENTS.md Audit

| Check | Pass Criteria |
|-------|---------------|
| Exists at repo root | File present |
| Build commands work | Commands are valid for current build system |
| Test commands work | Test commands match current test framework |
| Architecture matches | Directory references match actual structure |
| No stale references | No references to removed files/modules |

## Step 6: Generate Report

```markdown
## Audit Results

**Repository:** {name}
**Result:** [PASS|PARTIAL|FAIL]

| File | Status | Issues |
|------|--------|--------|
| llms.txt | [EXISTS/CREATED/MISSING] | {issues or "None"} |
| CLAUDE.md | [EXISTS/CREATED/MISSING] | {issues or "None"} |
| AGENTS.md | [EXISTS/CREATED/MISSING] | {issues or "None"} |

## Files Generated

| File | Action | Size |
|------|--------|------|
| llms.txt | [CREATED/UPDATED/UNCHANGED] | {tokens} |
| CLAUDE.md | [CREATED/UPDATED/UNCHANGED] | {tokens} |
| AGENTS.md | [CREATED/UPDATED/UNCHANGED] | {tokens} |

## Next Steps

{What remains to be done — PRs to open, links to verify, docs to write}
```
