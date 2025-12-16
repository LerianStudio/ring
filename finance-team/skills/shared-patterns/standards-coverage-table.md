# Standards Coverage Table

This file defines which financial standards each agent must verify.

## Agent to Standards Section Index

Each agent in ring-finance-team MUST verify the sections listed in this table.

| Agent | Standards Sections to Verify |
|-------|------------------------------|
| `ring-finance-team:financial-analyst` | Data Accuracy, Calculation Verification, Ratio Analysis, Trend Analysis, Benchmarking |
| `ring-finance-team:budget-planner` | Budget Structure, Assumption Documentation, Variance Analysis, Approval Workflow, Version Control |
| `ring-finance-team:financial-modeler` | Model Structure, Assumption Registry, Sensitivity Analysis, Scenario Management, Validation Tests |
| `ring-finance-team:treasury-specialist` | Cash Position, Liquidity Metrics, Forecast Accuracy, Investment Compliance, Risk Limits |
| `ring-finance-team:accounting-specialist` | GAAP/IFRS Compliance, Journal Entry Standards, Reconciliation Requirements, Close Procedures, Audit Trail |
| `ring-finance-team:metrics-analyst` | KPI Definitions, Data Lineage, Calculation Methodology, Visualization Standards, Anomaly Detection |

---

## Financial Standards Categories

### Data Accuracy Standards

| Standard | Requirement | Verification Method |
|----------|-------------|---------------------|
| Source Document Reference | All figures trace to source | Check citation/link |
| Data Vintage | Date of data clearly stated | Check timestamp |
| Currency Specification | Currency explicitly stated | Check headers |
| Unit Specification | Units (thousands, millions) clear | Check labels |
| Rounding Rules | Consistent rounding applied | Verify calculations |

### Calculation Standards

| Standard | Requirement | Verification Method |
|----------|-------------|---------------------|
| Formula Documentation | Formulas explicitly shown | Check documentation |
| Input Validation | Inputs verified before calculation | Check validation steps |
| Cross-Foot Check | Rows and columns sum correctly | Verify totals |
| Reasonableness Test | Results within expected range | Check against benchmarks |
| Independent Verification | Second calculation performed | Document verification |

### Documentation Standards

| Standard | Requirement | Verification Method |
|----------|-------------|---------------------|
| Assumption Registry | All assumptions listed | Check assumptions section |
| Methodology Description | Methods clearly explained | Check methodology section |
| Limitation Disclosure | Limitations explicitly stated | Check limitations section |
| Version Control | Version and date tracked | Check version info |
| Change Log | Changes documented | Check change history |

### Reporting Standards

| Standard | Requirement | Verification Method |
|----------|-------------|---------------------|
| Clear Presentation | Data clearly organized | Visual inspection |
| Consistent Formatting | Numbers formatted consistently | Check formatting |
| Footnotes Where Needed | Complex items explained | Check footnotes |
| Executive Summary | Key findings summarized | Check summary section |
| Actionable Recommendations | Clear next steps provided | Check recommendations |

---

## How to Use This File

Agents MUST reference this table when performing standards compliance checks:

```markdown
## Standards Compliance

Per [shared-patterns/standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md), this agent verifies:

| Standard Category | Status | Notes |
|-------------------|--------|-------|
| Data Accuracy | COMPLIANT/NON-COMPLIANT | [Finding details] |
| Calculation Standards | COMPLIANT/NON-COMPLIANT | [Finding details] |
| Documentation Standards | COMPLIANT/NON-COMPLIANT | [Finding details] |
| Reporting Standards | COMPLIANT/NON-COMPLIANT | [Finding details] |
```

---

## Compliance Determination

| Status | Criteria |
|--------|----------|
| **COMPLIANT** | All requirements in category met |
| **PARTIAL** | Some requirements met, gaps documented |
| **NON-COMPLIANT** | Critical requirements not met |
| **N/A** | Category does not apply to this analysis |

**CRITICAL:** A single non-compliant critical requirement = overall NON-COMPLIANT status.

---

## Cross-Reference Documentation

When this file is updated, also update:
- Agent files referencing specific standards
- Skill files that perform compliance checks
- CLAUDE.md standards-agent synchronization table
