---
name: metrics-dashboard
description: |
  KPI and metrics dashboard workflow covering metric definition, data sourcing,
  visualization design, and anomaly detection. Delivers actionable dashboards.

trigger: |
  - Defining KPIs and metrics
  - Designing executive dashboards
  - Implementing performance tracking
  - Setting up anomaly detection

skip_when: |
  - Detailed financial analysis → use financial-analysis
  - Building models → use financial-modeling
  - Preparing reports → use financial-reporting

related:
  similar: [financial-reporting, financial-analysis]
  uses: [metrics-analyst]
---

# Metrics Dashboard Workflow

This skill provides a structured workflow for designing KPI dashboards using the `metrics-analyst` agent.

## Workflow Overview

The metrics dashboard workflow follows 5 phases:

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Requirements | Define dashboard objectives and audience |
| 2 | KPI Design | Define metrics and methodology |
| 3 | Data Architecture | Map data sources and calculations |
| 4 | Visualization | Design visual presentation |
| 5 | Implementation | Build and validate |

---

## Phase 1: Requirements

**MANDATORY: Define dashboard objectives before building**

### Questions to Answer

| Question | Purpose |
|----------|---------|
| What decisions will this support? | Ensures relevance |
| Who is the primary audience? | Tailors complexity |
| What frequency of update? | Sets refresh requirements |
| What level of drill-down? | Scopes depth |
| What benchmark comparisons? | Defines targets |

### Dashboard Types

| Type | Audience | Focus |
|------|----------|-------|
| Executive | C-Suite | High-level, strategic |
| Operational | Managers | Detailed, actionable |
| Departmental | Department heads | Function-specific |
| Board | Directors | Governance, strategic |

### Blocker Check

**If ANY of these are unclear, STOP and ask:**
- Dashboard purpose
- Primary audience
- Key decisions supported
- Update frequency required

---

## Phase 2: KPI Design

**MANDATORY: Define all metrics with methodology**

### KPI Definition Standard

| Element | Requirement |
|---------|-------------|
| Name | Clear, concise name |
| Definition | Precise description |
| Formula | Exact calculation |
| Unit | Measurement unit |
| Target | Performance target |
| Owner | Accountable person |
| Frequency | Update cadence |

### KPI Categories

| Category | Example KPIs |
|----------|-------------|
| Financial | Revenue, margin, EBITDA, cash flow |
| Operational | Throughput, cycle time, utilization |
| Customer | Retention, NPS, LTV, CAC |
| Growth | ARR growth, customer growth, expansion |

### KPI Selection Principles

| Principle | Description |
|-----------|-------------|
| Relevance | Supports specific decisions |
| Measurable | Can be quantified objectively |
| Actionable | Drives specific actions |
| Timely | Available when needed |
| Owned | Clear accountability |

---

## Phase 3: Data Architecture

**MANDATORY: Document data lineage completely**

### Data Source Mapping

| Element | Documentation |
|---------|---------------|
| Source system | Where data originates |
| Extraction method | How data is obtained |
| Transformation | Any calculations or adjustments |
| Refresh frequency | How often updated |
| Data quality | Validation checks |

### Data Quality Requirements

| Check | Validation |
|-------|------------|
| Completeness | All required data present |
| Accuracy | Data matches source |
| Timeliness | Data is current |
| Consistency | Data consistent across sources |

---

## Phase 4: Agent Dispatch

**Dispatch to specialist with full context**

### Agent Dispatch

```
Task tool:
  subagent_type: "metrics-analyst"
  model: "opus"
  prompt: |
    Design metrics dashboard per these specifications:

    **Purpose**: [from Phase 1]
    **Audience**: [from Phase 1]
    **Update Frequency**: [from Phase 1]

    **KPIs Required**:
    [From Phase 2 - list with definitions]

    **Data Sources**:
    [From Phase 3 - source mapping]

    **Required Output**:
    - KPI definitions with formulas
    - Data source documentation
    - Calculation methodology
    - Visualization specifications
    - Anomaly thresholds
    - Implementation guide
```

### Required Output Elements

| Element | Requirement |
|---------|-------------|
| Metrics Summary | Dashboard overview |
| KPI Definitions | Complete definitions |
| Data Sources | Source documentation |
| Calculation Methodology | Formula details |
| Dashboard Design | Visual specifications |
| Anomaly Analysis | Threshold definitions |
| Recommendations | Enhancement suggestions |

---

## Phase 5: Implementation

**MANDATORY: Validate before deployment**

### Implementation Checklist

| Check | Validation |
|-------|------------|
| Data feeds working | All sources connected |
| Calculations verified | Outputs match expected |
| Visuals rendering | Display correctly |
| Refresh working | Updates as expected |
| Access controlled | Right users have access |

### Validation Tests

| Test | Description |
|------|-------------|
| Data reconciliation | Dashboard ties to source |
| Historical comparison | Trends make sense |
| Edge cases | Handles nulls, zeros |
| Performance | Loads in acceptable time |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures.

### Dashboard-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just show the numbers" | "Numbers without methodology cannot be trusted. I'll include documentation." |
| "Pick the most important KPIs" | "KPI selection requires business input. Which decisions should these support?" |
| "Skip the data quality checks" | "Unreliable data undermines dashboard value. I'll validate all sources." |
| "Copy the existing dashboard" | "Each dashboard needs fresh design. I'll validate requirements." |

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Dashboard-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Everyone knows what revenue means" | Definitions vary | **DEFINE specifically** |
| "Data source is obvious" | Lineage needs documentation | **DOCUMENT source** |
| "Calculation is standard" | Standard still needs documentation | **SHOW formula** |
| "Refresh frequency doesn't matter" | Stale data causes bad decisions | **SPECIFY frequency** |

---

## Execution Report

Upon completion, report:

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| KPIs Defined | N |
| Data Sources Mapped | N |
| Visualizations Designed | N |
| Anomaly Thresholds | N |
| Result | COMPLETE/PARTIAL |

### Quality Indicators

| Indicator | Status |
|-----------|--------|
| All KPIs defined | YES/NO |
| All sources documented | YES/NO |
| All calculations shown | YES/NO |
| Data validated | YES/NO |
| Refresh tested | YES/NO |
