---
name: create-budget
description: Create budget or forecast with documented assumptions and approval workflow
argument-hint: "[type] [options]"
---

Create budget or forecast with documented assumptions and approval workflow.

## Usage

```
/create-budget [type] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `type` | Yes | Budget type: `annual`, `departmental`, `project`, `forecast` |

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--period` | Budget period | `--period "FY2025"` |
| `--methodology` | Budgeting methodology | `--methodology "zero-based"` |
| `--department` | Specific department | `--department "Engineering"` |
| `--template` | Use template file | `--template docs/budget-template.xlsx` |
| `--prior` | Prior period reference | `--prior docs/budget-2024.xlsx` |

## Examples

```bash
# Annual operating budget
/create-budget annual --period FY2025

# Departmental budget
/create-budget departmental --department "Sales" --period FY2025

# Zero-based budget
/create-budget annual --methodology zero-based --period FY2025

# Rolling forecast update
/create-budget forecast --period "Q2-Q4 2025"

# Using prior year reference
/create-budget annual --period FY2025 --prior docs/budget-2024.xlsx
```

## Prerequisites

1. **Period specification**: Clear budget period
2. **Prior period data** (recommended): Historical actuals or prior budget
3. **Strategic initiatives**: Key initiatives to incorporate
4. **Constraints**: Any budget constraints or targets

## Budget Types

| Type | Description |
|------|-------------|
| `annual` | Full fiscal year operating budget |
| `departmental` | Single department budget |
| `project` | Project-specific budget |
| `forecast` | Rolling or updated forecast |
| `capital` | Capital expenditure budget |

## Methodologies

| Method | Description |
|--------|-------------|
| `incremental` | Prior year + adjustments |
| `zero-based` | Every item justified from zero |
| `driver-based` | Tied to activity drivers |
| `top-down` | Allocate from corporate total |
| `bottom-up` | Aggregate from detail |

## Output

The command produces a comprehensive budget including:

- Budget Summary with totals
- Assumptions documented with rationale
- Line Item Detail with owners
- Variance Analysis to prior period/target
- Approval Status tracking
- Version History

## Related Commands

| Command | Description |
|---------|-------------|
| `/analyze-financials` | Financial analysis |
| `/build-model` | Build financial model |

---

## MANDATORY: Load Full Skill

**This command MUST load the skill for complete workflow execution.**

```
Use Skill tool: budget-creation
```

The skill contains the complete 6-phase workflow with:
- Planning requirements
- Assumption development process
- Line item build structure
- Consolidation checks
- Approval workflow
- Documentation standards

## Execution Context

Pass the following context to the skill:

| Parameter | Value |
|-----------|-------|
| `type` | `$1` (first argument: annual, departmental, project, forecast) |
| `--period` | If provided, budget period |
| `--methodology` | If provided, budgeting methodology |
| `--department` | If provided, specific department |
| `--template` | If provided, template file path |
| `--prior` | If provided, prior period reference |

## Step 1: ASK BUDGET PARAMETERS (MANDATORY)

**After loading skill and before building budget, you MUST ask:**

```yaml
AskUserQuestion:
  questions:
    - question: "What is the budget methodology?"
      header: "Methodology"
      options:
        - label: "Incremental"
          description: "Prior year + adjustments"
        - label: "Zero-Based"
          description: "Every item justified from zero"
        - label: "Driver-Based"
          description: "Tied to activity drivers"
        - label: "Top-Down"
          description: "Allocate from corporate total"
        - label: "Bottom-Up"
          description: "Aggregate from detail"
    - question: "What are the key constraints or targets?"
      header: "Constraints"
      freeform: true
```

**Do NOT skip this.** Budget type alone does not define methodology.

## Quick Reference

See skill `budget-creation` for full details. Key rules:

- **All assumptions documented** - With rationale and owner
- **All line items have owners** - Accountability required
- **All approvals documented** - Written approval
- **Version control maintained** - Complete change history
- **Variance explained** - All material variances
