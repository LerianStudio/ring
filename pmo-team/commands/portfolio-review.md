---
name: portfolio-review
description: Conduct a comprehensive portfolio review across multiple projects
argument-hint: "[scope] [options]"
---

Conduct a comprehensive portfolio review across multiple projects.

## Usage

```
/portfolio-review [scope] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | No | Portfolio scope (default: all active projects) |

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--focus` | Focus area for review | `--focus resources` |
| `--output` | Output directory | `--output docs/pmo/q4-review` |
| `--format` | Report format | `--format executive` |

## Examples

```bash
# Full portfolio review
/portfolio-review

# Review specific program
/portfolio-review "Digital Transformation Program"

# Focus on resource utilization
/portfolio-review --focus resources

# Generate executive format
/portfolio-review --format executive
```

## What Gets Reviewed

| Dimension | Agent | Skill |
|-----------|-------|-------|
| Portfolio Health | `portfolio-manager` | `portfolio-planning` |
| Resource Capacity | `resource-planner` | `resource-allocation` |
| Risk Posture | `risk-analyst` | `risk-management` |
| Governance Status | `governance-specialist` | Gate compliance |
| Dependencies | Orchestrator | `dependency-mapping` |

## Output

- **Portfolio Status**: `docs/pmo/{date}/portfolio-status.md`
- **Resource Analysis**: `docs/pmo/{date}/resource-analysis.md`
- **Risk Summary**: `docs/pmo/{date}/risk-summary.md`
- **Recommendations**: `docs/pmo/{date}/recommendations.md`

## Related Commands

| Command | Description |
|---------|-------------|
| `/executive-summary` | Generate executive summary from review |
| `/dependency-analysis` | Deep dive on dependencies |

---

## MANDATORY: Load Full Skill

**This command MUST load the portfolio-planning skill for complete workflow execution.**

```
Use Skill tool: portfolio-planning
```

The skill contains the complete portfolio review gates with:
- Portfolio inventory
- Strategic alignment assessment
- Capacity assessment
- Risk portfolio view
- Portfolio optimization

## Execution Flow

### Step 1: Dispatch Portfolio Manager

```
Task tool:
  subagent_type: "portfolio-manager"
  model: "opus"
  prompt: "Conduct portfolio health assessment. Scope: [scope]. Focus: [focus]."
```

### Step 2: Dispatch Resource Planner (Parallel)

```
Task tool:
  subagent_type: "resource-planner"
  model: "opus"
  prompt: "Analyze resource utilization across portfolio."
```

### Step 3: Dispatch Risk Analyst (Parallel)

```
Task tool:
  subagent_type: "risk-analyst"
  model: "opus"
  prompt: "Assess portfolio risk posture and correlations."
```

### Step 4: Synthesize Findings

Combine outputs from all agents into unified portfolio review.

### Step 5: Generate Recommendations

Based on combined analysis, generate prioritized recommendations.

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I can do this analysis myself" | Specialists have frameworks loaded | **Dispatch all specialists** |
| "Only review troubled projects" | Healthy projects can hide issues | **Review ALL projects in scope** |
| "Sequential dispatch is fine" | Parallel is faster, same quality | **Dispatch in parallel** |

## Output Format

```markdown
# Portfolio Review - [Date]

## Executive Summary
[One paragraph summary of portfolio health]

## Portfolio Health Score: X/10 - [Green/Yellow/Red]

## Key Findings
1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

## Recommendations
1. [Recommendation with owner and deadline]
2. [Recommendation with owner and deadline]

## Decisions Required
| Decision | Options | Deadline |
|----------|---------|----------|
| [Decision] | [Options] | [Date] |

## Detailed Analysis
[Links to detailed reports]
```
