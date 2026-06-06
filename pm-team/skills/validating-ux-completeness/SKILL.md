---
name: ring:pre-dev-design-validation
description: |
  Gate 1.5/2.5: Design Validation - verifies UX specifications are complete
  before proceeding to technical architecture. Checklist-based validation
  that prevents incomplete designs from reaching implementation.
---

# Design Validation Gate

## When to use

- After PRD + UX criteria created (Gate 1)
- After Feature Map + UX Design created (Gate 2, Large track)
- Before starting TRD (Gate 3)
- User asks to "validate design" or "check if design is complete"

## Skip when

- Feature is backend-only with no UI
- Pure API/infrastructure task
- Bug fix with no UX changes

## Sequence

**Runs before:** ring:pre-dev-trd-creation
**Runs after:** ring:pre-dev-prd-creation, ring:pre-dev-feature-map


Verifies that UX specifications are COMPLETE before investing in technical architecture. This is a VALIDATION gate — it checks existing artifacts, does not create new ones.

TRD will STOP if this file is missing or verdict is not "DESIGN VALIDATED" for UI features.

## Gate Entry Criteria

| Artifact | Location | Required For |
|----------|----------|--------------|
| `prd.md` | `docs/pre-dev/{feature}/` | all features |
| `ux-criteria.md` | `docs/pre-dev/{feature}/` | all features with UI |
| `wireframes/` | `docs/pre-dev/{feature}/wireframes/` | all features with UI |
| `user-flows.md` | `docs/pre-dev/{feature}/wireframes/` | all features with UI |
| `feature-map.md` | `docs/pre-dev/{feature}/` | Large track only |

If artifacts do not exist → STOP. Return to previous gate.

**If feature has NO UI** → Skip this gate, proceed to TRD. Feature has UI if PRD contains: user stories with "see", "view", "click", "navigate", "page", "screen", "button", "form", or features involving login, dashboard, settings, profile, reports, notifications.

## Validation Checklist

### Section 1: Screen Completeness (CRITICAL — failure = HARD STOP)

- [ ] All screens from user stories have wireframes
- [ ] Each wireframe has all required UI elements
- [ ] Interactive elements identified (buttons, forms, links)
- [ ] Navigation flows between screens defined
- [ ] No screen in user stories is missing a wireframe

### Section 2: State Coverage (CRITICAL — failure = HARD STOP)

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
**Track:** Small | Large
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
VALIDATED → Proceed to ring:pre-dev-trd-creation
REVISION → Return to product-designer with gap list
```
