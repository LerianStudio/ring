# UI Primitives

Six primitives that compose Lerian editorial slide content. All primitives use tokens from [`design-tokens.md`](design-tokens.md); don't reinvent colors, fonts, or spacing. Layout discipline (canvas size, flex, 24px floor) comes from [`layout-rules.md`](layout-rules.md) — primitives do not override it.

**HARD GATE:** primitives MUST NOT be redefined with new base styles. Inline `style=""` tweaks are allowed for one-off positioning (margin, width, color override) but the class-level rules below are canon.

## Table of Contents

| # | Primitive | When to use |
| --- | --- | --- |
| 1 | [eyebrow](#eyebrow) | Small uppercase mono label above every h1, every section opener, every card title |
| 2 | [pill](#pill) | Rounded tag for deployment type, status, segment, time-box on a row |
| 3 | [kpi](#kpi) | Stacked label + big Poppins number + sub — the single-metric tile |
| 4 | [ticks](#ticks) | Bulleted list with 10×10 Amarelo squares instead of dots |
| 5 | [numbered](#numbered) | Ordinal list with mono `01/02/03` gutter — steps, discussion questions |
| 6 | [table.grid](#tablegrid) | Editorial data tables — agendas, P&L rows, side-by-side comps |

---

## eyebrow

**Purpose:** small uppercase monospace label that sits above every h1, every card title, every chart caption. It's the editorial anchor that tells the eye "this is a new unit."

**When to use:**
- Above the headline on every content slide (`.eyebrow` → `h1`)
- As a section label inside a card or column ("Context", "Ownership", "Channels")
- As a caption above a chart, table, or micro-data block
- Inside a meta-row (discussion timer pattern: `<div class="eyebrow">Discussion 01</div> ... <div class="eyebrow">~12 min</div>`)

**When NOT to use:**
- As a standalone headline — it is support text, not a title
- Below the h1 (reverses the reading order)
- For body copy — use IBM Plex Serif at `--t-body` instead
- At sizes other than `--t-eyebrow` (22px) without deliberate override; sub-eyebrows at 14px are used inline in the reference for deep labels

**HTML:**
```html
<div class="eyebrow">Portfolio — Where We Stand</div>
```

**CSS:**
```css
.eyebrow {
  font-family: 'JetBrains Mono', monospace;
  font-size: var(--t-eyebrow);
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--c-ink-3);
}
.slide.dark .eyebrow  { color: var(--c-accent); }
.slide.accent .eyebrow { color: rgba(25,26,27,0.72); }
```

**Variants:**

| Variant | How | Where observed |
| --- | --- | --- |
| Default | `<div class="eyebrow">…</div>` | Every content slide headline |
| Dark slide | auto (`.slide.dark` → Amarelo text) | Financial KPI slide, dark panels |
| Accent slide | auto (`.slide.accent` → 72%-black) | Act divider openers |
| Amarelo highlight | `style="color: var(--c-accent)"` | "Ask for the board", "Questions for the board", "Framing" — signals a callout |
| Verde highlight | `style="color: var(--c-accent-2)"` | "Services layer · wraps both" — supporting signal |
| In-card (small) | `style="font-size: 14px; color: var(--c-ink)"` | Client-tile headers ("Live in production") |

**Composition example:**
```html
<div class="eyebrow">GTM Strategy</div>
<h1 style="margin-top: 28px; max-width: 1600px;">Engineering-led. Founder-led. Channel-light.</h1>
```

**Timer-row pattern (paired eyebrows with hairline between):**
```html
<div style="display: flex; align-items: center; gap: 18px;">
  <div class="eyebrow">Discussion 01</div>
  <div style="height: 1px; flex: 1; background: var(--c-rule);"></div>
  <div class="eyebrow">~12 min</div>
</div>
```

The `.eyebrow` primitive is demonstrated in every content archetype — `../templates/slide-content.html`, `../templates/slide-content-paper.html`, `../templates/slide-content-dark.html`, `../templates/slide-content-accent.html`, `../templates/slide-agenda.html`, `../templates/slide-appendix-intro.html`, `../templates/slide-appendix-content.html` — and in `../templates/slide-cover.html` for the eyebrow above the title. The timer-row pattern above is built on the same primitive and is ready to drop into any content slide.

---

## pill

**Purpose:** rounded tag for deployment type, segment, status, or short time-box label. Sits inline next to a Poppins name or inside a row flex.

**When to use:**
- Tagging a client row with deployment type ("BYOC", "SaaS/PaaS")
- Marking new items in a list ("New")
- Deployment-callout captions ("Bring-your-own-cloud", "70% of new logos")
- Funnel-stage labels beside a headline ("Top of Funnel", "Cycle Mechanics")

**When NOT to use:**
- As the primary headline — it is chrome, not content
- As a button (deck is a projection surface; there are no clicks)
- For multi-word copy that wraps — pills are single-line
- More than ~6 in a single row (the `act-divider` uses 5; seven starts reading as chips, not pills)

**HTML:**
```html
<span class="pill">BYOC</span>
<span class="pill accent">New</span>
<span class="pill solid">SaaS/PaaS</span>
```

**CSS:**
```css
.pill {
  display: inline-flex; align-items: center; gap: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 18px; letter-spacing: 0.04em; text-transform: uppercase;
  padding: 8px 14px; border-radius: 999px;
  border: 1px solid var(--c-rule); background: transparent; color: var(--c-ink-2);
}
.pill.solid  { background: var(--c-ink);    color: var(--c-ink-inv);    border-color: transparent; }
.pill.accent { background: var(--c-accent); color: var(--c-accent-ink); border-color: transparent; }
```

**Variants:**

| Variant | Class | Background | Text | Use |
| --- | --- | --- | --- | --- |
| Default (outline) | `.pill` | transparent | `--c-ink-2` | Neutral tag — "BYOC", "Top of Funnel" |
| Solid (dark) | `.pill.solid` | `--c-ink` | white | Emphatic tag — "SaaS/PaaS", funnel stage |
| Accent (Amarelo) | `.pill.accent` | `--c-accent` | `--c-accent-ink` | "New", brand-signal tag |

**Observed inline override:** one-off pill with accent background + `white-space: nowrap` for a stat caption ("70% of new logos"). Prefer `.pill.accent` for that case going forward; the inline form is not a new variant.

**Composition example — act-divider chip row (5 pills, wraps if tight):**
```html
<div style="margin-top: 56px; display: flex; gap: 14px; flex-wrap: wrap;">
  <span class="pill solid">01 · Portfolio</span>
  <span class="pill solid">02 · Pricing</span>
  <span class="pill solid">03 · Clients</span>
  <span class="pill solid">04 · Pipeline</span>
  <span class="pill solid">05 · Competitive</span>
</div>
```

**Composition example — client row (name + pills):**
```html
<div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
  <span style="font-family: 'Poppins'; font-weight: 500; font-size: 26px;">SRM Asset</span>
  <span class="pill">BYOC</span>
  <span class="pill accent">New</span>
</div>
```

`.pill.solid` is demonstrated in `../templates/slide-act-divider.html` — the act's chip row uses the dark-pill pattern (local class `.act-pill`) with an inverted number chip, which is the canonical reference rendering of the `.pill.solid` shape. The outline (`.pill`) and accent (`.pill.accent`) variants are not instantiated in the current archetype set; they're defined in the base stylesheet and available for reuse in any content archetype that needs an inline tag next to a Poppins name (e.g., a future clients-row template).

---

## kpi

**Purpose:** the single-metric tile. Stacks a mono label over a big Poppins number over a small sub-caption. Composes into 3- or 4-column KPI walls.

**When to use:**
- KPI wall slides (3–4 metrics on one slide)
- Inside a left column paired with a chart on the right (financial-KPI slide)
- Dark-panel summary rows on statement slides

**When NOT to use:**
- For numbers that need to sit inline with sentence prose — use a Poppins `<span>` instead
- For ultra-hero single numbers (180–240px) — those are standalone, not tiles; see `layout-rules.md` Hero Numbers
- When the caption is longer than ~80 chars — kpi.sub is designed for one short line

**HTML:**
```html
<div class="kpi">
  <div class="label">ARR run rate</div>
  <div class="value">R$ 2.5M</div>
  <div class="sub">MRR R$ 207K · ↑ 590% since May/25 · ↑ 24% MoM</div>
</div>
```

**CSS:**
```css
.kpi { display: flex; flex-direction: column; gap: 10px; }
.kpi .label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 18px; letter-spacing: 0.06em; text-transform: uppercase;
  color: var(--c-ink-3);
}
.kpi .value {
  font-family: 'Poppins', sans-serif;
  font-weight: 500; font-size: 96px; line-height: 0.95; letter-spacing: -0.03em;
  color: var(--c-ink);
}
.kpi .sub { font-size: 22px; color: var(--c-ink-3); }
.slide.dark .kpi .value { color: var(--c-ink-inv); }
.slide.dark .kpi .label,
.slide.dark .kpi .sub   { color: rgba(255,255,255,0.55); }
```

**Variants:**

| Variant | How | Where observed |
| --- | --- | --- |
| Default | `<div class="kpi">` with 96px value | Financial-KPI slide, generic tiles |
| Accent value | `style="color: var(--c-accent)"` on `.value` | Primary KPI on a dark slide ("R$ 2.5M") |
| Reduced value | `style="font-size: 76px"` (or 60px) on `.value` | When three tiles stack vertically and 96px blows the column |
| Dark-slide auto | auto via `.slide.dark` | Value goes white, label/sub drop to 55% opacity |
| Inline sub-span | `<span style="font-size: 26px; font-weight: 400; color: rgba(255,255,255,0.55);">target</span>` inside `.value` | "NDR 130% target" — appendix to the hero number |

**Composition example — 4-up KPI row on a dark panel:**
```html
<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 40px;">
  <div class="kpi">
    <div class="label">Stage</div>
    <div class="value" style="font-size: 76px;">Post-Seed</div>
  </div>
  <div class="kpi">
    <div class="label">Runway</div>
    <div class="value" style="font-size: 76px;">20 – 32 mo</div>
  </div>
  <div class="kpi">
    <div class="label">Pipeline</div>
    <div class="value" style="font-size: 76px;">R$ 5.9M active</div>
  </div>
  <div class="kpi">
    <div class="label" style="color: var(--c-accent);">Cloud maturity</div>
    <div class="value" style="font-size: 76px;">Inflection</div>
  </div>
</div>
```

The dark-panel variant of this primitive is demonstrated in `../templates/slide-content-dark.html` — the local `.dark-kpi` class in that template is the canonical `.slide.dark .kpi` rendering (white value, 55%-white label/sub). The light-panel `.kpi` shape has no dedicated archetype in the current set; reuse it inside any `.slide` or `.slide.paper` content archetype when you need a metric tile or a 3-/4-up KPI row.

**HARD GATE:** when three `.kpi` tiles stack vertically inside a column, reduce `.value` to 60–76px. The 96px default assumes one row of tiles, not three stacked.

---

## ticks

**Purpose:** custom-bulleted list. 10×10 Amarelo square marker replaces the dot bullet — Lerian's list fingerprint.

**When to use:**
- "Context" columns on strategic-discussion slides
- Evidence blocks under a headline
- Any 3–6 item editorial list where each item is 1–3 lines

**When NOT to use:**
- For step-ordered content — use [`numbered`](#numbered) instead
- For >6 items — split into columns or trim; long lists dilute the square rhythm
- For single-line tag sequences — use [`pill`](#pill) in a flex row

**HTML:**
```html
<ul class="ticks">
  <li><strong>70% of new logos</strong> enter directly through SaaS (vs. 100% BYOC 12 months ago).</li>
  <li>Tenant-manager live since Q1/26. Clients deploy Lerian products <strong>and their own apps</strong> on Lerian infra.</li>
  <li><strong>No competitor offers this</strong> capability today.</li>
  <li>BYOC clients already requesting migration to managed tiers.</li>
</ul>
```

**CSS:**
```css
ul.ticks { list-style: none; padding: 0; margin: 0; }
ul.ticks li {
  position: relative; padding-left: 28px;
  font-size: 22px; line-height: 1.5; margin-bottom: 18px;
}
ul.ticks li::before {
  content: ""; width: 10px; height: 10px;
  background: var(--c-accent);
  display: block; border-radius: 2px;
  transform: translateY(12px);
}
```

**Variants:**
- Default is the only variant observed in the reference. No dark-slide override is defined — inherit body color from `.slide.dark p, .slide.dark li { color: rgba(255,255,255,0.78); }` in the base; the Amarelo square reads against both light and dark surfaces without a variant.
- Common inline adjustment: `style="flex: 1;"` on the `<ul>` so it stretches when the parent column is a flex container (discussion slides).

**Note on 22px font-size:** this is below the 24px body floor from `layout-rules.md`. The reference uses 22px intentionally for list density. When shipping new slides, prefer 24px. If sticking to 22px, treat it as a chrome-density exception (documented in `layout-rules.md` Minimum Text Size table, row "18–22px … small labels") and MUST NOT go lower.

**Composition example — Context column on a paper-variant slide:**
```html
<div class="eyebrow" style="margin-bottom: 24px; color: var(--c-ink);">Context</div>
<ul class="ticks" style="flex: 1;">
  <li>Brazil's regulatory complexity is the <strong>ultimate proof of adaptability</strong>.</li>
  <li><strong>La Finteca</strong> global CEO visited the office — organic LATAM demand.</li>
  <li><strong>Lerian LLC</strong> Delaware incorporated.</li>
  <li>Reference model: <strong>Tractian</strong> — BR-born, US expansion via physical presence.</li>
</ul>
```

The canonical instance lives in `../templates/slide-content-paper.html` — the "Context" column uses `<ul class="ticks">` against the paper surface. Reuse the primitive in any content archetype that needs a 3–6-item evidence list; the Amarelo square reads against `.slide` (white), `.slide.paper`, and `.slide.dark` without variant overrides.

---

## numbered

**Purpose:** ordinal list. Mono `01 / 02 / 03` gutter on the left, Poppins/Serif content on the right. For steps, questions, priorities where order matters.

**When to use:**
- "Questions for the board" blocks
- Step-by-step process lists
- Ranked priorities

**When NOT to use:**
- Unordered lists — use [`ticks`](#ticks)
- When the numerals themselves need to be huge (20–150px) — use a hero-number layout, not a list gutter

**HTML (canonical form, using the `ul.numbered` class):**
```html
<ul class="numbered">
  <li>
    <span class="n">01</span>
    <div>Target profile &amp; reference case. Enterprise gravitates hybrid, mid-market accepts full SaaS.</div>
  </li>
  <li>
    <span class="n">02</span>
    <div>GTM timing. 70% already choose SaaS. Is this the signal to go-to-market with Cloud now?</div>
  </li>
  <li>
    <span class="n">03</span>
    <div>Pricing strategy. Clients running their apps on Lerian infra creates platform lock-in.</div>
  </li>
</ul>
```

**CSS:**
```css
ul.numbered {
  list-style: none; padding: 0; margin: 0;
  display: flex; flex-direction: column; gap: 24px;
}
ul.numbered li {
  display: grid; grid-template-columns: 60px 1fr; gap: 28px; align-items: baseline;
  font-size: var(--t-body); line-height: 1.4;
}
ul.numbered li .n {
  font-family: 'JetBrains Mono', monospace;
  font-size: 18px; letter-spacing: 0.06em;
  color: var(--c-ink-3); padding-top: 8px;
}
```

**Variants:**

| Variant | How | Where observed |
| --- | --- | --- |
| Default (light) | `ul.numbered` on `.slide` | Canonical form per CSS |
| Dark-panel, Amarelo numerals | Inline-flex blocks on dark card, `.n` in Amarelo, Poppins title + Serif sub | "Questions for the board" blocks on all four Discussion slides |

**Two forms shipped.** (a) `ul.numbered` — canonical list form for simple ordered lists on light slides. (b) Inline dark-panel variant — dark `<div>` card with `display: flex` rows, `<span>` numeral in `JetBrains Mono` + Amarelo, `<div>` title/sub. Both are canonical. Prefer the class form for plain ordered lists; use the inline dark variant when each item needs title + body on a dark card (e.g., "Questions for the board").

**Composition example — dark "Questions for the board" card (inline variant from reference):**
```html
<div style="background: var(--c-ink); color: var(--c-ink-inv); padding: 40px 44px;
            border-radius: 4px; display: flex; flex-direction: column; gap: 24px;
            justify-content: space-between;">
  <div class="eyebrow" style="color: var(--c-accent);">Questions for the board</div>

  <div style="display: flex; gap: 14px;">
    <span style="font-family: 'JetBrains Mono'; color: var(--c-accent);
                 font-size: 16px; flex-shrink: 0; padding-top: 8px;">01</span>
    <div>
      <div style="font-family: 'Poppins'; font-size: 24px; font-weight: 500;
                  color: var(--c-ink-inv); line-height: 1.25;">Target profile &amp; reference case</div>
      <div style="font-size: 17px; line-height: 1.5;
                  color: rgba(255,255,255,0.75); margin-top: 6px;">
        Enterprise gravitates hybrid, mid-market accepts full SaaS.
      </div>
    </div>
  </div>
  <!-- 02, 03 … -->
</div>
```

The dark-card "Questions for the board" pattern is demonstrated in `../templates/slide-content-paper.html` — the right-column dark card composes the inline numbered variant (Amarelo numeral + Poppins title + Serif sub) on top of `background: var(--c-ink)`. That template is the reference rendering of this primitive's inline form. The light-slide `ul.numbered` class form is not instantiated in the current archetype set; use it inside any `.slide` content archetype when you need a ranked-step list.

---

## table.grid

**Purpose:** the editorial data grid. Hairline rules top and bottom, generous row padding, JetBrains Mono column headers, tabular-nums for numeric cells, Amarelo highlight row for the emphatic line.

**When to use:**
- Agenda tables (act × theme × time × format)
- P&L snapshots and financial grids
- Side-by-side comparisons with ≥3 columns
- Any data set where row rhythm carries meaning

**When NOT to use:**
- 1-column or 2-column lists where an editorial row would read as overengineered — use [`ticks`](#ticks) or a `div` row
- For layouts that need fixed column heights — `table.grid` is content-sized (see `layout-rules.md` Fixed-Height Cards — FORBIDDEN)
- Inside a scrollable container — the canvas is 1080px tall; rows MUST fit

**HTML:**
```html
<table class="grid" style="margin-top: 72px;">
  <thead>
    <tr>
      <th style="width: 100px;">Act</th>
      <th>Theme</th>
      <th style="width: 160px; text-align: right;">Time</th>
      <th style="width: 220px; text-align: right;">Format</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="num">01</td>
      <td style="font-size: 28px; font-family: 'Poppins'; color: var(--c-ink);">Traction, Product &amp; Competitive Positioning</td>
      <td class="num" style="text-align: right;">20 min</td>
      <td style="text-align: right; color: var(--c-ink-3);">Report</td>
    </tr>
    <tr class="hl">
      <td class="num">04</td>
      <td style="font-size: 28px; font-family: 'Poppins';">Four Strategic Discussions
        <span style="opacity: 0.62; font-weight: 400;">— the core of this board</span></td>
      <td class="num" style="text-align: right;">45 min</td>
      <td style="text-align: right; font-weight: 600;">Debate</td>
    </tr>
  </tbody>
</table>
```

**CSS:**
```css
table.grid {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--t-small);
}
table.grid th, table.grid td {
  text-align: left; padding: 18px 20px;
  border-top: 1px solid var(--c-rule);
  color: var(--c-ink-2);
  vertical-align: top;
}
table.grid th {
  font-family: 'JetBrains Mono', monospace;
  font-size: 16px; letter-spacing: 0.06em; text-transform: uppercase;
  color: var(--c-ink-3); font-weight: 500;
  border-top: none;
  padding-bottom: 14px;
}
table.grid tr:last-child td        { border-bottom: 1px solid var(--c-rule); }
table.grid td.num                  { font-family: 'JetBrains Mono', monospace; font-variant-numeric: tabular-nums; color: var(--c-ink); }
table.grid tr.hl td                { background: var(--c-accent); color: var(--c-accent-ink); font-weight: 500; }
table.grid tr.hl td.num            { color: var(--c-accent-ink); }
table.grid.compact th,
table.grid.compact td              { padding: 10px 16px; }
table.grid.compact th              { font-size: 14px; padding-bottom: 8px; }
table.grid.compact.tight th,
table.grid.compact.tight td        { padding: 7px 14px; font-size: 18px; }
table.grid.compact.tight td:last-child { font-size: 17px; color: var(--c-ink-2); }
```

**Variants:**

| Variant | Class | Row padding | Font | Use |
| --- | --- | --- | --- | --- |
| Default | `table.grid` | `18px 20px` | `--t-small` (22px) | Agendas, P&L, most editorial grids |
| Highlight row | `tr.hl` (on any density) | inherits | bg Amarelo, ink preto | The emphatic line ("Debate", "Net income") |
| Numeric cell | `td.num` | inherits | JetBrains Mono, tabular-nums | Ordinal + financial figures |
| Compact | `table.grid.compact` | `10px 16px` | 14px th / 22px td | Higher-density grids (defined; unused in reference) |
| Compact-tight | `table.grid.compact.tight` | `7px 14px` | 18px th/td, 17px last col | Dense grids with an axis-label last column (defined; unused in reference) |

**Density variants — compact and compact-tight.** `compact` (10px 16px padding, 14px/22px type) for grids where default density would overflow the canvas. `compact-tight` (7px 14px, 18px type, 17px last col) for dense grids with an axis-label last column — e.g., P&L with Q1..Q4 + YoY.

**Composition example — P&L grid with a highlight Net income row:**
```html
<table class="grid">
  <thead><tr>
    <th>R$ thousand</th>
    <th style="text-align: right;">Jan/26</th>
    <th style="text-align: right;">Feb/26</th>
    <th style="text-align: right;">Mar/26</th>
  </tr></thead>
  <tbody>
    <tr><td style="font-size: 22px; font-family: 'Poppins'; color: var(--c-ink);">Revenue (MRR)</td>
        <td class="num" style="text-align: right;">167</td>
        <td class="num" style="text-align: right;">207</td>
        <td class="num" style="text-align: right;">207</td></tr>
    <tr><td style="color: var(--c-ink-3);">COGS</td>
        <td class="num" style="text-align: right;">(1,160)</td>
        <td class="num" style="text-align: right;">(1,240)</td>
        <td class="num" style="text-align: right;">(1,370)</td></tr>
    <tr class="hl"><td style="font-size: 22px; font-family: 'Poppins';">Net income</td>
        <td class="num" style="text-align: right;">(1,590)</td>
        <td class="num" style="text-align: right;">(1,520)</td>
        <td class="num" style="text-align: right; font-weight: 600;">(1,390)</td></tr>
  </tbody>
</table>
```

The canonical instance — including the `tr.hl` highlight row — lives in `../templates/slide-agenda.html`. Reuse the primitive in any content archetype that needs a P&L, side-by-side comparison, or ≥3-column data grid; the variant classes (`compact`, `compact.tight`) are defined in the base stylesheet and ready to use when a denser grid is needed.

**HARD GATE:** no `height`, no `min-height` on rows. Row rhythm comes from padding, not fiat. Fixed cell heights are forbidden per `layout-rules.md`.

---

## Composition Rules

- **eyebrow is the anchor.** Every content slide has at least one `.eyebrow`. Headline goes right under it. Missing eyebrow = orphan headline.
- **One primitive per role per slide.** A slide MUST NOT mix `ul.ticks` and `ul.numbered` in the same column — the bullet grammar conflicts. Split into siblings if you need both.
- **Pills cluster, kpis breathe.** Pill rows flex-wrap tight (`gap: 10–14px`); kpi walls use `36–80px` column gaps. MUST NOT use pill density on kpis or vice versa.
- **Max 6 pills per row.** The act-divider pattern uses 5. Beyond 6, the rhythm breaks into chip-noise; split the slide or drop the pill.
- **Max 6 ticks per list.** Above 6, the square-bullet rhythm dilutes. Split into two columns (Context | Evidence) or trim.
- **KPI value stack discipline.** Three stacked `.kpi` tiles → reduce `.value` to 60–76px. Four-up horizontal row → keep 96px default or reduce to 76px only if copy is long ("R$ 5.9M active").
- **table.grid rules stay hairline.** MUST NOT add double borders, zebra stripes, or solid backgrounds beyond `tr.hl`. The rhythm is the white space between rows, not the lines.
- **Dark-slide kpi wins.** `.slide.dark` + `.kpi` is the canonical summary layout (capital-strategy slide). Eyebrows go Amarelo automatically; `.value` goes white.
- **Accent-slide discipline.** `.slide.accent` pairs with eyebrow + big Poppins number + pill row (the act-divider template). MUST NOT put a table.grid on `.slide.accent` — the Amarelo background eats the hairline rules.
- **Eyebrow color is editorial signal.** Default ink-3 = "label." Amarelo = "callout incoming" (Framing, Ask, Questions for the board). Verde = "supporting signal." MUST NOT use Amarelo eyebrow for neutral labels — it loses meaning.
- **numbered belongs in dark cards or as canonical light lists.** The Questions-for-the-board pattern is the reference's de-facto `numbered` use. Light-slide `ul.numbered` is available per the CSS; use it for ranked steps.

## Dark vs Light Pairing

| Primitive | Works on `.slide` | Works on `.slide.paper` | Works on `.slide.dark` | Works on `.slide.accent` |
| --- | --- | --- | --- | --- |
| eyebrow | yes | yes | yes (auto Amarelo) | yes (auto 72% ink) |
| pill | yes (all variants) | yes | `.pill.accent` only (outline disappears) | `.pill.solid` only (accent on accent = invisible) |
| kpi | yes | yes | yes (preferred — hero summaries) | avoid (Amarelo on Amarelo loses the value) |
| ticks | yes | yes | yes (inherits 78% white body) | yes, but the Amarelo square on Amarelo bg is invisible — swap bullet to ink inline |
| numbered | yes (class form) | yes | yes (the inline Questions pattern — numeral Amarelo, title white, sub 75% white) | avoid (same Amarelo-on-Amarelo problem) |
| table.grid | yes | yes | needs inverted rules (`border-color: rgba(255,255,255,0.18)`) — not in reference canon | **FORBIDDEN** — Amarelo bg eats hairlines |

**HARD GATE:** if the pairing table says "avoid" or "FORBIDDEN," the archetype MUST pick a different primitive or a different slide variant. Do not patch with inline color overrides.

## Related

- Tokens: [`design-tokens.md`](design-tokens.md)
- Canvas + flex discipline: [`layout-rules.md`](layout-rules.md)
- Archetype templates (what actually ships today): `../templates/slide-cover.html`, `../templates/slide-agenda.html`, `../templates/slide-act-divider.html`, `../templates/slide-content.html`, `../templates/slide-content-paper.html`, `../templates/slide-content-dark.html`, `../templates/slide-content-accent.html`, `../templates/slide-appendix-intro.html`, `../templates/slide-appendix-content.html`
