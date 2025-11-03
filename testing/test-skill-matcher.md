# Skill Matcher Integration Test

## Purpose

Validate skill-matcher correctly maps task descriptions to relevant skills.

## Test Case 1: Debugging Task

**Input:**
```bash
./lib/skill-matcher.sh "debug this authentication error"
```

**Expected:**
```
Relevant skills:

1. systematic-debugging (HIGH confidence)
2. test-driven-development (MEDIUM confidence)
...

Recommended: Start with systematic-debugging
```

**Verification:**
- ✅ systematic-debugging appears first
- ✅ Confidence level is HIGH or MEDIUM
- ✅ At least 1 skill suggested

## Test Case 2: Implementation Task

**Input:**
```bash
./lib/skill-matcher.sh "implement new user authentication feature"
```

**Expected:**
```
Relevant skills:

1. test-driven-development (HIGH confidence)
2. brainstorming (MEDIUM confidence)
...

Recommended: Start with test-driven-development
```

**Verification:**
- ✅ test-driven-development appears in top 3
- ✅ Appropriate confidence level

## Test Case 3: No Matches

**Input:**
```bash
./lib/skill-matcher.sh "xyz random unrelated task abc"
```

**Expected:**
```
No matching skills found
Try rephrasing your task or check available skills manually:
  ls skills/
```

**Verification:**
- ✅ Graceful handling of no matches
- ✅ Suggests alternative (manual check)

## Success Criteria

- ✅ Debugging tasks → systematic-debugging
- ✅ Implementation tasks → test-driven-development
- ✅ Planning tasks → brainstorming or pre-dev-*
- ✅ No matches handled gracefully
