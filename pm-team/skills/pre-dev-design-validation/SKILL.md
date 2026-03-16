---
name: pre-dev-design-validation
description: |
  Gate 1.5/2.5: Design Validation - verifies UX specifications are complete
  before proceeding to technical architecture. Checklist-based validation
  that prevents incomplete designs from reaching implementation.
metadata:
  sequence:
    after:
    - ring:pre-dev-prd-creation
    - ring:pre-dev-feature-map
    before:
    - ring:pre-dev-trd-creation
  skip_when: |
    - Feature is backend-only with no UI
    - Pure API/infrastructure task
    - Bug fix with no UX changes
  trigger: |
    - After PRD + UX criteria created (Gate 1)
    - After Feature Map + UX Design created (Gate 2, Large track)
    - Before starting TRD (Gate 3)
    - User asks to "validate design" or "check if design is complete"
---

# Design Validation Gate

## ⛔ MANDATORY GATE - CANNOT BE SKIPPED

**This gate is REQUIRED for all features with UI. No exceptions. No shortcuts.**

### Enforcement Points

| Enforcement | What Happens |
|-------------|--------------|
| **TRD checks for design-validation.md** | TRD skill will STOP if this file is missing or verdict is not VALIDATED |
| **Commands enforce gate order** | pre-dev-feature and pre-dev-full require this gate before TRD |
| **Critical gaps = HARD STOP** | Any Section 1-2 failure blocks progression to TRD |

### Why This Gate Exists

| Without Validation | With Validation |
|-------------------|-----------------|
| Missing UI states discovered during coding | All states defined upfront |
| "Mobile later" becomes "Mobile never" | Responsive specs locked in |
| Accessibility retrofitted expensively | A11y baked in from start |
| 10x implementation rework | Design complete before code |

---

## Standards Loading (MANDATORY)

This skill is a validation/checklist skill and does NOT require WebFetch of language-specific standards.

**Purpose:** Design Validation verifies UX artifact completeness against a checklist. Technical standards are irrelevant at this stage—they apply during TRD (Gate 3) and implementation.

**However**, if validating component library alignment (Section 8), MUST reference the UI library's documentation to verify component availability and variant names.

---

## Purpose

**Verify that UX specifications are COMPLETE before investing in technical architecture.**

This gate prevents:
- Incomplete wireframes reaching implementation
- Missing UI states causing implementation rework
- Accessibility gaps discovered late
- Responsive behavior undefined until coding

**This is a VALIDATION gate, not a CREATION gate.** It checks existing artifacts, does not create new ones.

---

## Gate Entry Criteria

**MUST have these artifacts before running this gate:**

| Artifact | Location | Required For |
|----------|----------|--------------|
| `prd.md` | `docs/pre-dev/{feature}/` | all features |
| `ux-criteria.md` | `docs/pre-dev/{feature}/` | all features with UI |
| `wireframes/` | `docs/pre-dev/{feature}/wireframes/` | all features with UI |
| `user-flows.md` | `docs/pre-dev/{feature}/wireframes/` | all features with UI |
| `feature-map.md` | `docs/pre-dev/{feature}/` | Large track only |

**If artifacts do not exist -> STOP. Return to previous gate.**

---

## UI Detection

**Feature has UI if PRD contains any of:**
- User stories with: "see", "view", "click", "navigate", "page", "screen", "button", "form"
- Features involving: login, dashboard, settings, profile, reports, notifications
- Any direct user-facing interaction

**If feature has NO UI -> Skip this gate, proceed to TRD.**

---

## Validation Checklist

### Section 1: Wireframe Completeness (CRITICAL)

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **all screens defined** | Every user-facing screen has a `.yaml` file | List missing screens |
| **ASCII prototype present** | Every wireframe has `ascii_prototype:` section | List wireframes without ASCII |
| **Components specified** | Every wireframe has `components:` with types | List incomplete wireframes |
| **Route defined** | Every wireframe has `route:` field | List wireframes without routes |

### Section 2: UI States Coverage (CRITICAL)

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **Loading state** | Every data-fetching screen defines loading | List screens missing loading |
| **Error state** | Every data-fetching screen defines error | List screens missing error |
| **Empty state** | Every list/table screen defines empty | List screens missing empty |
| **Success state** | Every form/action screen defines success | List screens missing success |

**State Detection Rules:**
- Screen has `data_source:` or API reference -> Needs loading/error states
- Screen has `type: table` or `type: list` -> Needs empty state
- Screen has `type: form` or `type: button` with action -> Needs success state

### Section 3: Accessibility Specifications

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **Keyboard navigation** | `ux-criteria.md` has "Keyboard accessible" criteria | Flag missing |
| **Screen reader support** | `ux-criteria.md` has "ARIA" or "screen reader" criteria | Flag missing |
| **Contrast requirements** | `ux-criteria.md` specifies contrast ratio | Flag missing |
| **Focus management** | Modal/dialog wireframes specify focus behavior | List modals without focus spec |

### Section 4: Responsive Specifications

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **Mobile layout defined** | Wireframes with significant layout have mobile ASCII | List wireframes without mobile |
| **Breakpoints documented** | `ux-criteria.md` specifies breakpoint behavior | Flag missing |
| **Touch targets noted** | Mobile wireframes consider 44x44px targets | Flag if not mentioned |

### Section 5: User Flow Completeness

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **Happy path documented** | `user-flows.md` has primary success flow | Flag missing |
| **Error paths documented** | `user-flows.md` has at least one error flow | Flag missing |
| **Entry points defined** | Flows specify how user arrives | Flag missing |
| **Exit points defined** | Flows specify where user goes after | Flag missing |

### Section 6: Content Specifications

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **Button labels defined** | all buttons have explicit `label:` | List buttons with generic labels |
| **Error messages specified** | Error states have specific messages | List generic error messages |
| **Empty state CTAs** | Empty states have actionable CTAs | List empty states without CTA |
| **Form validation messages** | Form fields with validation have error text | List fields without error text |

### Section 7: Design System (New Projects)

**This section applies when:** Project is new (no existing design system detected).

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **design-system.md exists** | `docs/pre-dev/{feature}/design-system.md` present | Flag: "Missing design-system.md" |
| **Color palette defined** | Primary, neutral, semantic colors documented | Flag: "Incomplete color palette" |
| **Typography specified** | Font family, scale, line heights documented | Flag: "Missing typography specs" |
| **Contrast validated** | Accessibility contrast ratios calculated | Flag: "Missing contrast validation" |
| **CSS variables listed** | All required CSS custom properties documented | Flag: "Missing CSS variables" |

**Detection Rule:** Project is "new" if:
- No `globals.css` with CSS variables exists, OR
- No `tailwind.config.*` with custom colors exists

**Why This Matters:**
- Frontend engineers need design tokens before implementation
- TRD references design-system.md for styling architecture
- Missing design system = styling decisions made ad-hoc during coding

### Section 8: Component Library Alignment (All UI Features)

**This section validates that wireframes use components available in the project's UI library.**

| Check | Pass Criteria | Fail Action |
|-------|---------------|-------------|
| **UI library identified** | `ux-criteria.md` specifies UI library (shadcn, Chakra, etc.) | Flag: "Missing UI library specification" |
| **Components exist in library** | all `components:` in wireframes exist in specified library | List unavailable components |
| **Variants match library** | Button variants, input types match library's variants | List incorrect variant usage |
| **Custom components flagged** | Components not in library marked as `custom: true` | List unmarked custom components |

**Validation Process:**

1. **Read UI library from ux-criteria.md:**
   ```yaml
   ui_library: shadcn/ui | Chakra UI | Material UI | Custom
   ```

2. **For each wireframe, check components:**
   ```yaml
   components:
     - type: Button        # Exists in shadcn? ✅
       variant: primary    # Valid variant? ✅
     - type: DataGrid      # Exists in shadcn? ❌ (custom needed)
   ```

3. **Flag mismatches:**
   - Component doesn't exist → Needs `custom: true` or different component
   - Variant doesn't exist → Use correct library variant

**Why This Matters:**
- Prevents wireframes specifying components that don't exist
- Prevents implementation errors from incorrect variant names
- Identifies custom component work needed before TRD

---

## Validation Process

### Phase 1: Artifact Discovery

```
1. Read docs/pre-dev/{feature}/prd.md
2. Detect if feature has UI (see UI Detection rules)
3. If no UI -> Skip validation, proceed to TRD
4. Read docs/pre-dev/{feature}/ux-criteria.md
5. Glob docs/pre-dev/{feature}/wireframes/*.yaml
6. Read docs/pre-dev/{feature}/wireframes/user-flows.md
7. If Large track: Read docs/pre-dev/{feature}/feature-map.md
```

### Phase 2: Systematic Validation

```
FOR EACH section in checklist:
  FOR EACH check in section:
    - Evaluate against artifacts
    - Record PASS or FAIL
    - If FAIL: Record specific gaps with file locations
```

### Phase 3: Verdict

| Condition | Verdict | Action |
|-----------|---------|--------|
| all checks PASS | DESIGN VALIDATED | Proceed to TRD |
| Any Section 1-2 check FAIL | CRITICAL GAPS | Return to UX gate, fix gaps |
| Only Section 3-6 checks FAIL | MINOR GAPS | Document gaps, user decides |

---

## Output Format

```markdown
# Design Validation Report

## Feature: {feature_name}

## Validation Date: {date}

## Artifacts Validated

| Artifact | Status | Location |
|----------|--------|----------|
| PRD | Found/Not Found | docs/pre-dev/{feature}/prd.md |
| UX Criteria | Found/Not Found | docs/pre-dev/{feature}/ux-criteria.md |
| Wireframes | Found (N files) | docs/pre-dev/{feature}/wireframes/ |
| User Flows | Found/Not Found | docs/pre-dev/{feature}/wireframes/user-flows.md |

## Validation Results

### Section 1: Wireframe Completeness

| Check | Status | Details |
|-------|--------|---------|
| all screens defined | PASS/FAIL | N/N screens have wireframes |
| ASCII prototype present | PASS/FAIL | Details |
| Components specified | PASS/FAIL | Details |
| Route defined | PASS/FAIL | Details |

### Section 2: UI States Coverage

| Check | Status | Details |
|-------|--------|---------|
| Loading state | PASS/FAIL | Details |
| Error state | PASS/FAIL | Details |
| Empty state | PASS/FAIL | Details |
| Success state | PASS/FAIL | Details |

### Section 3: Accessibility Specifications

| Check | Status | Details |
|-------|--------|---------|
| Keyboard navigation | PASS/FAIL | Details |
| Screen reader support | PASS/FAIL | Details |
| Contrast requirements | PASS/FAIL | Details |
| Focus management | PASS/FAIL | Details |

### Section 4: Responsive Specifications

| Check | Status | Details |
|-------|--------|---------|
| Mobile layout defined | PASS/FAIL | Details |
| Breakpoints documented | PASS/FAIL | Details |
| Touch targets noted | PASS/FAIL | Details |

### Section 5: User Flow Completeness

| Check | Status | Details |
|-------|--------|---------|
| Happy path documented | PASS/FAIL | Details |
| Error paths documented | PASS/FAIL | Details |
| Entry points defined | PASS/FAIL | Details |
| Exit points defined | PASS/FAIL | Details |

### Section 6: Content Specifications

| Check | Status | Details |
|-------|--------|---------|
| Button labels defined | PASS/FAIL | Details |
| Error messages specified | PASS/FAIL | Details |
| Empty state CTAs | PASS/FAIL | Details |
| Form validation messages | PASS/FAIL | Details |

### Section 7: Design System (New Projects Only)

| Check | Status | Details |
|-------|--------|---------|
| design-system.md exists | PASS/FAIL/N/A | Details |
| Color palette defined | PASS/FAIL/N/A | Details |
| Typography specified | PASS/FAIL/N/A | Details |
| Contrast validated | PASS/FAIL/N/A | Details |
| CSS variables listed | PASS/FAIL/N/A | Details |

### Section 8: Component Library Alignment

| Check | Status | Details |
|-------|--------|---------|
| UI library identified | PASS/FAIL | Details |
| Components exist in library | PASS/FAIL | Details |
| Variants match library | PASS/FAIL | Details |
| Custom components flagged | PASS/FAIL | Details |

## Summary

| Section | Status | Critical? |
|---------|--------|-----------|
| Wireframe Completeness | PASS/FAIL | Yes |
| UI States Coverage | PASS/FAIL | Yes |
| Accessibility | PASS/FAIL | Yes |
| Responsive | PASS/FAIL | No |
| User Flows | PASS/FAIL | Yes |
| Content | PASS/FAIL | No |
| Design System (new projects) | PASS/FAIL/N/A | Yes (if applicable) |
| Component Library Alignment | PASS/FAIL | Yes |

## Verdict: [DESIGN VALIDATED | CRITICAL GAPS | MINOR GAPS]

### Critical Gaps (MUST fix before TRD)

[List each critical gap with:]
1. **Gap description**
   - File: `path/to/file`
   - Required: What needs to be added

### Minor Gaps (Recommended to fix)

[List each minor gap with:]
1. **Gap description**
   - File: `path/to/file`
   - Issue: What's missing or incomplete

## Next Steps

| Priority | Action | Gate |
|----------|--------|------|
| P0 | Fix critical gaps | Return to Gate 1/2 |
| P1 | Review minor gaps | Optional |
| - | Re-run validation | After fixes |
| - | Proceed to TRD | After validation passes |
```

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Error states are implementation details" | Error states are UX decisions. Users experience errors. | **Specify all error states before TRD** |
| "We'll figure out mobile layout during coding" | Responsive is design decision, not implementation. | **Specify mobile layout now** |
| "Loading state is just a spinner" | Loading UX varies: skeleton, spinner, progressive. | **Specify loading behavior explicitly** |
| "Accessibility can be added later" | Retrofitting a11y is 10x more expensive. | **Include a11y specs from start** |
| "These are minor gaps, let's proceed" | Minor gaps compound. Fix them now. | **Fix gaps or explicitly accept risk** |
| "The wireframe is self-explanatory" | Self-explanatory to you does not mean clear to developer. | **Document all states explicitly** |
| "This validation is slowing us down" | Incomplete design slows implementation 10x more. | **Complete validation before TRD** |
| "We have tight deadlines" | Incomplete specs cause missed deadlines. | **Invest time now, save time later** |
| "Designer already approved this" | Designer approval does not equal completeness check. | **Run systematic validation** |
| "We'll add states as we implement" | Adding states during implementation causes scope creep. | **Define all states upfront** |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip validation, design is good enough" | "Design validation prevents implementation rework. 'Good enough' does not equal complete." |
| "We don't have time for this gate" | "Incomplete design costs 10x in implementation. Time invested now saves time later." |
| "Just the critical sections, skip the rest" | "all sections exist because they prevent real problems. No cherry-picking." |
| "Error states are obvious, no need to specify" | "Obvious to you does not equal obvious to developer does not equal obvious to user. Specify them." |
| "Mobile can wait for v2" | "Mobile users are 60%+ of traffic. Responsive is not optional." |
| "Let's start TRD in parallel" | "TRD depends on complete design. Starting with gaps creates rework." |
| "The previous feature didn't need this" | "Each feature is validated independently. Past shortcuts don't justify current ones." |
| "I'll fix gaps after TRD" | "Fixing design after technical architecture causes cascade changes. Fix now." |

---

## Blocker Criteria - STOP and Report

| Condition | Action |
|-----------|--------|
| PRD not found | **STOP.** Return to Gate 1 to create PRD. |
| Feature has UI but no ux-criteria.md | **STOP.** Return to Gate 1 to create UX criteria. |
| Feature has UI but no wireframes | **STOP.** Return to Gate 1/2 to create wireframes. |
| Critical gaps found (Section 1-2) | **STOP.** Return to UX gate to fix gaps. |
| Minor gaps found (Section 3-6) | **ASK USER.** Proceed with documented risk or fix first? |

---

## Severity Calibration

| Severity | Criteria | Examples | Action |
|----------|----------|----------|--------|
| **CRITICAL** | Missing Section 1-2 items | No wireframe for screen, no error state, no loading state | STOP, return to previous gate |
| **CRITICAL** | Missing Section 7 items (new projects) | No design-system.md, no color palette | STOP, return to PRD creation |
| **CRITICAL** | Missing Section 8 items | Components don't exist in library, wrong variants | STOP, fix wireframes |
| **HIGH** | Missing Section 3-5 items | No a11y criteria, no mobile layout, no error flow | Document, strongly recommend fix |
| **MEDIUM** | Missing Section 6 items | Generic button labels, missing CTA on empty state | Document, recommend fix |
| **LOW** | Incomplete but present | Mobile layout exists but lacks touch target note | Note for future improvement |

---

## When Validation is Not Needed

**Skip this gate when all conditions are true:**

- Feature is backend-only (no user-facing UI)
- Feature is pure API/infrastructure
- PRD explicitly states "No UI changes"
- Feature is bug fix with no UX modifications

**If any UI exists -> Validation is REQUIRED.**

---

## Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| `validation_pass_rate` | % of features passing on first validation | > 70% |
| `critical_gaps_per_validation` | Average critical gaps found | < 2 |
| `validation_time_minutes` | Time to complete validation | < 15 |
| `rework_reduction` | Implementation rework after validation | -50% |
