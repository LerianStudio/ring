---
name: ring:reviewing-docs
description: "Reviewing end-user and product documentation quality across voice/tone, structure, completeness, clarity, and technical accuracy; flags issues with prioritized findings and a pass/needs-revision verdict. Use when reviewing draft docs, running a pre-publication check, auditing existing docs, or enforcing style-guide compliance. Skip when writing new docs, or checking voice only (use ring:applying-voice-and-tone)."
---

# Documentation Review Process

## When to use
- Reviewing draft documentation
- Pre-publication quality check
- Documentation audit
- Ensuring style guide compliance

## Skip when
- Writing new documentation → dispatch the guide-writer or api-writer agent
- Only checking voice → use ring:applying-voice-and-tone

## Sequence
**Runs after:** guide-writer, api-writer (agents)

## Related
**Complementary:** ring:applying-voice-and-tone, ring:structuring-documentation

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

