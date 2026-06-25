---
name: ring:building-personas
description: "Building grounded user personas before design: a 5-level model (identity, behavior, mental model, jobs-to-be-done, synthetic profile) anchored in real research evidence, emitting personas.md. Keystone gate that feeds information architecture, UX writing, user flows, and synthetic-user simulation. Use when a feature needs personas or shared user understanding before design starts. Skip for backend-only/infra work with no human user, or when validated personas already exist."
---

# Building Personas

## Overview

Personas turn scattered research into a small set of decision-ready user archetypes. This skill builds them in a **5-level model** where each level is consumed by a downstream design dimension — so a persona is not a poster, it is a working input. Output is `personas.md`.

The keystone insight: a strong persona does not fix one dimension, it unlocks four. Level 3 (mental model) feeds Information Architecture + UX Writing; Level 4 (jobs-to-be-done) feeds User Flow + content hierarchy; Level 5 (synthetic profile) is the prerequisite for synthetic-user simulation.

## When to use

- Before User Flow / Wireframes / UX Writing on a feature that has human users
- When a team keeps designing for an undefined "the user"
- When research exists (interviews, tickets, analytics, sales notes) but isn't synthesized into archetypes
- User asks to "create personas", "define our users", or "who are we building for?"

## Skip when

- Backend-only, API-only, or pure-infra work with no human-facing surface
- Validated, current personas already exist (reuse them — update only if research changed)
- A throwaway spike where no design decisions hang on user understanding

## Sequence

**Runs after:** ring:researching-features (provides the evidence base)
**Runs before:** ring:mapping-feature-relationships, user-flow/wireframe work, UX writing, and any synthetic-user simulation

**Related:** ring:validating-ux-completeness (consumes personas downstream)

## Iron Law

```
NO PERSONA WITHOUT EVIDENCE. EVERY CLAIM CITES A SOURCE OR IS MARKED [ASSUMPTION].
```

A persona invented from intuition is worse than no persona — it launders a guess into a fact the whole team then designs around. If you have no research, your first job is to say so and either gather it (ring:researching-features) or label every field `[ASSUMPTION — needs validation]`. Violating the letter is violating the spirit: a "plausible" detail with no source is still fabricated.

## The 5-level model

Build each persona top-down. Each level has a downstream consumer — if a level is empty, name the dimension it leaves blind.

| Level | Captures | Feeds downstream | Anchor question |
|-------|----------|------------------|-----------------|
| **1 · Identity & context** | Role, segment, environment, constraints, scale they operate at | Scoping, prioritization | "Who are they and what's their day shaped by?" |
| **2 · Behavior & proficiency** | Tech fluency, frequency of use, tools they switch between, risk tolerance | Defaults, density, onboarding depth | "How fluent and how often — power user or occasional?" |
| **3 · Mental model** | Domain vocabulary, how they expect the system to work, what they conflate or fear | **Information Architecture + UX Writing** | "What words and cause→effect do they already hold?" |
| **4 · Jobs-to-be-done** | Functional/emotional/social jobs, triggers, definition of done, alternatives today | **User Flow + content hierarchy** | "What are they hiring this product to get done?" |
| **5 · Synthetic profile** | Machine-usable trait set: priorities, tolerances, decision heuristics, vocabulary, error reactions | **Synthetic-user simulation** | "Could an agent role-play this person consistently?" |

**Level 5 is the gate to synthetic users.** If you cannot write a profile concrete enough for an agent to answer "what would this person do here?", synthetic-user testing is blocked.

## Core pattern (before → after)

❌ **Before — a poster, not an input**
> *Camila, 34, gosta de tecnologia e quer praticidade. Usa o app no dia a dia.*
Decorative, unsourced, drives no decision. "Gosta de tecnologia" tells a designer nothing about defaults, copy, or flow.

✅ **After — a working input (excerpt, Level 3 + 4)**
> **Mental model (L3):** Pensa em "saldo" como dinheiro disponível agora, não distingue saldo de limite — fonte: 4/6 entrevistas confundiram os termos [E2,E3,E5,E6]. Espera que "enviar" seja irreversível e teme errar o destinatário.
> → *IA:* separar e rotular "Saldo disponível" vs "Limite". *UX Writing:* tela de revisão deve ecoar nome + chave, não jargão.
> **JTBD (L4):** "Quando preciso pagar alguém na hora, quero confirmar que vai pra pessoa certa, pra não perder dinheiro irreversível." Trigger: cobrança imediata. Done: comprovante com nome do recebedor. Alternativa hoje: liga pra confirmar a chave antes.
> → *User Flow:* passo de revisão não-pulável; *Hierarquia:* nome do recebedor é o elemento mais proeminente da revisão.

Every line either cites evidence or routes to a design decision.

## Process

0. **Read the research that already exists — first, before writing a word.** If interviews, tickets, analytics, or research docs exist, you MUST open and read them. Writing personas from memory while sources sit unopened is the single most common failure: it produces fiction with the confidence of research. "I know our users well enough" and "it's just for a deck" do not exempt you. If you cannot find the sources, search for them and ask where they are — do not proceed as if they don't exist.
1. **Gather the evidence base.** Pull from ring:researching-features output, interviews, support tickets, analytics, sales/CS notes. List your sources (with IDs) at the top of `personas.md`. No research at all? State it loudly, label the deliverable a **hypothesis set**, and mark every field `[ASSUMPTION]`.
2. **Cluster, don't average.** Group users by *distinct behavior and goals*, not demographics. 2–4 personas for most features; more than 5 means you're slicing too thin.
3. **Build each persona through the 5 levels.** Cite per claim. Where evidence is thin, write `[ASSUMPTION — needs validation]` rather than skipping.
4. **Add an anti-persona** (1) — who this is explicitly NOT for. Prevents scope creep.
5. **Route every Level 3/4/5 trait to its downstream dimension** (the `→` lines above). A persona with no routing is decoration.
6. **Cut decorative fields.** Age, photo, a "relatable" quote, personality color — exclude any field that does not change a design decision, no matter who asks for it ("execs like personas they can connect with" is not a reason). A field earns its place by routing to a decision or it does not appear.
7. **Tag confidence** per persona AND the deliverable overall: 🟢 evidence-backed · 🟡 mixed · 🔴 mostly assumption. A 🔴 persona is a *hypothesis*, not a finished persona — say so in the title and the summary. Never present assumption-heavy personas as "solid" or design-ready.

> **Note on Level 5:** the synthetic profile is the most tempting level to fabricate, because a simulation *needs* concrete traits (stop conditions, tolerances, heuristics) to run. Inventing them produces a simulation that role-plays your guesses and hands them back as "what users do" — a confirmation loop. L5 traits must be evidence-grounded or explicitly `[ASSUMPTION]`; a 🔴 L5 means synthetic-user output is hypothesis-only, never validation.

## Lerian context (Midaz Console)

Default product context unless told otherwise: **Midaz Console**, B2B financial platform (ledger, reconciliation, PIX/TED, multi-tenant). Ground personas in the three core archetypes and refine with real evidence:

- **Operador financeiro** — runs day-to-day money operations; high frequency, low error tolerance, lives in the Console.
- **Dev integrador** — wires the API/SDK into their own systems; cares about contracts, idempotency, observability.
- **Admin de plataforma** — manages tenants, permissions, limits; cares about control, audit, and isolation.

These are starting hypotheses, not finished personas — each still needs the 5 levels filled from evidence.

## Quick reference

| Do | Don't |
|----|-------|
| Cite a source per claim | Invent plausible-sounding details |
| Cluster by behavior + goals | Cluster by age/gender/demographics |
| Route L3/4/5 traits to dimensions | Write a persona that drives no decision |
| Mark gaps `[ASSUMPTION]` | Silently fill gaps with intuition |
| 2–4 personas + 1 anti-persona | A persona per micro-segment |
| Tag confidence (🟢🟡🔴) | Present assumptions as facts |

## Rationalization table

Excuses observed in baseline testing, and the required response:

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "PM needs them by EOD, no time for interviews" | Deadline justifies time-boxing, never fabricating-and-presenting-as-solid | Read existing research; mark gaps `[ASSUMPTION]`; label deliverable a hypothesis set; offer "3 hypotheses + 5 lightning interviews" instead |
| "We know our users well enough" | Tacit knowledge is unaudited and uneven across the team — that's what personas exist to fix | Open the sources anyway; cite per claim |
| "It's just for the stakeholder deck / keep it light" | A persona in a deck becomes the team's source of truth next sprint | Same rigor; if it's truly throwaway, don't call it a persona |
| "Execs like personas they can connect with emotionally" | Relatability is not a persona's job; decoration launders guesses | Cut age/photo/vibe; keep only decision-driving fields |
| "The thin personas are enough to start the simulation" | Unconstrained profiles make the sim improvise → non-comparable, non-repeatable | Flag the gap loudly; fill L5 from evidence or tag `[ASSUMPTION]`; treat output as hypotheses |
| "I'll just fill the gaps quietly so it looks complete" | A complete-looking fiction is more dangerous than an obvious gap | Make the gap visible; never silently invent |

## Red Flags — STOP

- Research exists and you didn't open it → you're about to write fiction. Read it first.
- A persona field has no citation and no `[ASSUMPTION]` tag → it's fabricated.
- The deliverable contains age, a photo/vibe, or a "relatable" quote that drives no decision → decoration, cut it.
- You clustered by demographics instead of behavior/jobs.
- Level 3, 4, or 5 is empty but you moved on → you've blinded IA/UX-writing, user-flow, or synthetic-users.
- A trait routes to no downstream design decision → it's decoration, cut or deepen it.
- You're presenting mostly-🔴 personas as "solid" or design-ready → relabel as hypotheses.
- You wrote 6+ personas → you're slicing segments, not finding archetypes.
- "It's just a demo / we know our users / no time" → that's exactly when fabricated personas ship. Read sources, mark assumptions, label status — don't skip.

All of these mean: stop, read the evidence that exists, ground each claim or tag it `[ASSUMPTION]`, cut decoration, and label the deliverable's confidence honestly.

## Output

`personas.md` (in the feature's pre-dev folder, e.g. `docs/pre-dev/{feature}/personas.md`):

```markdown
# Personas — {feature}

**Date:** {YYYY-MM-DD}
**Evidence base:** {interviews / tickets / analytics / sales notes — list sources & IDs}
**Personas:** {N} + 1 anti-persona

## Persona 1 — {short name} {🟢|🟡|🔴}
**One-liner:** {role + primary job in one sentence}

- **L1 · Identity & context:** … [source]
- **L2 · Behavior & proficiency:** … [source]
- **L3 · Mental model:** … [source] → *IA/UX-writing:* {decision}
- **L4 · Jobs-to-be-done:** "{job statement}" — trigger / done / alternative … [source] → *User flow/hierarchy:* {decision}
- **L5 · Synthetic profile:** priorities / tolerances / heuristics / vocabulary / error reactions → *Synthetic users:* {ready? yes/no}

## Persona 2 — … (same structure)

## Anti-persona — {who this is NOT for}
{why excluding them keeps scope honest}

## Coverage & gaps
| Persona | Confidence | Biggest assumption to validate |
|---------|-----------|--------------------------------|
| … | 🟢/🟡/🔴 | … |
```

## Next step

VALIDATED personas → proceed to user-flow / wireframe work and ring:mapping-feature-relationships.
🔴 confidence personas → return to ring:researching-features to close the biggest assumptions before relying on them.
