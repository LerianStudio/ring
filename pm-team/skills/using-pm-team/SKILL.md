---
name: ring:using-pm-team
description: "Routing feature planning through the ring-pm-team pre-dev workflow: choosing the Small Track (4 gates, <2 days) or Large Track (8 gates, 2+ days) and entering via ring:planning-small-features or ring:planning-large-features. Indexes pre-dev gates, standalone utilities, and research agents. Use when starting a feature that needs systematic planning. Skip for quick exploratory work, known-solution bug fixes, or trivial changes."
---

# Using Ring PM-Team: Pre-Dev Workflow

## When to use

- Starting any feature implementation
- Need systematic planning before coding
- User requests "plan a feature"

## Skip when

- Quick exploratory work → skip formal planning
- Bug fix with known solution → direct implementation
- Trivial change (<1 hour) → skip formal planning


The ring-pm-team plugin provides 14 skills and 4 agents. Use them via `Skill tool: "ring:gate-name"`.

Follow the **ORCHESTRATOR principle** from `ring:using-ring`. Dispatch pre-dev workflow to handle planning; plan thoroughly before coding.

All artifacts land in `docs/pre-dev/<feature-name>/`. Both tracks end at `plan.md` — the single execution document consumed by `ring:running-dev-cycle` and `ring:executing-plans`.

## Two Tracks: Choose Your Path

### Small Track (4 Gates) — <2 Day Features

Use when ALL criteria met: implementation <2 days, no new external dependencies, no new data models, no multi-service integration, uses existing architecture, single developer.

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:researching-features | research.md |
| 1 | ring:writing-prds | prd.md |
| 2 | ring:writing-trds | trd.md |
| 3 | ring:writing-plans (invoked by orchestrator) | plan.md |

### Large Track (8 Gates) — ≥2 Day Features

Use when ANY criteria met: implementation ≥2 days, new external dependencies, new data models/entities, multi-service integration, new architecture patterns, team collaboration needed.

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:researching-features | research.md |
| 1 | ring:writing-prds | prd.md |
| 2 | ring:mapping-feature-relationships | feature-map.md |
| 3 | ring:writing-trds | trd.md |
| 4 | ring:designing-api-contracts | openapi.yaml |
| 5 | ring:designing-data-model | schema.sql / schema.prisma (stack-native) |
| 6 | ring:pinning-dependency-versions | dependencies.md |
| 7 | ring:writing-plans (default plugin, invoked by orchestrator) | plan.md |

## Gate Summaries

| Gate | Skill | What It Does |
|------|-------|-------------|
| 0 | ring:researching-features | Parallel technical/product research: codebase patterns, web research (firecrawl/exa), framework docs |
| 1 | ring:writing-prds | Squad-facing product spec: what, why, scope, functional requirements, acceptance criteria |
| 2 | ring:mapping-feature-relationships | Feature relationships, dependencies, and the phasing the squad validates (Large only) |
| 3 | ring:writing-trds | Technical architecture: components, boundaries, data flow, integration points |
| 4 | ring:designing-api-contracts | Real OpenAPI 3.1 spec: paths, schemas, error envelope (Large only) |
| 5 | ring:designing-data-model | Real stack-native schema: DDL, indexes, constraints (Large only) |
| 6 | ring:pinning-dependency-versions | Explicit tech choices, versions, licenses (Large only) |
| 7/3 | ring:writing-plans | Rolling-wave phased plan: all phases with epics, Phase 1 detailed into tasks |

## Standalone Utilities

| Skill | When to Use |
|-------|-------------|
| ring:validating-ux-completeness | Before the TRD when the feature has UI; validates ux-criteria/wireframes from a product-designer run |
| ring:mapping-streaming-events | Map eventable points in Go service for lib-streaming |
| ring:creating-grafana-dashboards | Sweep telemetry → telemetry-dictionary.md → PM iterates themes → Grafonnet dashboards + blocking drift CI |
| ring:reconciling-predev-docs | Before dev-cycle to catch contradictions across pre-dev artifacts |

## Agents

| Agent | Specialization |
|-------|---------------|
| ring:repo-researcher | Codebase patterns, existing solutions (Gate 0) |
| ring:web-researcher | External best practices, industry standards (Gate 0) |
| ring:docs-researcher | Tech stack docs, version constraints (Gate 0) |
| ring:product-designer | Standalone UX step (ux-research, ux-validation, ux-design) — not a gate agent |

## Entry Points

- **Small Track:** Invoke `ring:planning-small-features`
- **Large Track:** Invoke `ring:planning-large-features`
- **Specific gate:** Invoke the gate's skill directly if prior gates are done
