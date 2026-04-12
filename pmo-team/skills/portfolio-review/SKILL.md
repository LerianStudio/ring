---
name: ring:portfolio-review
description: |
  Conduct comprehensive portfolio review by dispatching 4 PMO specialists in parallel
  (portfolio-manager, resource-planner, risk-analyst, governance-specialist) and
  synthesizing findings into a unified report with prioritized recommendations.

trigger: |
  - Quarterly or periodic portfolio health assessment
  - Executive requests portfolio status overview
  - Need cross-project resource, risk, and governance analysis
  - Before strategic planning or budget cycle

skip_when: |
  - Single project review → use ring:project-health-check
  - Single feature planning → use ring:pre-dev-feature or ring:pre-dev-full
  - Code implementation → use ring:dev-cycle
  - Executive summary only (no deep analysis) → use ring:executive-summary

NOT_skip_when: |
  - "Portfolio is small" → Small portfolios hide resource conflicts. Review required.
  - "Only review troubled projects" → Healthy projects can hide emerging issues. Review ALL.
  - "I can do this analysis myself" → Specialists have PMO frameworks loaded. MUST dispatch.
  - "Sequential dispatch is fine" → Parallel is faster, same quality. MUST dispatch in parallel.

related:
  complementary: [ring:portfolio-planning, ring:resource-allocation, ring:risk-management, ring:executive-summary]
  similar: [ring:project-health-check]

input_schema:
  required: []
  optional:
    - name: scope
      type: string
      description: "Portfolio scope (default: all active projects)"
    - name: focus
      type: string
      description: "Focus area for review (e.g., resources, risk, governance)"
    - name: output_dir
      type: string
      description: "Output directory (default: docs/pmo/{date})"
    - name: format
      type: string
      enum: [standard, executive]
      description: "Report format (default: standard)"
---

# Portfolio Review

Conduct a comprehensive portfolio review by dispatching 4 PMO specialists in parallel, then synthesizing their findings into a unified report.

---

## Execution Flow

### Step 1: Dispatch 4 PMO Specialists in Parallel

MUST dispatch all 4 agents in a **single message** using the Task tool. Sequential dispatch is FORBIDDEN.

```
Task #1 (parallel):
  subagent_type: "ring:portfolio-manager"
  prompt: |
    Conduct portfolio health assessment.
    Scope: {scope or "all active projects"}.
    Focus: {focus or "comprehensive"}.
    
    Analyze:
    - Portfolio health score (1-10)
    - Strategic alignment per project
    - Project status (RAG)
    - Portfolio balance (risk vs value)
    - Prioritization recommendations
    
    Output structured findings with evidence.

Task #2 (parallel):
  subagent_type: "ring:resource-planner"
  prompt: |
    Analyze resource utilization across portfolio.
    Scope: {scope or "all active projects"}.
    
    Analyze:
    - Current resource allocation vs capacity
    - Skills gaps and bottlenecks
    - Cross-project resource conflicts
    - Utilization rates per team/individual
    - Upcoming capacity needs
    
    Output structured findings with evidence.

Task #3 (parallel):
  subagent_type: "ring:risk-analyst"
  prompt: |
    Assess portfolio risk posture and correlations.
    Scope: {scope or "all active projects"}.
    
    Analyze:
    - Portfolio-level risk aggregation
    - Cross-project risk correlations
    - Top risks by impact and probability
    - Mitigation status and effectiveness
    - Emerging risks and trends
    
    Output structured findings with evidence.

Task #4 (parallel):
  subagent_type: "ring:governance-specialist"
  prompt: |
    Review governance compliance across portfolio.
    Scope: {scope or "all active projects"}.
    
    Analyze:
    - Gate compliance per project
    - Process adherence metrics
    - Audit readiness status
    - Governance gaps and violations
    - Compliance trend analysis
    
    Output structured findings with evidence.
```

### Step 2: Synthesize Findings

After all 4 agents return, combine their outputs into a unified portfolio review:

1. **Cross-reference** findings across agents (e.g., resource gaps causing project risks)
2. **Identify correlations** (e.g., governance gaps correlating with delivery delays)
3. **Resolve conflicts** (e.g., portfolio-manager vs risk-analyst priority recommendations)
4. **Calculate portfolio health score** based on all dimensions

### Step 3: Generate Prioritized Recommendations

Based on combined analysis:

1. Rank recommendations by impact and urgency
2. Assign owner and deadline to each recommendation
3. Identify decisions that require executive input
4. Flag items that need immediate action vs next cycle

### Step 4: Write Output Files

Write findings to `{output_dir or "docs/pmo/{date}"}`:

- `portfolio-status.md` - Portfolio health and project status
- `resource-analysis.md` - Resource utilization and capacity
- `risk-summary.md` - Risk posture and mitigation status
- `recommendations.md` - Prioritized recommendations with owners

---

## Output Format

```markdown
# Portfolio Review - {Date}

## Executive Summary
{One paragraph summary of portfolio health}

## Portfolio Health Score: X/10 - {Green/Yellow/Red}

## Key Findings
1. {Finding 1}
2. {Finding 2}
3. {Finding 3}

## Recommendations
1. {Recommendation with owner and deadline}
2. {Recommendation with owner and deadline}

## Decisions Required
| Decision | Options | Deadline |
|----------|---------|----------|
| {Decision} | {Options} | {Date} |

## Detailed Analysis
- [Portfolio Status](portfolio-status.md)
- [Resource Analysis](resource-analysis.md)
- [Risk Summary](risk-summary.md)
```

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I can do this analysis myself" | Specialists have PMO frameworks loaded | **Dispatch all 4 specialists** |
| "Only review troubled projects" | Healthy projects can hide emerging issues | **Review ALL projects in scope** |
| "Sequential dispatch is fine" | Parallel is faster, same quality | **Dispatch in parallel** |
| "Portfolio is too small for full review" | Size doesn't determine complexity | **Run full review** |
| "Governance check is optional" | Governance gaps cause downstream failures | **MUST include governance** |
| "Risk assessment is obvious" | Obvious risks are the ones you miss | **Dispatch risk-analyst** |
