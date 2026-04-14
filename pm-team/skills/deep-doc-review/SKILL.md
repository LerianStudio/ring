---
name: ring:deep-doc-review
description: |
  Deep review of project documentation before entering dev-cycle.
  Finds errors, inconsistencies, gaps, missing data, and contradictions
  across PRD, TRD, API design, data model, and other pre-dev artifacts.
  Cross-references information between docs — not just reviewing one doc
  in isolation — to catch mismatches that cause implementation failures.

trigger: |
  - Before starting dev-cycle (validate doc quality as a pre-gate)
  - After completing pre-dev workflow (ring:pre-dev-feature or ring:pre-dev-full)
  - When user requests project documentation review
  - After significant changes to reference docs (PRD, TRD, API design, data model)

skip_when: |
  - Code review needed (use ring:requesting-code-review instead)
  - Docs do not exist yet (run pre-dev workflow first)
  - Reviewing a single simple file (do it directly without the skill)

NOT_skip_when: |
  - "Docs were already reviewed" → Docs evolve and accumulate inconsistencies over time. Review again.
  - "There are only a few docs" → Even a few docs can have contradictions between them.
  - "Only one doc changed" → A change in one doc can create inconsistencies with others.
  - "We're in a hurry" → Shipping with contradictory docs causes more rework than reviewing now.

sequence:
  after: [ring:pre-dev-feature, ring:pre-dev-full]
  before: [ring:dev-cycle, ring:write-plan]

related:
  complementary:
    - ring:pre-dev-prd-creation
    - ring:pre-dev-trd-creation
    - ring:pre-dev-api-design
    - ring:pre-dev-data-model
    - ring:pre-dev-task-breakdown
  differentiation:
    - name: ring:requesting-code-review
      difference: |
        ring:requesting-code-review reviews code changes for quality, security, and correctness.
        ring:deep-doc-review reviews documentation artifacts against each other,
        independent of any code, to catch contradictions before implementation starts.

verification:
  manual:
    - All findings presented to user
    - Approved corrections applied correctly
    - Final summary with fixed/skipped counts presented
---

# Deep Doc Review

> Adapted from alexgarzao/optimus (optimus-deep-doc-review)

Deep review of project documentation. Finds errors, inconsistencies, gaps, missing data, and improvements — with emphasis on **cross-referencing between docs** to catch contradictions before they become implementation bugs.

**This skill is a pre-gate before `ring:dev-cycle`.** Run it after pre-dev workflows produce their artifacts and before implementation begins.

---

## Phase 0: Discover and Load Docs

### Step 0.1: Identify Docs to Review

If the user specified files, use those. Otherwise, discover automatically:

1. Search for project reference docs in these locations:
   - `docs/pre-dev/<feature>/` (Ring pre-dev artifacts)
   - `docs/` (general project docs)
   - Root directory (README, CHANGELOG, ARCHITECTURE)
2. Include: PRD, TRD, API design, data model, task specs, subtask specs, dependency map, delivery plan, research docs, coding standards, README, CHANGELOG
3. Exclude: generated files, node_modules, build artifacts, binary files, test fixtures

Use TodoWrite to track each phase of the review as a task item.

Present the list of discovered docs to the user before proceeding:

```
## Discovered Documentation

Found X documents to review:

| # | File | Type | Size |
|---|------|------|------|
| 1 | docs/pre-dev/feature/prd.md | PRD | ~200 lines |
| 2 | docs/pre-dev/feature/trd.md | TRD | ~350 lines |
| ... | ... | ... | ... |

Proceed with all X documents? (Or specify a subset)
```

If there are many docs (>15), ask whether to review all or select a subset.

### Step 0.2: Read All Docs

Read the full content of each identified doc. Build a mental map of:

- Entities and fields defined in each doc
- Endpoints and API contracts
- Business rules and acceptance criteria
- Technical decisions and architecture choices
- Dependencies between docs (e.g., TRD references PRD user stories, API design references data model entities)
- Naming conventions used across docs

---

## Phase 1: Analysis and Cross-Referencing

### Issue Types

| Type | Description |
|------|-------------|
| ERROR | Factually incorrect information |
| INCONSISTENCY | Contradiction between two or more docs |
| GAP | Expected information that is absent |
| MISSING | Referenced data that does not exist in any doc |
| IMPROVEMENT | Opportunity for clarity, organization, or completeness |

### Severity

| Severity | Criteria |
|----------|----------|
| CRITICAL | Blocks implementation — developer cannot proceed without resolving |
| HIGH | Causes bugs or significant confusion during implementation |
| MEDIUM | Affects doc quality but does not block implementation |
| LOW | Cosmetic — formatting, typos, organization |

### What to Analyze

For each doc, verify:

1. **Internal consistency** — does the doc contradict itself?
2. **Cross-doc consistency** — does the doc contradict other docs? This is the highest-value check.
3. **Completeness** — are expected sections missing?
4. **Valid references** — do referenced entities, fields, endpoints, and user stories exist in the corresponding docs?
5. **Clarity** — can a developer implement from this doc without needing to ask questions?
6. **Currency** — is the information outdated compared to existing code? (Use Bash to check source files when relevant.)

### Cross-Reference Matrix

MUST check these cross-doc relationships when applicable:

| Source Doc | Target Doc | What to Verify |
|-----------|-----------|----------------|
| PRD | TRD | Every user story has a technical approach; no TRD features without PRD justification |
| TRD | API Design | Architecture decisions reflected in API contracts; referenced components exist |
| API Design | Data Model | Every API field maps to a data model field; types and constraints match |
| Data Model | TRD | Every entity referenced in TRD exists in data model; relationships consistent |
| Task Specs | PRD + TRD | Tasks trace back to requirements; no orphan tasks without justification |
| Delivery Plan | Task Specs | All tasks accounted for; estimates are realistic given task complexity |

---

## Phase 2: Present Overview

Present the full findings table for a bird's-eye view:

```markdown
## Deep Doc Review — X findings across Y docs

| # | Type | Severity | File(s) | Problem | Suggested Fix | Tradeoff | Recommendation |
|---|------|----------|---------|---------|---------------|----------|----------------|
| 1 | INCONSISTENCY | CRITICAL | api-design.md, data-model.md | Field X defined as VARCHAR(50) in data-model but string with no limit in API design | Align to VARCHAR(100) in both | Changing limit may affect validation | Fix both docs |
| 2 | GAP | HIGH | tasks.md | Task T-008 does not define testing strategy | Add section with unit + integration tests | Additional writing effort | Add before implementation |
| ... | ... | ... | ... | ... | ... | ... | ... |

### Summary by Severity
- CRITICAL: X
- HIGH: X
- MEDIUM: X
- LOW: X
```

Wait for user acknowledgment before proceeding to interactive resolution.

---

## Phase 3: Interactive Resolution (one by one)

Present each finding individually, in severity order (CRITICAL first).

For EACH finding:

### 1. Show the Item

Display the number, type, severity, affected file(s), problem description, suggested fix, and tradeoff.

Include the relevant excerpts from each affected file for context:

```markdown
### Finding #1 — INCONSISTENCY (CRITICAL)

**Files:** `docs/pre-dev/feature/api-design.md:45`, `docs/pre-dev/feature/data-model.md:23`

**Problem:** Field `user_email` defined as `VARCHAR(50)` in data-model but `string` with no length constraint in API design.

**In api-design.md (line 45):**
> email: string — User's email address

**In data-model.md (line 23):**
> | user_email | VARCHAR(50) | NOT NULL | User's email |

**Suggested fix:** Align to `VARCHAR(100)` in data-model and add `maxLength: 100` in API design.
**Tradeoff:** Changing column size requires checking if existing migrations are affected.
**Recommendation:** Fix both docs.
```

### 2. Ask the User

Present options:
- **Fix as suggested** — apply the recommended correction
- **Fix with adjustment** — user specifies a different fix
- **Skip this item** — leave it as-is (record the reason)

MUST NOT advance to the next item until the user decides.

### 3. Apply (if approved)

If the user chose to fix:
1. Apply the correction to the affected file(s) immediately
2. Confirm it was applied with the exact change made
3. Only then advance to the next item

### Rules

- MUST NOT present more than one item at a time
- MUST NOT apply corrections without explicit user approval
- Record each decision internally (fixed, skipped, adjusted) for the final summary

---

## Phase 4: Final Summary

After processing all findings:

```markdown
## Deep Doc Review — Summary

### Fixed (X findings)
| # | Type | File(s) | Fix Applied |
|---|------|---------|-------------|
| 1 | INCONSISTENCY | api-design.md, data-model.md | Aligned to VARCHAR(100) in both |

### Skipped (X findings)
| # | Type | File(s) | Reason |
|---|------|---------|--------|
| 5 | IMPROVEMENT | trd.md | User: cosmetic, not a priority |

### Statistics
- Total findings: X
- Fixed: X
- Skipped: X
- Docs modified: [list of modified files]
- Cross-doc issues found: X (of total)
```

MUST NOT commit automatically. Present the summary and wait for the user to decide whether to commit.

---

## Rules

- MUST NOT generate code — this skill is for documentation only
- MUST NOT assume — if something is ambiguous, classify it as GAP or MISSING
- MUST cross-reference information between docs — intra-doc findings are useful, but inter-doc findings are the primary value
- Prioritize: CRITICAL > HIGH > MEDIUM > LOW
- Reference exact locations (file, section, line when possible)
- Tradeoffs must be honest — do not minimize the cost of a correction
- If a doc references existing code, use Bash to verify that the code matches the doc
- Use TodoWrite to track review phases and resolution progress
