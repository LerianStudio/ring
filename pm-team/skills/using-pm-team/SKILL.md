---
name: using-pm-team
description: |
  12 pre-dev workflow skills + 4 research agents organized into Small Track (4 gates, <2 days) and
  Large Track (9 gates, 2+ days) for systematic feature planning with research-first approach.
metadata:
  skip_when: |-
    - Quick exploratory work → ring:brainstorming may suffice
    - Bug fix with known solution → direct implementation
    - Trivial change (<1 hour) → skip formal planning
  trigger: |
    - Starting any feature implementation
    - Need systematic planning before coding
    - User requests "plan a feature"
---

# Using Ring Team-Product: Pre-Dev Workflow & Delivery Tracking

The ring-pm-team plugin provides 12 pre-development planning skills and 4 research agents. Use them via `Skill tool: "ring:gate-name"` or via slash commands.

**Remember:** Follow the **ORCHESTRATOR principle** from `ring:using-ring`. Dispatch pre-dev workflow to handle planning; plan thoroughly before coding.

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

### Small Track (5 Gates) – <2 Day Features

**Use when ALL criteria met:**

- ✅ Implementation <2 days
- ✅ No new external dependencies
- ✅ No new data models
- ✅ No multi-service integration
- ✅ Uses existing architecture
- ✅ Single developer

| Gate | Skill                       | Output      |
| ---- | --------------------------- | ----------- |
| 0    | ring:pre-dev-research       | research.md |
| 1    | ring:pre-dev-prd-creation   | PRD.md      |
| 2    | ring:pre-dev-trd-creation   | TRD.md      |
| 3    | ring:pre-dev-task-breakdown | tasks.md    |
| 4    | ring:pre-dev-delivery-planning | delivery-roadmap.md, .json |

**Planning time:** 60-90 minutes

### Large Track (10 Gates) – ≥2 Day Features

**Use when ANY criteria met:**

- ❌ Implementation ≥2 days
- ❌ New external dependencies
- ❌ New data models/entities
- ❌ Multi-service integration
- ❌ New architecture patterns
- ❌ Team collaboration needed

| Gate | Skill                         | Output          |
| ---- | ----------------------------- | --------------- |
| 0    | ring:pre-dev-research         | research.md     |
| 1    | ring:pre-dev-prd-creation     | PRD.md          |
| 2    | ring:pre-dev-feature-map      | feature-map.md  |
| 3    | ring:pre-dev-trd-creation     | TRD.md          |
| 4    | ring:pre-dev-api-design       | API.md          |
| 5    | ring:pre-dev-data-model       | data-model.md   |
| 6    | ring:pre-dev-dependency-map   | dependencies.md |
| 7    | ring:pre-dev-task-breakdown   | tasks.md        |
| 8    | ring:pre-dev-subtask-creation | subtasks/       |
| 9    | ring:pre-dev-delivery-planning | delivery-roadmap.md, .json |

**Planning time:** 2.5-5 hours

## Gate Summaries

| Gate | Skill                         | What It Does                                                         |
| ---- | ----------------------------- | -------------------------------------------------------------------- |
| 0    | ring:pre-dev-research         | Parallel research: codebase patterns, best practices, framework docs |
| 1    | ring:pre-dev-prd-creation     | Business requirements (WHAT/WHY), user stories, success metrics      |
| 2    | ring:pre-dev-feature-map      | Feature relationships, dependencies, deployment order (Large only)   |
| 3    | ring:pre-dev-trd-creation     | Technical architecture, technology-agnostic patterns                 |
| 4    | ring:pre-dev-api-design       | API contracts, operations, error handling (Large only)               |
| 5    | ring:pre-dev-data-model       | Entities, relationships, ownership (Large only)                      |
| 6    | ring:pre-dev-dependency-map   | Explicit tech choices, versions, licenses (Large only)               |
| 7    | ring:pre-dev-task-breakdown   | Value-driven tasks with success criteria                             |
| 8    | ring:pre-dev-subtask-creation | Zero-context 2-5 min implementation steps (Large only)               |
| 9    | ring:pre-dev-delivery-planning | Delivery roadmap with timeline, critical path, resource allocation (MANDATORY for both tracks) |

## Research Agents (Gate 0)

| Agent                            | Focus                                             |
| -------------------------------- | ------------------------------------------------- |
| `ring:repo-research-analyst`     | Codebase patterns, docs/solutions/ knowledge base |
| `ring:best-practices-researcher` | Web search, Context7 for best practices           |
| `ring:framework-docs-researcher` | Tech stack versions, official patterns            |

**Research Modes:**

- **greenfield**: Web research primary (new capability)
- **modification**: Codebase research primary (extending existing)
- **integration**: All agents equally weighted (connecting systems)

## Delivery Status Tracking (Post-Planning)

After planning and during execution, track progress:

| Skill                           | Command                 | Purpose                                                   |
| ------------------------------- | ----------------------- | --------------------------------------------------------- |
| `ring:delivery-status-tracking` | `/ring:delivery-status` | Evidence-based progress analysis against delivery roadmap |

**What it does:**

- Scans repository (ALL branches, commits, PRs, releases)
- Matches work to tasks (pattern + semantic analysis)
- Calculates % completion via specialized agents
- Identifies delays, blockers, critical path issues
- Extracts insights (velocity, quality trends, patterns)

**When to use:**

- Weekly checkpoints during execution
- Sprint/cycle end retrospectives
- Before stakeholder status meetings
- When roadmap shows signs of deviation

**Output:** `docs/pre-dev/{feature}/delivery-status-{date}.md`

## Using Pre-Dev Workflow

### Via Slash Commands

```
/ring:pre-dev-feature logout-button    # Small track (5 gates)
/ring:pre-dev-full payment-system      # Large track (10 gates)
```

### Via Skills (Manual)

```
Skill tool: "ring:pre-dev-prd-creation"
(Review output)
Skill tool: "ring:pre-dev-trd-creation"
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

| Plugin                    | Use For                                     |
| ------------------------- | ------------------------------------------- |
| ring:using-ring (default) | ORCHESTRATOR principle for ALL tasks        |
| ring:using-dev-team       | Developer specialists for reviewing designs |
| ring:using-finops-team    | Regulatory compliance planning              |
| ring:using-tw-team        | Documentation for features                  |

**Combined with:**

- `ring:execute-plan` – Run tasks in batches
- `ring:write-plan` – Generate plan from scratch
- `*-engineer` – Specialist review of design
- `ring:requesting-code-review` – Post-implementation review

## ORCHESTRATOR Principle

- **You're the orchestrator** – Dispatch pre-dev skills, don't plan manually
- **Don't skip gates** – Each gate adds clarity
- **Don't code without planning** – Plan first, code second
- **Use agents for specialist review** – Dispatch engineers to review TRD

### Good (ORCHESTRATOR):

> "I need to plan payment system. Let me run /ring:pre-dev-full, then dispatch ring:backend-engineer-golang to review the architecture."

### Bad (OPERATOR):

> "I'll start coding and plan as I go."

---

## Standards Loading (MANDATORY)

This skill is an orchestration/navigation skill for the pm-team plugin. It does NOT require WebFetch of language-specific standards.

**However**, when dispatching implementation agents (e.g., `ring:backend-engineer-golang`), those agents MUST load their respective standards via WebFetch before proceeding.

---

## Blocker Criteria - STOP and Report

| Condition | Action | Severity |
|-----------|--------|----------|
| No project scope or feature defined | STOP and report to user | CRITICAL |
| User requests to skip all planning | STOP and report - planning is mandatory | CRITICAL |
| PRD/TRD already exists but user wants to start over | STOP and confirm user intent | HIGH |
| Unclear whether Small or Large Track applies | STOP and ask clarifying questions | MEDIUM |
| Missing prerequisite gate artifacts | STOP and complete previous gate first | HIGH |

---

## Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST use ORCHESTRATOR principle - dispatch skills, don't plan manually
- MUST complete gates in sequence - CANNOT skip gates
- MUST validate gate outputs before proceeding to next gate
- MUST create planning artifacts before implementation
- MUST use Large Track when feature exceeds Small Track criteria
- CANNOT proceed to implementation without completing mandatory gates

---

## Severity Calibration

| Severity | Definition | Example |
|----------|------------|---------|
| **CRITICAL** | Blocks all progress, fundamental violation | Attempting to code without any planning artifacts |
| **HIGH** | Significant risk, must address before continuing | Skipping a mandatory gate in the workflow |
| **MEDIUM** | Quality impact, should address soon | Choosing wrong track (Small vs Large) |
| **LOW** | Minor issue, track for improvement | Incomplete gate documentation |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip planning, just start coding" | "Cannot proceed. Planning prevents 10x rework cost. I'll start with ring:pre-dev-research to gather context first." |
| "We don't need PRD, requirements are obvious" | "Cannot skip PRD. 'Obvious' requirements cause scope creep. I'll create a focused PRD documenting what we're building and why." |
| "Use Small Track, we're in a hurry" | "Cannot compromise on track selection. If feature meets Large Track criteria, I MUST use Large Track. Shortcuts now = rework later." |
| "Skip research, we know the codebase" | "Cannot skip Gate 0. Research validates assumptions and finds existing patterns. Takes 30 mins, saves hours of reinvention." |
| "Just give me tasks, skip the architecture" | "Cannot skip TRD. Architecture decisions affect all tasks. I'll create TRD first to ensure tasks are correctly scoped." |

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This feature is simple, skip planning" | Simple features still have requirements and architecture | **Use at minimum Small Track (5 gates)** |
| "We already know what to build" | Knowing ≠ documenting. Documentation prevents drift | **Create PRD regardless of certainty** |
| "Planning slows us down" | Unplanned work slows down 10x more during implementation | **Complete all gates in sequence** |
| "I can plan in my head while coding" | Mental planning isn't verifiable or shareable | **Create written artifacts for each gate** |
| "Previous similar feature didn't need this" | Each feature is independent. Past shortcuts don't justify current ones | **Evaluate each feature independently** |
| "User is experienced, they know what they want" | Experience doesn't replace systematic planning | **Follow the workflow regardless** |

---

## When This Skill Is Not Needed

- Quick exploratory work where `ring:brainstorming` suffices
- Bug fix with known solution requiring no design changes
- Trivial changes that take less than 1 hour
- Documentation-only updates
- Configuration changes with no code impact
- Direct implementation after planning is already complete (use `ring:executing-plans` or `ring:dev-cycle` instead)
