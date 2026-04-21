# Slide Archetypes

Nine archetypes cover the Lerian editorial deck vocabulary. Each is a self-contained `<section>` pattern. The scaffolded `deck.html` includes one example of each as a starter kit.

**MUST read [layout-rules.md](layout-rules.md) and [design-tokens.md](design-tokens.md) before composing slides.** These archetypes compose primitives from [ui-primitives.md](ui-primitives.md) and charts from [chart-primitives.md](chart-primitives.md).

**Canonicity:** when the distilled `../templates/slide-*.html` file differs from the reference deck (`lerian-ppt-example.html`), the template file is canonical. Reference-deck line ranges are cited to show real usage in the wild; templates represent the minimum viable pattern.

---

## Archetype Selection Decision Tree

```
Opening the deck?                     → cover
Showing the agenda?                   → agenda
Major section break?                  → act-divider   (Amarelo, sparingly)
Standard content slide on white?      → content
Same content on paper background?     → content-paper (visual pacing)
Hero statement + supporting metrics?  → content-dark
Big declarative statement?            → content-accent (Amarelo, sparingly)
Transitioning into appendix?          → appendix-intro
Appendix reference material?          → appendix-content
```

## Table of Contents

| # | Archetype | Typical use | File |
| --- | --- | --- | --- |
| 1 | [cover](#cover) | Deck opening: wordmark + title + roster | [`../templates/slide-cover.html`](../templates/slide-cover.html) |
| 2 | [agenda](#agenda) | Slide 2: Act x Theme x Time x Format table | [`../templates/slide-agenda.html`](../templates/slide-agenda.html) |
| 3 | [act-divider](#act-divider) | Amarelo section break with giant act number | [`../templates/slide-act-divider.html`](../templates/slide-act-divider.html) |
| 4 | [content](#content) | Default white workhorse: eyebrow + h1 + grid | [`../templates/slide-content.html`](../templates/slide-content.html) |
| 5 | [content-paper](#content-paper) | Paper (#F2F2F2) variant — strategic discussions | [`../templates/slide-content-paper.html`](../templates/slide-content-paper.html) |
| 6 | [content-dark](#content-dark) | Near-black statement + KPI strip | [`../templates/slide-content-dark.html`](../templates/slide-content-dark.html) |
| 7 | [content-accent](#content-accent) | Amarelo full-slide declaration | [`../templates/slide-content-accent.html`](../templates/slide-content-accent.html) |
| 8 | [appendix-intro](#appendix-intro) | Amarelo transition into appendix | [`../templates/slide-appendix-intro.html`](../templates/slide-appendix-intro.html) |
| 9 | [appendix-content](#appendix-content) | Letter-paginated reference cards | [`../templates/slide-appendix-content.html`](../templates/slide-appendix-content.html) |

---

## Editorial Discipline

### Use Amarelo sparingly

`.slide.accent` and `.slide.act-divider` both paint the full canvas Amarelo. In a 20-slide deck, **max 2–3 Amarelo slides total** — act dividers plus at most one `content-accent` moment plus the `appendix-intro`. Overuse fatigues the eye; the accent only pops when used rarely.

Per `ui-primitives.md`, `table.grid` is FORBIDDEN on `.slide.accent` (Amarelo bg eats the hairlines) and charts MUST NOT sit on Amarelo backgrounds. If the content needs either, pick `content` or `content-dark`.

### Pagination convention

Three numbering systems run in parallel:

| Range | Format | Example | Runtime behavior |
| --- | --- | --- | --- |
| Main deck | `NN / NN` numeric | `04 / 17` | `deck-stage.js` fills `.page-num` + `.page-total` spans |
| Main deck companion | `NNb / NN` letter-suffix | `09b / 14` | Static — runtime does NOT overwrite. Hard-coded in HTML. |
| Appendix | `AN / N` letter | `A1 / 8` | Static — runtime does NOT overwrite. Hard-coded in HTML. |

**MUST NOT hardcode main-deck numeric pagination.** `.page-num` and `.page-total` spans stay empty in the source; runtime populates them.
**MUST hardcode main-deck companion pagination.** Place `<span class="num">09b / 14</span>` in `meta.right` WITHOUT the `.page-num` class so the runtime leaves it alone. This is a deliberate exception to the dynamic-pagination HARD GATE in [`layout-rules.md`](layout-rules.md#dynamic-pagination).
**MUST hardcode appendix letter pagination.** Place `<span>A1 / 8</span>` in `meta.right` without the `.page-num` class so the runtime leaves it alone.

### Decimal / companion pagination

When a slide is a "zoom-in" follow-on that belongs to the same topic as its predecessor, use a **letter suffix** on the predecessor's slot instead of bumping to a new one: `09 / 14` → `09b / 14`. The main-deck total stays `14` — the companion is *detail*, not a new topic.

**Rules:**

- **Letter suffix signals companion detail.** The audience reads `09b` and understands "this is 09 zoomed in," not "we've added a new section."
- **Use sparingly.** One companion per host slide (`09` + `09b`). If you need a second companion, either the topic is big enough for its own slot (promote to `10`) or the companions belong in the appendix.
- **Total count is unchanged.** Slide 09 and 09b both display the same denominator (`/ 14`). If you see the total bumped, someone confused companions with new slides.
- **Distinct from appendix `AN / N`.** The appendix is reference material the presenter doesn't walk through. Companions are in-flow — the presenter DOES walk through them, and relegating to appendix would break the argument.
- **Runtime override is manual.** The `.page-num` dynamic-fill script in `assets/deck-stage.js` fills `NN` by slide index. Companion slides MUST drop the `.page-num` class so the runtime leaves the hardcoded suffix alone. Author writes `<span class="num">09b / 14</span>` explicitly. See [`layout-rules.md`](layout-rules.md#dynamic-pagination) for the base rule this overrides.

**Example meta.right for a companion slide:**

```html
<div class="meta">
  <div class="left"> … </div>
  <div class="right">
    <span>Board Meeting № 01</span>
    <!-- .num without .page-num — runtime leaves this alone -->
    <span class="num">09b / 14</span>
  </div>
</div>
```

**Anti-pattern:** using letter-suffix as a shortcut to avoid re-paginating when the deck grows. If the new slide is a distinct topic, it's a new slot (`10 / 15`), not a companion (`09b / 14`). Letter suffix is semantic, not procedural.

### Compact density

Apply `data-density="compact"` on individual `<section>` elements when content is denser than the default token spacing allows. This narrows `--pad-x` from 100px to 80px, drops `--t-h1` from 88px to 72px, and shrinks body text to 26px. Use when an appendix card grid has 4+ columns, or when a dense table needs more horizontal room. MUST NOT apply as a global default — the deck is designed at default density.

### Slide chrome invariants

Every content archetype (not cover, not act-divider, not appendix-intro) MUST include:

1. `.meta` top strip — wordmark + context on left, meeting label + page index on right
2. `.body` — `flex: 1; min-height: 0; display: flex; flex-direction: column` wrapper for content
3. `.footer` bottom strip — "Confidential — Lerian Board" + date, `flex-shrink: 0`

The hero archetypes (`cover`, `act-divider`, `appendix-intro`, `content-accent`, `content-dark` statement layouts) skip `.body` and put a `flex: 1; justify-content: center` wrapper directly inside `<section>`. Meta + footer still apply.

---

## cover

**Purpose:** the first impression. Wordmark, meeting identifier, deck title, directors/observers roster.

**When to use:**
- Deck opening. Always slide index 0.
- Once per deck — one cover, no "sub-covers" for acts (those are [act-divider](#act-divider)).
- When the audience needs to know who's in the room before who's presenting.

**When NOT to use:**
- For recurring section opens — that's act-divider territory.
- For internal working drafts where a cover slows the reading — start from agenda.
- As a placeholder — if the deck isn't ready for a cover, leave slide 1 blank and the runtime will surface "speaker-notes length mismatch."

**Composition pattern:**
- `meta` left: wordmark `<span>` + confidentiality label
- `meta` right: date
- Centered column: eyebrow → inline Lerian SVG (220px tall) → Poppins 72px deck title
- Bottom border-top strip: two columns (Directors / Observers) with role annotations

**Reference example:** `lerian-ppt-example.html` lines 344–380. Template canonical: `../templates/slide-cover.html` (43 lines).

**Common mistakes:**
- Using `<img src="...">` for the wordmark instead of inline SVG — adds an extra request and invites FOUC. `deck.html` inlines the SVG for this reason.
- Omitting the directors/observers strip — the cover is also a roster; without it, the board doesn't see who's accountable for what gets discussed.
- Shrinking the wordmark below 180px — at projection distance, anything smaller reads as "indecisive header" instead of "identity."
- Hardcoding `data-label="Cover"` and then manually numbering later slides in `.meta` — cover is slide index 0 but not paginated; runtime starts counting from slide 2 (first `.body` archetype).
- Pairing the cover with `.slide.dark` — works visually but breaks the reference convention; the cover is the one slide where the white canvas + inline wordmark is the signature.

---

## agenda

**Purpose:** the table of contents. A `table.grid` of acts × themes × time × format, with the debate row highlighted.

**When to use:**
- Second slide (index 1) after the cover.
- Once per deck.
- When the audience benefits from seeing how the time is budgeted — typical for board meetings, not for sales decks.

**When NOT to use:**
- Sales pitches where structure is less important than momentum — drop the agenda, go straight to the story.
- When there are fewer than three acts — a two-row agenda reads as underbaked; merge into a lead slide instead.
- Webinars where the agenda is already in the invite — repeating it kills pacing.

**Composition pattern:**
- Eyebrow: "Agenda"
- h1: time commitment in Poppins with a softened second clause ("Ninety minutes. Half of it on decisions, not reports.")
- `table.grid` with columns: Act | Theme | Time | Format
- `tr.hl` on the row where the real debate happens (e.g., strategic discussions) — this is the visual promise to the audience

**Reference example:** `lerian-ppt-example.html` lines 382–418. Template canonical: `../templates/slide-agenda.html` (68 lines).

**Common mistakes:**
- No `tr.hl` row — the Amarelo highlight is the signal that says "here's where you lean in." Without it, the agenda reads as filler.
- Every row using `.num` for ordinals but the "Time" column not — creates visual inconsistency. Both numeric columns use `td.num`.
- Using `<ol>` or `<ul>` instead of `table.grid` — loses the column rhythm that makes the time budget scannable.
- Wide first column — keep "Act" at `width: 100px` so the theme column gets the space.

---

## act-divider

**Purpose:** section break between major acts. Giant Amarelo canvas, huge act number, pill row of upcoming slides.

**When to use:**
- Between main acts of a structured deck. A 5-act deck has 5 act-dividers.
- Once per act.
- When the audience needs a reset — a moment to breathe between dense reports.

**When NOT to use:**
- For every sub-section — act-dividers are for acts, not sections. If every third slide is an Amarelo divider, the Amarelo loses all signal.
- For appendix transitions — that's [appendix-intro](#appendix-intro), which uses "Appendix" instead of `NN / NN` in meta.right.
- For sales decks under 10 slides — act-dividers buy pacing, but a 6-slide deck doesn't need pacing.

**Composition pattern:**
- `.slide.accent` variant (Amarelo background)
- `meta` right shows act-of-acts (`01 / 05`), NOT deck-of-deck pagination
- Hairline rule between "Act NN" mono label and "~N min · N slides" right-aligned
- Act number/title in Poppins 180px
- Lede paragraph in 78%-ink (`rgba(25,26,27,0.78)`)
- Pill row of the next 3–5 slide titles using scoped `.act-pill` class (solid-ink pill + inverted number chip)
- Max 6 pills per row — the reference uses 5. Above 6, the rhythm breaks into chip-noise.

**Reference example:** `lerian-ppt-example.html` lines 420–463 (Act 01 — Traction). Template canonical: `../templates/slide-act-divider.html` (83 lines).

**Common mistakes:**
- Using `.page-num`/`.page-total` in meta.right — act dividers show act-of-acts, not deck-of-deck. Hardcode `01 / 05`.
- Spelling out the act title in the pill row ("Portfolio — Where We Stand") — pills are short tags, not headlines. Use one or two words.
- Placing act-dividers before the cover — the cover is always slide 1; act-dividers punctuate the body.
- More than 3 act-dividers in a 20-slide deck — the Amarelo becomes noise. Merge small acts.
- Using `table.grid` on an act-divider — FORBIDDEN per `ui-primitives.md` (Amarelo bg eats hairlines).

---

## content

**Purpose:** the workhorse. White background, eyebrow + h1 + lede, then a 2- or 3-column grid of cards, lists, pills, KPIs, or a chart.

**When to use:**
- Any report slide that isn't a hero statement — portfolio breakdowns, pricing tables, client rosters, pipeline funnels, competitive matrices.
- 60–80% of a typical deck's body.
- When the content needs room to breathe but isn't a single declarative statement.

**When NOT to use:**
- For single-number hero slides — use [content-dark](#content-dark) or [content-accent](#content-accent).
- For strategic discussions where pacing benefits from a paper tint — use [content-paper](#content-paper).
- For appendix reference material — use [appendix-content](#appendix-content) for letter-paginated chrome.

**Composition pattern:**
- `.meta` with act context ("Act 01 — Traction & Product") in left, page index in right
- `.body` wrapper with `flex: 1; min-height: 0`
- Eyebrow → h1 (up to `max-width: 1600px`) → optional lede
- Main grid: `flex: 1; min-height: 0; display: grid; grid-template-columns: repeat(3, 1fr)` OR `repeat(2, 1fr)` with ratios like `1fr 1.15fr`
- HARD GATE: the grid MUST have `flex: 1` so it consumes remaining canvas space; `align-items: stretch` so sibling columns match heights.

**Reference example:** `lerian-ppt-example.html` lines 465–549 (Portfolio). Template canonical: `../templates/slide-content.html` (104 lines).

**Common mistakes:**
- Missing `flex: 1; min-height: 0` on `.body` — content clings to the top, leaving dead space above the footer. This is the single most common layout failure; `layout-rules.md` calls it out as the canonical bug.
- Hardcoding card heights — breaks the stretch. Let content decide height; let `align-items: stretch` match siblings.
- Using more than 3 columns — 4+ columns at 1920px divide to ~420px each before gaps; body text at 24–28px wraps awkwardly. Split across two slides instead.
- Skipping the eyebrow — the eyebrow is the editorial anchor. Missing eyebrow = orphan headline (see `ui-primitives.md` composition rules).
- Placing a `table.grid` and a `.kpi` grid on the same slide — two ideas per slide breaks the editorial rhythm. One primitive per role per slide.

---

## content-paper

**Purpose:** paper-background variant for visual pacing. Identical grid mechanics to `content`, but the `#F2F2F2` tint signals "pause and discuss."

**When to use:**
- Strategic discussion slides — the reference uses this exclusively for Act 04's four debates.
- When a run of white `content` slides has gone on too long and the audience needs a visual reset.
- Paired with a dark inline "Questions for the board" card — the paper/ink contrast is the signature.

**When NOT to use:**
- For straight report content — use `content` (white).
- For Amarelo moments — use `content-accent`.
- As the default for all body slides — if every slide is paper, the pacing signal is gone.

**Composition pattern:**
- `.slide.paper` variant
- Same `.meta` / `.body` / `.footer` scaffold as `content`
- Two-column grid: `1fr 1.15fr` with Context column (ticks list) on left and dark "Questions for the board" card on right
- Dark card uses scoped `.qblock`, `.qnum`, `.qtitle`, `.qbody` classes — numbered rows with Amarelo numerals, Poppins 24px title, IBM Plex Serif 17px body on 75%-white
- Eyebrow-timer pattern at top: "Discussion 01" — hairline — "~12 min"

**Reference example:** `lerian-ppt-example.html` lines 1457–1512 (Discussion 01 — Cloud). Also used for Discussions 02, 03, 04 (lines 1513–1688). Template canonical: `../templates/slide-content-paper.html` (98 lines).

**Common mistakes:**
- Using `.slide.paper` without the dark Questions card — the paper tint alone doesn't signal discussion. The contrast between paper bg and inline ink card is what makes the archetype read as "decision needed."
- More than three numbered questions — the card grows too tall and crowds the context column. Split into a follow-up slide.
- Using `ul.numbered` class inside the Questions card — the class exists (see `ui-primitives.md`) but the reference uses the scoped `.qblock` pattern for the Questions-card-on-dark composition. Keep them distinct: `ul.numbered` for light slides, `.qblock` inline pattern for dark cards on paper.
- Putting `content-paper` early in the deck — paper belongs in the discussion act, not in the report acts where it breaks the rhythm.

### Strategic-discussion scaffold

**Sub-template of `content-paper`.** A four-part rhetorical structure for board-facing "we need your input" slides. MUST be used with `.slide.paper` and the dark Questions card — this is not a standalone archetype; it's the disciplined form that `content-paper` takes when a discussion slide asks the board to decide something.

**When to use:**
- Strategic discussions where the board is being asked to weigh in on a specific decision (e.g., Cloud go/no-go, GTM timing, pricing strategy)
- Any slide where the thesis + evidence + punchline + questions sequence is the argument
- When consistency across 2–4 discussion slides in the same act is editorially load-bearing (the reference uses this three times for Discussions 01/02/03 to create a rhetorical rhythm)

**When NOT to use:**
- Report slides — the scaffold's structure (questions card) doesn't apply
- Discussion slides with no specific question to answer — if you can't name three questions the board can decide, you don't have a discussion slide
- For 2 or 4 questions — the scaffold's rhythm is three. Two feels underbaked; four dilutes focus. See question-count rule below.

**Four-part structure:**

- **Left column** — *thesis (~1fr)*:
  1. **Eyebrow:** "The thesis"
  2. **Prose thesis:** 1–2 paragraphs in IBM Plex Serif, 24–28px body. States the position.
  3. **Supporting block:** exactly one of — [`dual-sided-argument`](ui-primitives.md#dual-sided-argument) card ("Works both ways"), bulleted `ul.ticks` signals list, or an inline evidence block. MUST NOT stack two.
  4. **Accent-colored punchline band:** Poppins 20px weight 600, `background: var(--c-accent); color: var(--c-accent-ink);`, padding `14px 20px`, one-line crystallization. NON-NEGOTIABLE — this is the take-home. Without it, the thesis is just prose.
  5. **Optional market-signals grid:** 2-column, `→` arrow bullets in `var(--c-accent-2)` Verde. Use when the thesis wants external validation alongside the punchline.
- **Right column** — *questions card (~1.1fr, dark)*:
  - `background: var(--c-ink); color: var(--c-ink-inv); padding: 36px 40px; border-radius: 4px;`
  - Eyebrow: "Questions for the board" in Amarelo (`style="color: var(--c-accent);"`)
  - Exactly three questions, each with:
    - `01` / `02` / `03` in JetBrains Mono Amarelo, 16px, padded top 8px
    - Poppins 22px weight 500 title in full white
    - IBM Plex Serif 16px body in `rgba(255,255,255,0.75)` with **bold key phrases** in full white (`color: var(--c-ink-inv); font-weight: 600;`)
  - Dividers between questions: `height: 1px; background: rgba(255,255,255,0.12);`

**HARD RULES:**

- **Exactly three questions.** Not two, not four — three is the rhetorical rhythm the reference uses across three discussion slides deliberately. If there are four real questions, split into two discussion slides. If there are two, find the third or pick a different archetype.
- **Each question ends with an actual question.** The body MUST terminate with a bolded question the board can answer ("**Do we migrate BYOC clients now, or wait?**"). Statements dressed as questions ("What do you think?" without specifics) are failed questions.
- **Punchline band is NON-NEGOTIABLE.** The left column without an Amarelo punchline band is not a strategic-discussion scaffold — it's a content-paper slide that happens to have questions on the right. The punchline is the thesis crystallized.
- **Reading order: thesis first, questions second.** Questions card ALWAYS on the right. Placing it on the left violates reading order — the board needs the thesis before the questions land.
- **Max 12 minutes per discussion slide.** Time-boxed by the eyebrow-timer pattern at top of the slide (see `ui-primitives.md` timer-row).

**Composition pattern:**
- `.slide.paper` with the same `.meta` / `.body` / `.footer` scaffold as `content-paper`
- Eyebrow-timer row at top: "Discussion 01" — hairline — "~12 min"
- Main grid: `grid-template-columns: 1fr 1.1fr; gap: 60px;`
- Left column: thesis eyebrow → prose → supporting block → Amarelo punchline band → (optional) market-signals grid
- Right column: dark card with three numbered questions

**Reference example:** `lerian-ppt-example.html` lines 1457–1512 (Discussion 01), 1513–1580 (Discussion 02), 1581–1650 (Discussion 03) — three consecutive slides using the scaffold with deliberate consistency.

**Anti-patterns:**
- "Questions" that are statements wearing a question mark — "What do you think?" without a specific decision is a failed question. Each question ends with a concrete ask.
- Four questions — dilutes focus. The rhythm is three.
- Skipping the Amarelo punchline band — without it, the thesis is prose without a take-home.
- Questions card on the left — violates reading order.
- Reusing the scaffold for report slides — it's for *decisions*, not *updates*.
- Stacking two supporting blocks (e.g., a `ul.ticks` + a `dual-sided-argument`) — pick one. Two crowds the thesis column.

Pairs with: [`dual-sided-argument`](ui-primitives.md#dual-sided-argument) (typical supporting block), [`ticks`](ui-primitives.md#ticks) (alternative supporting block), [`numbered`](ui-primitives.md#numbered) inline dark variant (the Questions card's numeral pattern).

---

## content-dark

**Purpose:** near-black statement slides. High-impact moments — financial KPI walls, capital strategy, single declarative question.

**When to use:**
- Financial KPI walls (4-up horizontal `.kpi` row on dark panel)
- Capital strategy open questions (hero statement in Poppins 110px + bottom strip of 4 metrics)
- Any moment where the content warrants "stop and listen" — `.slide.dark` is the loudest variant without using Amarelo.

**When NOT to use:**
- For standard report content — use `content` (white).
- For multi-column grid content that needs hairline rules — the dark variant's `border-color: rgba(255,255,255,0.18)` works but loses definition. Use `content-paper` when you need rules and room to breathe.
- More than 3 times in a 20-slide deck — `.slide.dark` is punctuation; a run of dark slides exhausts the audience.

**Composition pattern:**
- `.slide.dark` variant
- Eyebrow auto-renders in Amarelo (`.slide.dark .eyebrow { color: var(--c-accent); }`)
- Hero statement region: `flex: 1; justify-content: center` wrapper with Poppins 88–150px text
- Bottom KPI strip: `flex-shrink: 0` row of 3–4 metrics, border-top at 15% white
- Uses scoped `.dark-kpi` class (Poppins 34px inverse-ink) for bottom-strip metrics — distinct from the `.kpi` primitive

**Reference example:** `lerian-ppt-example.html` lines 956–1039 (Financial KPIs) and 1719–1743 (Capital Strategy). Template canonical: `../templates/slide-content-dark.html` (65 lines).

**Common mistakes:**
- Using `.pill` (default outline) on dark — the outline disappears against the dark background. Use `.pill.accent` only, per `ui-primitives.md` pairing table.
- Putting a `table.grid` on dark without inverting rule colors — hairlines invisible on near-black. The reference doesn't use tables on dark slides; if you need one, override `border-color: rgba(255,255,255,0.18)` explicitly.
- Mega text on dark at 240px — on a single-statement dark slide, 88–110px is the sweet spot. 150px feels shouty, 240px feels like a cover.
- Forgetting `.kpi .value` auto-goes white on dark — no explicit color override needed; the base CSS handles it.

---

## content-accent

**Purpose:** Amarelo full-canvas declarative slide. The loudest moment in the deck.

**When to use:**
- One — at most two — times per deck, for a single message that the board must remember.
- When a statement is bigger than any chart or metric could carry ("Billing Day One. Reported revenue = real cash.").
- As a cliffhanger before an appendix or at the pivot of the deck.

**When NOT to use:**
- For anything supported by data — data slides belong on `content`, `content-paper`, or `content-dark`.
- Back-to-back with another Amarelo slide (act-divider → content-accent → act-divider chains) — the Amarelo burn-in destroys the effect of both slides.
- For discussion openers — Amarelo is "declaration," not "question." Discussions open on `content-paper`.

**Composition pattern:**
- `.slide.accent` variant
- Eyebrow in 72%-ink (`rgba(25,26,27,0.72)`) — auto-applied
- Hero statement in Poppins 150px, `--c-accent-ink` (black) — uses `flex: 1; justify-content: center` to fill canvas
- Optional supporting lede at 78%-ink
- Bottom proof-point strip: 3 `.accent-kpi` tiles (Poppins 72px) + `.accent-cap` mono captions, 18%-ink border-top

**Reference example:** This archetype was **synthesized in Wave 2A** — the reference deck (`lerian-ppt-example.html`) does not contain a pure `content-accent` slide. The closest neighbors are the act dividers (lines 420–463, 919–954, 1194–1225, 1416–1455, 1690–1717) and `appendix-intro` (lines 1745–1761). The archetype extends the `.slide.accent` pattern to a content-bearing statement slide. Template canonical: `../templates/slide-content-accent.html` (67 lines).

**Common mistakes:**
- Adding a `table.grid` or chart — FORBIDDEN per `ui-primitives.md` and `chart-primitives.md`. Amarelo bg eats hairlines and collapses chart highlight contrast.
- Using it as a report slide — if the content requires more than one statement, it's not `content-accent`; it's `content` with an Amarelo eyebrow callout.
- Running it next to an act-divider — both Amarelo canvases back-to-back neutralize each other's signal.
- Hero text under 88px — at 1920×1080, Amarelo-on-black needs presence. 150px is the reference default, 110px is the floor.
- Placing `.pill.accent` on `.slide.accent` — Amarelo pill on Amarelo background is invisible. Use `.pill.solid`.

---

## appendix-intro

**Purpose:** transition from main deck to appendix. Amarelo canvas like an act-divider, but signals "what follows is reference material, not presentation flow."

**When to use:**
- Once per deck, between the last main-deck slide and the first appendix slide.
- When the deck has ≥3 appendix slides worth pre-announcing.
- When the appendix contains material the board may want to navigate during Q&A — signaling its availability is the point.

**When NOT to use:**
- For decks without an appendix — no appendix, no `appendix-intro`.
- For "Next Steps" or "Questions" closer slides — those aren't appendix entries.
- If the appendix is a single slide — a single reference slide doesn't warrant a transition.

**Composition pattern:**
- `.slide.accent` variant (same as act-divider — but different meta right)
- `meta` right shows the literal string `Appendix` — NOT `NN / NN`, NOT a letter index
- Eyebrow: "Appendix — A1 through AN" (substitute actual range)
- Giant Poppins 180px title ("Context, on demand.")
- Lede paragraph enumerating the appendix sections

**Reference example:** `lerian-ppt-example.html` lines 1745–1761. Template canonical: `../templates/slide-appendix-intro.html` (29 lines).

**Common mistakes:**
- Using `NN / NN` in meta.right — runtime would happily fill it, but the visual convention is "Appendix" as a standalone word, signaling the role change.
- Making it look different from act-dividers — the audience reads Amarelo-canvas as "section break." `appendix-intro` intentionally reuses the act-divider chrome; the only signal difference is the meta.right word and the absence of a pill-list of upcoming slides.
- Pill row of appendix slides — the appendix is browsed, not presented. No pill row.
- Placing it before an act-divider instead of after the main-deck closer — breaks reading order. Main deck → closer → appendix-intro → A1 → A2 …

---

## appendix-content

**Purpose:** appendix body slides. Same grid discipline as `content`, but with letter-paginated meta and denser card layouts.

**When to use:**
- Any appendix entry with reference-material density — side letters, cap table detail, roadmap, risks, org chart, security posture.
- When the audience is likely to read alone during Q&A rather than during presentation.
- When the content benefits from card grids (3-up, 4-up) rather than hero layouts.

**When NOT to use:**
- For main-deck content — appendix is reference-only. If it belongs in the presentation flow, it belongs on `content`.
- For Amarelo statement slides — the appendix is informational, not declarative.
- For charts — charts belong on main-deck `content` slides where the presenter walks through them. Appendix readers don't get a presenter.

**Composition pattern:**
- `.slide` variant (white)
- `meta` left: wordmark + "· Appendix A1"
- `meta` right: STATIC letter pagination (`<span>A1 / 8</span>`) — NOT `.page-num` / `.page-total` classes. The runtime does NOT overwrite this.
- Eyebrow: "Appendix A1" (matches meta left)
- h1 describes the appendix section
- 3-up or 4-up card grid using scoped `.appendix-card` class (paper-bg summary blocks) with `.appendix-card-title` for Poppins 24–32px body copy
- `data-density="compact"` OPTIONAL — apply when content density exceeds the default token spacing

**Reference example:** `lerian-ppt-example.html` lines 1763–1791 (A1 Side Letters), plus A2–A8 at lines 1793–2153. Template canonical: `../templates/slide-appendix-content.html` (63 lines).

**Common mistakes:**
- Using `.page-num` / `.page-total` classes on meta.right — the runtime would overwrite `A1 / 8` with `09 / 17`. Plain `<span>A1 / 8</span>` with no runtime-sensitive class is REQUIRED.
- Hero layouts — the appendix is cards and tables, not statements. If the content wants to be a hero, promote it to the main deck.
- Rough letter-pagination (`A1`, `A2`, `A3` inconsistently numbered) — total is fixed. `A1 / 8` through `A8 / 8`, no skips, no gaps.
- Skipping the "· Appendix A1" breadcrumb in meta.left — readers navigating appendix during Q&A lose context without it.
- Putting speaker notes on appendix slides — the array length MUST still match `<section>` count (per `speaker-notes.md`), but notes for appendix slides can be a single short sentence (`"Appendix A1 — side letters. Refer to printed terms."`). Don't write 100-word notes for slides nobody presents.

---

## Related

- Tokens: [`design-tokens.md`](design-tokens.md)
- Canvas + flex discipline: [`layout-rules.md`](layout-rules.md)
- UI primitives: [`ui-primitives.md`](ui-primitives.md)
- Chart primitives: [`chart-primitives.md`](chart-primitives.md)
- Speaker notes schema: [`speaker-notes.md`](speaker-notes.md)
- Dev server runtime: [`server.md`](server.md)
- PDF export pipeline: [`export.md`](export.md)
