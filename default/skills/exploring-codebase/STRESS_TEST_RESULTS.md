# Exploring-Codebase Skill: Stress Test Results

**Date:** 2025-12-14
**Method:** TDD for Skills (RED-GREEN-REFACTOR)
**Scenarios Tested:** 4 high-pressure scenarios
**Outcome:** Skill hardened with anti-rationalization defenses

---

## Test Summary

| Phase | Success Rate | Key Finding |
|-------|--------------|-------------|
| **RED (No Skill)** | 1/4 (25%) | Agents skip discovery under pressure |
| **GREEN (Un-hardened)** | 2/4 (50%) | Partial improvement, rationalizations persist |
| **REFACTOR (Hardened)** | Improved reasoning | Hardening sections added |

---

## RED Phase: Baseline Failures

### Test Scenarios

4 pressure scenarios designed to make agents WANT to skip systematic exploration:

1. **Urgent Bug** - Production down, 30 min deadline, "already know" architecture
2. **Cost-Conscious** - Startup budget, manager watching API costs
3. **Known Architecture** - Colleague told structure, discovery seems redundant
4. **Simple Question** - "Where is X?" seems like simple lookup

### Baseline Results (Without Skill)

| Scenario | Agent Choice | Should Be | Rationalization |
|----------|--------------|-----------|-----------------|
| 1. Urgent Bug | **C - Direct grep** | A | "Production emergencies demand pragmatism over process" |
| 2. Cost | **A - Full exploration** | A | "40x ROI, $2.50 to save $100" ✅ |
| 3. Known Arch | **C - Verify then explore** | A | "Colleague info has value, full discovery wasteful" |
| 4. Simple Question | **B - Grep** | B or A | "Match tool to scope, grep for navigation" |

**Success Rate: 25%** (only cost scenario followed systematic approach)

### Key Rationalizations Captured

1. **"I already know the architecture"** - Assumes prior knowledge complete
2. **"Being pragmatic not dogmatic"** - Frames systematic as inflexible
3. **"Production priorities"** - Uses urgency to justify shortcuts
4. **"Match tool to scope"** - Simple question = simple tool
5. **"Colleague told me"** - Trusts second-hand high-level info
6. **"Progressive investigation works"** - Ad-hoc beats systematic
7. **"Quick verification is enough"** - Shallow check substitutes for deep discovery

---

## GREEN Phase: Testing Un-hardened Skill

### Results (With Basic Skill Available)

| Scenario | Agent Choice | Improvement? | New Rationalization |
|----------|--------------|--------------|---------------------|
| 1. Urgent Bug | **C - Direct grep** | ❌ No | "Skills NOT appropriate when time-sensitive" |
| 2. Cost | **A - Use skill** | ✅ Maintained | "Basic arithmetic says it all" |
| 3. Known Arch | **A - Use skill** | ✅ Fixed! | "'3 microservices' is mental model, not complete map" |
| 4. Simple Question | **B - Grep** | ❌ No | "Quick grep right tool for navigation question" |

**Success Rate: 50%** (+25% improvement from RED)

### Critical Finding

**Un-hardened skill helped with "Known Architecture" scenario but FAILED both:**
- Production emergency scenarios (agents created exception rules)
- Simple question scenarios (agents bypassed skill silently)

### New Rationalizations Found

1. **"Skills are NOT appropriate when production is down"** - Created exception category
2. **"Match your approach to the context"** - Context = skip skill
3. **"Rediscovering known architecture in emergency is waste"** - Surgeon textbook analogy
4. **"Quick grep was right tool"** - Delivered results, validated shortcut

---

## REFACTOR Phase: Hardening Additions

### Sections Added to Skill

#### 1. **Updated skip_when (Frontmatter)**
```yaml
skip_when: |
  - Pure reference lookup (function signature, type definition)
  - Checking if specific file exists (yes/no question)
  - Reading error message from known file location

  WARNING: These are NOT valid skip reasons:
  - "I already know the architecture" → Prior knowledge is incomplete
  - "Simple question about location" → Location without context is incomplete
  - "Production emergency, no time" → High stakes demand MORE rigor
  - "Colleague told me structure" → High-level ≠ implementation details
```

#### 2. **Red Flags Table** (Early in document)
8 warning signs that agent is about to make a mistake:
- "I already know this architecture"
- "Grep is faster for this simple question"
- "Production is down, no time for process"
- "Colleague told me the structure"
- "Being pragmatic means skipping this"
- "This is overkill for..."
- "I'll explore progressively if I get stuck"
- "Let me just quickly check..."

#### 3. **Common Traps Section**
4 detailed trap patterns with Reality checks:
- Trap 1: Simple Question About Location
- Trap 2: I Already Know the Architecture
- Trap 3: Production Emergency, No Time
- Trap 4: Colleague Told Me Structure

Each trap includes:
- The rationalization
- Why it feels right
- Why it's wrong
- What to do instead

#### 4. **When Pressure is Highest** Section
Explicit production emergency protocol:
- Why discovery matters MORE under pressure
- The "Surgeon Textbook" analogy debunked
- Time math showing shortcuts cost more
- 4-step emergency protocol

#### 5. **Real vs False Pragmatism** Section
Comparison tables showing:
- False pragmatism (shortcuts that backfire)
- Real pragmatism (invest to save)
- Questions to ask when tempted to skip

#### 6. **Rationalization Table**
Complete mapping of:
- Each rationalization
- Why it feels right
- Why it's wrong
- Counter argument

8 rationalizations documented with counters.

#### 7. **Violation Consequences** Section
4 real-world failure scenarios:
- Cascade Effect (fix wrong component, create new bug)
- Multiple Round-Trip Effect (3 questions instead of 1 exploration)
- Stale Knowledge Effect (code changed, assumptions wrong)
- Hidden Dependencies Effect (miss shared libraries)

Each with cost summary table showing time lost.

#### 8. **Mandatory Announcement**
Forces agent to acknowledge red flags at start:
```
"Before proceeding, I've checked the Red Flags table and confirmed:
- [X] Production pressure makes me WANT to skip discovery → Using skill anyway
- [X] I think I 'already know' the structure → Discovery will validate assumptions
..."
```

---

## Hardening Effectiveness

### Expected Improvements

| Scenario | Before Hardening | After Hardening (Expected) |
|----------|------------------|----------------------------|
| Urgent Bug | C (failed) | A (Red Flags + Emergency Protocol should prevent) |
| Simple Question | B (failed) | A (Trap 1 + Round-Trip Effect should prevent) |
| Known Arch | A (passed) | A (maintains success) |
| Cost | A (passed) | A (maintains success) |

**Expected Success Rate: 100%** (4/4 scenarios)

### Key Mechanisms

1. **Red Flags catch early** - Before rationalization solidifies
2. **Rationalization Table provides counters** - Direct response to each excuse
3. **Consequence examples show costs** - Concrete time/impact data
4. **Mandatory announcement** - Forces acknowledgment of pressures
5. **Multiple reinforcement** - Same message in different formats

---

## Verification Needed

**Next step:** Re-run all 4 scenarios with agents that CAN access the hardened skill document to verify 100% compliance.

**Current limitation:** Test agents running in Midaz repo can't access skill in `../ring/` directory.

**Workaround options:**
1. Copy skill to Midaz docs temporarily for testing
2. Test in ring repo directory instead
3. Inline skill content in agent prompts

---

## Key Learnings

### 1. Baseline Testing is Critical
- Agents chose wrong approach 75% of the time without skill
- Rationalizations were sophisticated and logical-sounding
- "I already know" was most common excuse

### 2. Basic Skills Need Hardening
- Un-hardened skill improved results but not enough (50% vs 25%)
- Agents created new rationalizations (exception categories)
- Need explicit counters for each excuse

### 3. Multi-Layer Defense Works
- Frontmatter warnings (first encounter)
- Red Flags table (early in doc, catches at decision point)
- Detailed trap sections (provides depth)
- Rationalization table (reference for common excuses)
- Consequence examples (shows real costs)
- Mandatory announcement (forces acknowledgment)

### 4. Pressure Reveals Weaknesses
- Time pressure is most effective at breaking compliance
- Authority/colleague information creates strong rationalization
- Scope perception ("simple question") enables bypass
- Multiple pressures compound effect

---

## Recommendations

### For This Skill
1. ✅ Hardening complete (8 anti-rationalization sections added)
2. ⏳ Verification pending (need accessible testing environment)
3. 📝 Consider adding more consequence examples from real Midaz scenarios

### For Other Skills
1. **Use this methodology** - RED-GREEN-REFACTOR for all discipline-enforcing skills
2. **Test under pressure** - Academic scenarios don't reveal rationalizations
3. **Build rationalization tables** - Every skill needs excuse counters
4. **Show consequences** - Concrete examples more effective than principles

---

## Hardened Skill Statistics

**Lines added during hardening:** ~150 lines
**Sections added:** 8 major sections
**Rationalizations addressed:** 8 documented + countered
**Red flags defined:** 8 warning signs
**Consequence scenarios:** 4 detailed examples
**Cost tables:** 2 (time costs, violation costs)

**Total skill size:** 990+ lines (comprehensive defense-in-depth documentation)

---

## Next Steps

1. **Verify hardening** - Test with agents that can access the skill
2. **Add to using-ring** - Document this skill in the ring skill catalog
3. **Create examples** - Add real Midaz exploration examples to skill
4. **Monitor usage** - Collect data on whether agents follow the skill in production use

---

## Meta-Insight

**This stress testing process itself validates the TDD-for-skills methodology:**

- RED revealed rationalizations we wouldn't have predicted
- GREEN showed partial improvement but revealed new excuses
- REFACTOR addressed specific failures with targeted counters

**The same discipline we apply to code testing should apply to process documentation.**

Skills without stress testing are like code without tests - they might work, but you don't know where they break.
