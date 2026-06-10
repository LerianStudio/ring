---
name: ring:validating-ux-completeness
description: "Validating that UX specifications are complete before technical design: a read-only checklist over wireframes, states, responsive behavior, accessibility, and component-library alignment, emitting a DESIGN VALIDATED / NEEDS REVISION verdict to design-validation.md. Standalone utility — run after a product-designer pass and before the TRD when the feature has UI; the pre-dev orchestrators recommend it when the feature has UI. Use to check UI design completeness. Skip for backend-only, API-only, or no-UI work."
---

# UX Completeness Validation

Standalone utility — not a gate in any pre-dev track. Verifies that UX specifications are COMPLETE before investing in technical architecture. This is a VALIDATION pass — it checks existing artifacts, does not create new ones.

The TRD does not hard-block on this verdict: ring:writing-trds honors `design-validation.md` if present; if absent, it proceeds and notes the UX risk.

## When to use

- Feature has UI and a standalone product-designer run produced UX artifacts
- Before starting the TRD (recommended slot: between PRD and TRD)
- The pre-dev orchestrators recommend it as an optional standalone step when the feature has UI
- User asks to "validate design" or "check if design is complete"

## Skip when

- Feature is backend-only with no UI
- Pure API/infrastructure task
- Bug fix with no UX changes

## Sequence

**Runs before:** ring:writing-trds (recommended, not required)
**Runs after:** ring:writing-prds and a standalone product-designer run (ux-validation mode; optionally ux-design mode)

## Entry Criteria

| Artifact | Location | Required |
|----------|----------|----------|
| `prd.md` | `docs/pre-dev/{feature}/` | always |
| `ux-criteria.md` | `docs/pre-dev/{feature}/` | yes — produced by product-designer ux-validation mode |
| `wireframes/` | `docs/pre-dev/{feature}/wireframes/` | yes — produced by product-designer ux-validation mode |
| `user-flows.md` | `docs/pre-dev/{feature}/` | only if a ux-design run happened — do NOT require otherwise |

If `prd.md`, `ux-criteria.md`, or `wireframes/` are missing → STOP. Report the missing artifacts and recommend a product-designer run first.

**If feature has NO UI** → this skill does not apply. Feature has UI if PRD contains: user stories with "see", "view", "click", "navigate", "page", "screen", "button", "form", or features involving login, dashboard, settings, profile, reports, notifications.

## Validation Checklist

### Section 1: Screen Completeness (CRITICAL — failure = NEEDS REVISION)

- [ ] All screens from user stories have wireframes
- [ ] Each wireframe has all required UI elements
- [ ] Interactive elements identified (buttons, forms, links)
- [ ] Navigation flows between screens defined
- [ ] No screen in user stories is missing a wireframe

### Section 2: State Coverage (CRITICAL — failure = NEEDS REVISION)

- [ ] Empty states designed (no data scenarios)
- [ ] Loading states shown
- [ ] Error states for each failure scenario
- [ ] Success states for key actions
- [ ] Edge cases with extreme content (long text, many items)

### Section 3: Responsive Behavior

- [ ] Desktop layout defined
- [ ] Mobile layout defined (or explicit "mobile not required" statement)
- [ ] Tablet behavior specified or derived from desktop/mobile
- [ ] Breakpoints documented

### Section 4: Accessibility

- [ ] Color contrast documented (AA minimum)
- [ ] Focus order for keyboard navigation specified
- [ ] ARIA labels for non-text elements
- [ ] Screen reader behavior documented for dynamic content

### Section 5: Interaction Details

- [ ] Form validation feedback shown (inline errors)
- [ ] Confirmation dialogs for destructive actions
- [ ] Feedback for async operations (loading, success, error)
- [ ] Tooltips and help text defined

### Section 6: Data Display

- [ ] Pagination or infinite scroll for lists
- [ ] Sort and filter behavior defined (if applicable)
- [ ] Data formatting (dates, numbers, currency)
- [ ] Truncation behavior for long content

### Section 7: Component Consistency

- [ ] Reuse of existing components documented
- [ ] New components needed identified
- [ ] Variants used consistently (button types, input states)
- [ ] Spacing and layout grid consistent

### Section 8: Component Library Alignment (if UI library configured)

- [ ] Components needed exist in chosen library
- [ ] Correct variant names used (not invented variants)
- [ ] Missing components identified for custom implementation

## Verdict

**DESIGN VALIDATED:** All Section 1-2 items pass AND ≥80% of Sections 3-8 pass.

**DESIGN NEEDS REVISION:** Any Section 1-2 item fails → list specific gaps → return to product-designer.

**File output:** `docs/pre-dev/{feature}/design-validation.md`

```markdown
# Design Validation Report

**Feature:** {feature-name}
**Date:** {YYYY-MM-DD}
**Verdict:** DESIGN VALIDATED | DESIGN NEEDS REVISION

## Results

| Section | Status | Notes |
|---------|--------|-------|
| 1. Screen Completeness | ✅ PASS / ❌ FAIL | ... |
| 2. State Coverage | ✅ PASS / ❌ FAIL | ... |
| 3. Responsive Behavior | ✅ PASS / ⚠️ PARTIAL | ... |
...

## Gaps Found (if REVISION needed)
- [Specific gap 1]
- [Specific gap 2]

## Next Step
VALIDATED → Proceed to ring:writing-trds
REVISION → Return to product-designer with gap list
```

## Related

- product-designer agent — produces the artifacts this skill validates (ux-research / ux-validation / ux-design modes)
- ring:writing-trds — honors `design-validation.md` if present; does not hard-block on it
