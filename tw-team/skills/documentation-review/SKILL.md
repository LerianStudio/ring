---
name: documentation-review
description: |
  Comprehensive checklist and process for reviewing documentation quality
  including voice, tone, structure, completeness, and technical accuracy.
metadata:
  related:
    complementary:
    - ring:voice-and-tone
    - ring:documentation-structure
  sequence:
    after:
    - ring:writing-functional-docs
    - ring:writing-api-docs
  skip_when: |
    - Writing new documentation → use ring:writing-functional-docs or ring:writing-api-docs
    - Only checking voice → use ring:voice-and-tone
  trigger: |
    - Reviewing draft documentation
    - Pre-publication quality check
    - Documentation audit
    - Ensuring style guide compliance
---

# Documentation Review Process

Review documentation systematically across multiple dimensions. A thorough review catches issues before they reach users.

## Review Dimensions

1. **Voice and Tone** – Does it sound right?
2. **Structure** – Is it organized effectively?
3. **Completeness** – Is everything covered?
4. **Clarity** – Is it easy to understand?
5. **Technical Accuracy** – Is it correct?

---

## Voice and Tone Review

| Check | Flag If |
|-------|---------|
| Second person | "Users can..." instead of "You can..." |
| Present tense | "will return" instead of "returns" |
| Active voice | "is returned by the API" instead of "The API returns" |
| Tone | Arrogant ("Obviously...") or condescending |

---

## Structure Review

| Check | Flag If |
|-------|---------|
| Hierarchy | Deep nesting (H4+), unclear parent-child |
| Headings | Title Case instead of sentence case |
| Section dividers | Missing `---` between major topics |
| Navigation | Missing links to related content |

---

## Completeness Review

**Conceptual docs:** Definition, characteristics, how it works, related concepts, next steps

**How-to guides:** Prerequisites, all steps, verification, troubleshooting, next steps

**API docs:** HTTP method/path, all parameters, all fields, required vs optional, examples, error codes

---

## Clarity Review

| Check | Flag If |
|-------|---------|
| Sentence length | >25 words per sentence |
| Paragraph length | >3 sentences per paragraph |
| Jargon | Technical terms not explained on first use |
| Examples | Abstract data ("foo", "bar") instead of realistic |

---

## Technical Accuracy Review

**Conceptual:** Facts correct, behavior matches description, links work

**API docs:** Paths correct, methods correct, field names match API, types accurate, examples valid JSON

**Code examples:** Compiles/runs, output matches description, no syntax errors

---

## Common Issues to Flag

| Category | Issue | Fix |
|----------|-------|-----|
| Voice | Third person ("Users can...") | "You can..." |
| Voice | Passive ("...is returned") | "...returns" |
| Voice | Future tense ("will provide") | "provides" |
| Structure | Title case heading | Sentence case |
| Structure | Wall of text | Add `---` dividers |
| Completeness | Missing prereqs | Add prerequisites |
| Completeness | No examples | Add code examples |
| Clarity | Long sentences (40+ words) | Split into multiple |
| Clarity | Undefined jargon | Define on first use |

---

## Review Output Format

> **Note:** Documentation reviews use `PASS/NEEDS_REVISION/MAJOR_ISSUES` verdicts (graduated), which differ from code review verdicts (`PASS/FAIL/NEEDS_DISCUSSION`).

```markdown
## Review Summary

**Overall Assessment:** [PASS | NEEDS_REVISION | MAJOR_ISSUES]

### Issues Found

#### High Priority
1. **Line 45:** Passive voice "is created by" → "creates"

#### Medium Priority
1. **Line 23:** Title case in heading → sentence case

#### Low Priority
1. **Line 12:** Could add example for clarity

### Recommendations
1. Fix passive voice instances (3 found)
2. Add missing API field documentation
```

---

## Quick Review Checklist

**Voice (30s):** "You" not "users", present tense, active voice

**Structure (30s):** Sentence case headings, section dividers, scannable (bullets/tables)

**Completeness (1m):** Examples present, links work, next steps included

**Accuracy (varies):** Technical facts correct, code examples work

---

## Standards Loading (MANDATORY)

Before reviewing documentation:

1. **Load voice and tone** - `ring:voice-and-tone` for style verification
2. **Load structure patterns** - `ring:documentation-structure` for organization checks
3. **Load document type patterns** - `ring:writing-functional-docs` or `ring:writing-api-docs`

**HARD GATE:** CANNOT review documentation without loading relevant standards.

---

## Blocker Criteria - STOP and Report

| Condition | Decision | Action |
|-----------|----------|--------|
| Style guide unavailable | STOP | Report: "Need style guide to review against" |
| Source material missing | STOP | Report: "Need source to verify technical accuracy" |
| Review scope undefined | STOP | Report: "Need to know what aspects to review" |
| Technical SME unavailable | STOP | Report: "Need SME access for accuracy verification" |

### Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST review all five dimensions (voice, structure, completeness, clarity, accuracy)
- MUST flag all issues found (not just major ones)
- MUST provide specific line references for issues
- MUST categorize issues by priority (High/Medium/Low)
- CANNOT approve documentation with HIGH-priority issues
- CANNOT skip accuracy verification

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Factually incorrect, misleading information | Wrong API paths, incorrect behavior described |
| **HIGH** | Major voice/structure violations, missing sections | Passive voice throughout, no examples |
| **MEDIUM** | Multiple minor issues, inconsistencies | Mixed pronouns, some title case |
| **LOW** | Polish issues, optimization opportunities | Could flow better, minor wording |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just do a quick review, we're rushing" | "Quick review still covers all 5 dimensions. CANNOT skip any review category." |
| "Only check for typos" | "Review MUST cover voice, structure, completeness, clarity, AND accuracy. Typos are LOW priority." |
| "Skip technical accuracy, trust the writer" | "Technical accuracy MUST be verified. Trust but verify." |
| "Approve it, minor issues can be fixed later" | "CANNOT approve with HIGH priority issues. They must be fixed first." |
| "The content is more important than style" | "Style affects comprehension. Voice and tone are REQUIRED review dimensions." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Good enough for now" | Good enough ≠ meets standards | **MUST flag all issues** |
| "Writer knows the product" | Knowledge ≠ documentation quality | **Review all dimensions** |
| "Style issues are subjective" | Style guidelines are objective standards | **Apply guidelines consistently** |
| "Users won't notice minor issues" | Minor issues accumulate into poor UX | **Flag all issues regardless of size** |
| "Review is blocking release" | Poor docs also block user success | **Complete review properly** |
| "Trust the automated checks" | Automated checks miss context | **Human review is REQUIRED** |

---

## When This Skill is Not Needed

Signs that documentation doesn't need review:

- Documentation was written by ring-tw-team specialists
- Previous review found zero issues
- Documentation hasn't changed since last review
- All five review dimensions already verified

**If all above are true:** Review may be skipped for unchanged content.

**Note:** New or modified documentation MUST always be reviewed.
