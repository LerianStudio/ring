---
name: ring:researching-features
description: "Researching codebase patterns, external best practices, framework constraints, and UX/product context into research.md (with file:line refs) before any planning document is written. Gate 0 of ring:using-pm-team; runs parallel discovery and selects a greenfield/modification/integration mode. Use before pre-dev planning a new feature or modification. Skip for trivial changes or when a recent research.md already exists."
---

# Pre-Dev Research Skill (Gate 0)

## When to use

- Before any pre-dev workflow (Gate 0)
- When planning new features or modifications
- Invoked by /ring:planning-large-features and /ring:planning-small-features

## Skip when

- Trivial changes that don't need planning
- Research already completed (research.md exists and is recent)

## Sequence

**Runs before:** ring:writing-prds, ring:mapping-feature-relationships

## Related

**Complementary:** ring:writing-prds, ring:writing-trds


Gathers comprehensive research BEFORE writing planning documents, ensuring PRDs and TRDs are grounded in codebase reality and industry best practices.

## Step 1: Determine Research Mode

| Mode | When | Agent Priority |
|------|------|----------------|
| **greenfield** | New capability (no existing patterns) | Web research primary |
| **modification** | Extending existing functionality | Codebase research primary |
| **integration** | Connecting external systems | All agents equally weighted |

If unclear, ask: "Is this (1) Greenfield, (2) Modification, or (3) Integration?"

## Step 2: Dispatch 4 Agents in Parallel

Single message, 4 Task calls:

| Agent | Focus | Mode Priority |
|-------|-------|---------------|
| `ring:repo-researcher` | Codebase patterns for [feature]; search docs/solutions/ knowledge base; return file:line refs | PRIMARY in modification |
| `ring:web-researcher` | External best practices for [feature]; use Context7 + WebSearch; return URLs | PRIMARY in greenfield |
| `ring:docs-researcher` | Tech stack docs for [feature]; detect versions from manifests; use Context7; return version constraints | PRIMARY in integration |
| `ring:product-designer` | User problem validation, personas, competitive UX analysis, design constraints; mode: `ux-research` | PRIMARY in greenfield |

## Step 2.5: Handle Topology Configuration

If `TopologyConfig` provided (from command's topology discovery), persist in research.md frontmatter:

```yaml
---
feature: {feature-name}
gate: 0
date: {YYYY-MM-DD}
research_mode: greenfield | modification | integration
agents_dispatched: 4
topology:
  scope: fullstack | backend-only | frontend-only
  structure: single-repo | monorepo | multi-repo
  modules:
    backend:
      path: {path}
      language: golang | typescript
    frontend:
      path: {path}
      framework: nextjs | react | vue
  doc_organization: unified | per-module
  api_pattern: direct | bff | other
---
```

## Step 3: Synthesize Results

Compile all 4 agents' findings into `docs/pre-dev/{feature}/research.md`.

**Required sections:**

```markdown
# Research: {Feature Name}

## Codebase Patterns
[From repo-researcher — existing patterns with file:line references]

## Best Practices
[From web-researcher — external references with URLs]

## Framework Constraints
[From docs-researcher — version constraints, compatibility notes]

## User Research
[From product-designer — personas, problem validation, competitive analysis, design constraints]

## Key Findings
[Top 5-10 insights that will inform PRD/TRD decisions]

## Risks & Unknowns
[Things that need more investigation before PRD/TRD]
```

## Output

**File:** `docs/pre-dev/{feature}/research.md` with topology frontmatter (if provided)

After research.md complete: invoke `ring:writing-prds` (Gate 1).
