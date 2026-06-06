---
name: ring:using-pm-team
description: "Routing feature planning through the ring-pm-team pre-dev workflow: choosing the Small Track (5 gates, <2 days) or Large Track (10 gates, 2+ days) and entering via ring:planning-small-features or ring:planning-large-features. Indexes pre-dev gates, standalone skills, and research agents. Use when starting a feature that needs systematic planning. Skip for quick exploratory work, known-solution bug fixes, or trivial changes."
---

# Using Ring Team-Product: Pre-Dev Workflow & Delivery Tracking

## When to use

- Starting any feature implementation
- Need systematic planning before coding
- User requests "plan a feature"

## Skip when

- Quick exploratory work → skip formal planning
- Bug fix with known solution → direct implementation
- Trivial change (<1 hour) → skip formal planning


The ring-pm-team plugin provides 12 pre-development planning skills and 4 research agents. Use them via `Skill tool: "ring:gate-name"`.

Follow the **ORCHESTRATOR principle** from `ring:using-ring`. Dispatch pre-dev workflow to handle planning; plan thoroughly before coding.

## Two Tracks: Choose Your Path

### Small Track (5 Gates) — <2 Day Features

Use when ALL criteria met: implementation <2 days, no new external dependencies, no new data models, no multi-service integration, uses existing architecture, single developer.

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:researching-features | research.md |
| 1 | ring:writing-prds | prd.md |
| 2 | ring:writing-trds | trd.md |
| 3 | ring:decomposing-phases-and-epics | tasks.md (phased plan; Phase 1 detailed inline) |
| 4 | ring:planning-delivery | delivery-roadmap.md + .json |

**Planning time:** 60-90 minutes

### Large Track (10 Gates) — ≥2 Day Features

Use when ANY criteria met: implementation ≥2 days, new external dependencies, new data models/entities, multi-service integration, new architecture patterns, team collaboration needed.

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:researching-features | research.md |
| 1 | ring:writing-prds | prd.md |
| 1.5 | ring:validating-ux-completeness | design-validation.md (if UI) |
| 2 | ring:mapping-feature-relationships | feature-map.md |
| 2.5 | ring:validating-ux-completeness | design-validation.md (if UI, Large) |
| 3 | ring:writing-trds | trd.md |
| 4 | ring:designing-api-contracts | api-design.md |
| 5 | ring:designing-data-model | data-model.md |
| 6 | ring:pinning-dependency-versions | dependencies.md |
| 7 | ring:decomposing-phases-and-epics | tasks.md (phased plan: phases + epics) |
| 8 | ring:detailing-tasks | Phase 1 tasks written into tasks.md |
| 9 | ring:planning-delivery | delivery-roadmap.md + .json |

**Planning time:** 2.5-5 hours

## Gate Summaries

| Gate | Skill | What It Does |
|------|-------|-------------|
| 0 | ring:researching-features | Parallel research: codebase patterns, best practices, framework docs |
| 1 | ring:writing-prds | Business requirements (WHAT/WHY), user stories, success metrics |
| 1.5/2.5 | ring:validating-ux-completeness | UX completeness check: screens, states, responsive, a11y |
| 2 | ring:mapping-feature-relationships | Feature relationships, dependencies, deployment order (Large only) |
| 3 | ring:writing-trds | Technical architecture, technology-agnostic patterns |
| 4 | ring:designing-api-contracts | API contracts, operations, error handling (Large only) |
| 5 | ring:designing-data-model | Entities, relationships, ownership (Large only) |
| 6 | ring:pinning-dependency-versions | Explicit tech choices, versions, licenses (Large only) |
| 7 | ring:decomposing-phases-and-epics | Phased plan: phases (verifiable milestones) + epics (value increments), rolling wave |
| 8 | ring:detailing-tasks | Phase 1 epics → dispatch-ready tasks, written into tasks.md (Large only) |
| 9/4 | ring:planning-delivery | Realistic schedule with critical path + JSON output |

## Standalone Skills

| Skill | When to Use |
|-------|-------------|
| ring:reconciling-predev-docs | Before dev-cycle to catch doc contradictions |
| ring:tracking-delivery | Progress tracking against approved roadmap |
| ring:mapping-streaming-events | Map eventable points in Go service for lib-streaming |
| ring:creating-grafana-dashboards | Sweep telemetry → telemetry-dictionary.md → PM iterates themes → Grafonnet dashboards + blocking drift CI |

## Research Agents (dispatched by Gate 0)

| Agent | Specialization |
|-------|---------------|
| ring:repo-researcher | Codebase patterns, existing solutions |
| ring:web-researcher | External best practices, industry standards |
| ring:docs-researcher | Tech stack docs, version constraints |
| ring:product-designer | UX research, personas, competitive analysis |

## Entry Points

- **Small Track:** Invoke `ring:planning-small-features`
- **Large Track:** Invoke `ring:planning-large-features`
- **Specific gate:** Invoke the gate's skill directly if prior gates are done
