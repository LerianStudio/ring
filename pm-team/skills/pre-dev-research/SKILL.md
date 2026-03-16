---
name: pre-dev-research
description: |
  Gate 0 research phase for pre-dev workflow. Dispatches 4 parallel research agents
  to gather codebase patterns, external best practices, framework documentation,
  and UX/product research BEFORE creating PRD/TRD. Outputs research.md with
  file:line references and user research findings.
metadata:
  related:
    complementary:
    - ring:pre-dev-prd-creation
    - ring:pre-dev-trd-creation
  research_modes:
    greenfield:
      description: New feature with no existing patterns to follow
      primary_agents:
      - ring:best-practices-researcher
      - ring:framework-docs-researcher
      - ring:product-designer
      focus: External best practices, framework patterns, and user problem validation
    modification:
      description: Changing or extending existing functionality
      primary_agents:
      - ring:repo-research-analyst
      secondary_agents:
      - ring:product-designer
      focus: Existing codebase patterns and conventions, UX impact assessment
    integration:
      description: Connecting systems or adding external dependencies
      primary_agents:
      - ring:framework-docs-researcher
      - ring:best-practices-researcher
      - ring:repo-research-analyst
      secondary_agents:
      - ring:product-designer
      focus: API documentation, integration patterns, and user experience considerations
  sequence:
    before:
    - ring:pre-dev-prd-creation
    - ring:pre-dev-feature-map
  skip_when: |
    - Trivial changes that don't need planning
    - Research already completed (research.md exists and is recent)
  trigger: |
    - Before any pre-dev workflow (Gate 0)
    - When planning new features or modifications
    - Invoked by /ring:pre-dev-full and /ring:pre-dev-feature
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

**Run 4 agents in PARALLEL** (single message, 4 Task calls):

| Agent | Prompt Focus | Mode |
|-------|--------------|------|
| `ring:repo-research-analyst` | Codebase patterns for [feature]. Search docs/solutions/ knowledge base. Return file:line references. | PRIMARY in modification |
| `ring:best-practices-researcher` | External best practices for [feature]. Use Context7 + WebSearch. Return URLs. | PRIMARY in greenfield |
| `ring:framework-docs-researcher` | Tech stack docs for [feature]. Detect versions from manifests. Use Context7. Return version constraints. | PRIMARY in integration |
| `ring:product-designer` | User problem validation, personas, competitive UX analysis, design constraints for [feature]. Mode: `ux-research`. | PRIMARY in greenfield, SECONDARY in others |

**Task invocation for product-designer:**
```
Task(
  subagent_type="ring:product-designer",
  prompt="Analyze user needs for [feature]. Mode: ux-research. Return: problem validation, preliminary personas, competitive analysis, design constraints."
)
```

## Step 2.5: Handle Topology Configuration

**If TopologyConfig is provided** (from command's topology discovery):

1. **Persist in research.md frontmatter:**
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
  modules:  # Only if monorepo or multi-repo
    backend:
      path: {path}
      language: golang | typescript
    frontend:
      path: {path}
      framework: nextjs | react | vue
  doc_organization: unified | per-module
  api_pattern: direct | bff | other  # Only if scope=fullstack
---
```

**Document Placement (based on topology.structure):**

| Structure | research.md Location |
|-----------|---------------------|
| single-repo | `docs/pre-dev/{feature-name}/research.md` |
| monorepo | `docs/pre-dev/{feature-name}/research.md` (root) |
| multi-repo | Write to BOTH: `{backend.path}/docs/pre-dev/{feature-name}/research.md` AND `{frontend.path}/docs/pre-dev/{feature-name}/research.md` |

**Multi-repo directory creation:**
```bash
# Create directories in both repos
mkdir -p "{backend.path}/docs/pre-dev/{feature-name}"
mkdir -p "{frontend.path}/docs/pre-dev/{feature-name}"
```

**Multi-repo sync note:** Add this footer to research.md for multi-repo:
```markdown
---
**Sync Status:** This document is maintained in both repositories.
- Primary: {backend.path}/docs/pre-dev/{feature-name}/research.md
- Mirror: {frontend.path}/docs/pre-dev/{feature-name}/research.md
```

2. **Adjust agent dispatch for multi-module projects:**

If `topology.structure` is `monorepo` or `multi-repo`:
- **ring:repo-research-analyst:** Run ONCE per module path
  - Backend: Search `{topology.modules.backend.path}` for patterns
  - Frontend: Search `{topology.modules.frontend.path}` for patterns
- **Combine findings** in single research.md with module sections:
  ```markdown
  ### Codebase Research

  #### Backend Module ({path})
  [Agent output for backend]

  #### Frontend Module ({path})
  [Agent output for frontend]
  ```

3. **TopologyConfig flows to all subsequent gates:**
- Gate 1 (PRD): Reads topology from research.md frontmatter
- Gate 2 (Feature Map): Uses topology for domain mapping
- Gate 7 (Task Breakdown): Tags tasks with `target:` based on topology

## Step 3: Aggregate Research Findings

**Output:**
- **single-repo/monorepo:** `docs/pre-dev/{feature-name}/research.md`
- **multi-repo:** Both `{backend.path}/docs/pre-dev/{feature-name}/research.md` AND `{frontend.path}/docs/pre-dev/{feature-name}/research.md`

| Section | Content |
|---------|---------|
| **Metadata (YAML frontmatter)** | date, feature, research_mode, agents_dispatched, topology |
| **Executive Summary** | 2-3 sentences synthesizing key findings |
| **Research Mode** | Why selected, what it means for focus |
| **Codebase Research** | Agent output (file:line references) |
| **Best Practices Research** | Agent output (URLs) |
| **Framework Documentation** | Agent output (version constraints) |
| **Product/UX Research** | Agent output (user problem, personas, design constraints) |
| **Synthesis** | Key patterns to follow (file:line, URL, doc ref); Constraints identified; Prior solutions from docs/solutions/; UX considerations; Open questions for PRD |

## Step 4: Gate 0 Validation

**BLOCKING CHECKLIST:**

| Check | Required For |
|-------|--------------|
| Research mode documented | All modes |
| All 4 agents returned | All modes |
| research.md created | All modes |
| TopologyConfig in frontmatter | All modes (if provided by command) |
| At least one file:line reference | modification, integration |
| At least one external URL | greenfield, integration |
| docs/solutions/ searched | All modes |
| Tech stack versions documented | All modes |
| Product/UX research documented | All modes |
| User problem identified | All modes |
| Synthesis section complete | All modes |
| Module-specific research (if multi-module) | monorepo, multi-repo |

**If validation fails:**
- Missing agent output → Re-run that agent
- No codebase patterns (modification) → May need mode change
- No external docs (greenfield) → Try different search terms
- No UX research (product-designer) → Re-run product-designer agent

## Integration with Pre-Dev Workflow

**ring:pre-dev-full (10-gate):** Gate 0 Research → Gate 1 PRD (reads research.md) → ... → Gate 3 TRD (reads research.md)

**ring:pre-dev-feature (5-gate):** Gate 0 Research → Gate 1 PRD → Gate 2 TRD → Gate 3 Tasks

## Research Document Usage

**In Gate 1 (PRD):** Reference existing patterns with file:line; cite docs/solutions/; include external URLs; note framework constraints

**In Gate 3 (TRD):** Reference implementation patterns; use version constraints; cite similar implementations

## Anti-Patterns

1. **Skipping research for "simple" features** - Even simple features benefit from convention checks
2. **Wrong research mode** - Greenfield with heavy codebase research wastes time; modification without codebase research misses patterns
3. **Ignoring docs/solutions/** - Prior solutions are gold; prevents repeating mistakes
4. **Vague references without file:line** - "There's a pattern somewhere" is not useful; exact locations enable quick reference

---

## Standards Loading (MANDATORY)

This skill is a research/analysis skill and does NOT require WebFetch of language-specific standards.

**Purpose:** This skill gathers research BEFORE technical decisions are made. Standards are loaded in TRD (Gate 3) after research establishes context.

**However**, research agents dispatched by this skill (e.g., `ring:framework-docs-researcher`) MUST use WebSearch and Context7 to gather current best practices.

---

## Blocker Criteria - STOP and Report

| Condition | Action | Severity |
|-----------|--------|----------|
| Research mode cannot be determined | STOP and ask user for clarification | CRITICAL |
| All 4 research agents failed to return results | STOP and investigate connectivity/availability | CRITICAL |
| No docs/solutions/ directory exists to search | Continue but document as limitation | MEDIUM |
| TopologyConfig provided but invalid | STOP and request valid topology | HIGH |
| research.md cannot be created (permissions) | STOP and report filesystem error | CRITICAL |

---

## Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST dispatch all 4 research agents in parallel
- MUST determine research mode BEFORE dispatching agents
- MUST include product/UX research via `ring:product-designer`
- MUST aggregate findings into research.md with file:line references
- MUST search docs/solutions/ for prior solutions
- MUST document tech stack versions from manifests
- CANNOT skip synthesis section

---

## Severity Calibration

| Severity | Definition | Example |
|----------|------------|---------|
| **CRITICAL** | Research cannot proceed | All research agents failed, no mode determined |
| **HIGH** | Research incomplete but usable | Missing agent output (1 of 4) |
| **MEDIUM** | Research quality degraded | No file:line references in codebase research |
| **LOW** | Minor gaps in documentation | Missing one external URL reference |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip research, just write the PRD" | "Cannot proceed. Research prevents reinventing existing patterns. Gate 0 takes 30 minutes, saves hours of rework." |
| "We already researched this manually" | "Cannot skip automated research. Manual research may miss codebase patterns. I'll run systematic analysis now." |
| "Only run codebase research, skip external" | "Cannot skip agents. Mode determines focus, not exclusion. Greenfield needs external research; modification needs both." |
| "Product research isn't needed, we know users" | "Cannot skip product-designer. User assumptions need validation. UX research prevents building wrong features." |
| "docs/solutions/ is empty, skip that check" | "Cannot skip the check. Empty result is documented. Future features benefit from knowing what doesn't exist." |

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Feature is simple, research is overkill" | Simple features have conventions too. Research validates simplicity | **Run all 4 agents regardless of perceived simplicity** |
| "I know the codebase, skip repo research" | Personal knowledge isn't documented or shared | **Run ring:repo-research-analyst anyway** |
| "External best practices don't apply to us" | Best practices exist for reasons. Evaluate, don't dismiss | **Run ring:best-practices-researcher** |
| "Framework docs are the same as last time" | Versions change. Patterns evolve. Check current state | **Run ring:framework-docs-researcher** |
| "User research slows us down" | Building wrong features slows down 100x more | **Run ring:product-designer in ux-research mode** |
| "Synthesis is just summary, I can skip it" | Synthesis extracts actionable insights. Summary isn't enough | **Complete synthesis section with patterns/constraints** |

---

## When This Skill Is Not Needed

- Trivial changes that don't need planning (< 1 hour work)
- research.md already exists and is recent (< 7 days old)
- Bug fixes with known root cause requiring no design research
- Documentation-only updates
- Pure refactoring with no new functionality
- Configuration changes requiring no architectural research
