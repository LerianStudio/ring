---
name: ring:writing-ux-copy
description: "Writing in-product UI microcopy — buttons, labels, placeholders, helper text, empty/loading/error/success states, and confirmations — for the Midaz Console and other fintech B2B surfaces. Anchors copy in the persona's vocabulary (mental model), enforces clarity-over-cleverness, and gives actionable error/confirmation patterns for irreversible money actions. Use when designing or reviewing any text a user reads inside the product. NOT for technical documentation voice — that's ring:applying-voice-and-tone."
---

# Writing UX Copy

## Overview

UX copy is the text a user reads *while using the product* — button labels, field labels, placeholders, helper text, empty states, error/success/loading messages, confirmations, tooltips. It is interface, not documentation. This skill produces copy that is clear, consistent with the user's vocabulary, and — in a fintech context where money moves and actions are irreversible — precise about what will happen.

**This is NOT `ring:applying-voice-and-tone`.** That skill governs *technical documentation* (guides, references) — long-form, explanatory, author voice. UX copy is short, in-context, action-oriented, and read mid-task by someone trying to get something done. Using the doc-voice skill for UI microcopy is the exact mismapping this skill exists to correct. If you're writing a sentence the user reads inside a screen, use this; if you're writing a paragraph in a guide, use that.

## When to use

- Writing or reviewing any in-product string: CTAs, labels, placeholders, helper/error/empty/success text, confirmations, toasts, tooltips
- A screen has lorem ipsum, "TODO copy", or engineer-placeholder text
- Error messages say "something went wrong" or expose stack traces / codes to users
- Reviewing a wireframe/implementation for copy quality before handoff or ship

## Skip when

- Writing technical documentation, guides, or API references → ring:applying-voice-and-tone
- Naming code symbols, variables, log messages (developer-facing, not user-facing)
- Marketing/landing copy (different goal: persuasion, not task completion)

## Sequence

**Runs after:** ring:building-personas (Level 3 mental model = the vocabulary you must match)
**Runs alongside:** wireframe / UI implementation work
**Related:** ring:applying-voice-and-tone (sibling — technical docs, not UI)

## Iron Law

```
USE THE USER'S WORDS. EVERY STRING IS CLEAR BEFORE IT IS CLEVER.
```

Copy that's witty but ambiguous, or "branded" but introduces a term the user doesn't hold, fails — especially when money is involved. If the persona's Level 3 mental model says they call it "saldo disponível", you do not rename it "available funds" or "limite" to sound consistent with something else. When clarity and personality conflict, clarity wins, every time. Violating the letter (sneaking in jargon or cleverness "just here") is violating the spirit.

## Voice (Lerian)

Assertive but not arrogant · encouraging · tech-savvy but human. In pt-BR by default for the Console. **Sentence case** for labels, buttons, and headings (only first letter + proper nouns capitalized). Address the user directly (você). Active voice. Short.

Personality lives in *empty states, success moments, and onboarding* — never in error messages, confirmations, or anything money-critical, where it reads as flippant.

## Core pattern (before → after)

❌ **Before — engineer/doc voice, vague, scary**
> Error: transaction failed (code 4471). Insufficient funds.
> [ Button: Submit ]
> Empty: No data available.

✅ **After — UI microcopy, in the user's words, actionable**
> **Error:** Saldo insuficiente para este Pix. Você tem R$ 2.450,00 disponível. → *Ajustar valor* / *Adicionar dinheiro*
> **Button:** Enviar R$ 150,00  *(the CTA states the consequence, not a generic verb)*
> **Empty:** Você ainda não enviou nenhum Pix. Quando enviar, eles aparecem aqui.

Every fix: the user's term ("saldo", "Pix"), the concrete fact (the amount), and a next action.

## Microcopy patterns by element

| Element | Rule | Example (pt-BR) |
|---------|------|-----------------|
| **Button / CTA** | Verb + object; state the consequence for committing/irreversible actions | `Enviar R$ 150,00` not `Confirmar` / `Submit` |
| **Label** | The user's noun, sentence case, no colon-jargon | `Chave Pix do destinatário` |
| **Placeholder** | Example of the input, never the label repeated | `nome@email.com` not `Digite o e-mail` |
| **Helper text** | One line, what they need to proceed or a constraint | `Você tem R$ 2.450,00 disponível` |
| **Empty state** | Why it's empty + how to fill it (1 action) | `Nenhum destinatário recente. Adicione uma chave Pix acima.` |
| **Loading** | What's happening, present tense | `Procurando destinatário…` |
| **Error** | What happened + (why) + how to fix; never a code or "algo deu errado" | `Não encontramos essa chave Pix. Confira e tente de novo.` |
| **Success** | Confirm the outcome with the concrete fact | `Pix de R$ 150,00 enviado para Maria S.` |
| **Confirmation (irreversible)** | Name the exact consequence + the specific values; no "Tem certeza?" | `Enviar R$ 150,00 para Maria agora? O Pix é imediato e não pode ser desfeito.` |

## Fintech rules (money is on the line)

1. **Terminology consistency = trust.** Pick one term per concept — *including the verb for the core action* (decide "enviar" XOR "transferir" and use it everywhere: button, loading, empty, success). Never vary it because it "sounds more natural"; varying a money verb erodes trust. Distinguish concepts the user conflates (saldo ≠ limite) explicitly — straight from persona Level 3. Lock these terms in a glossary at the top of the spec.
2. **Numbers are exact and formatted pt-BR.** `R$ 1.234,56`, never `R$1234.56`. State the actual amount in CTAs and confirmations, not "this amount".
3. **Irreversibility is stated, not implied.** Anything that moves money or can't be undone says so in plain words at the confirm step.
4. **Errors blame the situation, not the user.** "Não encontramos essa chave" not "Você digitou errado". Always give the fix.
5. **No leaked internals.** No error codes, stack traces, enum values, or English fallbacks in a pt-BR surface. (A code may go to logs and to a discreet support reference, never as the whole message.)
6. **Don't be cute where it costs.** Personality is banned in errors, confirmations, limits, and anything financial-critical. It is *welcome* in empty states, success, and onboarding — use it there rather than going sober everywhere.
7. **Never assert a system behavior you haven't verified.** Reassurances like "Nenhum valor foi debitado" or "não pode ser cancelada" are *claims about what the system did* — if the backend can debit-then-timeout, that copy is a dangerous lie. Only write such a guarantee if engineering confirms it's always true; otherwise hedge truthfully ("Não confirmamos se a transferência foi enviada — atualize para verificar antes de tentar de novo") and flag it as a copy↔system contract to verify.
8. **Even the catch-all is actionable.** An unmapped-error fallback must STILL say what's safe and what to do next — never bare "algo deu errado". Sanctioned pattern: `Não foi possível concluir {ação} agora. {Garantia verificada, se houver.} Tente novamente em instantes. Se continuar, fale com o suporte e informe o código {ID}.` The bare phrase alone is always a Red Flag, fallback or not.

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "Just use the field name as the placeholder" | Placeholder repeating the label is wasted space and hurts a11y | Show an example value, or omit |
| "'Algo deu errado' is friendlier than the detail" | Friendly + useless = the user is stuck and anxious about money | Say what happened + the fix; keep the code in logs |
| "Let's make the empty state fun/quirky" | Fun is fine here ONLY if it still says how to fill it | Personality + a clear next action, both |
| "Use 'Submit'/'Confirmar' — it's the standard button" | Generic verbs hide the consequence of a money action | State the action + amount: `Enviar R$ 150,00` |
| "I'll rename it to match our other screen's term" | Renaming the user's concept breaks their mental model | Use the persona's L3 word, even if inconsistent with internal naming |
| "It's just placeholder copy, real copy comes later" | Placeholder copy ships; lorem/TODO reaches users | Write the real string now, or mark it a blocking gap |
| "This is the product UI — voice-and-tone skill covers it" | That skill is for docs; applying it gives long author-voice prose | Use this skill's short, in-context patterns |
| "I won't map every error code, so I need a generic 'algo deu errado' net" | A net is fine; a *bare* generic message strands the user | Use the sanctioned fallback (fintech rule 8): still actionable + support code |
| "Varying enviar/transferir sounds more natural" | Two words for one money action reads as two different things | Lock ONE action verb in the glossary; use it everywhere |
| "'Nenhum valor foi debitado' reassures the user, so write it" | If unverified, it's a lie that compounds the failure | Only assert it if engineering confirms; else hedge truthfully (rule 7) |
| "I'll write from memory — no time to check existing copy" | Drifts from the product's locked terms and voice | Check existing strings/glossary first; match, don't reinvent |

## Red Flags — STOP

- A string says "algo deu errado" / "something went wrong" *alone* / shows a raw code or stack trace to the user (even as a fallback — use rule 8's actionable pattern).
- A CTA on a money action is a generic verb (`Confirmar`, `Submit`, `OK`) instead of stating the action + amount.
- The same concept — or the core action verb (enviar vs transferir) — is named two different ways across screens.
- Copy asserts a system guarantee ("nenhum valor foi debitado", "não pode ser cancelada") that engineering hasn't confirmed is always true.
- You wrote from memory without checking the product's existing strings/glossary first.
- An irreversible action's confirm doesn't say it's irreversible.
- A placeholder just repeats the label; helper text is a paragraph.
- English/dev fallbacks or untranslated strings on a pt-BR surface.
- You reached for ring:applying-voice-and-tone to write a button or error → wrong skill.
- Personality/jokes in an error, limit, or confirmation.

All of these mean: stop, use the user's exact word, state the concrete consequence, give the next action, and keep cleverness out of money-critical text.

## Output

A copy spec the engineer implements verbatim — inline in the wireframe/ux-criteria, or `ux-copy.md`:

```markdown
# UX Copy — {screen/feature}

**Voice:** assertive, human, sentence case, pt-BR · **Terminology:** {locked terms — e.g. "saldo disponível", "Pix", "destinatário"}

| Element | State | String (pt-BR) | Notes / source |
|---------|-------|----------------|----------------|
| CTA | default | `Enviar R$ 150,00` | states amount [persona L4: confirm consequence] |
| Saldo label | — | `Saldo disponível` | locked term, ≠ limite [persona L3] |
| Error | not-found | `Não encontramos essa chave Pix. Confira e tente de novo.` | no code; gives fix |
| Empty | no recents | `Nenhum destinatário recente. Adicione uma chave acima.` | why + action |
| Confirm | irreversible | `Enviar R$ 150,00 para Maria agora? O Pix é imediato e não pode ser desfeito.` | states irreversibility |
| … | | | |

## Open terminology decisions
- {any concept where the user's word isn't yet confirmed → flag for persona/research}
```

## Next step

Copy spec done → hand to UI implementation; feed locked terminology back into the design system / component labels for consistency. Unknown user vocabulary → return to ring:building-personas (Level 3) or research.
