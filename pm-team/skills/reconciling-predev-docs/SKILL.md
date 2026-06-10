---
name: ring:reconciling-predev-docs
description: "Reconciling pre-dev artifacts (research.md, prd.md, feature-map.md, trd.md, openapi.yaml, schema file, dependencies.md, plan.md) against each other to surface contradictions and gaps that break implementation, then applying approved corrections before ring:running-dev-cycle. Use after ring:planning-small-features or ring:planning-large-features. Skip for end-user docs (use ring:reviewing-docs), code review (use ring:reviewing-code), or before the docs exist."
---

# Deep Doc Review

## When to use

- Before starting dev-cycle (validate doc quality as a pre-gate)
- After completing pre-dev workflow (ring:planning-small-features or ring:planning-large-features)
- When user requests project documentation review
- After significant changes to reference docs (PRD, TRD, OpenAPI spec, schema, plan)

## Skip when

- Code review needed (use ring:reviewing-code instead)
- Docs do not exist yet (run pre-dev workflow first)
- Reviewing a single simple file (do it directly without the skill)

## Sequence

**Runs before:** ring:running-dev-cycle, ring:writing-plans
**Runs after:** ring:planning-small-features, ring:planning-large-features

## Related

**Complementary:** ring:writing-prds, ring:writing-trds, ring:designing-api-contracts, ring:designing-data-model, ring:writing-plans
**Differentiation:** ring:reviewing-code reviews code. ring:reconciling-predev-docs reviews documentation artifacts against each other.


> Adapted from alexgarzao/optimus (optimus-deep-doc-review)

Deep cross-reference review of project documentation to catch contradictions before they become implementation bugs. Emphasis is on **inconsistencies between docs**, not just intra-doc quality.

## Phase 0: Discover and Load Docs

### Step 0.1: Identify Docs to Review

If user specified files, use those. Otherwise, auto-discover:

**Search locations:**
- `docs/pre-dev/<feature>/` (Ring pre-dev artifacts)
- `docs/` (general project docs)
- Root directory (README, CHANGELOG, ARCHITECTURE)

**Include:** research.md, prd.md, feature-map.md, trd.md, openapi.yaml, schema file (schema.sql / schema.prisma), dependencies.md, plan.md, design-validation.md (if present), coding standards, README, CHANGELOG

**Exclude:** generated files, node_modules, build artifacts, binary files, test fixtures

Present discovered docs list to user before proceeding.

### Step 0.2: User Confirms Scope

Show doc list and ask: "Are there additional documents to include or any to exclude?"

### Step 0.3: Load All Docs

Read each document. Build a cross-reference map: entities, fields, endpoints, and decisions mentioned in each doc. Parse openapi.yaml and the schema file as machine-readable specs (paths, operations, components; tables, columns, types) — not prose.

## Phase 1: Cross-Reference Analysis

For each pair of docs that share entities or concepts, check for contradictions:

| Cross-Reference | What to Check |
|----------------|---------------|
| research.md ↔ TRD | Chosen architecture traces to research findings; rejected alternatives not silently reintroduced |
| PRD ↔ TRD | TRD covers all PRD requirements; TRD doesn't add new requirements; NFRs align |
| PRD ↔ feature-map.md | Every in-scope PRD feature appears in the map; `## Phases` cover full PRD scope (Large) |
| TRD ↔ openapi.yaml | Paths/operations match TRD component interfaces and data flow; spec is valid OpenAPI 3.1 |
| openapi.yaml ↔ schema file | Request/response schema fields exist as columns; names consistent; types compatible (machine-readable cross-check) |
| TRD ↔ schema file | All TRD entities have tables/models; relationships and constraints match the architecture |
| schema file ↔ plan.md | All entities have creation/migration tasks; relationships implemented |
| TRD ↔ dependencies.md | All TRD components have explicit pinned dependencies; no undeclared tech |
| feature-map.md ↔ plan.md | plan.md phases mirror feature-map `## Phases` one-to-one (Large) |
| PRD ↔ plan.md | Every PRD requirement covered by at least one epic/task; acceptance criteria traceable |
| design-validation.md ↔ TRD/plan.md (optional, if present) | UI surfaces honor the standalone UX verdict; flagged gaps have tasks |

## Phase 2: Intra-Document Quality

For each document:

| Check | Description |
|-------|-------------|
| Completeness | Required sections present; no "TBD" or placeholder content |
| Internal consistency | Same entity/field named the same way throughout |
| Format compliance | Gate-specific format requirements met |
| Clarity | No ambiguous language; success criteria testable |

## Phase 3: Findings Report

Classify findings:

| Severity | Criteria | Action |
|----------|----------|--------|
| **CRITICAL** | Contradiction that will cause implementation failure | MUST fix before dev-cycle |
| **HIGH** | Missing information that blocks a specific task | Should fix before dev-cycle |
| **MEDIUM** | Inconsistency that will cause confusion | Fix preferred |
| **LOW** | Style, formatting, minor clarity | Optional |

Present findings to user with:
- Finding description
- Documents affected
- Specific location (doc → section → line reference)
- Suggested correction

## Phase 4: Apply Approved Corrections

For each finding user approves:
1. Make the correction directly in the affected document
2. Mark finding as FIXED
3. Continue to next finding

## Phase 5: Summary

```markdown
# Deep Doc Review Summary

**Date:** {YYYY-MM-DD}
**Documents Reviewed:** {N}
**Cross-References Checked:** {N pairs}

## Finding Summary
| Severity | Found | Fixed | Skipped |
|----------|-------|-------|---------|
| CRITICAL | N | N | N |
| HIGH | N | N | N |
| MEDIUM | N | N | N |
| LOW | N | N | N |

## Status
✅ CLEARED — Ready for ring:running-dev-cycle
⚠️ ISSUES REMAIN — {N} unfixed critical/high findings
```

**Output:** `docs/pre-dev/{feature}/doc-review-{date}.md`
