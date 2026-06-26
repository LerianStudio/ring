---
name: ring:structuring-information
description: "Structuring a product's information architecture — navigation, grouping, labels, hierarchy — around the user's mental model, not the org chart or the database schema. Demands evidence (card sort / tree test / persona Level-3) for groupings, forbids internal-jargon labels and mirroring team structure, and caps nesting depth. Use when designing nav/IA, adding a section, or when 'users can't find X'. Skip for single-screen features with no navigation."
---

# Structuring Information

## Overview

Information architecture is how content and navigation are organized so people can find things and understand where they are. The recurring failure: structuring the product around *how the company is organized* (teams, database tables, internal terms) instead of *how the user thinks about the task*. This skill anchors IA to the user's mental model and demands evidence for the grouping.

## When to use

- Designing or revising navigation / menu / section structure
- Adding a new section and deciding where it lives
- "Users can't find X" / support tickets about navigation
- Labeling categories, tabs, menu items

## Skip when

- A single screen with no navigation/structure decisions
- Pure visual styling with the IA already settled

## Sequence

**Runs after:** ring:building-personas (Level-4 jobs + Level-3 mental model drive grouping)
**Related:** ring:critiquing-designs (navigation heuristics), ring:writing-ux-copy (label wording)

## Iron Law

```
ORGANIZE AROUND THE USER'S MENTAL MODEL, NOT THE ORG CHART OR THE SCHEMA. GROUPINGS NEED EVIDENCE.
```

If your nav mirrors your team structure or your database tables, you've optimized for the builder, not the user. A grouping you invented at your desk is a hypothesis — card sort / tree test / persona Level-3 turns it into a decision. Violating the letter (one "obvious" category nobody validated) is violating the spirit.

## Core pattern (before → after)

❌ **Before — mirrors internal structure & jargon**
> Nav: `Entities` · `Ledger Core` · `Postings` · `DDA Config` · `Webhooks`
> (These are database/domain-internal terms; grouped by which team owns them.)

✅ **After — mirrors the user's jobs & words**
> Nav: `Contas` · `Transações` · `Relatórios` · `Integrações` · `Configurações`
> (Grouped by what a finance operator comes to do; labeled in their vocabulary, validated by where they expected each task to live.)

## Principles

| Principle | Means |
|-----------|-------|
| **User mental model first** | Group by the user's tasks/concepts (persona L3/L4), not by team or table |
| **Labels in the user's words** | No internal jargon, no system/entity names; use the term the user already holds |
| **Shallow over deep** | Prefer breadth to deep nesting; aim ≤3 levels — every extra level loses people |
| **Mutually exclusive, clear categories** | A user should know which bucket a thing is in without guessing; avoid overlapping "misc" catch-alls |
| **Findability + wayfinding** | Search for big content; clear "you are here" (active state, breadcrumbs) so users never feel lost |
| **Consistency** | Same concept named the same everywhere (ties to ring:writing-ux-copy locked terms) |

## Methods to get evidence (pick by question)

- **Open card sort** — *what groups exist?* Users group items their way → reveals their mental model.
- **Closed card sort** — *do my proposed groups work?* Users sort items into your categories.
- **Tree test** — *can they find it?* Give a task, see if they navigate to the right place in the (label-only) structure.
- **Persona Level-3** — when you can't run a study, the mental model from ring:building-personas is your grounding (and you mark it as such).
- **Support tickets / search logs** — what users call things and what they fail to find.

No evidence at all → the IA is a `[hypothesis]`; label it and tree-test before committing.

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "Group it by which team owns it / by our modules" | Users don't know or care about your org chart; they think in tasks | Group by user job (persona L4); ownership is invisible to them |
| "Use the entity/table name, it's accurate" | Accurate to the system ≠ meaningful to the user | Label in the user's vocabulary (persona L3) |
| "It's a domain term, the B2B user surely knows it (portfolios, segments, postings)" | Often lazy research dressed up — you assumed it's their word without checking. Some domain terms ARE the user's word; you have to know which | Verify it's the *user's* term (persona L3 / ticket language); if unverified, mark the label `[hypothesis]` and name-test it |
| "It's obvious where this goes / I know this domain, no need to test" | Confident domain knowledge ≠ the user's mental model; "obvious" to the builder is where findability dies | Tree-test it, or ground in persona L3 and mark `[hypothesis]`; never label an intuitive grouping as if validated |
| "Just nest it under settings, 4 levels deep" | Each level sheds users; deep burial = invisible | Flatten; promote frequent tasks; ≤3 levels |
| "Add a 'More' / 'Misc' bucket for the leftovers" | Catch-alls hide things and signal you didn't model the space | Find the real category or split; no junk drawer |
| "Settings/General isn't called 'Misc' so it's fine to dump the leftovers there" | A section that's a catch-all *by function* is a junk drawer even without the name — it rots as you add more | Each item earns its section by a user job; if it only fits "the leftovers", you haven't modeled it |
| "Match the API resource names so it's consistent with code" | The code's structure is the schema, not the user's model | Decouple UI IA from API/schema naming |

## Red Flags — STOP

- Your navigation mirrors the team structure or the database schema.
- A label is an internal/entity/table name or jargon the user wouldn't say.
- Nesting goes deeper than ~3 levels for a common task.
- A "Misc"/"Other"/"More" catch-all — OR a Settings/General that has quietly become the dumping ground by function.
- Categories overlap so a user could reasonably look in two places.
- You grouped by intuition with zero evidence and no `[hypothesis]` label, or wrote group names as if validated when they're guesses.
- You kept a schema/entity term as a label claiming "it's a domain term" without verifying it's the user's word.
- No "you are here" (active state/breadcrumb) in a multi-level structure.

All of these mean: stop, re-group by the user's jobs/words (persona L3/L4 or a card sort), flatten the depth, kill the junk drawer, and tree-test before committing.

## Output

```markdown
# Information Architecture — {product/area}
**Date:** {YYYY-MM-DD} · **Grounding:** {card sort / tree test / persona L3 / [hypothesis]}

## Structure
- Top level: {Category} — {user job it serves} — label source: {persona term / validated}
  - Sub: {item} …
(≤3 levels; note depth)

## Labels (user's words)
| Shown to user | NOT (internal term) | Source |
|---------------|---------------------|--------|
| Transações | postings/entries | persona L3 |

## Findability
- Search: {where} · Wayfinding: {active state, breadcrumbs}

## Open questions to validate
- {grouping/label} → {card sort / tree test}
```

## Next step

Evidenced IA → hand to wireframes/nav implementation. `[hypothesis]` IA → tree-test the risky groupings before building. Label decisions → sync with ring:writing-ux-copy locked terms.
