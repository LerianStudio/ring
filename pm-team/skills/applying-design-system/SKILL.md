---
name: ring:applying-design-system
description: "Applying and enforcing the Lerian Console design system in product-design and frontend work: the locked decisions (Geist not Inter, two-layer HSL tokens, 375/768/1280 viewports + 1400px cap, custom theme provider with light default), a sweep mode that flags violations, and a biweekly design-QA checklist. Use when designing/implementing/reviewing any Console UI or token/theme/typography choice. Skip for non-Console surfaces or backend work."
---

# Applying the Design System (Lerian Console)

## Overview

The Lerian Console design system has **locked decisions** (ratified 2026-04-22) that override the generic shadcn/Tailwind defaults the Ring docs inherited. This skill makes those decisions enforceable: it states them, gives a sweep mode to catch violations in existing code/designs, and provides the biweekly design-QA checklist. The product is the source of truth where it diverges from stale doc defaults — these decisions encode *which* side wins per case.

## When to use

- Designing or implementing any Console screen/component
- Choosing or reviewing typography, color tokens, theming, or breakpoints
- Reviewing a PR/design for design-system compliance
- Running the periodic design-QA pass

## Skip when

- Non-Console product surface with its own DS
- Backend / API / infra work with no UI
- A throwaway prototype not intended to match the Console

## Locked decisions (do not re-litigate)

| # | Area | Decision | What the generic default got wrong |
|---|------|----------|-------------------------------------|
| 1 | **Typography** | **Geist** is the font for Console AND `sindarian-ui`. **Inter is banned.** | Inter = generic AI/SaaS aesthetic; Geist is purpose-built for dense financial UIs (tabular numerals, small-size legibility) |
| 2 | **CSS variables** | **Two layers:** raw HSL value (`--body-surface: 240 5% 96%`) + Tailwind wrapper (`--color-body-surface: hsl(var(--body-surface))`). Token names mirror Figma. | shadcn single-layer (`--color-primary: 220 90% 56%`) blocks `hsl(var(--x) / alpha)` opacity needed for dark mode + states |
| 3 | **Breakpoints / viewports** | Reference + test viewports: **375 (mobile) / 768 (tablet) / 1280 (desktop)**. Container cap **1400px**. Playwright must snapshot all three. | Tailwind defaults are fine, but untested mobile/tablet = unverified responsiveness |
| 4 | **Dark mode** | **Custom theme provider** (NOT `next-themes`), class-based `.dark`, **default `light`**. Provider supports **accent color per tenant**. | `next-themes` + `defaultTheme:"system"` can't do per-tenant accent and makes demo≠prod |

**These are settled.** "The Ring frontend.md says otherwise" is not a reason to revert — the doc is being updated to match these; the decisions win.

## Sweep mode — violations to flag

Scan code/design for these and report file:line:

- **Inter anywhere** (❌ critical) — `next/font/google` importing Inter, `--font-inter`, `Inter` in a font stack (Console `layout.tsx` or `sindarian-ui`). → must be Geist.
- **No affirmative Geist** (⚠️ partial) — a generic `system-ui`/`sans-serif` stack with no Inter *but also no Geist*. Weaker than an Inter violation, but the surface still must use Geist. → wire Geist.
- **Single-layer color tokens** — a `--color-*` defined with a raw value directly (instead of wrapping a raw `--token`), **OR raw hex/hsl in `tailwind.config` `theme.extend.colors`** (same violation, different file). → must be two-layer.
- **Hardcoded hex/hsl in components** — colors not referencing a token. → use the token. *(Raw values living ONLY in the token definitions are correct — that's the single source; flag duplication in components, not the definitions.)*
- **`next-themes`** import or `defaultTheme="system"` / `defaultTheme="dark"`. → custom provider, default `light`.
- **Playwright config** missing the exact **375 / 768 / 1280** viewports — `320`/`390` "close enough" approximations count as violations — or no mobile/tablet snapshots. → use exactly 375/768/1280.
- **Container** without the 1400px cap on wide screens.
- **Off-scale spacing/size** — a `[…]` arbitrary value used for *spacing off the scale* (`mt-[13px]`). NOT every bracket value: a deliberate width like `max-w-[480px]` is fine.

**Rate each finding** `critical` / `major` / `minor` (reuse the Design-QA severity vocabulary below): Inter = critical; single-layer tokens / `next-themes` = major; viewport/cap/off-scale spacing = minor→major by impact.

## Design QA checklist (biweekly, sprint-close)

**Visual consistency:** tokens match Figma · typography (Geist, sizes, weights) consistent · spacing on-scale (no arbitrary values) · icons consistent (lucide, standard sizes).
**Responsiveness:** works at 375px · works at 768px · stable at 1280px+ · container ≤ 1400px on wide screens.
**Dark mode:** every new screen has a correct dark variant · WCAG AA contrast in light AND dark · no hardcoded colors that break in dark.
**UI states:** loading on async ops · informative empty states (not just "sem dados") · error states cover real failures · disabled visually distinct.
**UX/nav:** main flows work end-to-end · breadcrumbs/nav consistent · visual feedback for destructive/important actions · forms with clear validation.
**Visual bugs:** no text overflow · no unexpected overlap · no needless horizontal scroll · no FOUC/flicker on load.

Output: short doc with screenshots, severity (`critical`/`major`/`minor`), and suggested fix/owner.

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "Ring's frontend.md shows Inter / single-layer tokens / next-themes" | That doc inherited shadcn defaults un-reviewed; the 2026-04-22 decisions supersede it | Follow the locked decision; the doc is being corrected |
| "The no-Inter rule is for marketing/landing, not a data-dense dashboard" | Backwards — Geist was chosen *specifically* for the financial dashboard (tabular numerals, small-size legibility on dense tables). The decision is dashboard-aware, not a generic marketing rule | Use Geist; the dashboard context is exactly why |
| "Inter is fine, it's readable / great for dashboards" | Readability isn't the point — it's generic identity, and the call was made for this product | Use Geist |
| "I'm just consuming the existing --font-sans, not changing the font" | Building a new surface on Inter cements it and grows the migration; propagating the violation is still the violation | Don't ship new UI on Inter; consume the Geist token (or block on the migration) |
| "I'll just hardcode this one color / px value" | One arbitrary value becomes the crack that spreads; breaks dark mode + traceability | Reference a token / use the scale |
| "Only tested desktop, it probably works on mobile" | Untested responsiveness is unverified; that's the whole gap the viewports fix | Snapshot exactly 375/768/1280 |
| "320 / 390 / 640 are close enough viewports" | "Close" baselines drift from the locked set and from Figma; the standard is exact | Use exactly 375, 768, 1280 — not approximations |
| "next-themes is the standard, let's use it" | It can't do per-tenant accent — a real product requirement. You WILL hit a dark-mode bug where the tenant accent is ignored | Custom provider, class-based `.dark`, default light |
| "Changing the font is too much work right now" | True (it touches sindarian-ui) — but that's a coordination task with the frontend owner, not a reason to keep or extend Inter | Plan the Geist migration; don't add new Inter |

## Red Flags — STOP

- You're about to add, keep, OR build a new surface on **Inter** ("just consuming the token" still counts).
- You're justifying Inter with "the rule is for marketing, not dashboards" — the Geist call was made *for* the dashboard.
- A color token is **single-layer**, or a component has a **hardcoded hex/hsl**.
- You reached for **`next-themes`** or set default theme to `system`/`dark` (and per-tenant accent will silently break in dark mode).
- A design/PR ships without checking **exactly 375 / 768 / 1280** (not 320/390 approximations).
- You're treating the Ring `frontend.md` generic example as authoritative over these locked decisions.
- Arbitrary spacing/size values instead of the scale.

All of these mean: stop, apply the locked decision (Geist · two-layer tokens · 3 viewports + 1400 cap · custom provider/light), and reference tokens instead of hardcoding.

## Cross-repo note

Typography (decision 1) touches `sindarian-ui` (shared package) → coordinate with the frontend owner (Drax) before executing the Geist migration; don't do it piecemeal. Decisions 2 and 4 are doc updates to the Ring `frontend.md`; decision 3 is a Playwright config + baseline-snapshot task. The structural home for injecting these into Ring agents is `PROJECT_RULES.md` (the single entry point) — if it doesn't exist for the Console yet, creating it is the upstream unblocker.

## Output

A compliance note or design-QA report:

```markdown
# Design System Check — {screen/PR/feature}
**Date:** {YYYY-MM-DD}

| Decision | Status | Evidence (file:line) | Fix |
|----------|--------|----------------------|-----|
| Geist (no Inter) | ✅/❌ | … | … |
| Two-layer tokens | ✅/❌ | … | … |
| Viewports 375/768/1280 + 1400 cap | ✅/⚠️/❌ | … | … |
| Custom provider, default light | ✅/❌ | … | … |

## Violations (severity)
- [critical/major/minor] {what} @ {file:line} → {fix}
```

## Next step

Compliant → ship. Violations → fix per the locked decision. Font migration → coordinate with frontend owner. Missing `PROJECT_RULES.md` → flag as the upstream task that lets Ring agents enforce this automatically.
