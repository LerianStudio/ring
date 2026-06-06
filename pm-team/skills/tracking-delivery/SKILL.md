---
name: ring:tracking-delivery
description: "Tracking actual delivery progress against plan by scanning repo branches, commits, and PRs, matching work to roadmap epics and tasks.md, and producing an evidence-linked status report with per-task completion, variance, critical-path impact, and velocity/risk insights. Consumes the roadmap from ring:planning-delivery. Use for status updates or sprint checkpoints. Skip when no roadmap exists or the repo has no activity yet."
---

# Delivery Status Tracking — Evidence-Based Progress Reporting

## When to use

- Delivery roadmap exists (from ring:planning-delivery)
- Need to check progress against plan
- Stakeholders requesting status update
- Regular checkpoint (weekly/sprint end)

## Skip when

- No delivery roadmap → create one first with ring:planning-delivery
- Planning phase only → execute tasks first
- No repository activity → nothing to analyze

## Sequence

**Runs after:** ring:planning-delivery, ring:running-dev-cycle


Every status report must be grounded in repository evidence, not estimates or verbal updates. Status answers WHAT is actually done vs what was planned.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Input Gathering** | Load delivery-roadmap.md (required), tasks.md (required; the phased plan — epics plus detailed Phase 1 tasks), current date |
| **2. Repository Scan** | Scan ALL branches, commits, PRs, releases; build activity timeline; identify task-related work |
| **3. Task Matching** | Pattern matching (branches, commits, PRs) + semantic analysis (code content vs scope) via specialized agents |
| **4. Completion Calculation** | Per task: analyze scope items found vs expected; calculate % done; determine status |
| **5. Variance Analysis** | Compare planned vs actual dates; identify delays/early completions; calculate critical path impact |
| **6. Insights Extraction** | Velocity trends, bug rate, review time, code patterns, risk indicators |
| **7. Report Generation** | Save to `docs/pre-dev/{feature}/delivery-status-{date}.md`; include evidence links |

## Mandatory User Questions

**Q1: Repository** — Which org/repo to analyze? (format: org/repo)

**Q2: Roadmap Source** — Options: File path (local), GitHub URL (raw), Document link, Paste content

**Q3: Tasks File** — Same options as Q2 (REQUIRED — not optional)

**Q4 (optional): Subtasks File** — Yes (with source options) or No (analyze at task level only)

**Q5: Analysis Date** — Today (auto-detect) or Custom date (accepts DD/MM/YYYY or YYYY-MM-DD)

## Repository Scan Workflow

```bash
# Scan ALL branches (not just main)
git fetch --all && git branch -a
git log --all --pretty=format:"%H|%an|%ae|%ad|%s" --date=iso

# Find task-related branches
git branch -a | grep -iE "T-[0-9]+|task|feature|fix"

# Get all PRs (merged + open)
gh pr list --state all --limit 100 --json number,title,state,mergedAt,headRefName

# Find task-related files changed
git log --all --name-only --format="%H|%ad|%s" --date=iso | grep -v "^$"
```

## Task Matching Strategy

1. **Pattern matching:** Search branch names, PR titles, commit messages for T-XXX patterns
2. **Semantic analysis:** Dispatch specialized agent per task type to analyze actual code changes vs task scope
3. **Completion calculation:** Count scope items found (endpoints, tests, migrations) vs expected

| Signal | Weight |
|--------|--------|
| PR merged to main | High (but validate scope completion) |
| Feature branch active | Medium |
| Commits with task reference | Medium |
| Code changes matching scope | High |
| Test files for task scope | High |

## Status Classification

| Status | Criteria |
|--------|----------|
| ✅ Complete | All scope items found; tests present; merged to main |
| 🔄 In Progress | Active branch; partial scope found; open PR |
| ⏸️ Not Started | No branch, no commits matching this task |
| ⚠️ At Risk | Started but behind schedule per critical path |
| ❌ Blocked | No progress for >3 days on critical path task |

## Report Structure

```markdown
# Delivery Status Report — {Feature} — {Date}

## Executive Summary
- Overall status: 🟢 On Track | 🟡 At Risk | 🔴 Behind
- Planned completion: {date}
- Revised forecast: {date} (if different)

## Task Progress

| Task | Status | % Done | Planned End | Actual/Forecast | Variance | Evidence |
|------|--------|--------|-------------|-----------------|----------|----------|
| T-001 | ✅ Complete | 100% | 2026-03-10 | 2026-03-09 | +1 day early | [PR #42] |
| T-002 | 🔄 In Progress | 65% | 2026-03-20 | 2026-03-22 | -2 days late | [branch] |

## Period Status (if Sprint/Cycle)
- Sprint 1: ✅ Done (2 complete, 1 partial)
- Sprint 2: 🔄 In Progress

## Insights
- Velocity: X tasks/sprint (planned Y)
- Average PR review time: X days
- Bug rate: X bugs per task

## Risk Alerts
- [T-002 is on critical path, currently -2 days]

## Recommendations
- [Action items with owners and dates]
```

## Evidence Standards

Every completion claim must include at least one of:
- PR URL (merged)
- Commit hash with message
- File path showing relevant changes
- Test file path confirming coverage

Never report completion without evidence links.
