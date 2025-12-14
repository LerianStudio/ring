Generate an executive summary of portfolio status for leadership.

## Usage

```
/ring-pmo-team:executive-summary [type] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `type` | No | Report type: `dashboard`, `board`, `escalation` (default: dashboard) |

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--period` | Reporting period | `--period "Q4 2024"` |
| `--audience` | Target audience | `--audience "Board of Directors"` |
| `--source` | Source data file | `--source docs/pmo/data.md` |
| `--output` | Output file | `--output docs/pmo/exec-summary.md` |

## Examples

```bash
# Weekly dashboard
/ring-pmo-team:executive-summary dashboard

# Board package
/ring-pmo-team:executive-summary board --period "Q4 2024"

# Escalation report
/ring-pmo-team:executive-summary escalation

# Custom audience
/ring-pmo-team:executive-summary --audience "Steering Committee"
```

## Report Types

| Type | Audience | Content | Length |
|------|----------|---------|--------|
| **Dashboard** | Executive team | Weekly/monthly status | 1-2 pages |
| **Board** | Board of Directors | Quarterly summary | 5-10 pages |
| **Escalation** | Sponsor/Executive | Critical issue | 1 page |
| **Stakeholder** | Key stakeholders | Project update | 1 page |

## Output

- **Dashboard**: `docs/pmo/{date}/executive-dashboard.md`
- **Board Package**: `docs/pmo/{date}/board-package.md`
- **Escalation**: `docs/pmo/{date}/escalation-{issue}.md`

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-pmo-team:portfolio-review` | Conduct full review first |
| `/ring-pmo-team:dependency-analysis` | Add dependency details |

---

## MANDATORY: Load Full Skill

**This command MUST load the executive-reporting skill for complete workflow execution.**

```
Use Skill tool: ring-pmo-team:executive-reporting
```

The skill contains the complete reporting workflow with:
- Audience analysis
- Data gathering
- Insight development
- Report creation
- Review and delivery

## Execution Flow

### Step 1: Dispatch Executive Reporter

```
Task tool:
  subagent_type: "ring-pmo-team:executive-reporter"
  model: "opus"
  prompt: "Create [type] executive report. Audience: [audience]. Period: [period]."
```

### Step 2: If Source Data Missing, Dispatch Portfolio Manager

```
Task tool:
  subagent_type: "ring-pmo-team:portfolio-manager"
  model: "opus"
  prompt: "Provide portfolio status data for executive report."
```

### Step 3: Review and Validate

Ensure data is accurate and report is balanced.

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I can write the summary myself" | Executive Reporter has communication frameworks | **Dispatch specialist** |
| "Just copy last week's report" | Status changes; stale reports mislead | **Generate from current data** |
| "Make it short, executives are busy" | Short ≠ shallow. Tiered detail required. | **Provide summary + detail available** |

## Output Format

### Dashboard Format

```markdown
# Portfolio Status Dashboard - [Date]

## Executive Summary
[One paragraph: Status, key achievements, concerns, decisions needed]

## Portfolio Health: [GREEN/YELLOW/RED]

| Metric | Value | Trend | Status |
|--------|-------|-------|--------|
| Projects On Track | X/Y | ↑/↓/→ | G/Y/R |
| Budget Utilization | X% | ↑/↓/→ | G/Y/R |
| Resource Utilization | X% | ↑/↓/→ | G/Y/R |

## Items Requiring Attention
1. [Item with impact and recommended action]

## Decisions Required
| Decision | Options | Deadline |
|----------|---------|----------|
| [Decision] | [A, B, C] | [Date] |
```

### Board Package Format

```markdown
# Portfolio Report - [Period]

## 1. Executive Summary
[Strategic overview, portfolio health, key achievements]

## 2. Portfolio Performance
[Project status, metrics, trends]

## 3. Strategic Initiative Status
[Progress on strategic objectives]

## 4. Key Risks and Mitigations
[Top risks with response status]

## 5. Resource and Financial Summary
[Budget and resource utilization]

## 6. Decisions and Approvals Needed
[Board-level decisions required]

## Appendix
[Detailed data]
```

### Escalation Format

```markdown
# ESCALATION: [Issue Title]

## Issue Summary
[One sentence description]

## Impact
- Business Impact: [Description]
- Financial Impact: [$ amount]
- Timeline Impact: [Days/weeks]

## Root Cause
[What caused this issue]

## Options

| Option | Pros | Cons | Cost | Time |
|--------|------|------|------|------|
| A | | | | |
| B | | | | |
| C | | | | |

## Recommendation
[Recommended option with rationale]

## Decision Required By
[Date and decision maker]
```
