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

The ring-pm-team plugin provides 10 pre-development planning skills and 3 research agents. Use them via `Skill tool: "ring-pm-team:gate-name"` or via slash commands.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch pre-dev workflow to handle planning; plan thoroughly before coding.

---

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

---

## Two Tracks: Choose Your Path

### Small Track (4 Gates) – <2 Day Features

**Use when ALL criteria met:**
- ✅ Implementation: <2 days
- ✅ No new external dependencies
- ✅ No new data models
- ✅ No multi-service integration
- ✅ Uses existing architecture
- ✅ Single developer

**Gates:**
| # | Gate | Skill | Output |
|---|------|-------|--------|
| 0 | **Research Phase** | pre-dev-research | research.md |
| 1 | Product Requirements | pre-dev-prd-creation | PRD.md |
| 2 | Technical Requirements | pre-dev-trd-creation | TRD.md |
| 3 | Task Breakdown | pre-dev-task-breakdown | tasks.md |

**Planning time:** 45-75 minutes

**Examples:**
- Add logout button
- Fix email validation bug
- Add rate limiting to endpoint

---

### Large Track (9 Gates) – ≥2 Day Features

**Use when ANY criteria met:**
- ❌ Implementation: ≥2 days
- ❌ New external dependencies
- ❌ New data models/entities
- ❌ Multi-service integration
- ❌ New architecture patterns
- ❌ Team collaboration needed

**Gates:**
| # | Gate | Skill | Output |
|---|------|-------|--------|
| 0 | **Research Phase** | pre-dev-research | research.md |
| 1 | Product Requirements | pre-dev-prd-creation | PRD.md |
| 2 | Feature Map | pre-dev-feature-map | feature-map.md |
| 3 | Technical Requirements | pre-dev-trd-creation | TRD.md |
| 4 | API Design | pre-dev-api-design | API.md |
| 5 | Data Model | pre-dev-data-model | data-model.md |
| 6 | Dependencies | pre-dev-dependency-map | dependencies.md |
| 7 | Task Breakdown | pre-dev-task-breakdown | tasks.md |
| 8 | Subtask Creation | pre-dev-subtask-creation | subtasks.md |

**Planning time:** 2.5-4.5 hours

**Examples:**
- Add user authentication
- Implement payment processing
- Add file upload with CDN
- Multi-service integration

---

## 10 Pre-Dev Skills + 3 Research Agents

### Gate 0: Research Phase (NEW)
**Skill:** `pre-dev-research`
**Output:** `docs/pre-dev/{feature}/research.md`

**What:** Parallel research before planning
**Covers:**
- Existing codebase patterns (file:line references)
- External best practices (URLs)
- Framework documentation (version-specific)
- Knowledge base search (docs/solutions/)

**Research Modes:**
| Mode | Primary Focus | When to Use |
|------|---------------|-------------|
| **greenfield** | Web research, best practices | New capability, no existing patterns |
| **modification** | Codebase patterns | Extending existing functionality |
| **integration** | API docs, SDK docs | Connecting external systems |

**Dispatches 3 agents in PARALLEL:**
1. `ring-pm-team:repo-research-analyst` - Codebase patterns, docs/solutions/
2. `ring-pm-team:best-practices-researcher` - Web search, Context7
3. `ring-pm-team:framework-docs-researcher` - Tech stack, versions

**Use when:**
- Starting any feature (always recommended)
- Need to understand existing patterns
- Greenfield feature needs best practices research

---

### Gate 1: Product Requirements
**Skill:** `pre-dev-prd-creation`
**Output:** `docs/pre-dev/{feature}/prd.md`

**What:** Business requirements document
**Covers:**
- Goal & success criteria
- User stories & use cases
- Business value & priority
- Constraints & assumptions
- Non-functional requirements

**Use when:**
- Starting any feature
- Need clarity on WHAT/WHY

---

### Gate 2: Feature Map (Large Track Only)
**Skill:** `pre-dev-feature-map`
**Output:** `docs/pre-dev/{feature}/feature-map.md`

**What:** Feature relationship diagram
**Covers:**
- Feature breakdown into components
- Dependencies between features
- Sequencing & prerequisites
- Integration points
- Deployment order

**Use when:**
- Complex feature with multiple parts
- Need to understand relationships
- Team coordination required

---

### Gate 3: Technical Requirements
**Skill:** `pre-dev-trd-creation`
**Output:** `docs/pre-dev/{feature}/trd.md`

**What:** Technical architecture document
**Covers:**
- System design & architecture
- Technology selection
- Implementation approach
- Scalability & performance targets
- Security requirements

**Use when:**
- Understanding HOW to implement
- Need architecture clarity
- Before any coding

---

### Gate 4: API Design (Large Track Only)
**Skill:** `pre-dev-api-design`
**Output:** `docs/pre-dev/{feature}/api-design.md`

**What:** API contracts & boundaries
**Covers:**
- Endpoint specifications
- Request/response schemas
- Error handling
- Versioning strategy
- Integration patterns

**Use when:**
- Service boundaries need definition
- Multiple services collaborate
- Contract-driven development

---

### Gate 5: Data Model (Large Track Only)
**Skill:** `pre-dev-data-model`
**Output:** `docs/pre-dev/{feature}/data-model.md`

**What:** Entity relationships & schemas
**Covers:**
- Entity definitions
- Relationships & cardinality
- Database schemas
- Migration strategy
- Data persistence

**Use when:**
- New entities/tables needed
- Data structure complex
- Migrations required

---

### Gate 6: Dependencies (Large Track Only)
**Skill:** `pre-dev-dependency-map`
**Output:** `docs/pre-dev/{feature}/dependency-map.md`

**What:** Technology & library selection
**Covers:**
- External dependencies
- Library choices & alternatives
- Version compatibility
- License implications
- Risk assessment

**Use when:**
- New libraries needed
- Tech choices unclear
- Alternatives to evaluate

---

### Gate 7: Task Breakdown
**Skill:** `pre-dev-task-breakdown`
**Output:** `docs/pre-dev/{feature}/tasks.md`

**What:** Implementation tasks
**Covers:**
- Atomic work units (2-5 min each)
- Execution order
- Dependencies between tasks
- Verification steps
- Completeness checklist

**Use when:**
- Ready to create implementation plan
- Need task granularity
- Before assigning work

---

### Gate 8: Subtask Creation (Large Track Only)
**Skill:** `pre-dev-subtask-creation`
**Output:** `docs/pre-dev/{feature}/subtasks/`

**What:** Ultra-atomic task breakdown
**Covers:**
- Sub-unit decomposition
- Exact file paths
- Code snippets
- Verification commands
- Expected outputs

**Use when:**
- Need absolute clarity
- Complex task needs detail
- Zero-context execution required

---

## Using Pre-Dev Workflow

### Via Slash Commands (Easy)

**Small feature:**
```
/ring-pm-team:pre-dev-feature logout-button
```

**Large feature:**
```
/ring-pm-team:pre-dev-full payment-system
```

These run all gates sequentially and create artifacts in `docs/pre-dev/{feature}/`.

---

### Via Skills (Manual)

Run individually or sequence:

```
Skill tool: "ring-pm-team:pre-dev-prd-creation"
(Review output)

Skill tool: "ring-pm-team:pre-dev-trd-creation"
(Review output)

Skill tool: "ring-pm-team:pre-dev-task-breakdown"
(Review output)
```

---

## Pre-Dev Output Structure

```
docs/pre-dev/{feature}/
├── prd.md                 # Gate 1: Business requirements
├── feature-map.md         # Gate 2: Feature relationships (large only)
├── trd.md                 # Gate 3: Technical architecture
├── api-design.md          # Gate 4: API contracts (large only)
├── data-model.md          # Gate 5: Entity schemas (large only)
├── dependency-map.md      # Gate 6: Tech choices (large only)
├── tasks.md               # Gate 7: Implementation tasks
└── subtasks/              # Gate 8: Ultra-atomic tasks (large only)
```

---

## Decision: Small or Large Track?

**When in doubt: Use Large Track.**

Better to over-plan than discover mid-implementation that feature is larger.

**You can switch:** If Small Track feature grows, pause and complete Large Track gates.

---

## Integration with Other Planning

**Pre-dev workflow provides:**
- ✅ Complete planning artifacts
- ✅ Atomic tasks ready to execute
- ✅ Zero-context handoff capability
- ✅ Clear implementation boundaries

**Combined with:**
- `ring-default:execute-plan` – Run tasks in batches
- `ring-default:write-plan` – Generate from scratch
- `ring-dev-team:*-engineer` – Specialist review of design
- `ring-default:requesting-code-review` – Post-implementation review

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** – Dispatch pre-dev skills, don't plan manually
- **Don't skip gates** – Each gate adds clarity
- **Don't code without planning** – Plan first, code second
- **Use agents for specialist review** – Dispatch backend-engineer-golang to review TRD

### Good Example (ORCHESTRATOR):
> "I need to plan payment system. Let me run /ring-pm-team:pre-dev-full to get organized, then dispatch backend-engineer-golang to review the architecture."

### Bad Example (OPERATOR):
> "I'll start coding and plan as I go."

---

## Available in This Plugin

**Skills:**
- pre-dev-research (Gate 0) ← NEW
- pre-dev-prd-creation (Gate 1)
- pre-dev-feature-map (Gate 2)
- pre-dev-trd-creation (Gate 3)
- pre-dev-api-design (Gate 4)
- pre-dev-data-model (Gate 5)
- pre-dev-dependency-map (Gate 6)
- pre-dev-task-breakdown (Gate 7)
- pre-dev-subtask-creation (Gate 8)
- using-pm-team (this skill)

**Research Agents:**
- ring-pm-team:repo-research-analyst (codebase patterns, docs/solutions/)
- ring-pm-team:best-practices-researcher (web search, Context7)
- ring-pm-team:framework-docs-researcher (tech stack, versions)

**Commands:**
- `/ring-pm-team:pre-dev-feature` – Small track (4 gates)
- `/ring-pm-team:pre-dev-full` – Large track (9 gates)

**Note:** If skills are unavailable, check if ring-pm-team is enabled in `.claude-plugin/marketplace.json`.

---

## Integration with Other Plugins

- **using-ring** (default) – ORCHESTRATOR principle for ALL tasks
- **using-dev-team** – Developer specialists for reviewing designs
- **using-finops-team** – Regulatory compliance planning
- **using-pm-team** – Pre-dev workflow (this skill)

Dispatch based on your need:
- General code review → default plugin agents
- Regulatory compliance → ring-finops-team agents
- Specialist review of design → ring-dev-team agents
- Feature planning → ring-pm-team skills
