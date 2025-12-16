---
name: dependency-analysis
description: Analyze cross-project dependencies across the portfolio
argument-hint: "[scope] [options]"
---

Analyze cross-project dependencies across the portfolio.

## Usage

```
/dependency-analysis [scope] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | No | Projects to analyze (default: all active) |

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--focus` | Focus type | `--focus critical-path` |
| `--depth` | Analysis depth | `--depth external` |
| `--output` | Output file | `--output docs/pmo/deps.md` |
| `--format` | Output format | `--format visual` |

## Examples

```bash
# Full dependency analysis
/dependency-analysis

# Analyze specific projects
/dependency-analysis "Alpha, Beta, Gamma"

# Focus on critical path
/dependency-analysis --focus critical-path

# Include external dependencies
/dependency-analysis --depth external

# Visual dependency map
/dependency-analysis --format visual
```

## Analysis Types

| Type | Description | Use When |
|------|-------------|----------|
| **Internal** | Dependencies between projects | Default analysis |
| **External** | Vendor and third-party dependencies | Supply chain risk |
| **Critical Path** | Dependencies on project critical paths | Schedule risk |
| **Resource** | Shared resource dependencies | Resource conflicts |

## Output

- **Dependency Map**: `docs/pmo/{date}/dependency-map.md`
- **Critical Path Analysis**: `docs/pmo/{date}/critical-path.md`
- **At-Risk Dependencies**: `docs/pmo/{date}/at-risk-deps.md`

## Related Commands

| Command | Description |
|---------|-------------|
| `/portfolio-review` | Include as part of full review |
| `/executive-summary` | Summarize for executives |

---

## MANDATORY: Load Full Skill

**This command MUST load the dependency-mapping skill for complete workflow execution.**

```
Use Skill tool: dependency-mapping
```

The skill contains the complete dependency mapping gates with:
- Dependency identification
- Dependency classification
- Impact analysis
- Critical path analysis
- Dependency tracking plan

## Execution Flow

### Step 1: Gather Project Data

Collect schedule and deliverable information from projects in scope.

### Step 2: Dispatch Portfolio Manager for Cross-Project View

```
Task tool:
  subagent_type: "portfolio-manager"
  model: "opus"
  prompt: "Identify cross-project dependencies for: [scope]"
```

### Step 3: Dispatch Risk Analyst for Dependency Risks

```
Task tool:
  subagent_type: "risk-analyst"
  model: "opus"
  prompt: "Analyze risks associated with identified dependencies"
```

### Step 4: Map Critical Path

Identify which dependencies are on the portfolio critical path.

### Step 5: Generate Tracking Plan

Create monitoring plan for identified dependencies.

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Projects manage their own deps" | Cross-project deps need portfolio view | **Analyze at portfolio level** |
| "Only track hard dependencies" | Soft deps become hard when they fail | **Track all dependency types** |
| "External deps are vendor's problem" | External delays impact your projects | **Include external dependencies** |

## Output Format

```markdown
# Cross-Project Dependency Analysis - [Date]

## Summary

| Metric | Value |
|--------|-------|
| Total Dependencies | N |
| Internal | N |
| External | N |
| On Critical Path | N |
| At Risk | N |

## Dependency Matrix

| From | To | Dependency | Type | Criticality | Status |
|------|-----|------------|------|-------------|--------|
| Project A | Project B | API ready | FS | Critical | On Track |
| Project B | Project C | Data model | FS | High | At Risk |

## Critical Path

```
Project A: [Task A1] → [Task A2] → [Deliverable]
                                        ↓
Project B:                    [Task B1] → [Task B2]
                                               ↓
Project C:                              [Task C1] → [Final]
```

## External Dependencies

| Vendor | Dependency | Due | Status | Risk |
|--------|------------|-----|--------|------|
| Vendor X | API v2 | Dec 15 | Yellow | Medium |

## At-Risk Dependencies

| Dependency | Risk | Impact | Mitigation |
|------------|------|--------|------------|
| B → C Data model | Design delays | 2 week slip | Parallel design work |

## Recommendations

1. [Recommendation with owner]
2. [Recommendation with owner]

## Tracking Plan

| Dependency | Owner | Monitor Freq | Escalation Trigger |
|------------|-------|--------------|-------------------|
| A → B API | PM-A | Weekly | >3 day delay |
```

## Visual Format (--format visual)

When visual format is requested, include ASCII dependency diagram:

```
                    ┌─────────────┐
                    │  Project A  │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
              ┌─────│  Project B  │─────┐
              │     └─────────────┘     │
              │                         │
       ┌──────▼──────┐          ┌───────▼──────┐
       │  Project C  │          │   Project D  │
       └──────┬──────┘          └──────────────┘
              │
       ┌──────▼──────┐
       │  Project E  │
       └─────────────┘

Legend:
─── Direct dependency
=== Critical path dependency
- - At-risk dependency
```
