---
name: ring-tw-team:review-docs
description: Review existing documentation for quality, voice, tone, and completeness
argument-hint: "[file]"
arguments:
  - name: file
    description: Path to the documentation file to review
    required: false
---

# Review Documentation Command

You're reviewing documentation quality. This command dispatches the docs-reviewer agent.

## Review Process

The review covers five dimensions:

### 1. Voice and Tone
- Uses "you" not "users"
- Present tense for current behavior
- Active voice (subject does action)
- Assertive but not arrogant
- Sounds like helping a colleague

### 2. Structure
- Sentence case headings
- Section dividers between major topics
- Scannable (bullets, tables, headings)
- Logical hierarchy

### 3. Completeness
- All sections present
- Examples included
- Links work
- Next steps provided

### 4. Clarity
- Short sentences (one idea)
- Short paragraphs (2-3 sentences)
- Jargon explained
- Realistic examples

### 5. Technical Accuracy
- Facts are correct
- Code examples work
- Links valid
- Version info current

## Dispatch Review Agent

```
Task tool:
  subagent_type: "docs-reviewer"
  model: "opus"
  prompt: "Review this documentation for quality. Check:
          1. Voice and tone (second person, active voice, present tense)
          2. Structure (sentence case, dividers, scannable)
          3. Completeness (examples, links, next steps)
          4. Clarity (short sentences, no jargon)
          5. Accuracy (facts, code, links)

          Provide:
          - VERDICT: PASS / NEEDS_REVISION / MAJOR_ISSUES
          - Prioritized issues with locations and fixes
          - What was done well

          Documentation to review:
          [paste or reference file content]"
```

## Quick Checklist

### Voice (scan for these)
- [ ] No "users" or "one" (should be "you")
- [ ] No "will" for current behavior (should be present tense)
- [ ] No "is created by" (should be active: "creates")

### Structure (scan for these)
- [ ] Headings are sentence case
- [ ] `---` dividers present
- [ ] Content is scannable

### Completeness (check for)
- [ ] Examples present
- [ ] Links work
- [ ] Next steps at end

## Verdict Criteria

**PASS:** No critical issues, ≤2 high-priority issues, consistent voice/tone

**NEEDS_REVISION:** Has high-priority issues, some inconsistencies, minor gaps

**MAJOR_ISSUES:** Critical issues, significant problems, poor structure

## Common Issues Reference

| Issue | Example | Fix |
|-------|---------|-----|
| Third person | "Users can..." | "You can..." |
| Passive voice | "...is returned" | "...returns" |
| Title case | "Getting Started" | "Getting started" |
| Missing prereqs | Steps without context | Add prerequisites |
| No examples | API without code | Add examples |
| Long sentences | 40+ words | Split into multiple |

## Proceed

**Documentation to review:** $ARGUMENTS.file

If no file path was provided, paste the documentation content or specify a file path now.
