# Design: Composition Patterns Integration in Frontend Dev-Cycle

**Date:** 2026-06-24
**Status:** Approved
**Approach:** B + A Hybrid (Conditional Gate + Standards Breadcrumb)
**Scope:** `ring:applying-composition-patterns` wired into `ring:running-dev-cycle-frontend`

---

## Problem

`ring:applying-composition-patterns` is a standalone skill with 5x the depth of `frontend.md` Section 8 on composition patterns. However:

1. `ring:frontend` agent doesn't know about it — loads standards but has no reference to the skill
2. Gate 0 dispatch has no extensibility hook to inject additional skills
3. No post-implementation check detects when composition refactoring is warranted

Components with boolean prop proliferation, excessive conditional rendering, or oversized files pass through the dev-cycle without composition review.

## Design

### Part A: Standards Breadcrumb

**File:** `dev-team/docs/standards/frontend.md` (Section 8: Component Patterns)

Add after existing Tabs compound component example (~10 lines):

```markdown
#### Advanced Composition Patterns

For comprehensive guidance on composition patterns that prevent boolean prop
proliferation, compound component architecture, state lifting, and React 19
patterns — use skill `ring:applying-composition-patterns`.

Trigger indicators:
- Component accepts >3 boolean props
- Multiple conditional rendering branches based on boolean flags
- Component file exceeds 200 lines with >3 useState/useEffect hooks
```

**Effect:** Every frontend agent that loads Section 8 gains passive awareness. No duplication — the skill owns the content.

### Part B: Gate 0.5 — Composition Complexity Scan

**File:** `dev-team/skills/running-dev-cycle-frontend/SKILL.md`

Insert between Gate 0 (TDD) and Gate 7 (Review).

#### Flow

```
Gate 0 (TDD RED->GREEN)
  -> PASS
    -> Gate 0.5: Composition Complexity Scan
      -> Scan changed .tsx/.jsx files from Gate 0 output
      -> Apply detection heuristics
      -> If NO triggers hit -> skip, proceed to Gate 7
      -> If triggers hit -> dispatch refactoring pass
    -> Gate 7 (Code Review)
```

#### Detection Heuristics

| Signal | Threshold | Detection Method |
|--------|-----------|------------------|
| Boolean prop count | >=3 boolean props in component signature | Grep: `prop?: boolean` or `prop: boolean` in Props type/interface |
| File size + hooks | >200 lines AND >3 useState/useEffect | Line count + hook grep |
| Conditional render branches | >=3 ternaries or `&&` chains tied to boolean props | Pattern match: `{isX && ...}` or `isX ? ... : ...` |

#### When Triggers Hit

1. Load `ring:applying-composition-patterns` skill
2. Dispatch `ring:frontend` with the skill content + flagged files as context
3. Agent refactors flagged components following skill patterns
4. Re-run tests to confirm GREEN still holds
5. If tests break -> fix until GREEN, then proceed

#### When No Triggers Hit

Gate 0.5 is a no-op. Zero overhead for simple components.

#### Dispatch Prompt Template

```markdown
## Gate 0.5: Composition Refactoring

**Flagged files** (complexity signals detected):
- {file_path}: {signal} (e.g., "5 boolean props", "247 lines + 4 useState")

**Skill reference:** ring:applying-composition-patterns
Load this skill and apply its patterns to the flagged files.

**Priority order:**
1. Section 1.1 - Eliminate boolean prop proliferation (CRITICAL)
2. Section 1.2 - Extract compound components if applicable
3. Section 2.x - Lift state into providers only if warranted
4. Sections 3-4 - Apply only if natural fit, don't force

**Constraints:**
- MUST preserve all existing test assertions (update test API, not remove tests)
- MUST maintain or improve coverage (current: {gate0_coverage}%)
- MUST NOT change component behavior - refactor structure only
- If component uses {ui_library_mode} -> respect library conventions

**Verification:**
- Run tests -> all pass
- Run coverage -> >= {gate0_coverage}%
- Confirm no behavioral changes (same props in = same render out)
```

#### State Management

```
Gate 0 output:
  state.gate0_files_changed = [...]
  state.gate0_test_files = [...]
  state.gate0_coverage = N%

Gate 0.5 scan:
  state.gate05_triggered = true | false
  state.gate05_flagged_files = [...]

Gate 0.5 refactor (if triggered):
  state.gate05_refactored_files = [...]
  state.gate05_tests_pass = true
  state.gate05_coverage = N%  (must be >= gate0_coverage)
```

#### Safety Invariants

1. Coverage MUST NOT decrease post-refactoring (>= Gate 0 threshold)
2. All Gate 0 tests MUST pass after refactoring (or be updated + pass)
3. If refactoring breaks irrecoverably -> rollback to Gate 0 state, skip Gate 0.5, proceed to review with note: "Composition refactoring attempted but reverted -- review flagged files manually"

#### Commit Boundary

Gate 0.5 produces its own commit, separate from Gate 0:
`refactor(component): apply composition patterns to <ComponentName>`

## Integration Map

```
frontend.md Section 8 (Standards)
  "For advanced composition -> use ring:applying-composition-patterns"
  -> Gives ring:frontend passive awareness
  -> Agent may proactively apply patterns at Gate 0
        |
        v
Gate 0: TDD RED -> GREEN
  ring:frontend / ring:ui-engineer / ring:bff-ts
  -> Produces implementation + passing tests
        |
        v
Gate 0.5: Composition Complexity Scan (NEW)
  Orchestrator scans changed .tsx/.jsx files
  - NO triggers -> skip to Gate 7
  - TRIGGERS HIT:
    Load ring:applying-composition-patterns
    Dispatch ring:frontend with flagged files
    Refactor -> re-test -> verify coverage
    Commit: refactor(scope): apply composition
        |
        v
Gate 7: Code Review
  9 default reviewers (ring:code-reviewer catches
  any remaining complexity issues)
```

**Three layers of coverage:**
1. **Passive** - Agent reads the standards breadcrumb, may apply patterns during implementation
2. **Active** - Gate 0.5 catches what the agent missed, refactors automatically
3. **Review** - `ring:code-reviewer` can still flag complexity in Gate 7

## Files Changed

| File | Change | Size |
|------|--------|------|
| `dev-team/docs/standards/frontend.md` | Add breadcrumb to Section 8 | ~10 lines |
| `dev-team/skills/running-dev-cycle-frontend/SKILL.md` | Add Gate 0.5 block | ~40 lines |

## Alternatives Considered

### A: Standards Enrichment Only
Expand frontend.md Section 8 with full composition patterns. Rejected: bloats standards (2,241 lines already), duplicates skill content, no enforcement.

### C: Agent Awareness + Conditional Reviewer
Add composition checks to ring:frontend forbidden-patterns + new ring:composition-reviewer in Gate 7 pool. Rejected: triggers 7-file update rule for reviewer, over-rotates for a pattern-specific concern.

## Open Questions

None. Design approved as-is.
