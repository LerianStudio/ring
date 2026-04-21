# UI Primitives

Eleven primitives that compose Lerian editorial slide content. All primitives use tokens from [`design-tokens.md`](design-tokens.md); don't reinvent colors, fonts, or spacing. Layout discipline (canvas size, flex, 24px floor) comes from [`layout-rules.md`](layout-rules.md) — primitives do not override it.

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
| 7 | [dashed-hairline](#dashed-hairline) | "Related but secondary" divider — the soft cousin of `.rule` |
| 8 | [narrative-arc](#narrative-arc) | Cross-slide threading callout — directional, names two slides by name |
| 9 | [transition-column](#transition-column) | Semantic hinge between two cards — old→new, manual→automated, BYOC→Managed |
| 10 | [org-node-flag](#org-node-flag) | Tab-style status badge hanging off the top edge of a card — PAIN POINT, NEW, HIRE |
| 11 | [dual-sided-argument](#dual-sided-argument) | Two-column symmetric-benefit card — same argument, two stakeholder perspectives |
| 12 | [inline-mini-legend](#inline-mini-legend) | Legend dots embedded inline inside a caption sentence — 2–3 categories |

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

## dashed-hairline

**Purpose:** "related but secondary" divider. A softer cousin of the solid `.rule` hairline. The dashed edge reads as a semantic pause — "the thing below is connected to the thing above, but not continuous with it."

**When to use:**
- Separating a [`narrative-arc`](#narrative-arc) callout from the primary slide content
- Marking a tangential footnote or caption that threads off the main argument
- Between a card's main body and its "ownership" / "next steps" meta-row when a solid rule would feel too assertive

**When NOT to use:**
- For structural separation — use a solid `.rule` (1px `--c-rule`) or a table border
- As a decorative accent — dashes are semantic, not chrome. Overuse flattens the signal.
- On `.slide.accent` backgrounds — Amarelo eats the dash rhythm; use a solid rule or drop the divider

**HTML:**
```html
<div style="border-top: 1px dashed var(--c-rule);"></div>
```

**Inline composition — above a narrative-arc callout:**
```html
<div style="margin-top: 26px; padding-top: 18px; border-top: 1px dashed var(--c-rule);">
  <!-- narrative-arc block goes here -->
</div>
```

**Dashed vs solid — pairing table:**

| Style | CSS | Semantic role |
| --- | --- | --- |
| Solid `.rule` | `border-top: 1px solid var(--c-rule)` | Structural — "new section," column divider, footer border |
| Dashed hairline | `border-top: 1px dashed var(--c-rule)` | Semantic pause — "related but secondary," threads a callout off the main argument |

**HARD GATE:** MUST NOT mix dashed and solid hairlines inside a single card without a reason. Inconsistent hairlines read as sloppy, not editorial.

**Anti-pattern:** using a dashed hairline as a generic "divider with visual interest" — it becomes noise. Reserve it for the callout-threading role.

Pairs with: [`narrative-arc`](#narrative-arc) (dashed hairline sits directly above the arc callout).

---

## narrative-arc

**Purpose:** cross-slide threading device. A small callout that names the current slide's relationship to another slide by name, letting the audience hold the deck's through-line across sections. One arc per slide at most.

**When to use:**
- A discussion slide that *depends on* a report slide from earlier acts — name both and the dependency relationship
- A decision slide that *opens* an act the audience hasn't reached yet — name the forward link
- A summary slide that *closes* a loop opened many slides earlier — name the callback

**When NOT to use:**
- For vague relationships ("related to X") — arcs MUST be directional and specific
- To summarize the current slide — the arc threads a *relationship*, not a recap
- On every slide — the arc is a pacing device; using it more than 2–3 times per deck neutralizes the signal
- On `.slide.accent` or `.slide.dark` — the Amarelo pill + muted prose is tuned for light surfaces

**Relationship vocabulary (REQUIRED — pick one):**

| Word | Direction | Example |
| --- | --- | --- |
| **hinge** | Present slide is the pivot between two sections | "Discussion 01 · Cloud is the **hinge** into Act 05 · Capital Strategy." |
| **continues** | Present slide extends an argument from earlier | "This **continues** 04 · Pricing — the unit-economics question asked there." |
| **answers** | Present slide resolves a question opened earlier | "This **answers** Discussion 02 · GTM." |
| **opens** | Present slide sets up a section ahead | "This **opens** Act 04 · Strategic Discussions." |
| **closes** | Present slide resolves a loop opened earlier | "This **closes** the Cap-Table thread started at A1." |

**HTML:**
```html
<div style="margin-top: 26px; padding-top: 18px; border-top: 1px dashed var(--c-rule); display: flex; align-items: flex-start; gap: 12px;">
  <div style="font-family: 'JetBrains Mono'; font-size: 11px; letter-spacing: 0.1em; text-transform: uppercase; color: var(--c-accent-ink); background: var(--c-accent); padding: 3px 8px; border-radius: 2px; white-space: nowrap; font-weight: 600; flex-shrink: 0;">Narrative arc</div>
  <div style="font-size: 14px; line-height: 1.45; color: var(--c-ink-2);">Discussion <strong style="color: var(--c-ink);">01 · Cloud</strong> is the hinge into <strong style="color: var(--c-ink);">Act 05 · Capital Strategy</strong>. If Cloud is go, the raise timing moves up.</div>
</div>
```

**Composition rules:**

- **Pill text is fixed.** Always "Narrative arc" (or the translated equivalent for non-English decks: `Arco narrativo`, `Fil narratif`). MUST NOT customize per slide — the label is the recognition pattern.
- **Prose is subdued.** Body text at `var(--c-ink-2)` (14px IBM Plex Serif). Key slide names bolded in full `var(--c-ink)`. The bold is the only emphasis allowed — no italics, no underlines.
- **Dashed hairline above is REQUIRED.** The dashed separator from `border-top: 1px dashed var(--c-rule)` tells the eye "this is related but secondary." A solid rule promotes the arc to primary content, which it is not.
- **Directional statement.** The prose MUST name *both* slides and use one of the relationship words above. A non-directional arc ("related to slide 3") is a failed arc.
- **One per slide.** Two arcs on a single slide overload the threading; split into sibling slides if both matter.

**Anti-patterns:**
- Vague connection — "See also Discussion 01" is a breadcrumb, not an arc
- Summary-flavored arcs — "This slide covers cloud" is a lede, not a cross-reference
- Arc above the dashed rule — the rule MUST sit above the arc to signal "threading off the main content"
- Arc pill in outline form (`.pill`) — the Amarelo fill is load-bearing; an outlined pill reads as generic chrome

Pairs with: [`dashed-hairline`](#dashed-hairline) (always sits above the arc).

---

## transition-column

**Purpose:** a named narrow column that sits *between* two cards signaling a journey. Not a card, not a gap — a semantic hinge. The reader's eye crosses it and understands "the thing on the right is what the thing on the left becomes."

**When to use:**
- BYOC → Managed migration narratives
- Old → New architecture comparisons where the *transition* is part of the story
- Manual → Automated process diagrams
- Any two-card pair where the relationship word ("migrating," "upgrading," "consolidating") is load-bearing

**When NOT to use:**
- For `vs.` comparisons — use the [`2x2-matrix`](chart-primitives.md#2x2-matrix) or a two-column `table.grid`. A transition column implies motion; comparisons don't move.
- As a generic separator between any two cards — use a `.rule` or a grid `gap`
- For three-way transitions (A → B → C) — the pattern is two-card only. Three stages is a [`funnel`](chart-primitives.md#funnel).
- Inside columns narrower than ~80px — the arrow + dual-label stack collapses

**HTML:**
```html
<div style="display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 0 14px; position: relative; min-width: 80px;">
  <div style="font-family: 'JetBrains Mono'; font-size: 10px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--c-ink-3); text-align: center; line-height: 1.3; white-space: nowrap;">Migrating</div>
  <div style="font-size: 42px; color: var(--c-ink); margin-top: 4px; line-height: 1;">→</div>
  <div style="font-family: 'JetBrains Mono'; font-size: 10px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--c-ink-3); text-align: center; line-height: 1.3; margin-top: 4px; white-space: nowrap;">to managed</div>
</div>
```

**Parent composition — three-cell grid with the transition column as the `auto` track:**
```html
<div style="display: grid; grid-template-columns: 1fr auto 1.15fr; gap: 0; align-items: stretch;">
  <div class="card"> <!-- left card: current state --> </div>
  <div> <!-- transition column HTML from above --> </div>
  <div class="card"> <!-- right card: target state --> </div>
</div>
```

**Composition rules:**

- **`grid-template-columns: 1fr auto 1.15fr`.** Right card gets a slight size premium because it's the destination — the eye lands there. Adjust to `1fr auto 1fr` if both states carry equal weight.
- **Arrow glyph is `→` at 42px.** Black arrow on white. MUST NOT substitute an SVG or an emoji — the Unicode arrow at 42px is the signature.
- **Top and bottom mono labels answer "from what, to what."** Top label = verb/phase ("Migrating", "Upgrading", "Consolidating"). Bottom label = destination ("to managed", "to v5", "to one pipeline"). Both in JetBrains Mono 10px, `--c-ink-3`.
- **Flanking cards share the paired-shape convention.** The left card rounds its outward corners (left-side) and squares its inward corners (right-side); the right card mirrors. Visual: the two cards read as one split shape with the transition column bridging. `border-radius: 4px 0 0 4px` on left, `0 4px 4px 0` on right, or use scoped classes.

**Anti-patterns:**
- Transition column as "vs." separator — violates the directional contract
- Arrow pointing left or bidirectional — the column is one-way. If the relationship is reciprocal, use a [`dual-sided-argument`](#dual-sided-argument) card instead.
- Missing top or bottom label — the arrow alone is ambiguous; both labels are REQUIRED
- Using `.rule` styling (solid border) between the cards instead of the column — loses the "hinge" semantics

---

## org-node-flag

**Purpose:** tab-style status badge, absolute-positioned above an org-chart (or any entity) card. Hangs off the top edge like a file-tab — drawing the eye to a single card that needs special attention inside a grid of siblings.

**When to use:**
- Org charts: flagging a role that's open to hire, at risk, or the critical path
- Product matrices: flagging a product area that's a pain point or newly shipped
- Roadmap grids: flagging the one quarter or swim-lane the slide is about
- Any uniform grid where one card needs "read me first" treatment without becoming a hero

**When NOT to use:**
- On more than one card in a grid — two flags cancel each other. If two cards need attention, flag one and bold the other.
- On hero slides — the flag is a grid-level signal; hero slides don't have siblings to contrast against
- As a decorative tag — use `.pill.accent` for tags; the flag is structural

**Suggested values (REQUIRED — ALL CAPS, one or two words):**

| Value | Meaning |
| --- | --- |
| `PAIN POINT` | This card is the problem the slide is naming |
| `NEW` | This card arrived since last review |
| `AT RISK` | This card is slipping or under-resourced |
| `CRITICAL PATH` | The plan depends on this card |
| `HIRE` | Open role (org-chart use) |

**HTML (badge + parent card):**
```html
<div style="background: var(--c-ink); color: var(--c-ink-inv); padding: 18px 20px; border-radius: 4px; text-align: center; position: relative; border: 2px solid var(--c-accent);">
  <div style="position: absolute; top: -11px; left: 50%; transform: translateX(-50%); background: var(--c-accent); color: var(--c-ink); font-family: 'JetBrains Mono'; font-size: 10px; letter-spacing: 0.12em; padding: 3px 8px; border-radius: 2px; font-weight: 600; white-space: nowrap;">PAIN POINT</div>
  <!-- card content -->
</div>
```

**Composition rules:**

- **Parent card MUST be `position: relative`.** The flag is absolute-positioned relative to its parent; non-relative parents break the layout.
- **Parent card MUST gain `border: 2px solid var(--c-accent)`.** The Amarelo border visually binds the flag to the card. A flagged card without the accent border reads as a floating sticker.
- **Flag text is ALL CAPS JetBrains Mono 10px.** Letter-spacing `0.12em`, font-weight 600. MUST NOT use mixed case or larger sizes — the tab shape depends on this density.
- **Flag position is `top: -11px; left: 50%; transform: translateX(-50%)`.** The -11px offset hangs half the flag above the card edge, which is the "file-tab" signature. MUST NOT adjust to fully above or flush.
- **Max one flag per card.** Two flags stack awkwardly and dilute the signal.

**Anti-patterns:**
- Flag without Amarelo card border — the tab floats, loses its binding
- Lowercase or Title Case flag text — breaks the mono-tab aesthetic
- More than one flag per card — the signal is "read this one"; two flags contradict
- Flag on `.slide.accent` (Amarelo background) — the Amarelo flag disappears; swap the flag background to `var(--c-ink)` with white text, or pick a different primitive

---

## dual-sided-argument

**Purpose:** a two-column symmetric-benefit card. The eyebrow on top names the relationship ("Works both ways"), two columns show the same argument from two stakeholder perspectives. Use when a decision genuinely cuts the same way for both sides.

**When to use:**
- Clients + Company benefits (pricing change that serves both)
- Buyers + Sellers (marketplace decisions)
- Devs + Ops (platform choices)
- Present + Future (decision that compounds positively in both directions)

**When NOT to use:**
- When the benefits are asymmetric — forcing asymmetric content into symmetric columns creates false equivalence. Use a two-column layout with distinct eyebrows instead.
- When one side has three bullets and the other has one — the visual weight mismatch undermines the "both ways" claim
- For three or more stakeholders — the primitive is deliberately two-column. Three groups is a [`table.grid`](#tablegrid).
- As a generic two-column comparison — this is a specific rhetorical device, not a layout primitive

**HTML:**
```html
<div style="background: var(--c-card); border: 1px solid var(--c-rule); border-radius: 4px; padding: 14px 20px;">
  <div class="eyebrow" style="margin-bottom: 6px;">Works both ways</div>
  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
    <div>
      <div style="font-family: 'JetBrains Mono'; font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--c-ink-3); margin-bottom: 3px;">For clients</div>
      <div style="font-size: 16px; line-height: 1.35;">Enterprise-grade control without the ops burden.</div>
    </div>
    <div>
      <div style="font-family: 'JetBrains Mono'; font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--c-ink-3); margin-bottom: 3px;">For Lerian</div>
      <div style="font-size: 16px; line-height: 1.35;">BYOC = N infras, N configs, N upgrade paths. Cloud = one pipeline, one stack, one environment we own.</div>
    </div>
  </div>
</div>
```

**Composition rules:**

- **Eyebrow text names the relationship.** "Works both ways" is the reference default. Alternatives: "Cuts both ways," "Serves both sides," "Both sides win." MUST NOT use a generic label like "Benefits."
- **Sub-eyebrows name the two stakeholders.** "For clients" / "For Lerian" is the reference pattern. Sub-eyebrows are JetBrains Mono 11px `--c-ink-3` — smaller than the top eyebrow so the hierarchy reads as "one card, two sides."
- **Columns are `1fr 1fr`.** Equal real estate. MUST NOT skew to `1fr 1.2fr` — asymmetric widths undermine the symmetric-benefit claim.
- **Body text is 16px IBM Plex Serif.** This is below the 24px body floor — deliberate and documented, because this primitive is a supporting block inside a larger argument (strategic-discussion thesis column), not the primary content. Treat it as a chrome-density exception (see `layout-rules.md` Minimum Text Size).
- **Each side is one sentence or one short paragraph.** If one side needs three bullets, this isn't a dual-sided argument — it's an asymmetric comparison. Pick a different primitive.

**Anti-patterns:**
- Asymmetric content forced into symmetric columns — defeats the whole point
- Three or more columns — the primitive is two-column by construction
- Wordy copy (>2 lines per side) — the card grows too tall; either trim or promote to a full-slide layout
- Stakeholder labels in Title Case ("For Clients") — MUST be ALL CAPS mono to match eyebrow conventions

---

## inline-mini-legend

**Purpose:** legend dots embedded directly inside a caption sentence, using inline-block spans. Compresses a typical multi-line legend block into a single line of prose. Ideal for tiny charts (e.g., inline micro-charts in table cells) where a full legend block would outweigh the chart.

**When to use:**
- Paired with [`inline-micro-chart` in table cells](chart-primitives.md#inline-micro-chart) — the canonical pairing
- As a caption under a small `vertical-bar-chart` with 2 categories
- For 2–3 categories where a stacked legend block would dominate visual weight

**When NOT to use:**
- For 4+ categories — readability breaks. Use a stacked legend block (see `chart-primitives.md` → `stacked-horizontal-bar` legend pattern).
- When the chart is the slide's main content — a full legend with numeric values is clearer
- Inside body paragraphs — this is caption chrome, not prose

**HTML:**
```html
<div style="font-size: 14px; color: var(--c-ink-2);">
  All figures R$ thousands ·
  BYOC <span style="display: inline-block; width: 7px; height: 7px; border: 1.5px solid var(--c-ink); border-radius: 999px; margin: 0 3px -1px 3px; box-sizing: border-box;"></span>
  SaaS <span style="display: inline-block; width: 7px; height: 7px; background: var(--c-ink); border-radius: 999px; margin: 0 3px -1px 3px;"></span>
</div>
```

**Composition rules:**

- **Dots are 7×7px, `border-radius: 999px` (circles).** Square dots read as data points; circles read as legend markers.
- **Outline state: `border: 1.5px solid var(--c-ink)` with no background.** Use for the "empty/unfilled" category in a two-state split.
- **Filled state: `background: var(--c-ink)` with no border.** Use for the "full/filled" category. MUST NOT add a border on the filled state — visually doubles the weight.
- **Baseline alignment: `margin: 0 3px -1px 3px`.** The `-1px` bottom margin nudges the dot down so it sits on the text baseline. Without it, dots float above the line.
- **`box-sizing: border-box` REQUIRED on the outline state.** Without it, the 1.5px border adds to the 7px width, making outlined dots visually larger than filled ones. (Filled dots need no `box-sizing` because they have no border.)
- **Category name precedes the dot.** "BYOC ●" not "● BYOC" — the text anchors the dot semantically.
- **Categories separated by ` · `.** Mid-dot on spaces, not commas. Matches the eyebrow and meta-row cadence.

**Anti-patterns:**
- 4+ categories inline — unreadable prose. Use a stacked legend.
- Dot before label — flips reading order
- Filled dot with border + outlined dot without `box-sizing` — size mismatch breaks the pairing
- Using for a chart where segment sizes are the message — the inline legend has no numeric anchor; add `numeric %` or use a full legend

Pairs with: [`inline-micro-chart` in table cells](chart-primitives.md#inline-micro-chart) (typical pairing — mini-chart in cells, mini-legend in the caption below).

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
| dashed-hairline | yes | yes | needs `border-color: rgba(255,255,255,0.18)` dashed | **FORBIDDEN** — Amarelo eats the dash rhythm |
| narrative-arc | yes | yes | avoid — Amarelo pill on dark loses contrast; muted prose disappears | **FORBIDDEN** — pill + muted prose collapse |
| transition-column | yes | yes | yes (labels inherit `rgba(255,255,255,0.55)`) | avoid — arrow on Amarelo reads as chrome |
| org-node-flag | yes | yes | yes (flag Amarelo on dark card — strong contrast) | **FORBIDDEN** — Amarelo flag on Amarelo bg invisible |
| dual-sided-argument | yes | yes | needs `background: rgba(255,255,255,0.06)` and inverted rule color | avoid — light card on Amarelo loses the card boundary |
| inline-mini-legend | yes | yes | swap outline dot to `rgba(255,255,255,0.75)` border, filled dot to white | avoid — black dots on Amarelo read as noise |

**HARD GATE:** if the pairing table says "avoid" or "FORBIDDEN," the archetype MUST pick a different primitive or a different slide variant. Do not patch with inline color overrides.

## Related

- Tokens: [`design-tokens.md`](design-tokens.md)
- Canvas + flex discipline: [`layout-rules.md`](layout-rules.md)
- Archetype templates (what actually ships today): `../templates/slide-cover.html`, `../templates/slide-agenda.html`, `../templates/slide-act-divider.html`, `../templates/slide-content.html`, `../templates/slide-content-paper.html`, `../templates/slide-content-dark.html`, `../templates/slide-content-accent.html`, `../templates/slide-appendix-intro.html`, `../templates/slide-appendix-content.html`
