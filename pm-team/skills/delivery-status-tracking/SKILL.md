---
name: delivery-status-tracking
description: |
  Delivery status tracking and progress reporting. Analyzes repository against
  delivery roadmap to calculate actual vs planned progress, identify delays,
  and provide insights on velocity and risk trends.
metadata:
  sequence:
    after:
    - ring:pre-dev-delivery-planning
    - ring:executing-plans
    - ring:dev-cycle
    before: []
  skip_when: |
    - No delivery roadmap → create one first with ring:pre-dev-delivery-planning
    - Planning phase only → execute tasks first
    - No repository activity → nothing to analyze
  trigger: |
    - Delivery roadmap exists (from ring:pre-dev-delivery-planning)
    - Need to check progress against plan
    - Stakeholders requesting status update
    - Regular checkpoint (weekly/sprint end)
---

# Delivery Status Tracking - Evidence-Based Progress Reporting

## Foundational Principle

**Every status report must be grounded in repository evidence, not estimates.**

Creating status reports without evidence creates:
- False sense of progress (looks good, actually behind)
- Hidden blockers discovered too late
- Inaccurate projections that break trust
- Decisions based on incomplete data

**Status reports answer**: What is actually done vs what was planned?
**Status reports never answer**: What do people say is done (that's hearsay).

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Input Gathering** | Load delivery-roadmap.md (required), tasks.md (required), subtasks.md (optional), current date (auto or user input) |
| **2. Repository Scan** | Scan ALL branches, commits, PRs, releases; build activity timeline; identify task-related work |
| **3. Task Matching** | Pattern matching (branches, commits, PRs) + semantic analysis (code content vs scope); dispatch specialized agents per task type |
| **4. Completion Calculation** | Per task: analyze scope items found vs expected; calculate % done; determine status (complete/in-progress/not-started) |
| **5. Variance Analysis** | Compare planned vs actual dates; identify delays/early completions; calculate critical path impact |
| **6. Insights Extraction** | Velocity trends, bug rate, review time, code patterns, risk indicators |
| **7. Report Generation** | Save to docs/pre-dev/{feature}/delivery-status-{date}.md; include evidence links |

## Explicit Rules

### ✅ DO Include in Status Report

Evidence from repository (commits, PRs, files, branches), actual dates (start/end per task), % completion based on scope analysis (not estimates), variance calculations (planned vs actual), critical path impact, period status (sprint/cycle if applicable), risk alerts with evidence, insights from code patterns, trend analysis (velocity, quality), GitHub links to evidence

### ❌ NEVER Include in Status Report

Estimates without evidence ("probably 80% done"), assumptions about completion ("looks finished"), status from verbal updates ("team says it's done"), projections without data, missing evidence ("trust me"), vague completion ("almost done"), ignoring delays ("we'll catch up"), skipping semantic analysis for speed

## Rationalization Table

| Excuse | Reality | Required Action |
|--------|---------|-----------------|
| "Pattern matching is enough, skip semantic" | Patterns miss uncommitted work and scope gaps. | **MUST run semantic analysis via specialized agents.** |
| "Current date is obvious, don't ask" | Wrong date = wrong variance calculations. | **MUST get current date (auto or user input).** |
| "Tasks file is optional" | Without tasks, can't validate scope completion. | **STOP. Tasks file is REQUIRED input.** |
| "Main branch only, ignore feature branches" | Work happens in branches first. | **MUST scan all branches, not just main.** |
| "Merged PRs mean 100% done" | PR merged ≠ scope complete. Verify with agents. | **MUST validate scope completion, not just PR status.** |
| "Commit count = progress" | Commit count ≠ scope completion. Analyze content. | **MUST use semantic analysis, not commit metrics.** |
| "Skip delays, report only what's done" | Hiding delays breaks trust. Report accurately. | **MUST report variance (early/late), not just completion.** |
| "User knows what's in code, skip evidence" | Evidence = verifiable. Provide GitHub links. | **MUST include evidence links (commits, PRs, files).** |
| "Insights are optional" | Insights enable decisions. Always include. | **MUST extract velocity, bug rate, review time.** |
| "Quick scan is fine, deep analysis slow" | Deep analysis = accurate. Speed ≠ priority. | **MUST run complete analysis (all branches, semantic).** |

## Red Flags - STOP

If you catch yourself doing any of these, **STOP and ask the user**:

- Reporting completion % without code analysis
- Assuming task is done because PR merged
- Skipping branches (not scanning ALL)
- Using commit count as sole completion metric
- Ignoring scope items (tasks.md not fully validated)
- Missing current date (can't calculate variance)
- No evidence links in report
- Skipping semantic analysis for unmapped tasks
- Vague status ("mostly done", "almost finished")
- No insights section (velocity, trends)

**When you catch yourself**: Run the analysis properly with evidence.

## Mandatory User Questions

**Use AskUserQuestion tool to gather these inputs:**

### Question 1: Repository
- **Header:** "Repository"
- **Question:** "Which repository should I analyze?"
- **Format:** org/repo (e.g., "LerianStudio/my-project")
- **Why:** Determines where to scan for evidence

### Question 2: Delivery Roadmap
- **Header:** "Roadmap Source"
- **Question:** "How do you want to provide the delivery roadmap?"
- **Options:**
  - "File path (local)" - Path to delivery-roadmap.md
  - "GitHub URL (raw)" - Link to file on GitHub
  - "Document link (Google Docs/Notion)" - External document
  - "Paste content" - Copy/paste the markdown
- **Follow-up:** Prompt for the specific path/URL/content based on choice
- **Why:** Need roadmap to know planned dates and tasks

### Question 3: Tasks File
- **Header:** "Tasks Source"
- **Question:** "How do you want to provide the tasks file?"
- **Options:** (same as Question 2)
- **Follow-up:** Prompt for the specific path/URL/content
- **Why:** Need task scope to validate completion (REQUIRED)

### Question 4 (OPTIONAL): Subtasks File
- **Header:** "Subtasks Source"
- **Question:** "Do you have a subtasks file? (Optional for detailed scope analysis)"
- **Options:**
  - "Yes - provide subtasks" - (then same options as Q2/Q3)
  - "No - analyze at task level only"
- **Why:** Subtasks provide finer-grained scope for completion %

### Question 5: Current Date
- **Header:** "Analysis Date"
- **Question:** "What date should I use as 'today' for this analysis?"
- **Options:**
  - "Today (auto-detect)" - System uses current date
  - "Custom date" - User specifies
- **Follow-up (if custom):** "Enter date (DD/MM/YYYY or YYYY-MM-DD):"
- **Why:** Determines variance calculation (planned vs actual as of this date)
- **Note:** System accepts both Brazilian (DD/MM/YYYY) and ISO (YYYY-MM-DD) formats

## Repository Scan Workflow

### Phase 1: Comprehensive GitHub Scan

```bash
# Scan ALL branches (not just main)
git fetch --all
git branch -a

# Get ALL commits (across all branches)
git log --all --pretty=format:"%H|%an|%ae|%ad|%s" --date=iso

# Get ALL PRs (open + closed + merged)
gh pr list --state all --json number,title,state,createdAt,mergedAt,closedAt,author,labels

# Get ALL releases
gh release list --limit 1000

# Get file changes per branch
for branch in $(git branch -a | grep -v HEAD); do
  git diff main..$branch --stat
done
```

### Phase 2: Task Matching Strategy

**For each task from tasks.md:**

**Strategy 1: Pattern Matching (Fast)**
```
1. Branch names:
   - feat/T-001-*
   - fix/T-001-*
   - T-001/* (any prefix)

2. Commit messages:
   - "feat(T-001):"
   - "[T-001]"
   - "T-001:"
   - Contains "T-001" anywhere

3. PR titles:
   - Contains "T-001"
   - Contains task title keywords
```

**Strategy 2: Semantic Matching (Fallback)**
```
If pattern matching finds <50% of expected work:

1. Detect project type:
   - go.mod → ring:backend-engineer-golang
   - package.json + React → ring:frontend-engineer
   - Mixed → ring:codebase-explorer

2. Dispatch agent with task scope:
   Prompt: "Analyze repository and find code implementing:

   Task T-001 scope:
   - PostgreSQL connection pool
   - User table schema
   - CRUD operations
   - Transaction support

   Search all branches. Report which files/commits implement each item."

3. Agent returns:
   - Files found: internal/database/pool.go, migrations/001_users.sql
   - Commits: abc123, def456, ghi789
   - Branches: feat/database-layer, feat/user-model
   - Completion: 4 of 4 scope items found (100%)
```

### Phase 3: Completion Calculation

```
For task T-001:
  Expected scope (from tasks.md):
    - Item 1: PostgreSQL connection pool
    - Item 2: User table schema
    - Item 3: CRUD operations
    - Item 4: Transaction support
    - Item 5: Error handling

  Found in repository (via agent analysis):
    ✅ Item 1: internal/database/pool.go (commit abc123)
    ✅ Item 2: migrations/001_users.sql (commit def456)
    ✅ Item 3: internal/repository/user_repository.go (commit ghi789)
    ✅ Item 4: internal/database/tx.go (commit jkl012)
    ⏳ Item 5: Partial (basic errors, missing custom types)

  Completion: 4.5 of 5 items = 90%
  Status: ⏳ In Progress (>75% but <100%)
```

## Output Template

**Saved to:** `docs/pre-dev/{feature-name}/delivery-status-{YYYY-MM-DD}.md`

```markdown
# Delivery Status Report: {Feature Name}

**Generated:** {YYYY-MM-DD HH:MM} BRT
**Repository:** org/repo
**Analysis Period:** {start-date} to {current-date} ({N} days elapsed)
**Data Sources:** {M} branches, {X} commits, {Y} PRs, {Z} releases analyzed

---

## Executive Summary

| Metric | Planned | Actual | Variance | Health |
|--------|---------|--------|----------|--------|
| **Overall Progress** | X% (by date) | Y% (by scope) | ±Z% | 🟢/⚠️/🔴 |
| **Projected End Date** | YYYY-MM-DD | YYYY-MM-DD | ±N days | 🟢/⚠️/🔴 |
| **Critical Path Status** | On track | Status | Impact | 🟢/⚠️/🔴 |
| **Current Period** | Sprint/Cycle X | Progress | Velocity | 🟢/⚠️/🔴 |
| **Tasks Complete** | N of M | N of M | ±X | 🟢/⚠️/🔴 |
| **Blocked Tasks** | 0 expected | N actual | +N | 🟢/⚠️/🔴 |

---

## Task Status Breakdown

### T-XXX: {Task Title} {Status Icon} ({%} Complete)

**Planned:** Start to End (N days)
**Actual:** Start to End/Current (N days elapsed)
**Variance:** ±N days
**Critical Path:** Yes/No

**GitHub Evidence:**
- **Branches:** `feat/T-XXX-*` ([link])
- **Commits:** N commits ([link to commits])
- **PRs:** #NNN "title" (state) ([link])
- **Files:** N files changed (+X, -Y lines)
- **Releases:** vX.Y.Z (if applicable)

**Scope Analysis (via {specialized-agent}):**
```
Expected scope (from tasks.md):
✅ Scope item 1 → Found in: path/file.go (commit hash)
⏳ Scope item 2 → Partial in: path/file.go (missing X)
⏸️ Scope item 3 → Not found

Completion: X of Y scope items = Z%
```

---

## 🚨 Alerts

### Alert Title {Severity}
**Impact:** Description
**Root Cause:** Analysis from code/commits
**Evidence:** GitHub links
**Projected Impact:** Timeline/scope/resource impact

---

## 📊 Insights & Observations

### Velocity Analysis
| Metric | Planned | Actual | Variance |
|--------|---------|--------|----------|
| **Team Velocity** | Xx | Yx | ±Z% |
| **By Role** | ... | ... | ... |

**Trend:** Analysis of velocity patterns across tasks

### Code Activity Patterns
- **Commit frequency:** X commits/day
- **Average PR size:** X lines/PR
- **Review time:** X days average
- **Commits per task:** X average

### Quality & Risk Indicators
- **Bug fix rate:** N "fix" PRs / M total PRs = X%
- **Refactor activity:** N refactor PRs
- **Test commits:** N of M commits mention "test"

### Observations & Trends
- **Pattern 1:** Large PRs correlate with delays
- **Pattern 2:** Many PRs with "fix" tag → quality issues upstream
- **Pattern 3:** Frontend tasks finishing early → backend bottleneck
- **Pattern 4:** Spill overs accumulating → period duration too short
- _(Other patterns discovered by agents)_

---

## 📈 Progress Visualization

```
Overall Progress:
Planned:  [██████████] 30% (by date)
Actual:   [████████  ] 25% (by scope) ⚠️ -5%

Critical Path:
  T-001: [██████████] 100% (⚠️ +2 days)
  T-002: [██████    ] 60%   (in progress)
  T-003: [          ] 0%    (blocked)
  T-007: [          ] 0%    (not started)

Parallel Stream:
  T-005: [██████████] 100% (✅ -1 day)
  T-006: [          ] 0%    (not started)
```

---

## Period Status (if Sprint/Cycle)

**{Period Type} {N}:** {start} to {end} ({M} days)
**Current:** Day X of M (Y% elapsed)
**Work Complete:** Z% (vs Y% expected)
**Verdict:** 🟢 On track / ⚠️ Behind / ✅ Ahead

**Tasks in period:**
- List with status

---

## Evidence Index

**All analysis based on:**
- Repository: org/repo
- Branches analyzed: {list}
- Date range: {start} to {current}
- Commits: [View all commits](GitHub link)
- PRs: [View all PRs](GitHub link)
- Releases: [View releases](GitHub link)
```

## Specialized Agent Dispatch

### Project Type Detection

```
1. Check repository structure:
   - go.mod exists? → Go project
   - package.json + React? → Frontend project
   - Both? → Full-stack

2. Dispatch appropriate agents:
   - Go → ring:backend-engineer-golang
   - TypeScript Backend → ring:backend-engineer-typescript
   - Frontend → ring:frontend-engineer
   - Unknown/Mixed → ring:codebase-explorer
```

### Agent Analysis Prompt Template

```
Task: T-001 - {Task Title}

Expected Scope (from tasks.md):
- Scope item 1: {description}
- Scope item 2: {description}
- ...

Repository: org/repo
Branches to analyze: ALL (use git branch -a)

Your task:
1. Search repository for code implementing each scope item
2. For each item, report:
   - Status: ✅ Complete / ⏳ Partial / ⏸️ Not Found
   - Files: path/to/file.ext
   - Commits: hash (link)
   - Completeness: What's implemented vs what's missing
3. Calculate: X of Y scope items = Z% complete

Provide evidence with GitHub links.
```

## Input Flexibility Handling

### Roadmap/Tasks Input Types

**Type 1: File Path (Local)**
```
Input: "./docs/pre-dev/auth-system/delivery-roadmap.md"
Action: Read file directly
```

**Type 2: GitHub URL (Raw)**
```
Input: "https://github.com/org/repo/blob/main/docs/..."
Action: Fetch via gh api or WebFetch
```

**Type 3: Document Link (External)**
```
Input: "https://docs.google.com/document/d/..."
Action: WebFetch with prompt "Extract delivery roadmap markdown"
Note: May require authentication - ask user to share as public or paste content
```

**Type 4: Paste Content**
```
Input: User pastes full markdown content
Action: Parse directly from string
```

**Type 5: Upload (Future)**
```
Input: User uploads file
Action: Read from uploaded path
Note: Depends on Claude Code upload support
```

### Date Format Normalization

```
Input formats accepted:
- ISO: 2026-03-15 → Use as-is
- Brazilian: 15/03/2026 → Convert to 2026-03-15
- Auto: "today" or empty → Use system date

Conversion logic:
if input matches DD/MM/YYYY:
  parts = input.split('/')
  return f"{parts[2]}-{parts[1]}-{parts[0]}"
elif input matches YYYY-MM-DD:
  return input
else:
  return $(date +%Y-%m-%d)
```

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| **Evidence Quality** | 0-30 | All tasks have GitHub links: 30, Most have: 20, Some missing: 10 |
| **Scope Coverage** | 0-25 | All scope items validated: 25, Most validated: 15, Assumptions: 5 |
| **Agent Analysis** | 0-25 | Specialized agents used: 25, General agent: 15, No agents (pattern only): 5 |
| **Data Completeness** | 0-20 | All branches scanned: 20, Main only: 10, Incomplete: 5 |

**Total Score Interpretation:**
- **80-100 points:** HIGH confidence - Report is evidence-based and accurate
- **50-79 points:** MEDIUM confidence - Some gaps, verify manually
- **0-49 points:** LOW confidence - Insufficient evidence, re-analyze

## Output & Next Steps

**Output to:** `docs/pre-dev/{feature-name}/delivery-status-{YYYY-MM-DD}.md`

**After generating report:**

1. ✅ Share with stakeholders (evidence-based status)
2. 🚨 Act on alerts (critical path delays, blockers)
3. 📊 Track trends (compare with previous status reports)
4. 🔄 Re-plan if needed (major delays, scope changes)
5. 📅 Schedule next status check (weekly/sprint end)

**Integration:**
- Use with `ring:pre-dev-delivery-planning` (create roadmap first)
- Run periodically during execution (weekly checkpoints)
- Compare multiple status reports to see trends

## The Bottom Line

**If you generated a status report without scanning ALL branches or running semantic analysis, delete it and start over.**

Status reports are not guesses. Status reports are evidence-based assessments:
- Every % completion backed by code analysis (via specialized agents)
- Every variance backed by actual dates (from commits/PRs)
- Every alert backed by repository evidence (GitHub links)
- Every insight backed by data patterns (velocity, bug rate, trends)

"It looks about 80% done" is not a status. It's a guess.

**Questions that must be answered with evidence:**
1. What is actually implemented? (code analysis via agents)
2. When did it actually happen? (commit dates, PR merge dates)
3. How does it compare to plan? (roadmap dates vs actual dates)
4. What scope is missing? (task scope vs found code)
5. What are the trends? (velocity, quality, patterns)

If any question lacks evidence, **STOP and gather data from repository.**

**Deliver evidence-based status. Build trust through accuracy. Enable decisions with insights.**

---

## Standards Loading (MANDATORY)

This skill is a status tracking skill and does NOT require WebFetch of language-specific standards.

**Purpose:** Delivery Status Tracking analyzes repository evidence to calculate progress. Technical standards are irrelevant at this stage—this skill focuses on evidence-based progress reporting.

**However**, when dispatching specialized agents for semantic analysis (e.g., `ring:backend-engineer-golang`), those agents apply their standards to evaluate code quality.

---

## Blocker Criteria - STOP and Report

| Condition | Action | Severity |
|-----------|--------|----------|
| No delivery roadmap exists | STOP and create roadmap first | CRITICAL |
| Tasks file not provided | STOP and request tasks.md location | CRITICAL |
| Repository cannot be accessed | STOP and verify repository permissions | CRITICAL |
| Current date not determined | STOP and get date (auto or user input) | HIGH |
| Pattern matching finds <50% and semantic analysis unavailable | STOP and investigate agent availability | HIGH |

---

## Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST scan ALL branches (not just main)
- MUST run semantic analysis via specialized agents when pattern matching insufficient
- MUST provide GitHub links as evidence for all claims
- MUST calculate variance against planned dates from roadmap
- MUST include insights section (velocity, quality, trends)
- MUST NOT report completion % without code analysis evidence
- CANNOT assume task is done because PR merged (verify scope)

---

## Severity Calibration

| Severity | Definition | Example |
|----------|------------|---------|
| **CRITICAL** | Cannot generate status report | No roadmap, no tasks file, repository inaccessible |
| **HIGH** | Report lacks essential evidence | No semantic analysis, main branch only |
| **MEDIUM** | Report incomplete but usable | Missing some GitHub links |
| **LOW** | Minor documentation gaps | Trends section brief |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just give quick estimate of progress" | "Cannot estimate without evidence. I'll scan repository and provide evidence-based progress with GitHub links." |
| "Pattern matching is enough" | "Cannot rely on patterns alone. Patterns miss uncommitted work. I'll run semantic analysis via specialized agents." |
| "Main branch status is sufficient" | "Cannot ignore branches. Work happens in feature branches first. I'll scan ALL branches." |
| "Skip variance, just tell me what's done" | "Cannot skip variance. Variance shows plan vs reality. I'll report both completion and timeline variance." |
| "Report looks good enough without links" | "Cannot report without evidence links. Every % must have GitHub evidence. I'll add all links." |

---

## When This Skill Is Not Needed

- No delivery roadmap exists → create roadmap first with `ring:pre-dev-delivery-planning`
- Planning phase only → execute tasks first
- No repository activity → nothing to analyze yet
- Status tracking not requested → continue execution
- Informal progress check → direct query to user is sufficient
