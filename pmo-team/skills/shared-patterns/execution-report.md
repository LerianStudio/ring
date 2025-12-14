# Execution Report Format for PMO

This file defines the standard execution report format for all PMO activities.

## Standard Report Structure

Every PMO skill MUST produce an execution report with these base metrics:

| Metric | Value | Description |
|--------|-------|-------------|
| Analysis Date | YYYY-MM-DD | Date of analysis |
| Scope | Projects/Portfolio | What was analyzed |
| Duration | Xh Ym | Time spent on analysis |
| Result | COMPLETE/PARTIAL/BLOCKED | Analysis outcome |

## How to Use This File

Skills should reference this format and add domain-specific metrics:

```markdown
## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Analysis Date | YYYY-MM-DD |
| Scope | [Description] |
| Duration | Xh Ym |
| Result | COMPLETE/PARTIAL/BLOCKED |

### Domain-Specific Details
[Add domain-specific metrics here]
```

## Domain-Specific Metric Examples

### Portfolio Planning

| Metric | Description |
|--------|-------------|
| projects_reviewed | Number of projects analyzed |
| capacity_utilization | Current portfolio capacity usage (%) |
| strategic_alignment_score | Average alignment score (1-5) |
| recommendations_count | Number of recommendations generated |

### Resource Allocation

| Metric | Description |
|--------|-------------|
| roles_analyzed | Number of roles/skills reviewed |
| allocation_conflicts | Number of resource conflicts identified |
| utilization_average | Average resource utilization (%) |
| gap_count | Number of skill/capacity gaps identified |

### Risk Management

| Metric | Description |
|--------|-------------|
| risks_identified | Total risks in register |
| risks_by_severity | Critical/High/Medium/Low counts |
| mitigation_plans | Risks with documented mitigations |
| overdue_actions | Risk actions past due date |

### Project Health Check

| Metric | Description |
|--------|-------------|
| health_score | Overall health score (1-10) |
| schedule_variance | SV in days or percentage |
| cost_variance | CV in currency or percentage |
| scope_changes | Number of scope changes since baseline |

### Dependency Mapping

| Metric | Description |
|--------|-------------|
| dependencies_total | Total dependencies mapped |
| critical_path_deps | Dependencies on critical path |
| external_deps | Dependencies on external parties |
| at_risk_deps | Dependencies with issues |

### Executive Reporting

| Metric | Description |
|--------|-------------|
| projects_reported | Number of projects in report |
| status_distribution | Green/Yellow/Red counts |
| escalations | Items requiring executive action |
| decisions_needed | Pending decision count |

### PMO Retrospective

| Metric | Description |
|--------|-------------|
| period_covered | Time period analyzed |
| projects_completed | Projects closed in period |
| lessons_captured | Number of lessons learned |
| process_improvements | Improvements identified |
