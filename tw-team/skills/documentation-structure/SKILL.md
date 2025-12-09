---
name: documentation-structure
description: |
  Patterns for organizing and structuring documentation including hierarchy,
  navigation, and information architecture.

trigger: |
  - Planning documentation structure
  - Organizing content hierarchy
  - Deciding how to split content across pages
  - Creating navigation patterns

skip_when: |
  - Writing content → use writing-functional-docs or writing-api-docs
  - Checking voice → use voice-and-tone

related:
  complementary: [writing-functional-docs, writing-api-docs]
---

# Documentation Structure

Good structure helps users find what they need quickly. Organize content by user tasks and mental models, not by internal system organization.

## Content Hierarchy

```
Documentation/
├── Welcome/              # Entry point, product overview
├── Getting Started/      # First steps, quick wins
├── Guides/              # Task-oriented documentation
│   ├── Understanding X   # Conceptual
│   ├── Use Cases        # Real-world scenarios
│   └── Best Practices   # Recommendations
├── API Reference/       # Technical reference
│   ├── Introduction     # API overview
│   └── Endpoints/       # Per-resource documentation
└── Updates/             # Changelog, versioning
```

---

## Page Structure Patterns

| Page Type | Structure |
|-----------|-----------|
| **Overview** | Brief description → "In this section you will find:" → Linked list of child pages |
| **Conceptual** | Lead paragraph → Key characteristics (bullets) → How it works → Subtopics with `---` dividers → Related concepts |
| **Task-Oriented** | Brief context → Prerequisites → Numbered steps → Verification → Next steps |

---

## Section Dividers

Use `---` between major sections for visual separation.

**When to use:**
- Between major topic changes
- Before "Related" or "Next steps" sections
- After introductory content
- Before prerequisites in guides

**Don't overuse:** Not every heading needs a divider.

---

## Navigation Patterns

| Pattern | Usage |
|---------|-------|
| Breadcrumb | Show hierarchy: `Guides > Core Entities > Accounts` |
| Prev/Next | Connect sequential content: `[Previous: Assets] \| [Next: Portfolios]` |
| On-this-page | For long pages, show section links at top |

---

## Information Density

**Scannable content:**
1. Lead with key point in each section
2. Use bullet points for 3+ items
3. Use tables for comparing options
4. Use headings every 2-3 paragraphs
5. Bold key terms on first use

**Progressive disclosure:**
- Essential info (80% of users need) first
- Advanced configuration in separate section
- Edge cases and rare scenarios last

---

## Tables vs Lists

**Use tables when:** Comparing items across same attributes, showing structured data (API fields), displaying options with consistent properties

**Use lists when:** Items don't have comparable attributes, sequence matters (steps), items have varying detail levels

---

## Code Examples Placement

| Type | When |
|------|------|
| Inline code | Short references: "Set the `assetCode` field..." |
| Code blocks | Complete, runnable examples |

**Rules:**
1. Show example immediately after explaining it
2. Keep examples minimal but complete
3. Use realistic data (not "foo", "bar")
4. Show both request and response for API docs

---

## Cross-Linking Strategy

- **Link first mention** of a concept in each section
- **Don't over-link** – once per section is enough
- **Link destinations:** Concept → conceptual docs, API action → endpoint, "Learn more" → deeper dive

---

## Page Length Guidelines

| Page Type | Target | Reasoning |
|-----------|--------|-----------|
| Overview | 1-2 screens | Quick orientation |
| Concept | 2-4 screens | Thorough explanation |
| How-to | 1-3 screens | Task completion |
| API endpoint | 2-3 screens | Complete reference |
| Best practices | 3-5 screens | Multiple recommendations |

If >5 screens, consider splitting.

---

## Quality Checklist

- [ ] Content organized by user task, not system structure
- [ ] Overview pages link to all child content
- [ ] Section dividers separate major topics
- [ ] Headings create scannable structure
- [ ] Tables used for comparable items
- [ ] Code examples follow explanations
- [ ] Cross-links connect related content
- [ ] Page length appropriate for type
- [ ] Navigation connects sequential content
