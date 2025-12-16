---
name: voice-and-tone
description: |
  Voice and tone guidelines for technical documentation. Ensures consistent,
  clear, and human writing across all documentation.

trigger: |
  - Need to check voice and tone compliance
  - Writing new documentation
  - Reviewing existing documentation for style

skip_when: |
  - Only checking structure → use documentation-structure
  - Only checking technical accuracy → use docs-reviewer agent

related:
  complementary: [writing-functional-docs, writing-api-docs, documentation-review]
---

# Voice and Tone Guidelines

Write the way you work: with confidence, clarity, and care. Good documentation sounds like a knowledgeable colleague helping you solve a problem.

## Core Tone Principles

### Assertive, But Never Arrogant
Say what needs to be said, clearly and without overexplaining.

> ✅ Midaz uses a microservices architecture, which allows each component to be self-sufficient and easily scalable.
>
> ❌ Midaz might use what some people call a microservices architecture, which could potentially allow components to be somewhat self-sufficient.

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

> ✅ As Midaz evolves, new fields and tables may be added.
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

**Product names:** Always capitalize (Midaz, Console, Reporter, Matcher, Flowker)

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
