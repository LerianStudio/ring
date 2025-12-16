---
name: using-finance-team
description: |
  6 specialist financial agents for analysis, budgeting, modeling, treasury,
  accounting, and metrics. Dispatch when you need deep financial expertise.

trigger: |
  - Need financial analysis or reporting
  - Building budgets or forecasts → budget-planner
  - Financial modeling (DCF, projections) → financial-modeler
  - Cash flow or treasury management → treasury-specialist
  - Accounting operations or close → accounting-specialist
  - KPI dashboards or metrics → metrics-analyst

skip_when: |
  - General code review → use default plugin reviewers
  - Brazilian regulatory compliance → use ring-finops-team
  - Planning/design → use brainstorming

related:
  similar: [using-ring, using-finops-team]
---

# Using Ring Finance Specialists

The ring-finance-team plugin provides 6 specialized financial agents. Use them via `Task tool with subagent_type:`.

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) and [using-ring](https://raw.githubusercontent.com/LerianStudio/ring/main/default/skills/using-ring/SKILL.md) for canonical workflow requirements and ORCHESTRATOR principle. This skill introduces finance-team-specific agents.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch agents to handle complexity; don't operate tools directly.

**Domain Distinction:**
- **ring-finops-team**: Brazilian regulatory compliance (BACEN, RFB, Open Banking)
- **ring-finance-team**: Financial operations, analysis, planning, and modeling

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Decision Type | Examples | Action |
|--------------|----------|--------|
| **Accounting Standards** | GAAP vs IFRS treatment | STOP. Report options and implications. Wait for user. |
| **Valuation Method** | DCF vs Comparable vs Precedent | STOP. Report trade-offs. Wait for user. |
| **Forecast Methodology** | Top-down vs Bottom-up | STOP. Check existing patterns. Ask user. |
| **Materiality Threshold** | What constitutes material | STOP. This is a management decision. Ask user. |
| **Recognition Timing** | When to recognize revenue/expense | STOP. Requires judgment. Ask user. |

**You CANNOT make financial judgment decisions autonomously. STOP and ask.**

---

## Common Misconceptions - REJECTED

| Misconception | Reality |
|--------------|---------|
| "I can calculate this myself" | ORCHESTRATOR principle: dispatch specialists, don't calculate directly. This is NON-NEGOTIABLE. |
| "Simple ratio, no specialist needed" | Ratio interpretation requires context. Specialists have standards loading. MUST dispatch. |
| "Just need a quick estimate" | Quick estimates without documentation create liability. DISPATCH is REQUIRED. |
| "I know finance well enough" | Specialists have financial standards loading. You don't. MUST dispatch. |
| "Faster if I calculate myself" | Faster ≠ auditable. Specialist output follows documentation standards. DISPATCH is REQUIRED. |

**Self-sufficiency bias check:** If you're tempted to calculate directly, ask:
1. Is there a specialist for this? (Check the 6 specialists below)
2. Would a specialist document assumptions I might skip?
3. Am I avoiding dispatch because it feels like "overhead"?

**If ANY answer is yes -> You MUST DISPATCH the specialist. This is NON-NEGOTIABLE.**

---

## Anti-Rationalization Table

**If you catch yourself thinking ANY of these, STOP:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is a simple calculation, no need for specialist" | Simplicity doesn't reduce documentation requirements. | **DISPATCH specialist** |
| "I already know how to calculate this ratio" | Your knowledge ≠ auditable documentation by specialist. | **DISPATCH specialist** |
| "Dispatching takes too long for just numbers" | Quality > speed. Specialist documents all assumptions. | **DISPATCH specialist** |
| "I'll just estimate and note it's approximate" | Estimates without basis create liability. | **DISPATCH specialist** |
| "The specialist will just do what I would do" | Specialists have financial anti-rationalization. You don't. | **DISPATCH specialist** |
| "This doesn't need full documentation" | ALL financial work needs documentation. No exceptions. | **Follow documentation standards** |
| "I've already done 80% of the analysis" | Past work doesn't justify wrong approach. Dispatch specialist, verify compliance. | **STOP. DISPATCH specialist. Accept sunk cost.** |
| "Quick draft first, proper analysis later" | Drafts become finals. Standards apply to ALL work. | **DISPATCH specialist BEFORE any calculation** |

---

### Cannot Be Overridden

**These requirements are NON-NEGOTIABLE:**

| Requirement | Why It Cannot Be Waived |
|-------------|------------------------|
| **Dispatch to specialist** | Specialists have standards loading, you don't |
| **Assumption documentation** | Undocumented assumptions create liability |
| **Source verification** | Unverified data leads to wrong conclusions |
| **Independent verification** | Single-point-of-failure in calculations |
| **Audit trail** | Missing trails fail audits |

**User cannot override these. Time pressure cannot override these. "Quick estimate" cannot override these.**

---

## Pressure Resistance

**When facing pressure to bypass specialist dispatch:**

| User Says | Your Response |
|-----------|---------------|
| "Board meeting in an hour, no time for specialist" | "I understand the urgency. However, specialists ensure auditable documentation. I'll dispatch with URGENT context. This takes 5-10 minutes, not hours." |
| "You've already done 80% of this analysis" | "Sunk cost doesn't justify wrong approach. The 80% may lack proper documentation. I MUST dispatch the specialist to verify compliance." |
| "CFO said you don't need the specialist for this" | "I respect the CFO's experience, but Ring standards require specialist dispatch. Specialists have financial standards that ensure audit readiness." |
| "This is just internal analysis, no specialist needed" | "Internal analysis becomes external evidence. Every analysis MUST follow documentation standards. I CANNOT calculate without specialist dispatch." |
| "Just round to the nearest million, don't be precise" | "Rounding decisions require documented rationale. I'll dispatch specialist to determine appropriate precision." |

**Critical Reminder:**
- **Urgency does not equal permission to bypass** - Rushed analysis has higher error risk
- **Authority does not equal permission to bypass** - Ring standards override preferences
- **Internal use does not equal permission to bypass** - Internal becomes external under audit

---

## 6 Financial Specialists

| Agent | Specializations | Use When |
|-------|-----------------|----------|
| **`financial-analyst`** | Ratio analysis, trend analysis, benchmarking, variance analysis, financial statement analysis | Financial health assessment, performance analysis, investment evaluation |
| **`budget-planner`** | Budget creation, forecasting, variance analysis, rolling forecasts, zero-based budgeting | Annual budgets, departmental budgets, budget-to-actual analysis |
| **`financial-modeler`** | DCF models, LBO models, merger models, scenario analysis, sensitivity analysis | Valuation, investment analysis, strategic planning, M&A |
| **`treasury-specialist`** | Cash flow forecasting, liquidity management, working capital, FX exposure, debt management | Cash position, liquidity planning, treasury operations |
| **`accounting-specialist`** | Journal entries, reconciliations, close procedures, GAAP/IFRS compliance, audit support | Month-end close, year-end close, accounting entries, compliance |
| **`metrics-analyst`** | KPI definition, dashboard design, performance metrics, data visualization, anomaly detection | Executive dashboards, KPI tracking, performance monitoring |

**Dispatch template:**
```
Task tool:
  subagent_type: "{agent-name}"
  model: "opus"
  prompt: "{Your specific request with context}"
```

---

## When to Use Finance Specialists vs FinOps

### Use Finance Specialists (ring-finance-team) for:
- Financial analysis and reporting
- Budgeting and forecasting
- Financial modeling (DCF, scenarios)
- Treasury and cash management
- Accounting operations
- KPI and metrics dashboards

### Use FinOps Specialists (ring-finops-team) for:
- Brazilian regulatory compliance (BACEN)
- Tax reporting (RFB, DIMP, eFinanceira)
- Open Banking Brasil requirements
- Regulatory template generation

**Both can be used together:** Use finance specialists for analysis, then finops specialists for regulatory formatting.

---

## Dispatching Multiple Specialists

If you need multiple specialists (e.g., financial-analyst + budget-planner), dispatch in **parallel** (single message, multiple Task calls):

```
CORRECT:
Task #1: financial-analyst
Task #2: budget-planner
(Both run in parallel)

WRONG:
Task #1: financial-analyst
(Wait for response)
Task #2: budget-planner
(Sequential = 2x slower)
```

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** - Dispatch specialists, don't calculate directly
- **Don't perform analysis yourself** - Dispatch to specialist, they have standards
- **Combine with using-ring principle** - Skills + Specialists = complete workflow

### Good Example (ORCHESTRATOR):
> "I need a DCF valuation. Let me dispatch `financial-modeler` to build it."

### Bad Example (OPERATOR):
> "I'll calculate the DCF myself and just note my assumptions."

---

## Available in This Plugin

**Agents:** See "6 Financial Specialists" table above.

**Skills:**
- `using-finance-team` (this) - Plugin introduction
- `financial-analysis` - Comprehensive financial analysis workflow
- `budget-creation` - Budget planning and forecasting workflow
- `financial-modeling` - Financial model building workflow
- `cash-flow-analysis` - Cash flow and liquidity workflow
- `financial-reporting` - Financial report preparation workflow
- `metrics-dashboard` - KPI and metrics workflow
- `financial-close` - Month/year-end close workflow

**Commands:**
- `/analyze-financials` - Run financial analysis
- `/create-budget` - Create budget or forecast
- `/build-model` - Build financial model

**Note:** Missing agents? Check `.claude-plugin/marketplace.json` for ring-finance-team plugin.

---

## Financial Workflows

| Workflow | Entry Point | Output |
|----------|-------------|--------|
| **Financial Analysis** | `/analyze-financials` | Analysis report with findings |
| **Budget Creation** | `/create-budget` | Budget document with assumptions |
| **Financial Model** | `/build-model` | Model with scenarios and sensitivity |

**Key Principle:** All financial work follows documentation and verification standards.

---

## Integration with Other Plugins

- **using-ring** (default) - ORCHESTRATOR principle for ALL agents
- **using-finops-team** - Brazilian regulatory compliance
- **using-dev-team** - Development when building financial systems
- **using-pm-team** - Planning for financial features

Dispatch based on your need:
- Financial analysis/modeling -> ring-finance-team agents
- Regulatory compliance -> ring-finops-team agents
- System development -> ring-dev-team agents
- Feature planning -> ring-pm-team agents
