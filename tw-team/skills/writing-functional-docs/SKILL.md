---
name: writing-functional-docs
description: |
  Patterns and structure for writing functional documentation including guides,
  conceptual explanations, tutorials, and best practices documentation.
metadata:
  related:
    similar:
    - writing-api-docs
    complementary:
    - voice-and-tone
    - documentation-structure
  sequence:
    before:
    - documentation-review
  skip_when: |
    - Writing API reference → use writing-api-docs
    - Reviewing documentation → use documentation-review
    - Writing code → use dev-team agents
  trigger: |
    - Writing a new guide or tutorial
    - Creating conceptual documentation
    - Documenting best practices
    - Writing "how to" content
---

# Writing Functional Documentation

Functional documentation explains concepts, guides users through workflows, and helps them understand "why" and "how" things work. This differs from API reference, which documents "what" each endpoint does.

## Document Types

| Type | Purpose | Key Sections |
|------|---------|--------------|
| **Conceptual** | Explains core concepts and how things work | Definition → Key characteristics → How it works → Related concepts |
| **Getting Started** | First task with the product | Intro → Prerequisites → Numbered steps → Next steps |
| **How-To** | Task-focused for specific goals | Context → Before you begin → Steps → Verification → Troubleshooting |
| **Best Practices** | Optimal usage patterns | Intro → Practice sections (Mistake/Best practice) → Summary |

---

## Writing Patterns

### Lead with Value
Start every document with what the reader will learn or accomplish.

> ✅ This guide shows you how to create your first transaction in under 5 minutes.
>
> ❌ In this document, we will discuss the various aspects of transaction creation.

### Use Second Person
Address the reader directly.

> ✅ You can create as many accounts as your structure demands.
>
> ❌ Users can create as many accounts as their structure demands.

### Present Tense
Use for current behavior.

> ✅ Core one uses a microservices architecture.
>
> ❌ Core one will use a microservices architecture.

### Action-Oriented Headings
Indicate what the section covers or what users will do.

> ✅ Creating your first account
>
> ❌ Account creation process overview

### Short Paragraphs
2-3 sentences maximum. Use bullets for lists.

---

## Visual Elements

| Element | Usage |
|---------|-------|
| **Info box** | `> **Tip:** Helpful additional context` |
| **Warning box** | `> **Warning:** Important caution` |
| **Code examples** | Always include working examples for technical concepts |
| **Tables** | For comparing options or structured data |

---

## Section Dividers

Use `---` to separate major sections. Improves scannability.

---

## Linking Patterns

- **Internal links:** Link concepts when first mentioned: "Each Account is linked to a single [Asset](link)"
- **API reference links:** Connect to API docs: "Manage via [API](link) or [Console](link)"
- **Next steps:** End guides with clear next steps

---

## Quality Checklist

- [ ] Leads with clear value statement
- [ ] Uses second person ("you")
- [ ] Uses present tense
- [ ] Headings are action-oriented (sentence case)
- [ ] Paragraphs are short (2-3 sentences)
- [ ] Includes working code examples
- [ ] Links to related documentation
- [ ] Ends with next steps
- [ ] Follows voice and tone guidelines

---

## Standards Loading (MANDATORY)

Before writing any functional documentation, MUST load relevant standards:

1. **Voice and Tone Guidelines** - Load `ring:voice-and-tone` skill
2. **Documentation Structure** - Load `ring:documentation-structure` skill
3. **Document Type Patterns** - Review patterns for specific document type (conceptual, how-to, tutorial)

**HARD GATE:** CANNOT proceed with functional documentation without loading these standards.

---

## Blocker Criteria - STOP and Report

| Condition | Decision | Action |
|-----------|----------|--------|
| Feature not implemented | STOP | Report: "Cannot document non-existent feature" |
| Feature behavior unclear | STOP | Report: "Need confirmed feature behavior" |
| Target audience undefined | STOP | Report: "Need audience definition for appropriate depth" |
| Prerequisite knowledge undefined | STOP | Report: "Need to know what readers should know first" |
| No working examples available | STOP | Report: "Need working examples to include" |

### Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST lead with clear value statement
- MUST use second person ("you")
- MUST use present tense for current behavior
- MUST include working code examples
- MUST end with clear next steps
- CANNOT use passive voice for actions
- CANNOT use title case for headings

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Missing core sections, incorrect information | No examples, wrong feature behavior described |
| **HIGH** | Missing value statement, no next steps | Reader doesn't know why they're reading or what to do next |
| **MEDIUM** | Voice/tone violations, structure issues | Third person, long paragraphs, title case |
| **LOW** | Minor clarity improvements | Could flow better, additional context helpful |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip examples, explain the concept" | "CANNOT skip examples. Examples make concepts concrete. I'll include working examples." |
| "We'll document later, feature is done" | "Documentation is part of the feature. CANNOT ship undocumented features. I'll write the docs now." |
| "Just a quick README overview" | "README is not functional documentation. MUST create proper guide with examples and next steps." |
| "Developers don't need handholding" | "Good documentation helps ALL developers. I'll write clear, complete guides." |
| "Copy from the design doc" | "Design docs are not user docs. MUST rewrite for user audience with examples." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Feature is intuitive, minimal docs needed" | Intuitive to you ≠ intuitive to users | **MUST write complete documentation** |
| "Design doc already explains this" | Design docs serve different audience | **Rewrite for user audience** |
| "Examples are extra work" | Examples are the most valuable part | **MUST include working examples** |
| "Users can figure out next steps" | Users shouldn't have to guess | **MUST include clear next steps** |
| "Quick overview is enough" | Overviews don't enable task completion | **Write task-oriented guides** |
| "Code comments are documentation" | Comments serve developers, not users | **Write separate user documentation** |

---

## When This Skill is Not Needed

Signs that functional documentation already meets standards:

- Document leads with clear value statement
- Consistently uses second person ("you")
- Uses present tense throughout
- Action-oriented headings in sentence case
- Short paragraphs (2-3 sentences max)
- Working code examples included
- Links to related documentation present
- Ends with clear next steps
- Follows voice and tone guidelines

**If all above are true:** Documentation is complete, no changes needed.
