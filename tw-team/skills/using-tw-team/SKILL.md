---
name: using-tw-team
description: |
  Technical writing specialists for functional and API documentation. Dispatch when
  you need to create guides, conceptual docs, or API references following established
  documentation standards.
metadata:
  related:
    similar:
    - ring:using-ring
    - ring:using-dev-team
  skip_when: |
    - Writing code → use dev-team agents
    - Writing plans → use pm-team agents
    - General code review → use default plugin reviewers
  trigger: |
    - Need to write functional documentation (guides, conceptual docs, tutorials)
    - Need to write API reference documentation
    - Need to review existing documentation quality
    - Writing or updating product documentation
---

# Using Ring Technical Writing Specialists

The ring-tw-team plugin provides specialized agents for technical documentation. Use them via `Task tool with subagent_type:`.

**Remember:** Follow the **ORCHESTRATOR principle** from `ring:using-ring`. Dispatch agents to handle documentation tasks; don't write complex documentation directly.

## 3 Documentation Specialists

| Agent | Specialization | Use When |
|-------|---------------|----------|
| `ring:functional-writer` | Conceptual docs, guides, tutorials, best practices, workflows | Writing product guides, tutorials, "how to" content |
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
| ring:using-ring (default) | ORCHESTRATOR principle |
| ring:using-dev-team | Developer agents for technical accuracy |
| ring:using-pm-team | Pre-dev planning before documentation |

---

## ORCHESTRATOR Principle

- **You're the orchestrator** – Dispatch specialists, don't write directly
- **Let specialists apply standards** – They know voice, tone, structure
- **Combine with other plugins** – API writers + backend engineers for accuracy

> ✅ "I need documentation for the new feature. Let me dispatch functional-writer."
>
> ❌ "I'll manually write all the documentation myself."

---

## Standards Loading (MANDATORY)

Before dispatching any documentation agent:

1. **Understand the documentation type** - Functional guide vs API reference
2. **Load relevant skills** - Writing patterns for the document type
3. **Verify prerequisites** - Product knowledge, terminology, audience

**HARD GATE:** MUST dispatch appropriate specialist (not write directly).

---

## Blocker Criteria - STOP and Report

| Condition | Decision | Action |
|-----------|----------|--------|
| Documentation type unclear | STOP | Report: "Need to clarify functional guide vs API reference" |
| No subject matter source | STOP | Report: "Need source material or SME access" |
| Audience undefined | STOP | Report: "Need target audience definition" |
| Product not yet defined | STOP | Report: "Cannot document undefined features" |

### Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST dispatch specialist agents (not write directly)
- MUST use appropriate agent for document type
- MUST follow ORCHESTRATOR principle
- CANNOT skip documentation review before publication
- CANNOT mix agent responsibilities

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Writing directly instead of dispatching | Orchestrator writes full documentation |
| **HIGH** | Wrong agent for document type | Using api-writer for conceptual guide |
| **MEDIUM** | Skipping review step | Publishing without docs-reviewer check |
| **LOW** | Suboptimal agent combination | Could parallelize dispatches |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just write the docs quickly, no need for specialists" | "MUST dispatch specialists. They apply consistent standards. I'll dispatch the appropriate agent." |
| "Skip the review, we're in a hurry" | "Documentation review is REQUIRED before publication. I'll dispatch docs-reviewer." |
| "One agent can do it all" | "Each agent has specialized knowledge. I'll dispatch the correct specialist for each document type." |
| "README is enough documentation" | "README is an entry point, not complete documentation. I'll dispatch agents for proper docs." |
| "Developers can figure it out from the code" | "Code is NOT documentation. MUST create proper documentation. I'll dispatch the appropriate writers." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Simple docs, I can write directly" | Simple ≠ no standards. Specialists ensure consistency | **MUST dispatch specialist** |
| "Faster to write myself" | Speed without quality creates tech debt | **Dispatch agents, ensure quality** |
| "Already know the product well" | Knowledge ≠ documentation skill | **Use specialists for writing** |
| "Review takes too long" | Review catches issues before users do | **MUST include review step** |
| "Documentation isn't critical path" | Documentation IS part of the feature | **Treat docs as required deliverable** |
| "Internal docs don't need standards" | Internal users deserve quality too | **Apply same standards everywhere** |

---

## When This Skill is Not Needed

Signs that documentation workflow is already correct:

- Appropriate specialist dispatched for each document type
- ORCHESTRATOR principle followed (not writing directly)
- Documentation review included in workflow
- Parallel dispatch used for efficiency
- Clear handoffs between agents

**If all above are true:** Workflow is correct, proceed with dispatches.
