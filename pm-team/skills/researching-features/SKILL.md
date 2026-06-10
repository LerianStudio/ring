---
name: ring:researching-features
description: "Researching the product/feature in depth before any planning document is written: the product itself, technical approach, third-party integrations, prior art, and existing codebase grounding (file:line refs) via parallel repo/web/docs agents using firecrawl and exa. Gate 0 of ring:using-pm-team (both tracks); runs before ring:writing-prds. Use before pre-dev planning a new feature or modification. Skip for trivial changes or when a recent research.md already exists."
---

# Pre-Dev Research Skill (Gate 0)

## When to use

- Before any pre-dev workflow (Gate 0 of both tracks)
- When planning new features or modifications
- Invoked by /ring:planning-large-features and /ring:planning-small-features

## Skip when

- Trivial changes that don't need planning
- Research already completed (research.md exists and is recent)

## Sequence

**Runs before:** ring:writing-prds (Gate 1)

## Related

**Complementary:** ring:writing-prds, ring:writing-trds


Gathers deep technical/product research BEFORE writing planning documents, ensuring PRDs and TRDs are grounded in codebase reality, prior art, and authoritative technical sources.

**Scope is technical/product only.** Research covers: the product/feature itself (what it is, how comparable products solve it), technical approach, third-party integrations, prior art, and existing codebase patterns. **ZERO business content** — no market analysis, no personas, no user research, no go-to-market.

## Step 1: Determine Research Mode

| Mode | When | Agent Priority |
|------|------|----------------|
| **greenfield** | New capability (no existing patterns) | Web research primary |
| **modification** | Extending existing functionality | Codebase research primary |
| **integration** | Connecting external systems | All agents equally weighted |

If unclear, ask: "Is this (1) Greenfield, (2) Modification, or (3) Integration?"

## Step 2: Dispatch 3 Agents in Parallel

Single message, 3 Task calls:

| Agent | Focus | Mode Priority |
|-------|-------|---------------|
| `ring:repo-researcher` | Codebase patterns for [feature]; search docs/solutions/ knowledge base; return file:line refs | PRIMARY in modification |
| `ring:web-researcher` | Technical approach, prior art, and best practices for [feature]; use firecrawl (search/scrape/crawl) + exa; return URLs | PRIMARY in greenfield |
| `ring:docs-researcher` | Tech stack docs for [feature]; detect versions from manifests; firecrawl scrape/crawl of official docs + exa search; return version constraints | PRIMARY in integration |

Web research tooling is explicit: agents MUST use **firecrawl** (`firecrawl_search`, `firecrawl_scrape`, `firecrawl_crawl`) and **exa** for discovery and source retrieval — not memory.

## Step 2.5: Handle Topology Configuration

If `TopologyConfig` provided (from command's topology discovery), persist in research.md frontmatter:

```yaml
---
feature: {feature-name}
gate: 0
date: {YYYY-MM-DD}
research_mode: greenfield | modification | integration
agents_dispatched: 3
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
  api_pattern: bff | none
---
```

## Step 3: Synthesize Results

Compile all 3 agents' findings into `docs/pre-dev/{feature}/research.md`.

**Required sections:**

```markdown
# Research: {Feature Name}

## Codebase Patterns
[From repo-researcher — existing patterns with file:line references]

## Technical Approach & Prior Art
[From web-researcher — how comparable products/projects solve this, candidate approaches, third-party integrations, with URLs]

## Framework Constraints
[From docs-researcher — version constraints, compatibility notes]

## Key Findings
[Top 5-10 insights that will inform PRD/TRD decisions]

## Risks & Unknowns
[Things that need more investigation before PRD/TRD]
```

## Output

**File:** `docs/pre-dev/{feature}/research.md` with topology frontmatter (if provided)

After research.md complete: invoke `ring:writing-prds` (Gate 1).
