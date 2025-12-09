---
name: writing-functional-docs
description: |
  Patterns and structure for writing functional documentation including guides,
  conceptual explanations, tutorials, and best practices documentation.

trigger: |
  - Writing a new guide or tutorial
  - Creating conceptual documentation
  - Documenting best practices
  - Writing "how to" content

skip_when: |
  - Writing API reference → use writing-api-docs
  - Reviewing documentation → use documentation-review
  - Writing code → use dev-team agents

sequence:
  before: [documentation-review]

related:
  similar: [writing-api-docs]
  complementary: [voice-and-tone, documentation-structure]
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

> ✅ Midaz uses a microservices architecture.
>
> ❌ Midaz will use a microservices architecture.

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
