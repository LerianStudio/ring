# Reviewer Quality Feedback

**Version:** 1.0.0
**Purpose:** Define metrics and processes for evaluating reviewer accuracy over time

---

## Overview

This shared pattern establishes a feedback mechanism to evaluate the quality of reviewer outputs, identify false positives/negatives, and enable continuous improvement of reviewer agents.

---

## Quality Metrics

### Accuracy Indicators

| Metric | Definition | Target |
|--------|------------|--------|
| True Positive Rate | Issues found that were actual problems | > 90% |
| False Positive Rate | Issues flagged that weren't problems | < 10% |
| False Negative Rate | Real issues missed by reviewer | < 5% |
| Actionability Score | % of findings with clear fix guidance | > 95% |

### Per-Review Quality Checklist

After implementing fixes from a review, track:

- [ ] How many flagged issues were actual problems? (True Positives)
- [ ] How many flagged issues were false alarms? (False Positives)
- [ ] Were any real issues discovered later that the reviewer missed? (False Negatives)
- [ ] Were the fix recommendations actionable and correct?

---

## Feedback Template

When a review cycle completes, optionally record feedback:

```markdown
## Review Quality Feedback

**Review Date:** [YYYY-MM-DD]
**Reviewer:** [ring:code-reviewer | ring:business-logic-reviewer | ring:security-reviewer | ring:test-reviewer | ring:nil-safety-reviewer | ring:dead-code-reviewer | ring:performance-reviewer | ring:multi-tenant-reviewer | ring:lib-commons-reviewer]
**Files Reviewed:** [count]

### Accuracy Assessment

| Category | Count | Examples |
|----------|-------|----------|
| True Positives | [N] | [Brief description of valid findings] |
| False Positives | [N] | [Brief description of invalid findings] |
| False Negatives | [N] | [Issues found later that were missed] |

### Actionability Assessment

- Were fix recommendations clear? [Yes/No]
- Were file:line references accurate? [Yes/No]
- Were severity ratings appropriate? [Yes/No]

### Improvement Suggestions

[Any patterns noticed that could improve the reviewer agent]
```

---

## Calibration Review Process

**Quarterly Calibration (Recommended):**

1. **Collect Feedback:** Aggregate feedback from past review cycles
2. **Identify Patterns:** Look for recurring false positive/negative patterns
3. **Update Checklists:** Adjust reviewer checklists based on patterns
4. **Test Changes:** Run updated reviewer on known codebase
5. **Document Changes:** Update reviewer changelog

---

## Integration with Review Workflow

This feedback mechanism is OPTIONAL but recommended for teams wanting to track reviewer quality.

**When to Record Feedback:**
- After fixing issues from a review
- When discovering issues the reviewer missed
- When a flagged issue turns out to be a false alarm

**Where to Store Feedback:**
- Project-specific: `docs/review-feedback/[date]-[reviewer].md`
- Or integrated into PR/ring:commit notes

---

## Anti-Gaming Measures

To prevent feedback from being gamed:

1. **Feedback is retrospective** - Only recorded after implementation, not during review
2. **False negatives count** - Missing real issues is tracked, not just false positives
3. **Severity matters** - A missed Critical counts more than a missed Low
4. **Aggregate over time** - Individual reviews may vary; patterns matter

---

## Reference from Reviewers

Reviewers should reference this pattern in their output:

```markdown
---

*Quality feedback for this review can be recorded using the template in
[reviewer-quality-feedback.md](../skills/shared-patterns/reviewer-quality-feedback.md)*
```
