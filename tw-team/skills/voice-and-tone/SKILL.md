---
name: voice-and-tone
description: |
  Voice and tone guidelines for technical documentation. Ensures consistent,
  clear, and human writing across all documentation.
metadata:
  related:
    complementary:
    - ring:writing-functional-docs
    - ring:writing-api-docs
    - ring:documentation-review
  skip_when: |
    - Only checking structure → use ring:documentation-structure
    - Only checking technical accuracy → use docs-reviewer agent
  trigger: |
    - Need to check voice and tone compliance
    - Writing new documentation
    - Reviewing existing documentation for style
---

# Voice and Tone Guidelines

Write the way you work: with confidence, clarity, and care. Good documentation sounds like a knowledgeable colleague helping you solve a problem.

## Core Tone Principles

### Assertive, But Never Arrogant
Say what needs to be said, clearly and without overexplaining.

> ✅ Core one uses a microservices architecture, which allows each component to be self-sufficient and easily scalable.
>
> ❌ Core one might use what some people call a microservices architecture, which could potentially allow components to be somewhat self-sufficient.

### Encouraging and Empowering
Guide users to make progress, especially when things get complex.

> ✅ This setup isn't just technically solid; it's built for real-world use. You can add new components as needed without disrupting what's already in place.
>
> ❌ This complex setup requires careful understanding of multiple systems before you can safely make changes.

### Tech-Savvy, But Human
Talk to developers, not at them. Use technical terms when needed, but prioritize clarity.

> ✅ Each Account is linked to exactly one Asset type.
>
> ❌ The Account entity maintains a mandatory one-to-one cardinality with the Asset entity.

### Humble and Open
Be confident in your solutions but always assume there's more to learn.

> ✅ As Core one evolves, new fields and tables may be added.
>
> ❌ The system is complete and requires no further development.

---

## The Golden Rule

> Write like you're helping a smart colleague who just joined the team.

This colleague is: Technical and can handle complexity, new to this system, busy and appreciates efficiency, capable of learning quickly with guidance.

---

## Writing Mechanics

| Rule | Use | Avoid |
|------|-----|-------|
| Second person | "You can create..." | "Users can create..." |
| Present tense | "The system returns..." | "The system will return..." |
| Active voice | "The API returns a JSON response" | "A JSON response is returned by the API" |
| Short sentences | Two sentences, one idea each | One long sentence with multiple clauses |

---

## Capitalization

**Sentence case for all headings** – Only capitalize first letter and proper nouns.

| ✅ Correct | ❌ Avoid |
|-----------|---------|
| Getting started with the API | Getting Started With The API |
| Using the transaction builder | Using The Transaction Builder |
| Managing account types | Managing Account Types |

Applies to: Page titles, section headings, card titles, navigation labels, table headers

---

## Terminology

**Product names:** Always capitalize (Core one, Console, Reporter, Core two, Core four)

**Entity names:** Capitalize when referring to specific concept (Account, Ledger, Asset, Portfolio, Segment, Transaction, Operation, Balance)

> Each Account is linked to a single Asset.

Lowercase for general references:
> You can create multiple accounts within a ledger.

---

## Contractions

Use naturally to make writing conversational:

| Natural | Stiff |
|---------|-------|
| You'll find... | You will find... |
| It's important... | It is important... |
| Don't delete... | Do not delete... |

---

## Emphasis

**Bold** for UI elements and key terms: Click **Create Account**, the **metadata** field

`Code formatting` for technical terms: `POST /accounts`, `allowSending`

**Don't overuse** – if everything is emphasized, nothing stands out.

---

## Info Boxes

| Type | When |
|------|------|
| **Tip:** | Helpful information |
| **Note:** | Important context |
| **Warning:** | Potential issues |
| **Deprecated:** | Removal notices |

---

## Quality Checklist

- [ ] Uses "you" consistently (not "users")
- [ ] Uses present tense for current behavior
- [ ] Uses active voice (subject does action)
- [ ] Sentences are short (one idea each)
- [ ] Headings use sentence case
- [ ] Technical terms used appropriately
- [ ] Contractions used naturally
- [ ] Emphasis used sparingly
- [ ] Sounds like helping a colleague

---

## Standards Loading (MANDATORY)

Voice and tone guidelines are foundational. When applying this skill:

1. **Load this skill first** before any documentation writing
2. **Cross-reference** with `ring:writing-functional-docs` or `ring:writing-api-docs`
3. **Use with documentation-review** for quality verification

**HARD GATE:** CANNOT write documentation without understanding voice and tone principles.

---

## Blocker Criteria - STOP and Report

| Condition | Decision | Action |
|-----------|----------|--------|
| Target audience undefined | STOP | Report: "Need audience definition before writing" |
| Product terminology undefined | STOP | Report: "Need terminology guide for consistent naming" |
| Conflicting style guidelines | STOP | Report: "Need style guide clarification" |
| Brand voice undefined | STOP | Report: "Need brand voice parameters" |

### Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST use second person ("you") consistently
- MUST use present tense for current behavior
- MUST use active voice (subject performs action)
- MUST use sentence case for all headings
- CANNOT use condescending or arrogant tone
- CANNOT use passive voice for describing actions

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Consistently wrong voice or tone | Third person throughout, condescending language |
| **HIGH** | Multiple voice/tone violations | Passive voice abuse, future tense for current features |
| **MEDIUM** | Occasional inconsistencies | Mixed pronouns, some title case headings |
| **LOW** | Minor polish needed | Could flow better, minor word choices |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Formal writing is more professional" | "Professional ≠ formal. Clear, direct language IS professional. I'll write like a knowledgeable colleague helping." |
| "Use 'users' to sound objective" | "MUST use 'you' for direct address. 'Users' creates distance. I'll address the reader directly." |
| "Future tense sounds more polished" | "MUST use present tense for current behavior. 'Returns' not 'will return'. I'll use present tense." |
| "Title Case Looks Better" | "Sentence case is the standard. Only first word and proper nouns capitalized. I'll use sentence case." |
| "Add more emphasis, it's important" | "Over-emphasis = no emphasis. I'll use bold/caps sparingly for truly critical items." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Users' is more formal/professional" | Formality ≠ quality. Direct address improves comprehension | **MUST use 'you' consistently** |
| "Passive voice sounds more technical" | Passive voice obscures who does what | **MUST use active voice** |
| "Title Case is industry standard" | It's not. Sentence case is clearer and more readable | **MUST use sentence case** |
| "This content is different, rules don't apply" | Voice/tone applies to ALL documentation | **Apply guidelines uniformly** |
| "Users will understand either way" | Consistency reduces cognitive load | **MUST follow guidelines exactly** |
| "The content matters more than the style" | Style IS content. Poor style obscures meaning | **Voice and tone are REQUIRED** |

---

## When This Skill is Not Needed

Signs that documentation already follows voice and tone guidelines:

- Consistently uses "you" (not "users", "one", "they")
- Uses present tense for current behavior throughout
- Uses active voice for all actions
- All headings use sentence case (not Title Case)
- Tone is assertive but helpful (not arrogant or condescending)
- Contractions used naturally
- Emphasis used sparingly and purposefully

**If all above are true:** Voice and tone is compliant, no changes needed.
