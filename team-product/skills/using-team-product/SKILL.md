---
name: using-team-product
description: Pre-dev workflow skills for feature planning - organize requirements, architecture, APIs, data models, dependencies, and tasks before implementation
when_to_use: Before starting implementation of any feature - use to systematically plan through 8 gates (or 3 for simple features) to create executable implementation plans
---

# Using Ring Team-Product: Pre-Dev Workflow

The ring-team-product plugin provides 8 pre-development planning skills. Use them via `Skill tool: "ring-team-product:gate-name"` or via slash commands.

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

### Small Track (3 Gates) – <2 Day Features

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
| 1 | Product Requirements | pre-dev-prd-creation | PRD.md |
| 2 | Technical Requirements | pre-dev-trd-creation | TRD.md |
| 3 | Task Breakdown | pre-dev-task-breakdown | tasks.md |

**Planning time:** 30-60 minutes

**Examples:**
- Add logout button
- Fix email validation bug
- Add rate limiting to endpoint

---

### Large Track (8 Gates) – ≥2 Day Features

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
| 1 | Product Requirements | pre-dev-prd-creation | PRD.md |
| 2 | Feature Map | pre-dev-feature-map | feature-map.md |
| 3 | Technical Requirements | pre-dev-trd-creation | TRD.md |
| 4 | API Design | pre-dev-api-design | API.md |
| 5 | Data Model | pre-dev-data-model | data-model.md |
| 6 | Dependencies | pre-dev-dependency-map | dependencies.md |
| 7 | Task Breakdown | pre-dev-task-breakdown | tasks.md |
| 8 | Subtask Creation | pre-dev-subtask-creation | subtasks.md |

**Planning time:** 2-4 hours

**Examples:**
- Add user authentication
- Implement payment processing
- Add file upload with CDN
- Multi-service integration

---

## 8 Pre-Dev Skills

### Gate 1: Product Requirements
**Skill:** `pre-dev-prd-creation`
**Output:** `docs/pre-dev/{feature}/PRD.md`

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
**Output:** `docs/pre-dev/{feature}/TRD.md`

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
**Output:** `docs/pre-dev/{feature}/API.md`

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
**Output:** `docs/pre-dev/{feature}/dependencies.md`

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
**Output:** `docs/pre-dev/{feature}/subtasks.md`

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
/ring:pre-dev-feature logout-button
```

**Large feature:**
```
/ring:pre-dev-full payment-system
```

These run all gates sequentially and create artifacts in `docs/pre-dev/{feature}/`.

---

### Via Skills (Manual)

Run individually or sequence:

```
Skill tool: "ring-team-product:pre-dev-prd-creation"
(Review output)

Skill tool: "ring-team-product:pre-dev-trd-creation"
(Review output)

Skill tool: "ring-team-product:pre-dev-task-breakdown"
(Review output)
```

---

## Pre-Dev Output Structure

```
docs/pre-dev/{feature}/
├── PRD.md                 # Gate 1: Business requirements
├── feature-map.md         # Gate 2: Feature relationships (large only)
├── TRD.md                 # Gate 3: Technical architecture
├── API.md                 # Gate 4: API contracts (large only)
├── data-model.md          # Gate 5: Entity schemas (large only)
├── dependencies.md        # Gate 6: Tech choices (large only)
├── tasks.md               # Gate 7: Implementation tasks
└── subtasks.md            # Gate 8: Ultra-atomic tasks (large only)
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
- `ring-developers:*-engineer` – Specialist review of design
- `ring-default:requesting-code-review` – Post-implementation review

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** – Dispatch pre-dev skills, don't plan manually
- **Don't skip gates** – Each gate adds clarity
- **Don't code without planning** – Plan first, code second
- **Use agents for specialist review** – Dispatch backend-engineer-golang to review TRD

### Good Example (ORCHESTRATOR):
> "I need to plan payment system. Let me run /ring:pre-dev-full to get organized, then dispatch backend-engineer-golang to review the architecture."

### Bad Example (OPERATOR):
> "I'll start coding and plan as I go."

---

## Available in This Plugin

**Skills:**
- pre-dev-prd-creation (Gate 1)
- pre-dev-feature-map (Gate 2)
- pre-dev-trd-creation (Gate 3)
- pre-dev-api-design (Gate 4)
- pre-dev-data-model (Gate 5)
- pre-dev-dependency-map (Gate 6)
- pre-dev-task-breakdown (Gate 7)
- pre-dev-subtask-creation (Gate 8)
- using-team-product (this skill)

**Commands:**
- `/ring:pre-dev-feature` – Small track (3 gates)
- `/ring:pre-dev-full` – Large track (8 gates)

**Note:** If skills are unavailable, check if ring-team-product is enabled in `.claude-plugin/marketplace.json`.

---

## Integration with Other Plugins

- **using-ring** (default) – ORCHESTRATOR principle for ALL tasks
- **using-developers** – Developer specialists for reviewing designs
- **using-product-reporter** – Regulatory compliance planning
- **using-team-product** – Pre-dev workflow (this skill)

Dispatch based on your need:
- General code review → default plugin agents
- Regulatory compliance → ring-product-reporter agents
- Specialist review of design → ring-developers agents
- Feature planning → ring-team-product skills
