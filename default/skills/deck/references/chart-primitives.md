# Chart Primitives

Four chart types, all pure CSS/HTML — no Chart.js, no D3, no build step. Charts render identically in browser, PDF, and presenter preview.

**v1 scope:** four primitives cover ~80% of board/investor/conference deck needs.
**v2 candidate:** Chart.js opt-in for richer analytical slides (scatter plots, multi-series line charts, stacked vertical bars with annotations, radar, treemap).

**HARD GATE: Accessibility.** Every chart MUST declare `role="img"` and `aria-label="..."` on the chart container. The reference deck had zero accessibility annotations on its charts — that is the gap this doc closes. Color MUST NOT be the only signal; labels and numeric values MUST be visible on segments wherever space allows.

## Table of Contents

| # | Primitive | Typical use |
| --- | --- | --- |
| 1 | [stacked-horizontal-bar](#stacked-horizontal-bar) | Cap table, ownership, budget split |
| 2 | [vertical-bar-chart](#vertical-bar-chart) | Time-series: MRR, headcount, revenue |
| 3 | [2x2-matrix](#2x2-matrix) | Competitive map, strategic framework |
| 4 | [funnel](#funnel) | Pipeline, conversion stages |
| 4b | [funnel — monetary overlay](#funnel--monetary-overlay) | Extension of `funnel` showing monetary weight beneath the stages |
| 5 | [inline-micro-chart](#inline-micro-chart) | Per-row mini stacked bars inside table cells — period-over-period mix |

---

## stacked-horizontal-bar

**Purpose:** Render a single 100% bar split into proportional segments, paired with a legend table that shows each segment's label, color swatch, and exact percentage.

**When to use:**
- Cap table / ownership breakdown (the canonical use).
- Budget allocation — single period, multi-category.
- Revenue mix by product line (single snapshot).
- Any "shares of 100%" relationship with 4–8 segments.

**When NOT to use:**
- More than 8 segments — labels collide in the legend; merge the smallest into "Others".
- Segments smaller than 3% — visually unreadable in the bar; fold into "Others" or annotate with a leader line (complexity cost; avoid).
- Comparing two distributions side-by-side — use two bars or a grouped bar, NOT two independent stacked bars the audience has to eyeball-compare.
- Time series — this is a snapshot. For evolution, use vertical-bar-chart.

**Reference example:** Lerian board deck, slide 10 — Cap Table & ESOP. Extracted verbatim from `lerian-ppt-example.html` lines 1143–1168.

**HTML:**

```html
<div class="chart-stacked-hbar" role="img"
     aria-label="Cap table fully diluted: Fred Amaral 31.6%, Maya Capital 19.4%, Supera Capital 10.6%, Quartzo 8.6%, Norte Ventures 8.9%, Kevin Efrusy Accel 5.0%, ESOP granted 6.0%, Others 9.9%">

  <div class="eyebrow" style="margin-bottom: 20px;">Ownership · fully diluted</div>

  <!-- The bar -->
  <div class="bar">
    <div style="flex: 31.6; background: var(--c-ink);"></div>
    <div style="flex: 19.4; background: var(--c-accent-2);"></div>
    <div style="flex: 10.6; background: #737373;"></div>
    <div style="flex: 8.6;  background: #a3a3a3;"></div>
    <div style="flex: 8.9;  background: #d4d4d4;"></div>
    <div style="flex: 5.0;  background: #0E7490;"></div>
    <div style="flex: 6.0;  background: var(--c-accent); border: 2px solid var(--c-ink); box-sizing: border-box;"></div>
    <div style="flex: 9.9;  background: #f5f5f4;"></div>
  </div>

  <!-- Legend -->
  <div class="legend">
    <div class="row"><span><span class="sw" style="background: var(--c-ink);"></span>Fred Amaral</span><span class="num">31.6%</span></div>
    <div class="row"><span><span class="sw" style="background: var(--c-accent-2);"></span>Maya Capital</span><span class="num">19.4%</span></div>
    <div class="row"><span><span class="sw" style="background: #737373;"></span>Supera Capital</span><span class="num">10.6%</span></div>
    <div class="row"><span><span class="sw" style="background: #a3a3a3;"></span>Norte Ventures</span><span class="num">8.9%</span></div>
    <div class="row"><span><span class="sw" style="background: #d4d4d4;"></span>Quartzo</span><span class="num">8.6%</span></div>
    <div class="row"><span><span class="sw" style="background: #0E7490;"></span>Kevin Efrusy · Accel</span><span class="num">5.0%</span></div>
    <div class="row"><span><span class="sw" style="background: var(--c-accent); border: 1px solid var(--c-ink);"></span><strong>ESOP granted</strong></span><span class="num">6.0%</span></div>
    <div class="row muted"><span><span class="sw" style="background: #f5f5f4; border: 1px solid var(--c-rule);"></span>Others</span><span class="num">9.9%</span></div>
  </div>
</div>
```

**CSS:**

```css
.chart-stacked-hbar { display: flex; flex-direction: column; }

.chart-stacked-hbar .bar {
  display: flex;
  width: 100%;
  height: 64px;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 28px;
}

.chart-stacked-hbar .legend {
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 20px;
  flex: 1;
  justify-content: space-between;
}
.chart-stacked-hbar .legend .row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid var(--c-rule);
}
.chart-stacked-hbar .legend .row:last-child { border-bottom: none; }
.chart-stacked-hbar .legend .row.muted { color: var(--c-ink-3); }
.chart-stacked-hbar .legend .row.muted .num { color: var(--c-ink-3); }

.chart-stacked-hbar .sw {
  display: inline-block;
  width: 14px; height: 14px;
  margin-right: 12px;
  vertical-align: middle;
}
.chart-stacked-hbar .num {
  font-family: 'JetBrains Mono', monospace;
  color: var(--c-ink);
}
```

**Design calls:**
- **No in-bar labels.** The reference puts labels in the legend below, not inside the segments. Rationale: at 8 segments, most segments are too narrow (<10% of 1920px-ish width) for readable Poppins-20px text. Legend pattern is canonical; segment-label pattern is v2 territory.
- **Segment color ramp.** The reference uses a grayscale ramp (`#191A1B → #d4d4d4 → #f5f5f4`) for stakeholder rank, plus two accent segments (`--c-accent-2` Verde for the top external investor, `--c-accent` Amarelo-with-border for the ESOP highlight). Followers of the archetype SHOULD keep this pattern: grayscale for default segments, Amarelo + Preto border for the one segment the slide is about.

**Accessibility:**
- `role="img"` + `aria-label` listing every segment with its percentage — this is the HARD GATE.
- Legend duplicates color as text + numeric percentage — audiences who can't distinguish the grayscale ramp still read the table.

**Anti-patterns:**
- More than 8 segments — labels collide in the legend row padding. Fold smaller segments into "Others".
- Segments < 3% width — visually ambiguous; merge or annotate.
- Missing `aria-label` — fails accessibility gate.
- Hard-coded percentages in pixels instead of `flex:` values — breaks if canvas resizes for print-export.
- Using color alone to distinguish segments (no numeric label, no legend) — fails WCAG 1.4.1.

---

## vertical-bar-chart

**Purpose:** Time-series bars over an ordered category axis (months, quarters, years). One bar per period, height proportional to value, with the latest/highlighted bar in `--c-accent`.

**When to use:**
- MRR / ARR / revenue evolution.
- Headcount growth over time.
- Any monthly/quarterly metric where "trajectory" is the message.

**When NOT to use:**
- More than ~8 bars on 1920×1080 — bars get skinny; switch to a line chart (v2 Chart.js territory).
- Multi-series comparison — this is single-series only. v2 handles grouped/stacked vertical.
- Negative values — no zero line; all bars grow from the baseline up. For mixed pos/neg, use a table.
- Non-ordered categories — a bar chart implies sequence. For category comparison, use a table with a bar-in-cell pattern.

**Reference example:** Lerian board deck, slide 8 — Financial KPIs (MRR evolution, dark variant). Extracted from lines 985–1020.

**HTML:**

```html
<div class="chart-vbar" role="img"
     aria-label="MRR evolution in thousands of reais per month: May 2025 R$30K, Aug 2025 R$65K, Oct 2025 R$90K, Jan 2026 R$167K, Mar 2026 R$207K">

  <div class="eyebrow" style="color: rgba(255,255,255,0.55); margin-bottom: 8px;">MRR evolution · R$ thousand / month</div>
  <div class="caption">R$ 30K &nbsp;·&nbsp; May 25 &nbsp; → &nbsp; R$ 207K &nbsp;·&nbsp; Mar 26</div>

  <div class="bars">
    <div class="bar"><div class="v">30</div>  <div class="fill" style="height: 14%;"></div></div>
    <div class="bar"><div class="v">65</div>  <div class="fill" style="height: 31%;"></div></div>
    <div class="bar"><div class="v">90</div>  <div class="fill" style="height: 43%;"></div></div>
    <div class="bar"><div class="v">167</div> <div class="fill" style="height: 81%;"></div></div>
    <div class="bar highlight"><div class="v">207</div><div class="fill" style="height: 100%;"></div></div>
  </div>

  <div class="axis">
    <div>May 25</div><div>Aug 25</div><div>Oct 25</div><div>Jan 26</div><div>Mar 26</div>
  </div>
</div>
```

**CSS:**

```css
.chart-vbar { display: flex; flex-direction: column; }

.chart-vbar .caption {
  color: var(--c-ink-inv);
  font-size: 22px;
  margin-bottom: 28px;
}

.chart-vbar .bars {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(5, 1fr);       /* match column count to bar count */
  gap: 18px;
  align-items: end;
  padding-bottom: 60px;
  position: relative;
  border-bottom: 1px solid rgba(255,255,255,0.18);
}

.chart-vbar .bar {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-end;
  height: 100%;
}
.chart-vbar .bar .v {
  font-family: 'JetBrains Mono', monospace;
  font-size: 20px;
  color: var(--c-ink-inv);
  margin-bottom: 12px;
}
.chart-vbar .bar .fill {
  width: 100%;
  background: rgba(255,255,255,0.85);
  border-radius: 2px 2px 0 0;
}
.chart-vbar .bar.highlight .fill { background: var(--c-accent); }

.chart-vbar .axis {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 18px;
  padding-top: 14px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 18px;
  color: rgba(255,255,255,0.55);
  text-align: center;
}

/* Light-variant override: chart on .slide (not .slide.dark) */
.slide:not(.dark) .chart-vbar .bars { border-bottom-color: var(--c-rule); }
.slide:not(.dark) .chart-vbar .bar .fill { background: var(--c-ink); }
.slide:not(.dark) .chart-vbar .bar .v { color: var(--c-ink); }
.slide:not(.dark) .chart-vbar .axis { color: var(--c-ink-3); }
.slide:not(.dark) .chart-vbar .caption { color: var(--c-ink); }
```

**Design calls:**
- **Percentage heights set manually in inline `style`.** Author computes `height = (value / max) * 100%` by hand — no JS. This is the chart-primitives contract: zero computation at render time.
- **Highlight-last-bar convention.** The rightmost (or current-period) bar uses `--c-accent` by default to signal "this is where we are now." Override by moving `.highlight` to any bar that carries the slide's message.
- **Dark variant is default in the reference** because slide 8 is a `.slide.dark` KPI wall. The CSS above includes a light-variant override so the primitive works on both `.slide` and `.slide.dark`.

**Accessibility:**
- `role="img"` + `aria-label` listing every period and value.
- Numeric value visible above each bar (`.v`) — audiences do not need to estimate heights.
- Month labels below — no decoding of bar position required.

**Anti-patterns:**
- More than 8 bars — switch to line chart (v2).
- Bars without numeric labels — audiences squint to estimate; defeats the editorial floor (24px body text principle).
- Grid column count not matching bar count — axis labels misalign. `grid-template-columns: repeat(N, 1fr)` MUST be duplicated on `.bars` and `.axis` with the same N.
- Using `.slide.accent` (Amarelo background) — chart readability collapses. See "Using charts inside archetypes" below.

---

## 2x2-matrix

**Purpose:** Position entities on a two-axis strategic map to show competitive/strategic relationships. Classic consulting framework (BCG matrix, Ansoff, etc.), adapted to editorial visuals.

**When to use:**
- Competitive positioning (you vs. competitors on two dimensions).
- Strategic framework (effort vs. impact, risk vs. reward).
- Portfolio segmentation (stars/dogs/cash-cows/question-marks).

**When NOT to use:**
- More than ~6 entities on the matrix — label collision becomes a visual mess.
- Axes that aren't genuinely 2-dimensional — if one axis is a function of the other, it's a scatter plot, not a matrix.
- Numeric positioning — this is a qualitative framework. Audiences read "upper-right" / "lower-left", not `(0.82, 0.82)`. If numbers matter, use a table.
- When you don't know where competitors sit — do the homework first; a matrix with shaky positioning is worse than no matrix.

**Reference example:** Lerian board deck, slide 7 — Competitive Positioning. Extracted from lines 848–886.

**HTML:**

```html
<div class="chart-2x2" role="img"
     aria-label="Competitive positioning on composability (y-axis) and deployment flexibility (x-axis): Thought Machine low-low, Mambu low-low, Matera middle, Lerian high-high">

  <!-- Y-axis label (rotated) -->
  <div class="y-axis">Composability →</div>
  <!-- X-axis label -->
  <div class="x-axis">Deployment flexibility →</div>

  <!-- Plot area -->
  <div class="plot">
    <!-- Quadrant grid lines -->
    <div class="v-rule"></div>
    <div class="h-rule"></div>

    <!-- Entities — positions set manually via inline style (left: X%, bottom: Y%) -->
    <div class="entity" style="left: 12%; bottom: 18%;">
      <div class="dot"></div>
      <div class="name">Thought Machine</div>
      <div class="meta">1 product · SaaS only</div>
    </div>
    <div class="entity" style="left: 22%; bottom: 28%;">
      <div class="dot"></div>
      <div class="name">Mambu</div>
      <div class="meta">1 product · SaaS only</div>
    </div>
    <div class="entity" style="left: 55%; bottom: 38%;">
      <div class="dot"></div>
      <div class="name">Matera</div>
      <div class="meta">Monolithic · SaaS + BYOC</div>
    </div>
    <div class="entity highlight" style="left: 82%; bottom: 82%;">
      <div class="dot"></div>
      <div class="name">Lerian</div>
      <div class="meta strong">8 primitives + plugins</div>
      <div class="meta">BYOC · SaaS · Cloud</div>
    </div>
  </div>
</div>
```

**CSS:**

```css
.chart-2x2 {
  position: relative;
  padding: 0 0 60px 60px;
  display: flex;
  flex-direction: column;
}

.chart-2x2 .y-axis {
  position: absolute;
  left: 0; top: 50%;
  transform: translateY(-50%) rotate(-90deg);
  transform-origin: left center;
  font-family: 'JetBrains Mono', monospace;
  font-size: 16px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--c-ink-3);
  white-space: nowrap;
}
.chart-2x2 .x-axis {
  position: absolute;
  left: 60px; right: 0; bottom: 0;
  text-align: center;
  font-family: 'JetBrains Mono', monospace;
  font-size: 16px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--c-ink-3);
}

.chart-2x2 .plot {
  position: relative;
  flex: 1;
  min-height: 440px;
  border-left: 1px solid var(--c-ink);
  border-bottom: 1px solid var(--c-ink);
}
.chart-2x2 .v-rule {
  position: absolute;
  left: 50%; top: 0; bottom: 0;
  border-left: 1px dashed var(--c-rule);
}
.chart-2x2 .h-rule {
  position: absolute;
  left: 0; right: 0; top: 50%;
  border-top: 1px dashed var(--c-rule);
}

.chart-2x2 .entity {
  position: absolute;
  transform: translate(-50%, 50%);     /* dot centered on (left, bottom) coords */
}
.chart-2x2 .entity .dot {
  width: 20px; height: 20px;
  background: var(--c-ink-3);
  border-radius: 999px;
}
.chart-2x2 .entity .name {
  font-family: 'Poppins', sans-serif;
  font-weight: 500;
  font-size: 22px;
  margin-top: 8px;
  white-space: nowrap;
}
.chart-2x2 .entity .meta {
  font-size: 16px;
  color: var(--c-ink-3);
}
.chart-2x2 .entity .meta.strong {
  color: var(--c-ink);
  font-weight: 500;
  font-size: 18px;
}

.chart-2x2 .entity.highlight .dot {
  width: 36px; height: 36px;
  background: var(--c-accent);
  border: 3px solid var(--c-ink);
}
.chart-2x2 .entity.highlight .name {
  font-weight: 600;
  font-size: 28px;
  margin-top: 10px;
}
```

**Design calls:**
- **Inline `left`/`bottom` percentages for positioning.** Authors place entities manually — this is declarative, deterministic, and doesn't require a JS pass. Percentages are relative to the `.plot` box (`position: relative`).
- **Coordinate convention.** `left: X%` = distance from left edge (0% = far left, 100% = far right). `bottom: Y%` = distance from bottom edge (0% = bottom axis, 100% = top). The CSS translates `(-50%, 50%)` so the dot center sits exactly on the declared coords.
- **Dashed quadrant lines over solid axes.** The outer L-shape (`border-left` + `border-bottom` on `.plot`) is solid — that's the axes. The inner `+` cross is dashed — that's the quadrant divider. This hierarchy is intentional: axes are chart structure, quadrants are annotation.
- **Highlight styling for "you".** The entity the slide is about gets `.highlight` — bigger dot, Amarelo fill with Preto border, larger name. Everyone else is muted gray. This is the editorial voice — the matrix exists to frame a single claim.
- **Label placement.** Labels sit below-right of the dot (natural reading order). When two entities are close together, authors MUST manually nudge `left`/`bottom` by a few percent to avoid overlap. There is no auto-layout.

**Accessibility:**
- `role="img"` + `aria-label` with every entity and its rough quadrant ("low-low", "upper-right", etc.).
- Axis labels are text (not graphic) — screen readers read them.
- Dot color is not the only signal: labels and `.meta` sit alongside.

**Anti-patterns:**
- Overlapping labels — nudge positions manually; if they still collide, you have too many entities. Cut.
- Axes without labels ("Composability" / "Deployment flexibility" in the reference) — an unlabeled 2x2 is indecipherable. Labels are MANDATORY.
- Numeric axis ticks on a qualitative matrix — implies precision the framework doesn't have. Keep axes text-only with an arrow (`→`).
- Positioning Lerian at exactly `(100%, 100%)` — dot gets clipped by the plot border. Keep all entities within 10–90% range.
- Missing quadrant dashed lines — audiences can't parse "upper-right" without the divider cross.

---

## funnel

**Purpose:** Show stages of a pipeline or conversion with decreasing counts from left to right. Each stage is a labeled cell with its count; later stages can use a `--c-accent` or dark background to mark commitment.

**When to use:**
- Sales pipeline (Hunting → SAL → SQL → Negotiation → Proposal → Signed).
- Hiring funnel (Applied → Screened → Interviewed → Offer → Hired).
- Conversion funnel (Visitor → Signup → Activated → Paid).
- Any ordered reduction where absolute counts matter more than conversion rates.

**When NOT to use:**
- When conversion rates between stages are the message — use a table with stage-to-stage conversion percentages instead, or a Sankey diagram (v2).
- When stages are weighted by revenue, not count — the equal-column-width layout misleads. Use a table with a revenue column, OR scale the column `flex` by dollar value.
- More than 7 stages — cells shrink below the 24px type floor. Collapse adjacent early-funnel stages.
- Unordered categories — a funnel implies sequence. Don't use it for a segmentation.

**Reference example:** Lerian board deck, slide 6 — Active Pipeline (full funnel). Extracted from lines 737–763.

**HTML:**

```html
<div class="chart-funnel" role="img"
     aria-label="Sales pipeline: Hunting 42, SAL 28, SQL 15, Negotiation 8, Proposal 4, Contract Signed this month 2">

  <div class="stages">
    <div class="stage">
      <div class="label">Hunting</div>
      <div class="count">42</div>
    </div>
    <div class="stage">
      <div class="label">SAL</div>
      <div class="count">28</div>
    </div>
    <div class="stage">
      <div class="label">SQL</div>
      <div class="count">15</div>
    </div>
    <div class="stage warm">
      <div class="label">Negotiation</div>
      <div class="count strong">8</div>
    </div>
    <div class="stage warm">
      <div class="label">Proposal</div>
      <div class="count strong">4</div>
    </div>
    <div class="stage hot">
      <div class="label">Contract signed this month</div>
      <div class="count strong">2</div>
    </div>
  </div>
</div>
```

**CSS:**

```css
.chart-funnel .stages {
  display: grid;
  grid-template-columns: repeat(6, 1fr);        /* one column per stage */
  gap: 0;
  border-top: 1px solid var(--c-ink);
  border-bottom: 1px solid var(--c-ink);
}

.chart-funnel .stage {
  padding: 44px 28px;
  border-right: 1px solid var(--c-rule);
}
.chart-funnel .stage:last-child { border-right: none; }

.chart-funnel .stage .label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;                              /* chrome — below 24px floor is OK per layout-rules */
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--c-ink-3);
}
.chart-funnel .stage .count {
  font-family: 'Poppins', sans-serif;
  font-size: 72px;
  font-weight: 500;
  letter-spacing: -0.02em;
  margin-top: 14px;
  font-variant-numeric: tabular-nums;
}
.chart-funnel .stage .count.strong { font-weight: 600; }

/* Stage temperature — warm = near-close, hot = signed */
.chart-funnel .stage.warm { background: #F0EFE9; }
.chart-funnel .stage.hot {
  background: var(--c-ink);
  color: var(--c-ink-inv);
}
.chart-funnel .stage.hot .label { color: var(--c-accent); }
```

**Design calls:**
- **Equal-width columns, not decreasing trapezoids.** The reference uses a `repeat(6, 1fr)` grid — every stage gets the same horizontal real estate. Rationale: the editorial reading is the *number* in each stage, not the *shape* of the funnel. A true narrowing-trapezoid funnel is a classic chart library feature (v2 Chart.js) and adds no information the numbers don't already carry. The grid-strip is cleaner and legible at projection distance.
- **Temperature progression.** Early stages are default chrome (white bg, gray label). Middle stages (`.warm`) get a warm-paper tint (`#F0EFE9`) to signal "close to close." The final stage (`.hot`) inverts to Preto + Amarelo label — this is the slide's payoff. Authors override the cutoff per deck.
- **Labels at 12px mono, counts at 72px Poppins.** This violates the 24px body-floor from `layout-rules.md` — deliberate and documented: mono chrome labels are allowed below 24px (see layout-rules "Minimum Text Size" exceptions). The count is the content; the label is chrome.

**Accessibility:**
- `role="img"` + `aria-label` listing every stage and count in order — critical because the visual reduction isn't conveyed by labels alone.
- Counts are text (not graphic) — screen readers read them.
- Color (`.warm`, `.hot`) is not the only signal: labels + counts still carry the meaning.

**Anti-patterns:**
- More than 7 stages — cells shrink, counts wrap. Collapse.
- Counts that increase left-to-right — this is not a funnel. If the metric genuinely grows through stages, use `vertical-bar-chart` instead.
- Missing stage labels — a row of numbers is not a funnel, it's a number parade.
- Using `.hot` styling on a non-final stage — breaks the temperature metaphor. Audiences expect the darkest cell at the far right.

---

## funnel — monetary overlay

**Purpose:** extend the base [`funnel`](#funnel) with an overlay banner at the bottom of the stages strip showing monetary weight per zone. Turns a procedural funnel (stage counts) into a financial one (qualified ARR, closed revenue). The temperature progression in the base funnel stays — this overlay adds dollar anchors.

**When to use:**
- Pipeline slides where both *count* and *dollar weight* matter — "42 prospects, but the 12 qualified are R$ 8M of ARR"
- Revenue-forecast decks where the funnel doubles as a capital-allocation argument
- Board-facing pipelines where the count-only funnel would understate the real signal

**When NOT to use:**
- When monetary weight is the *only* message — use a table, not a funnel with overlay. The overlay complements; it doesn't replace.
- When the funnel already has temperature stages (`.warm`, `.hot`) AND an accent banner above — three stacked signals is overload. Pick two.
- For hiring or conversion funnels where dollars don't apply

**HTML (overlay portion — parent `.chart-funnel` MUST be `position: relative`):**
```html
<div class="chart-funnel" style="position: relative;" role="img"
     aria-label="Sales pipeline with monetary overlay. Potential ARR ~R$ 60M, Qualified ARR R$ 8.12M, Closed tracked separately.">

  <!-- base funnel stages (from funnel primitive) -->
  <div class="stages"> … </div>

  <!-- monetary overlay banner -->
  <div style="position: absolute; left: 0; right: 0; bottom: 0; display: grid; grid-template-columns: 3fr 2fr 1fr; pointer-events: none;">
    <div style="border-right: 3px solid var(--c-ink); padding: 10px 28px 12px; display: flex; align-items: baseline; gap: 14px; background: color-mix(in oklab, var(--c-accent) 40%, white); color: var(--c-ink);">
      <div style="font-family: 'JetBrains Mono'; font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--c-ink-2);">Potential ARR</div>
      <div style="font-family: 'Poppins'; font-size: 22px; font-weight: 700; font-variant-numeric: tabular-nums; letter-spacing: -0.01em;">~ R$ 60M</div>
    </div>
    <div style="padding: 10px 28px 12px; display: flex; align-items: baseline; gap: 14px; background: var(--c-accent); color: var(--c-accent-ink);">
      <div style="font-family: 'JetBrains Mono'; font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase;">Qualified ARR</div>
      <div style="font-family: 'Poppins'; font-size: 22px; font-weight: 700; font-variant-numeric: tabular-nums; letter-spacing: -0.01em;">R$ 8.12M</div>
    </div>
    <div style="padding: 10px 28px 12px; background: var(--c-ink); color: var(--c-ink-inv); display: flex; align-items: baseline; gap: 14px;">
      <div style="font-family: 'JetBrains Mono'; font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--c-accent);">Closed</div>
    </div>
  </div>
</div>
```

**Design calls:**

- **Three-zone temperature, color-coded by qualification:**

  | Zone | Background | Text | Signals |
  | --- | --- | --- | --- |
  | Potential / unqualified | `color-mix(in oklab, var(--c-accent) 40%, white)` (pale Amarelo) | `var(--c-ink)` | "Could be revenue, not yet committed" |
  | Qualified | `var(--c-accent)` on `var(--c-accent-ink)` | `var(--c-ink)` | "Committed — real probability" |
  | Closed | `var(--c-ink)` on `var(--c-ink-inv)` with Amarelo eyebrow | white | "Already revenue" |

- **Color-mix for the pale banner.** Use `color-mix(in oklab, var(--c-accent) 40%, white)` — see [`design-tokens.md` → Derived Tints](design-tokens.md#derived-tints--color-mix-technique). MUST NOT use a hardcoded hex like `#FFF7A0`. OKlab keeps the Amarelo hue true in the mix.
- **Grid ratios reflect monetary weighting, not stage count.** `grid-template-columns: 3fr 2fr 1fr` is the reference — potential is the biggest zone because the unqualified pipeline is the largest dollar bucket, qualified is middle, closed is narrowest. MUST NOT use `1fr 1fr 1fr` — equal columns erase the signal.
- **Thicker divider between qualified and closed.** `border-right: 3px solid var(--c-ink)` on the middle (qualified) cell. This visually separates committed from closed — the boundary that matters for the board. The divider between potential and qualified is the cells' own background contrast; no extra border needed.
- **`pointer-events: none`** on the overlay — the overlay sits on top of the funnel cells visually, but the funnel is not interactive anyway (deck is projection chrome). The attribute prevents accidental text-selection weirdness in browsers during presentation.
- **Eyebrow inside the Closed zone is Amarelo on ink.** The only Amarelo on the dark zone — reads as a callout on the darkest background.

**Accessibility:**
- `aria-label` on the parent `.chart-funnel` MUST describe both the count funnel AND the monetary zones. Example: "Sales pipeline. Stages: Hunting 42, SAL 28, SQL 15. Monetary: Potential ARR ~R$ 60M, Qualified ARR R$ 8.12M, Closed tracked separately."
- Numeric values are text, not graphic — screen readers read them.
- Color is not the only signal — each zone has an UPPERCASE mono label AND a Poppins numeric value.

**Anti-patterns:**
- Equal grid columns (`1fr 1fr 1fr`) — erases the monetary-weight signal
- Same color on all three zones — defeats the qualification temperature
- Adding a fourth zone — the mental model is three (potential / qualified / closed). Four zones demands a different primitive.
- Inline hex instead of `color-mix()` for the pale banner — creates a drift-prone tint. Derive it.
- Overlay on a base funnel that already uses `.warm` and `.hot` temperature stages — three stacked signals is overload. Either use the base temperature OR the monetary overlay, not both.

Pairs with: [`color-mix()` technique](design-tokens.md#derived-tints--color-mix-technique) for the pale banner; [`--c-bg-warm`](design-tokens.md#surfaces) is an alternative hardcoded surface when a single-use tint doesn't justify the mix.

---

## inline-micro-chart

**Purpose:** per-row mini stacked bars inside table cells. A 2-segment vertical bar at 18px tall, wrapped N times across a `<td>` that spans the data columns of a `table.grid`. Use for period-over-period mix changes (monthly BYOC/SaaS split, quarterly product mix) where a full `stacked-horizontal-bar` chart would be overkill and a numeric-only row doesn't show the trend.

**When to use:**
- Inside a 12-month revenue table showing "% Mix" per month as tiny 2-segment bars
- Inside a quarterly product-mix table showing segment evolution
- As a caption-row under a numeric table, summarizing the mix the numbers describe
- When the reader benefits from *seeing the shift* without reading the percentages

**When NOT to use:**
- For more than 2 segments per bar — use a full [`stacked-horizontal-bar`](#stacked-horizontal-bar) chart. Three segments in 18px of height is unreadable.
- When absolute values (not percentages) are the story — the bars visualize share, not magnitude
- Inside cells — labels at 10–12px inside 18px of height is illegible. Use an [`inline-mini-legend`](ui-primitives.md#inline-mini-legend) below the table instead.
- Without a border on the bar — empty/near-zero segments disappear into the cell background

**HTML (one cell — single 2-segment mini-bar):**
```html
<div style="display: flex; flex-direction: column; height: 18px; border: 1px solid var(--c-ink);">
  <div style="flex: 70.1; background: transparent;"></div>
  <div style="flex: 29.9; background: var(--c-ink);"></div>
</div>
```

**Composition — N mini-bars inside a single `<td>` that spans the data columns:**
```html
<tr>
  <td>% Mix</td>
  <td colspan="12">
    <div style="display: grid; grid-template-columns: repeat(12, 1fr); gap: 3px;">
      <!-- Jan -->
      <div style="display: flex; flex-direction: column; height: 18px; border: 1px solid var(--c-ink);">
        <div style="flex: 70.1; background: transparent;"></div>
        <div style="flex: 29.9; background: var(--c-ink);"></div>
      </div>
      <!-- Feb -->
      <div style="display: flex; flex-direction: column; height: 18px; border: 1px solid var(--c-ink);">
        <div style="flex: 62.4; background: transparent;"></div>
        <div style="flex: 37.6; background: var(--c-ink);"></div>
      </div>
      <!-- … continue for each period -->
    </div>
  </td>
</tr>
```

**Design calls:**

- **Fixed 18px height.** MUST NOT grow or shrink — this is the editorial scale for in-cell chart chrome. Taller breaks the row rhythm; shorter collapses the segments.
- **`border: 1px solid var(--c-ink)` is REQUIRED.** The border frames the bar so the empty (transparent) segment remains readable even when its share is small. Without the border, a near-100% filled bar looks like a solid cell with no chart at all.
- **Two segments maximum.** Top segment defaults to `background: transparent` (the "outline / empty / first category" state), bottom to `background: var(--c-ink)` (filled / second category). More segments fail at this scale — promote to a real chart.
- **`flex:` values sum to 100.** Same pattern as [`stacked-horizontal-bar`](#stacked-horizontal-bar) — percentages go on `flex`, not on pixel widths. Lets the grid resize cleanly.
- **Parent grid: `display: grid; grid-template-columns: repeat(N, 1fr); gap: 3px;`.** The 3px gap gives each period its own visual lane without crowding.
- **No in-cell labels.** At 18px of height, any text becomes chrome noise. Pair with an [`inline-mini-legend`](ui-primitives.md#inline-mini-legend) below the table.

**Accessibility:**
- The parent `table.grid` carries the aria-label on the `<table>` or via a visible caption. Example caption: "Monthly revenue mix: BYOC (outlined) vs SaaS (filled). Jan 70/30, Feb 62/38, …"
- The micro-chart row does NOT need its own `role="img"` — it's a data visualization inside a semantic table; screen readers read the surrounding `<th>` + `<td>` structure. Add `aria-hidden="true"` to the mini-bars if the caption already enumerates the data.
- Legend MUST appear (as [`inline-mini-legend`](ui-primitives.md#inline-mini-legend)) within the same visual block — color-only signal fails WCAG 1.4.1.

**Anti-patterns:**
- More than 2 segments — unreadable at 18px; use a real chart
- Labels inside the bars — too small; use a caption legend below
- Bars without a border — empty/near-zero segments disappear
- Variable heights across the row — breaks row rhythm; fix at 18px
- Using for absolute-value comparison — this primitive shows *share*, not *magnitude*. If magnitude matters, the row above (numeric values) carries it.

Pairs with: [`inline-mini-legend`](ui-primitives.md#inline-mini-legend) (typical pairing — micro-chart row + mini-legend caption, one visual unit).

---

## Using charts inside archetypes

- **`slide-content`** and **`slide-content-paper`** are the default home for charts. Light backgrounds, clear axes, full color contrast.
- **`slide-content-dark`** — charts work and have explicit light-on-dark variants documented above (`vertical-bar-chart` ships dark-first; other primitives include `.slide.dark` overrides in archetype CSS). When authoring dark-variant charts:
  - Text: `--c-ink-inv` (white).
  - Bars/segments: `rgba(255,255,255,0.85)` default, `--c-accent` (Amarelo) for highlight.
  - Rules/axes: `rgba(255,255,255,0.18)`.
- **`slide-content-accent`** (Amarelo background) — charts MUST NOT be placed here. Amarelo backgrounds are for headline statements only; the accent color is the chart's highlight signal, and placing a chart on Amarelo collapses the highlight contrast.
- **Max one chart per slide.** Multiple charts = split into multiple slides. The editorial rhythm is "one idea per slide" — two charts means two ideas means two slides.
- **Charts consume `.body`'s flex.** Every chart primitive's outer container is `display: flex; flex-direction: column; flex: 1; min-height: 0;` when placed as the main body element. Follow `layout-rules.md` — the chart expands into the canvas, chrome (meta bar, footer) pins.

## Future work (v2)

- **Chart.js opt-in** — for scatter, multi-series line, stacked vertical with annotations, radar, treemap. Loaded via `package.json.tmpl` dependency and a `chart-js.html` partial. All opt-in; v1 primitives remain the default.
- **Responsive chart sizing** — current primitives are tuned to the 1920×1080 fixed canvas. If the deck runtime adds a responsive mode (16:9 aspect-fit to viewport), font sizes and gaps MUST scale with `clamp()` or an archetype-level CSS var.
- **Animation on slide-enter** — staggered bar grow-in, funnel stage cascade, matrix dot fade-in. Triggered by a `deck-stage` slide-change event; out of v1 scope because PDF export ignores transitions anyway.
- **Leader-line labels** — for stacked-horizontal-bar segments that need in-bar labels at <3% widths. Adds SVG complexity; deferred.
- **Grouped vertical bars** — side-by-side comparison (e.g., BYOC vs. PaaS per month). Currently handled by splitting into two slides or by the secondary KPI row below the primary chart (see reference slide 8 lines 1022–1031 for the split-below-chart pattern).
