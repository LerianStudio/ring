---
name: using-pm-team
description: |
  10 pre-dev workflow skills + 3 research agents organized into Small Track (4 gates, <2 days) and
  Large Track (9 gates, 2+ days) for systematic feature planning with research-first approach.

trigger: |
  - Starting any feature implementation
  - Need systematic planning before coding
  - User requests "plan a feature"

skip_when: |
  - Quick exploratory work → brainstorming may suffice
  - Bug fix with known solution → direct implementation
  - Trivial change (<1 hour) → skip formal planning
---

# Using Ring Team-Product: Pre-Dev Workflow

The ring-pm-team plugin provides 10 pre-development planning skills and 3 research agents. Use them via `Skill tool: "gate-name"` or via slash commands.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch pre-dev workflow to handle planning; plan thoroughly before coding.

## Pre-Dev Philosophy

**Before you code, you plan. Every time.**

Pre-dev workflow ensures:
- ✅ Requirements are clear (WHAT/WHY)
- ✅ Architecture is sound (HOW)
- ✅ APIs are contracts (boundaries)
- ✅ Data models are explicit (entities)
- ✅ Dependencies are known (tech choices)
- ✅ Tasks are atomic (2-5 min each)
- ✅ Implementation is execution, not design

## Two Tracks: Choose Your Path

### Small Track (4 Gates) – <2 Day Features

**Use when ALL criteria met:**
- ✅ Implementation <2 days
- ✅ No new external dependencies
- ✅ No new data models
- ✅ No multi-service integration
- ✅ Uses existing architecture
- ✅ Single developer

| Gate | Skill | Output |
|------|-------|--------|
| 0 | pre-dev-research | research.md |
| 1 | pre-dev-prd-creation | PRD.md |
| 2 | pre-dev-trd-creation | TRD.md |
| 3 | pre-dev-task-breakdown | tasks.md |

**Planning time:** 45-75 minutes

### Large Track (9 Gates) – ≥2 Day Features

**Use when ANY criteria met:**
- ❌ Implementation ≥2 days
- ❌ New external dependencies
- ❌ New data models/entities
- ❌ Multi-service integration
- ❌ New architecture patterns
- ❌ Team collaboration needed

| Gate | Skill | Output |
|------|-------|--------|
| 0 | pre-dev-research | research.md |
| 1 | pre-dev-prd-creation | PRD.md |
| 2 | pre-dev-feature-map | feature-map.md |
| 3 | pre-dev-trd-creation | TRD.md |
| 4 | pre-dev-api-design | API.md |
| 5 | pre-dev-data-model | data-model.md |
| 6 | pre-dev-dependency-map | dependencies.md |
| 7 | pre-dev-task-breakdown | tasks.md |
| 8 | pre-dev-subtask-creation | subtasks/ |

**Planning time:** 2.5-4.5 hours

## Gate Summaries

| Gate | Skill | What It Does |
|------|-------|--------------|
| 0 | pre-dev-research | Parallel research: codebase patterns, best practices, framework docs |
| 1 | pre-dev-prd-creation | Business requirements (WHAT/WHY), user stories, success metrics |
| 2 | pre-dev-feature-map | Feature relationships, dependencies, deployment order (Large only) |
| 3 | pre-dev-trd-creation | Technical architecture, technology-agnostic patterns |
| 4 | pre-dev-api-design | API contracts, operations, error handling (Large only) |
| 5 | pre-dev-data-model | Entities, relationships, ownership (Large only) |
| 6 | pre-dev-dependency-map | Explicit tech choices, versions, licenses (Large only) |
| 7 | pre-dev-task-breakdown | Value-driven tasks with success criteria |
| 8 | pre-dev-subtask-creation | Zero-context 2-5 min implementation steps (Large only) |

## Research Agents (Gate 0)

| Agent | Focus |
|-------|-------|
| `repo-research-analyst` | Codebase patterns, docs/solutions/ knowledge base |
| `best-practices-researcher` | Web search, Context7 for best practices |
| `framework-docs-researcher` | Tech stack versions, official patterns |

**Research Modes:**
- **greenfield**: Web research primary (new capability)
- **modification**: Codebase research primary (extending existing)
- **integration**: All agents equally weighted (connecting systems)

## Using Pre-Dev Workflow

### Via Slash Commands

```
/pre-dev-feature logout-button    # Small track (4 gates)
/pre-dev-full payment-system      # Large track (9 gates)
```

### Via Skills (Manual)

```
Skill tool: "pre-dev-prd-creation"
(Review output)
Skill tool: "pre-dev-trd-creation"
(Review output)
```

## Output Structure

```
docs/pre-dev/{feature}/
├── research.md        # Gate 0
├── prd.md             # Gate 1
├── feature-map.md     # Gate 2 (large only)
├── trd.md             # Gate 3
├── api-design.md      # Gate 4 (large only)
├── data-model.md      # Gate 5 (large only)
├── dependency-map.md  # Gate 6 (large only)
├── tasks.md           # Gate 7
└── subtasks/          # Gate 8 (large only)
```

## Decision: Small or Large Track?

**When in doubt: Use Large Track.** Better to over-plan than discover mid-implementation that feature is larger.

**You can switch:** If Small Track feature grows, pause and complete Large Track gates.

## Integration with Other Plugins

| Plugin | Use For |
|--------|---------|
| using-ring (default) | ORCHESTRATOR principle for ALL tasks |
| using-dev-team | Developer specialists for reviewing designs |
| using-finops-team | Regulatory compliance planning |
| using-tw-team | Documentation for features |

**Combined with:**
- `execute-plan` – Run tasks in batches
- `write-plan` – Generate plan from scratch
- `*-engineer` – Specialist review of design
- `requesting-code-review` – Post-implementation review

## ORCHESTRATOR Principle

- **You're the orchestrator** – Dispatch pre-dev skills, don't plan manually
- **Don't skip gates** – Each gate adds clarity
- **Don't code without planning** – Plan first, code second
- **Use agents for specialist review** – Dispatch engineers to review TRD

### Good (ORCHESTRATOR):
> "I need to plan payment system. Let me run /pre-dev-full, then dispatch backend-engineer-golang to review the architecture."

### Bad (OPERATOR):
> "I'll start coding and plan as I go."
