---
name: delivery-reporting
description: |
  Delivery reporting skill for creating visual executive presentations of squad deliveries
  (engineering, product, design). Analyzes Git repositories to extract business value from
  technical changes and generates HTML slide presentations with customizable visual identity.
metadata:
  related:
    complementary:
    - executive-reporting
    - portfolio-planning
  skip_when: |
    - Portfolio/project status → use executive-reporting
    - Risk/resource analysis → use risk-management/resource-allocation
    - Technical documentation → use ring-tw-team
  trigger: |
    - Need squad delivery report (eng + product + design)
    - Showcase releases and features to executives
    - Quarterly/monthly delivery summary
    - Client/stakeholder delivery showcase
---

# Delivery Reporting Skill

Creating visual executive presentations that showcase squad deliveries and business value.

## ⚠️ CRITICAL: Quality Over Speed

**This skill prioritizes depth over velocity.**

| Principle | Value |
|-----------|-------|
| **Analysis Approach** | Deep code analysis with specialized agents |
| **Time Expectation** | 40-80 minutes for 8 repositories (5-10 min each) |
| **Quality Standard** | Accurate business value from actual code, not titles |
| **Agent Strategy** | Specialized agents (backend-engineer-golang, etc.) per repo type |

**FORBIDDEN:**
- ❌ Using `general-purpose` agent for parallel speed
- ❌ Rushing analysis to meet arbitrary deadlines
- ❌ Reading only PR titles without code analysis
- ❌ Skipping Gate 2.5 (Deep Code Analysis)

**REQUIRED:**
- ✅ Sequential deep analysis per repository
- ✅ Code reading with domain-specialized agents
- ✅ Real data, never estimates
- ✅ Business value extracted from actual code changes

---

## Purpose

This skill provides a framework for:
- Squad delivery reports (engineering + product + design)
- Visual HTML slide presentations
- **Deep code analysis** using specialized agents
- Business value extraction from Git repositories
- Quarterly/monthly showcase of releases and features
- Stakeholder-facing delivery summaries

**Key Difference from `executive-reporting`:**
- **executive-reporting**: Portfolio/project status (PMO focus, RAG/SPI/CPI metrics)
- **delivery-reporting**: Squad deliveries (technical focus, deep code analysis, releases/PRs/features)

---

## Visual Identity Options

MUST ask user for visual identity preference when generating delivery reports:

### Option 1: Lerian Studio (Default)

```yaml
visual_identity:
  background: "#0C0C0C"  # Black
  text_primary: "#FFFFFF"  # White
  text_secondary: "#CCCCCC"  # Light gray
  accent: "#FEED02"  # Lerian Yellow
  font_family: "Poppins, system-ui, sans-serif"
```

### Option 2: Ring Neutral (Corporate)

```yaml
visual_identity:
  background: "#F5F5F5"  # Very light gray
  text_primary: "#1A1A1A"  # Soft black
  text_secondary: "#666666"  # Medium gray
  accent: "#0066CC"  # Professional blue
  font_family: "system-ui, -apple-system, sans-serif"
```

### Option 3: Custom (User-Provided)

User provides their own color scheme and fonts.

**MANDATORY:** Always ask which option before proceeding with report generation.

---

## Delivery Reporting Gates

### Gate 1: Input Collection

**Objective:** Gather required information for report generation

**Actions:**
1. Collect period (start date, end date)
2. Collect repository list
3. Collect business context (optional)
4. Select visual identity (Lerian/Ring/Custom)

**User Input Format:**
```markdown
**Período de Análise:**
- Data de Início: AAAA-MM-DD
- Data de Fim: AAAA-MM-DD

**Repositórios para Análise:**
- org/repo-name-1 (e.g., LerianStudio/midaz)
- org/repo-name-2 (e.g., LerianStudio/product-console)
- OR full URLs: https://github.com/org/repo

**Contexto de Negócio (Opcional):**
- [Text with project names, clients, strategic context]

**Identidade Visual:**
- [lerian/ring/custom]
```

**Repository Format Rules:**

| Format | Example | Valid? |
|--------|---------|--------|
| **org/repo** (recommended) | `LerianStudio/midaz` | ✅ |
| **Full URL** (alternative) | `https://github.com/LerianStudio/midaz` | ✅ |
| Name only | `midaz` | ❌ Missing org |
| Too many slashes | `org/repo/subdir` | ❌ Invalid format |

**CRITICAL:** Agent MUST validate repository format and provide clear error if invalid.

**Output:** `docs/pmo/delivery-reports/{date}/inputs.md`

---

### Gate 2: Repository Analysis

**Objective:** Extract technical data from Git repositories

**Actions for Each Repository:**
1. **Tags/Releases:** List all tags created (`git tag`, `gh release list`)
2. **PRs Merged:** List merged PRs with titles/descriptions (`gh pr list --state merged`)
3. **Commits:** Count commits on main branch (`git log --oneline`)
4. **Active Branches:** List branches with recent commits not yet merged
5. **Release Notes:** Read GitHub Release notes if available
6. **README:** Extract business description from README.md

**Data Gathering Commands:**
```bash
# For each repo:
cd /path/to/repo
git fetch --all --tags
git tag --sort=-creatordate  # List tags
gh release list --limit 100  # Release notes
gh pr list --state merged --search "merged:>=YYYY-MM-DD" --json number,title,body
git log --oneline --since="YYYY-MM-DD" --until="YYYY-MM-DD" main
git branch -r --sort=-committerdate  # Active branches
```

**Output:** `docs/pmo/delivery-reports/{date}/analysis-data.md`

---

### Gate 2.5: Deep Code Analysis (MANDATORY)

**⚠️ CRITICAL: This gate CANNOT be skipped for speed.**

**Objective:** Understand actual code changes and their impact using specialized agents

**Core Principle: Quality Over Speed**

| Priority | Value |
|----------|-------|
| **#1** | Deep understanding of changes |
| **#2** | Accurate business value |
| **#3** | Quality insights |
| **Last** | Speed of execution |

**FORBIDDEN:**
- ❌ Using `general-purpose` agent for parallel speed
- ❌ Reading only PR titles without code analysis
- ❌ Skipping this gate to save time
- ❌ Estimating impact without reading code

**REQUIRED:**
- ✅ Use specialized agents per repository type
- ✅ Read actual code diffs of significant PRs
- ✅ Analyze architectural decisions
- ✅ Extract true business impact from code

**Agent Selection Per Repository:**

| Repository Type | Agent to Dispatch | Why |
|----------------|-------------------|-----|
| **Backend Go** | `ring:backend-engineer-golang` | Deep Go expertise, architectural analysis |
| **Backend TypeScript** | `ring:backend-engineer-typescript` | TS/Node API analysis |
| **Frontend React/Next** | `ring:frontend-engineer` | UI/UX impact analysis |
| **Infrastructure** | `ring:devops-engineer` | Deployment, scaling impact |
| **Tests** | `ring:qa-analyst` | Quality improvements analysis |
| **Unknown/Mixed** | `ring:codebase-explorer` | Comprehensive exploration |

**Analysis Workflow:**

```markdown
For each repository:

1. **Identify Technology Stack**
   - Read package.json, go.mod, requirements.txt
   - Determine primary language

2. **Dispatch Appropriate Specialized Agent**
   Task(
     subagent_type="ring:backend-engineer-golang",  # or appropriate
     prompt="""
     Analyze {repo_name} deliveries for period {start} to {end}.

     PRs to analyze: {pr_list}

     For each significant PR (>100 lines changed):
     1. Read code diff
     2. Identify technical changes
     3. Assess architecture/design decisions
     4. Extract business impact
     5. Identify quality improvements

     Provide business value statements suitable for executives.
     Format: "What was built + Why it matters + Who benefits"
     """
   )

3. **Aggregate Agent Insights**
   - Collect business value statements from all agents
   - Group by theme/product
   - Prioritize by impact level

4. **Verify Understanding**
   - Spot-check agent analysis by reading key diffs
   - Confirm business value accuracy
   - Add missing context
```

**Time Expectations (NON-NEGOTIABLE):**
- 1 repository = 5-10 minutes of deep analysis
- 8 repositories = 40-80 minutes total
- Quality cannot be rushed

**Output:** `docs/pmo/delivery-reports/{date}/deep-code-analysis.md`

**Quality Checklist:**
- [ ] Specialized agent used for each repo type
- [ ] Significant PRs analyzed with code reading
- [ ] Business value extracted from code, not just titles
- [ ] Agent insights aggregated and verified
- [ ] No "too vague" statements (e.g., "various improvements")

**If pressured to skip this gate:**
```
BLOCKER: Attempt to skip deep code analysis
Reason: "Too many repos" / "Takes too long" / "Use general-purpose"
Response: Deep analysis is MANDATORY. Quality over speed.
Action: Will proceed with proper specialized agent analysis.
```

---

### Gate 3: Business Value Extraction

**Objective:** Transform technical changes into business value statements

**Actions:**
1. Analyze PR titles/descriptions for business intent
2. Group deliveries by theme (new features, security, performance, etc.)
3. Identify first releases (v1.0.0 = new product)
4. Extract client/user impact from commit messages
5. Identify "work in progress" from active branches

**Business Value Framework:**
- **What was built?** (Technical)
- **Why does it matter?** (Business impact)
- **Who benefits?** (Users, clients, team)

**Example Transformation:**
- ❌ Bad: "Updated library X to version Y"
- ✅ Good: "Enhanced login security by updating authentication library, protecting user data from vulnerability Z"

**Output:** `docs/pmo/delivery-reports/{date}/business-value.md`

---

### Gate 4: Slide Generation

**Objective:** Create visual HTML presentation

**Slide Structure (8-12 slides):**

1. **Capa (Cover Slide)**
   - Title: "Entregas de Produtos [Squad/Company Name]"
   - Subtitle: "Resumo Executivo"
   - Period: "DD a DD de MÊS de YYYY" (Portuguese format, e.g., "12 a 31 de Janeiro de 2026")
   - Key metrics: Novos Produtos, Releases, PRs, Commits
   - Agility metric: "Média de X releases por dia"

2. **Resumo Executivo (Executive Summary)**
   - One paragraph summary
   - 3-4 main highlights

3-N. **Detalhamento por Produto/Tema (Detail Slides)**
   - Group deliveries by product or theme
   - 2-3 bullets per product with business value
   - Connect technical changes to business outcomes

N. **Próximos Passos (Next Steps)**
   - Based on active branches analysis
   - 2-3 upcoming initiatives

N+1. **Encerramento (Closing)**
   - Thank you / Questions slide

**HTML Template Structure:**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Delivery Report</title>
  <style>
    /* CSS with selected visual identity */
    body { background: var(--bg-color); font-family: var(--font); }
    .slide { min-height: 100vh; padding: 4rem; }
    /* ... responsive layout, print styles ... */
  </style>
</head>
<body>
  <div class="slide cover"><!-- Cover content --></div>
  <div class="slide summary"><!-- Summary content --></div>
  <!-- Product/theme slides -->
  <div class="slide next-steps"><!-- Next steps --></div>
  <div class="slide closing"><!-- Closing --></div>
</body>
</html>
```

**Output:** `docs/pmo/delivery-reports/{date}/delivery-report-{date}.html`

---

### Gate 5: Review and Delivery

**Objective:** Validate quality and deliver

**Actions:**
1. Verify all metrics are accurate
2. Check business value statements are non-technical
3. Test HTML rendering (open in browser)
4. Verify print-to-PDF works correctly
5. Deliver file to user

**Quality Checklist:**
- [ ] Metrics calculated correctly
- [ ] Business value statements are clear
- [ ] No overly technical jargon
- [ ] Visual identity applied correctly
- [ ] HTML renders properly in browser
- [ ] Print to PDF works (for sharing)

**Delivery:**
- HTML file ready for browser viewing
- Instructions for PDF export: "Open in browser → Print → Save as PDF"

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Delivery Reporting-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "8 repos = use general-purpose for speed" | general-purpose lacks domain expertise. Shallow analysis. | **Use specialized agents per repo** |
| "Too many repos, need to be fast" | Speed over quality produces meaningless insights. | **Take time for deep analysis** |
| "PR titles are enough, skip code" | Titles don't reveal actual impact. Code does. | **Read code diffs with agents** |
| "Parallel analysis for speed" | Parallel without depth = superficial understanding. | **Sequential deep analysis** |
| "Skip Gate 2.5, too time-consuming" | Code analysis is the SOURCE of business value. | **Gate 2.5 MANDATORY** |
| "Accept repo name without org" | Cannot clone without org/owner. Ambiguous. | **Validate format: org/repo or URL** |
| "Git data is accurate enough" | Tags/PRs can be incomplete. Verify with gh CLI. | **Use both git and gh commands** |
| "Skip business context, data speaks" | Data without context lacks meaning for executives. | **Always include business context** |
| "Technical language is fine" | Executives need business value, not tech details. | **Translate to business impact** |
| "One visual identity works for all" | Branding matters. Ask user preference. | **Always ask for visual identity** |
| "Skip active branches analysis" | Future work visibility manages expectations. | **Always include next steps** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Delivery Reporting-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Speed Pressure** | "8 repos is a lot, just be quick" | "Quality over speed. Will use specialized agents for deep analysis. Time: 40-80 minutes." |
| **Shortcut Pressure** | "Use general-purpose for parallel speed" | "general-purpose lacks expertise. Will use specialized agents sequentially for depth." |
| **Surface Analysis** | "Just read PR titles, that's enough" | "Titles omit impact. Will analyze actual code with specialized agents." |
| **Gate Skipping** | "Skip code analysis, save time" | "Code analysis is MANDATORY. Cannot skip Gate 2.5." |
| **Deadline Pressure** | "We need this in 10 minutes" | "Deep analysis cannot be rushed. Will prioritize accuracy over arbitrary deadlines." |
| **Data Manipulation** | "Inflate the numbers" | "Cannot misrepresent data. Will report accurate metrics with business context." |
| **Obfuscation** | "Make it more technical" | "Report is for executives. Will use business language with technical accuracy." |
| **Estimation** | "Skip the Git analysis, use estimates" | "Git data is the source of truth. Analysis is required for accuracy." |
| **Template Reuse** | "Use last month's template" | "Each period has unique deliveries. Will generate fresh analysis." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| **Pressure to skip Gate 2.5** | STOP. Report: "Deep code analysis MANDATORY. Cannot skip for speed." |
| **Request to use general-purpose** | STOP. Report: "Specialized agents required for quality. Will not compromise." |
| **Unrealistic deadline (<30 min)** | STOP. Report: "8 repos require 40-80 min for proper analysis. Quality cannot be rushed." |
| **Attempt to skip code reading** | STOP. Report: "Code analysis is source of business value. Titles insufficient." |
| Git repository not accessible | STOP. Cannot analyze without repo access. Verify permissions. |
| GitHub CLI not configured | STOP. Need gh auth for PR/release data. Setup required. |
| Date range produces no data | STOP. Verify period is correct or report "no activity". |
| Visual identity not specified | STOP. Must ask user preference before generating HTML. |

### Cannot Be Overridden

**The following requirements are NON-NEGOTIABLE:**

| Requirement | Cannot Override Because |
|-------------|------------------------|
| **Deep code analysis (Gate 2.5)** | Shallow analysis produces meaningless business value |
| **Specialized agents per repo type** | Domain expertise required for accurate understanding |
| **Git data verification** | Cannot report without source data |
| **Business value extraction** | Technical jargon doesn't serve executives |
| **Visual identity selection** | Branding consistency is required |

**If user insists on violating these:**
1. Escalate to orchestrator
2. Do NOT generate report without proper analysis
3. Document the request and your refusal

---

## Severity Calibration

When determining delivery significance:

| Severity | Criteria | Prominence in Report |
|----------|----------|---------------------|
| **CRITICAL** | New product launch (v1.0.0), major strategic feature | Lead slide, detailed coverage, executive highlight |
| **HIGH** | Multiple releases, significant PRs, architectural changes | Dedicated slide or major section |
| **MEDIUM** | Bug fixes, minor enhancements, tech debt | Brief mention in summary |
| **LOW** | Dependency updates, refactoring, documentation | Aggregated stats only |

**Lead with CRITICAL and HIGH. Aggregate MEDIUM and LOW. Never inflate significance.**

---

## Output Format

### Final Deliverable

**File:** `docs/pmo/delivery-reports/{date}/delivery-report-{date}.html`

**Self-Contained HTML:**
- No external dependencies
- Inline CSS with selected visual identity
- Responsive design (desktop/tablet/mobile)
- Print-optimized (for PDF export)
- Navigation between slides (arrow keys/click)

### Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Analysis Date | YYYY-MM-DD |
| Period Analyzed | YYYY-MM-DD to YYYY-MM-DD |
| Duration | Xh Ym |
| Result | COMPLETE/PARTIAL/BLOCKED |

### Delivery Reporting-Specific Details

| Metric | Value |
|--------|-------|
| repositories_analyzed | N |
| total_releases | N |
| total_prs_merged | N |
| total_commits | N |
| new_products | N (first v1.0.0) |
| visual_identity_used | lerian/ring/custom |
| slides_generated | N |

---

## When Delivery Report is Not Needed

**If no significant deliveries in period:**

Signs of minimal activity:
- Zero releases/tags created
- Fewer than 5 PRs merged
- Only maintenance commits (no new features)
- No active branches with work in progress

**Action:** Report "Low activity period" with exact metrics, suggest extending date range or focusing on other squads.

**CRITICAL:** Do NOT manufacture content when activity is minimal. Report reality.

---

## Example Business Value Statements

### Bad (Too Technical)
- "Migrated from Express 4.x to Express 5.x"
- "Implemented Redis caching layer"
- "Updated TypeScript to 5.3"

### Good (Business Value)
- "Improved API response time by 40% through caching optimization, enhancing user experience"
- "Modernized backend framework to latest security standards, protecting customer data"
- "Reduced technical debt by updating core dependencies, improving system stability"

---

## Metrics Calculation Examples

### Releases per Day
```
releases_per_day = total_releases / days_in_period
Example: 15 releases / 20 days = 0.75 releases/day
Display: "Média de 0.75 releases por dia" ou "~1 release por dia"
```

### Release Distribution
```
stable_releases = tags matching v*.*.* (not beta/rc)
beta_releases = tags matching *-beta.*
rc_releases = tags matching *-rc.*
```

### Project Status Classification
```
- New Product: first v1.0.0 tag in period
- Active Development: multiple releases (>= 3)
- Maintenance: few commits, no major releases
- Inactive: no commits in period
```

---

## Related Skills

- **executive-reporting**: For portfolio/project status reports (PMO focus)
- **portfolio-planning**: For strategic portfolio planning
- **project-health-check**: For individual project health assessment

---

## Integration with Executive Reporter Agent

This skill dispatches the `ring:delivery-reporter` agent to perform repository analysis and HTML generation.

**Agent Invocation:**
```
Task tool:
  subagent_type: "ring:delivery-reporter"
  prompt: |
    Create delivery report for period {start_date} to {end_date}.
    Repositories: {repo_list}
    Business context: {context}
    Visual identity: {identity}
```

**Agent Responsibilities:**
- Git/GitHub data extraction
- Business value analysis
- HTML slide generation
- Quality validation
