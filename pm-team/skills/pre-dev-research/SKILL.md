---
name: pre-dev-research
description: |
  Gate 0 research phase for pre-dev workflow. Dispatches 3 parallel research agents
  to gather codebase patterns, external best practices, and framework documentation
  BEFORE creating PRD/TRD. Outputs research.md with file:line references.

trigger: |
  - Before any pre-dev workflow (Gate 0)
  - When planning new features or modifications
  - Invoked by /pre-dev-full and /pre-dev-feature

skip_when: |
  - Trivial changes that don't need planning
  - Research already completed (research.md exists and is recent)

sequence:
  before: [pre-dev-prd-creation, pre-dev-feature-map]

related:
  complementary: [pre-dev-prd-creation, pre-dev-trd-creation]

research_modes:
  greenfield:
    description: "New feature with no existing patterns to follow"
    primary_agents: [best-practices-researcher, framework-docs-researcher]
    focus: "External best practices and framework patterns"

  modification:
    description: "Changing or extending existing functionality"
    primary_agents: [repo-research-analyst]
    focus: "Existing codebase patterns and conventions"

  integration:
    description: "Connecting systems or adding external dependencies"
    primary_agents: [framework-docs-researcher, best-practices-researcher, repo-research-analyst]
    focus: "API documentation and integration patterns"
---

# Pre-Dev Research Skill (Gate 0)

**Purpose:** Gather comprehensive research BEFORE writing planning documents, ensuring PRDs and TRDs are grounded in codebase reality and industry best practices.

## The Research-First Principle

```
Traditional:  Request → PRD → Discover problems during implementation
Research-First:  Request → Research → Informed PRD → Smoother implementation

Research prevents: Reinventing existing patterns, ignoring conventions, missing framework constraints, repeating solved problems
```

## Step 1: Determine Research Mode

**BLOCKING GATE:** Before dispatching agents, determine the research mode.

| Mode | When to Use | Example |
|------|-------------|---------|
| **greenfield** | No existing patterns | "Add GraphQL API" (when project has none) |
| **modification** | Extending existing functionality | "Add pagination to user list API" |
| **integration** | Connecting external systems | "Integrate Stripe payments" |

**If unclear, ask:**
> Before starting research: Is this (1) Greenfield - new capability, (2) Modification - extends existing, or (3) Integration - connects external systems?

**Mode affects agent priority:**
- Greenfield → Web research primary (best-practices, framework-docs)
- Modification → Codebase research primary (repo-research)
- Integration → All agents equally weighted

## Step 2: Dispatch Research Agents

**Run 3 agents in PARALLEL** (single message, 3 Task calls):

| Agent | Prompt Focus |
|-------|--------------|
| `repo-research-analyst` | Codebase patterns for [feature]. Search docs/solutions/ knowledge base. Return file:line references. If modification mode: PRIMARY focus. |
| `best-practices-researcher` | External best practices for [feature]. Use Context7 + WebSearch. Return URLs. If greenfield mode: PRIMARY focus. |
| `framework-docs-researcher` | Tech stack docs for [feature]. Detect versions from manifests. Use Context7. Return version constraints. If integration mode: focus on SDK/API docs. |

## Step 3: Aggregate Research Findings

**Output:** `docs/pre-dev/{feature-name}/research.md`

| Section | Content |
|---------|---------|
| **Metadata** | date, feature, research_mode, agents_dispatched |
| **Executive Summary** | 2-3 sentences synthesizing key findings |
| **Research Mode** | Why selected, what it means for focus |
| **Codebase Research** | Agent output (file:line references) |
| **Best Practices Research** | Agent output (URLs) |
| **Framework Documentation** | Agent output (version constraints) |
| **Synthesis** | Key patterns to follow (file:line, URL, doc ref); Constraints identified; Prior solutions from docs/solutions/; Open questions for PRD |

## Step 4: Gate 0 Validation

**BLOCKING CHECKLIST:**

| Check | Required For |
|-------|--------------|
| Research mode documented | All modes |
| All 3 agents returned | All modes |
| research.md created | All modes |
| At least one file:line reference | modification, integration |
| At least one external URL | greenfield, integration |
| docs/solutions/ searched | All modes |
| Tech stack versions documented | All modes |
| Synthesis section complete | All modes |

**If validation fails:**
- Missing agent output → Re-run that agent
- No codebase patterns (modification) → May need mode change
- No external docs (greenfield) → Try different search terms

## Integration with Pre-Dev Workflow

**pre-dev-full (9-gate):** Gate 0 Research → Gate 1 PRD (reads research.md) → ... → Gate 3 TRD (reads research.md)

**pre-dev-feature (4-gate):** Gate 0 Research → Gate 1 PRD → Gate 2 TRD → Gate 3 Tasks

## Research Document Usage

**In Gate 1 (PRD):** Reference existing patterns with file:line; cite docs/solutions/; include external URLs; note framework constraints

**In Gate 3 (TRD):** Reference implementation patterns; use version constraints; cite similar implementations

## Anti-Patterns

1. **Skipping research for "simple" features** - Even simple features benefit from convention checks
2. **Wrong research mode** - Greenfield with heavy codebase research wastes time; modification without codebase research misses patterns
3. **Ignoring docs/solutions/** - Prior solutions are gold; prevents repeating mistakes
4. **Vague references without file:line** - "There's a pattern somewhere" is not useful; exact locations enable quick reference
