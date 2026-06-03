## Scoring Guide

### Per-Dimension Scoring (0-10 each)

| Score | Criteria |
|-------|----------|
| 10 | Exemplary - fully aligned with Ring standards, could serve as reference |
| 8-9 | Strong - minor deviations from Ring standards |
| 6-7 | Adequate - meets basic requirements but missing some Ring patterns |
| 4-5 | Concerning - multiple gaps vs Ring standards |
| 2-3 | Poor - significant non-compliance with Ring standards |
| 0-1 | Critical - fundamentally misaligned or missing |

### Deductions Per Dimension

- Each CRITICAL issue: -3 points (includes HARD GATE violations)
- Each HIGH issue: -1.5 points
- Each MEDIUM issue: -0.5 points
- Each LOW issue: -0.25 points
- Minimum score: 0 (no negative scores)

### Category Weights

| Category | Dimensions | Count | Max Score |
|----------|------------|-------|-----------|
| A: Code Structure | 1-5, 28-30, 35, 38, 42 | 11 | 110 |
| B: Security | 6-9, 33*, 37, 41, 43, 44 | 9 (+1c) | 90 (+10c) |
| C: Operations | 11-15, 36, 39 | 7 | 70 |
| D: Quality | 16-23, 31, 40 | 10 | 100 |
| E: Infrastructure | 24-27, 32, 34 | 6 | 60 |
| **Total** | | **43 (+1c = 44)** | **430 (+10c = 440)** |

*c = conditional (Multi-Tenant). dynamic_max = 430 + (10 if MULTI_TENANT=true)*

### Overall Classification (Percentage-Based)

| Score Range | Percentage | Classification |
|-------------|------------|----------------|
| 90%+ of dynamic_max | 90%+ | Production Ready |
| 75-89% of dynamic_max | 75-89% | Ready with Minor Remediation |
| 50-74% of dynamic_max | 50-74% | Needs Significant Work |
| Below 50% of dynamic_max | <50% | Not Production Ready |

---

## Usage Example

```
User: /production-readiness-audit
```

---

## Assistant Execution Protocol

When this skill is invoked, follow this exact protocol:

### Step 1: Initialize Todo List

```
TodoWrite: Create todos for stack detection, standards loading, all 5 batches + consolidation
```

### Step 2: Detect Stack (Step 0)

Use Glob and Grep to detect:
- GO, TS_BACKEND, FRONTEND, DOCKER, MAKEFILE, LICENSE, MULTI_TENANT flags

### Step 3: Load Standards (Step 0.5)

Use WebFetch to load Ring standards based on detected stack. Store content for injection into explorer prompts.

**If WebFetch fails for any module:** Note the failure and proceed with generic patterns for affected dimensions.

### Step 4: Initialize Report File

Write the report header with Audit Configuration to `docs/audits/production-readiness-{YYYY-MM-DDTHH:MM:SS}.md`

### Step 5: Launch Parallel Explorers (Batch 1)

**CRITICAL**: Use a SINGLE response with 10 Task tool calls for agents 1-10.

Each Task call should include:
- The full explorer prompt from the dimension
- Injected Ring standards content between ---BEGIN STANDARDS--- / ---END STANDARDS--- markers
- Detected stack information
- Instruction to search the codebase thoroughly

### Step 6: Launch Parallel Explorers (Batch 2)

Launch 10 agents (11-20) in a SINGLE response.

### Step 7: Launch Parallel Explorers (Batch 3)

Launch 10 agents (21-30) in a SINGLE response.

### Step 8: Launch Parallel Explorers (Batch 4)

Launch agents 31-42 in a SINGLE response. Note: Agent 33 (Multi-Tenant) is CONDITIONAL — only include if MULTI_TENANT=true was detected in Step 2.

### Step 9: Launch Parallel Explorers (Batch 5)

Launch agents 43-44 in a SINGLE response.

### Step 10: Collect Results

As each explorer completes, mark its todo as completed and append to report.

### Step 11: Consolidate Report

Once ALL explorers complete:
1. Calculate scores for each dimension (0-10 scale)
2. Calculate category totals (A: /110, B: /90-100, C: /70, D: /100, E: /60)
3. Calculate overall score (/{dynamic_max})
4. Aggregate critical/high/medium/low counts
5. Determine readiness classification (percentage-based)
6. Generate Standards Compliance Cross-Reference table
7. Generate the consolidated report

### Step 12: Write Report

```
Write: docs/audits/production-readiness-{YYYY-MM-DDTHH:MM:SS}.md
```

### Step 12.5: Visual Readiness Dashboard

**MANDATORY: Generate a visual HTML dashboard from the audit results.**

Invokes `Skill("ring:visualize")` to produce a self-contained HTML page showing the production readiness score and findings visually. The markdown report is exhaustive (thousands of lines) — the HTML dashboard provides an executive overview that opens in the browser.

**Read templates first:** Read `default/skills/visualize/templates/code-diff.html` for severity badges and KPI card patterns, AND read `default/skills/visualize/templates/data-table.html` for table/heatmap patterns. Combine patterns for an audit dashboard layout. Also read `default/skills/visualize/references/responsive-nav.md` for section navigation (7 sections require sidebar TOC).

**Generate the HTML dashboard with these sections:**

**1. Score Hero**
- Large overall score display: `{score}/{dynamic_max}` with percentage
- Readiness classification badge (Production Ready / Ready with Minor Remediation / Needs Significant Work / Not Production Ready)
- Color-coded: green (90%+), yellow (75-89%), orange (50-74%), red (<50%)

**2. Category Scoreboard**
- 5 category cards (A: Structure, B: Security, C: Operations, D: Quality, E: Infrastructure)
- Each card shows: score/max, percentage bar, critical/high/medium/low counts with severity badges
- Visual progress bars per category

**3. Dimension Scores Heatmap**
- All 44 dimensions in a grid/table
- Color-coded cells: 8-10 green, 6-7 yellow, 4-5 orange, 0-3 red
- Grouped by category with subtotals

**4. HARD GATE Violations** (if any)
- Prominent red section listing all HARD GATE violations
- Each violation shows: dimension, standard reference, evidence, remediation

**5. Critical Blockers** (if any)
- Per-blocker cards with: severity badge, description, file:line references, impact, remediation steps

**6. Remediation Roadmap**
- 4-phase timeline: Immediate (blockers) → Short-term (HIGH) → Medium-term (MEDIUM) → Backlog (LOW)
- Issue count per phase
- Collapsible details per phase

**7. Standards Compliance Summary**
- Table showing which Ring standards were checked and their compliance status
- Collapsible per-standard details

**Output:** Save to `docs/audits/production-readiness-{YYYY-MM-DDTHH:MM:SS}-dashboard.html`

**Open in browser:**
```text
macOS: open docs/audits/production-readiness-{YYYY-MM-DDTHH:MM:SS}-dashboard.html
Linux: xdg-open docs/audits/production-readiness-{YYYY-MM-DDTHH:MM:SS}-dashboard.html
```

**Tell the user** the file path. The dashboard opens before the verbal summary.

See [dev-team/skills/shared-patterns/anti-rationalization-visual-report.md](../../../../dev-team/skills/shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table.

### Step 13: Present Summary

Provide a verbal summary to the user including:
- Detected stack and standards loaded
- Overall score and classification
- Number of critical/high issues
- HARD GATE violations summary
- Top 3 recommendations
- Link to full report and visual dashboard

---

## Customization Options

Users can customize the audit:

### Scope Limiting

```
User: /production-readiness-audit --modules=matching,ingestion
```

Only audit specified modules.

### Dimension Selection

```
User: /production-readiness-audit --dimensions=security
```

Run only security-related auditors (6, 7, 8, 9, 37, 41, 43, 44, 33).

### Output Format

```
User: /production-readiness-audit --format=json
```

Output structured JSON instead of markdown.

### Standards Override

```
User: /production-readiness-audit --no-standards
```

Run without Ring standards injection (generic mode, equivalent to v2.0 behavior).

---

## Integration with CI/CD

This skill can be automated:

1. Run audit on every release branch
2. Block merges if CRITICAL issues exist
3. Block merges if HARD GATE violations exist (Ring standards)
4. Track debt trends over time
5. Generate dashboards from JSON output
6. Compare scores across audit runs to measure standards adoption

---

## Reference Patterns Source

The reference implementations in this skill are derived from two sources:

### Ring Development Standards (Primary - Source of Truth)
Standards loaded at runtime via WebFetch from `dev-team/docs/standards/`:
- **golang/*.md** — Go-specific standards (core, bootstrap, security, domain, API patterns, quality, architecture, messaging, domain-modeling, idempotency, multi-tenant)
- **devops.md** — Container, Makefile, and infrastructure standards
- **sre.md** — Observability and health check standards

### Core two Codebase (Legacy Reference)
Original reference implementations derived from the Core two codebase, which serves as the organizational standard for:
- Hexagonal architecture per bounded context
- lib-observability telemetry plus lib-commons database/messaging integration
- lib-auth integration (JWT validation, tenant extraction)
- Fiber HTTP framework conventions

When auditing projects, findings are compared against Ring standards as the authoritative reference. Core two patterns remain as supplementary examples.

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| Stack Detection | Cannot detect project stack (no go.mod, package.json, etc.) | STOP and ask user to specify stack |
| Batch Failure | Entire batch of agents fails to complete | STOP and report - investigate infrastructure issue |
| Report File | Cannot write to docs/audits/ directory | STOP and report - ensure directory exists and is writable |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- MUST load Ring standards before dispatching explorers - audit without standards is not Ring-compliant
- MUST run ALL applicable dimensions (43 base + 1 conditional) - partial audits are incomplete
- MUST include HARD GATE violations prominently in report - they CANNOT be buried in findings
- CANNOT mark audit complete without generating both markdown report AND HTML dashboard

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | HARD GATE violation per Ring standards | MUST be fixed before production deployment - blocks release |
| HIGH | Security vulnerability or missing auth protection | MUST fix before completing audit remediation |
| MEDIUM | Quality issue or missing best practice | Should fix - improves maintainability |
| LOW | Style inconsistency or documentation gap | Fix in next iteration |

## Pressure Resistance

| User Says | Your Response |
|---|---|
| "Just audit security, skip the rest" | "CANNOT run partial audit unless --dimensions flag is specified. Full audit (44 dimensions) is required for production readiness assessment." |
| "Skip the standards loading, just run generic checks" | "CANNOT audit without Ring standards unless --no-standards flag is specified. Standards are the source of truth for compliance." |
| "We need to deploy tomorrow, mark it production ready" | "CANNOT mark production ready if CRITICAL issues or HARD GATE violations exist. Report shows actual state - deployment decision is yours." |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "Most dimensions passed, skip the remaining ones" | Partial audit hides unknown risks. Each dimension covers unique production concerns. | **MUST complete all 44 dimensions** |
| "Standards fetch is slow, use cached version" | Cached standards may be outdated. Ring standards evolve - fresh fetch ensures accuracy. | **MUST WebFetch current standards** |
| "HARD GATE violations are minor for this project" | HARD GATE means NON-NEGOTIABLE per Ring standards. Project size doesn't change compliance. | **MUST report HARD GATE violations prominently** |
| "HTML dashboard is optional, markdown is enough" | Dashboard provides executive visibility. Both outputs are required for complete audit. | **MUST generate both markdown and HTML dashboard** |
