---
name: using-tw-team
description: |
  Technical writing specialists for functional and API documentation. Dispatch when
  you need to create guides, conceptual docs, or API references following established
  documentation standards.

trigger: |
  - Need to write functional documentation (guides, conceptual docs, tutorials)
  - Need to write API reference documentation
  - Need to review existing documentation quality
  - Writing or updating product documentation

skip_when: |
  - Writing code → use dev-team agents
  - Writing plans → use pm-team agents
  - General code review → use default plugin reviewers

related:
  similar: [using-ring, using-dev-team]
---

# Using Ring Technical Writing Specialists

The ring-tw-team plugin provides specialized agents for technical documentation. Use them via `Task tool with subagent_type:`.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch agents to handle documentation tasks; don't write complex documentation directly.

## 3 Documentation Specialists

| Agent | Specialization | Use When |
|-------|---------------|----------|
| `functional-writer` | Conceptual docs, guides, tutorials, best practices, workflows | Writing product guides, tutorials, "how to" content |
| `api-writer` | REST API reference, endpoints, schemas, errors, field descriptions | Documenting API endpoints, request/response examples |
| `docs-reviewer` | Voice/tone, structure, completeness, clarity, accuracy | Reviewing drafts, pre-publication quality check |

---

## Documentation Standards Summary

### Voice and Tone
- **Assertive, but never arrogant** – Say what needs to be said, clearly
- **Encouraging and empowering** – Guide users through complexity
- **Tech-savvy, but human** – Use technical terms when needed, prioritize clarity
- **Humble and open** – Confident but always learning

### Capitalization
- **Sentence case** for all headings and titles
- Only first letter and proper nouns capitalized
- ✅ "Getting started with the API"
- ❌ "Getting Started With The API"

### Structure Patterns
1. Lead with clear definition paragraph
2. Use bullet points for key characteristics
3. Separate sections with `---` dividers
4. Include info boxes and warnings where needed
5. Link to related API reference
6. Add code examples for technical topics

---

## Dispatching Specialists

**Parallel dispatch** for comprehensive documentation (single message, multiple Tasks):

```
Task #1: functional-writer (write the guide)
Task #2: api-writer (write API reference)
(Both run in parallel)

Then:
Task #3: docs-reviewer (review both)
```

---

## Available in This Plugin

**Agents:** functional-writer, api-writer, docs-reviewer

**Skills:**
- using-tw-team: Plugin introduction
- writing-functional-docs: Functional doc patterns
- writing-api-docs: API reference patterns
- documentation-structure: Hierarchy and organization
- voice-and-tone: Voice guidelines
- documentation-review: Quality checklist
- api-field-descriptions: Field description patterns

**Commands:**
- /write-guide: Start functional guide
- /write-api: Start API documentation
- /review-docs: Review existing docs

---

## Integration with Other Plugins

| Plugin | Use For |
|--------|---------|
| using-ring (default) | ORCHESTRATOR principle |
| using-dev-team | Developer agents for technical accuracy |
| using-pm-team | Pre-dev planning before documentation |

---

## ORCHESTRATOR Principle

- **You're the orchestrator** – Dispatch specialists, don't write directly
- **Let specialists apply standards** – They know voice, tone, structure
- **Combine with other plugins** – API writers + backend engineers for accuracy

> ✅ "I need documentation for the new feature. Let me dispatch functional-writer."
>
> ❌ "I'll manually write all the documentation myself."
