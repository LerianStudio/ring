---
name: ring:using-tw-team
description: "Using the ring-tw-team plugin and orchestrating its documentation specialists in parallel: guide-writer (guides/concepts/tutorials), api-writer (REST API reference), and docs-reviewer (quality review). Use when creating functional or API documentation, or reviewing doc quality. Skip when writing code (use dev-team) or writing plans (use pm-team)."
---

# Using Ring Technical Writing Specialists

## When to use
- Need to write functional documentation (guides, conceptual docs, tutorials)
- Need to write API reference documentation
- Need to review existing documentation quality
- Writing or updating product documentation

## Skip when
- Writing code → use dev-team agents
- Writing plans → use pm-team agents
- General code review → use `ring:reviewing-code` with dev-team reviewer agents

## Related
**Similar:** ring:using-ring, ring:using-dev-team

The ring-tw-team plugin provides specialized agents for technical documentation. Use them via `Task tool with subagent_type:`.

**Remember:** Follow the **ORCHESTRATOR principle** from `ring:using-ring`. Dispatch agents to handle documentation tasks; don't write complex documentation directly.

## 3 Documentation Specialists

| Agent | Specialization | Use When |
|-------|---------------|----------|
| `ring:guide-writer` | Conceptual docs, guides, tutorials, best practices, workflows | Writing product guides, tutorials, "how to" content |
| `ring:api-writer` | REST API reference, endpoints, schemas, errors, field descriptions | Documenting API endpoints, request/response examples |
| `ring:docs-reviewer` | Voice/tone, structure, completeness, clarity, accuracy | Reviewing drafts, pre-publication quality check |

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

**Parallel dispatch** for comprehensive documentation (single turn, multiple Tasks):

```
Task #1: guide-writer (write the guide)
Task #2: api-writer (write API reference)
(Both run in parallel)

Then:
Task #3: docs-reviewer (review both)
```

### ⛔ MUST NOT trickle-dispatch

Tasks #1 and #2 leave in the SAME TURN, before reading either's output. Forbidden: dispatch #1 → read result → dispatch #2. If you find yourself about to dispatch #2 in a turn AFTER #1 has already returned → STOP, report the violation, and re-dispatch both together. Task #3 runs only after both #1 and #2 complete — that sequencing is intentional; the trickle inside the parallel pair is not.

### Parallel dispatch — atomic batch

Emit both Task calls in a SINGLE TURN as one atomic batch. If your runtime exposes a `multi_tool_use.parallel` wrapper, use it. The anti-trickle guard above remains binding.

---

## Available in This Plugin

**Agents:** guide-writer, api-writer, docs-reviewer

**Skills:**
- using-tw-team: Plugin introduction
- structuring-documentation: Hierarchy and organization
- applying-voice-and-tone: Voice guidelines
- reviewing-docs: Quality checklist

**Commands:**
- /ring:reviewing-docs: Review existing docs

---

## Integration with Other Plugins

| Plugin | Use For |
|--------|---------|
| ring:using-ring (default) | ORCHESTRATOR principle |
| ring:using-dev-team | Developer agents for technical accuracy |
| ring:using-pm-team | Pre-dev planning before documentation |

---

## ORCHESTRATOR Principle

- **You're the orchestrator** – Dispatch specialists, don't write directly
- **Let specialists apply standards** – They know voice, tone, structure
- **Combine with other plugins** – API writers + backend engineers for accuracy

> ✅ "I need documentation for the new feature. Let me dispatch guide-writer."
>
> ❌ "I'll manually write all the documentation myself."

---
