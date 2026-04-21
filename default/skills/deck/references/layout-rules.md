# Layout Rules — Editorial Deck Discipline

**HARD GATE.** Every archetype, every slide, every card MUST obey these rules. Violations surface visually on the 1920×1080 canvas — cramped tiles, scrollbars, orphaned footers, ragged type. No rationalization clears a violation; the canvas is the referee.

## Vertical-Canvas Rule

Every slide is exactly **1920×1080 pixels**. No scrolling. No overflow. No wasted space.

```css
deck-stage > section {
  width: 1920px;
  height: 1080px;
  display: flex;
  flex-direction: column;
  position: relative;
}
.slide {
  padding: 64px var(--pad-x) 48px;
  height: 1080px;
  box-sizing: border-box;
  overflow: hidden;
}
```

- `overflow: hidden` is REQUIRED — a scrollbar on the projected canvas is a bug.
- `height: 1080px` is REQUIRED — not `min-height`, not `100vh`. Fixed.
- Content fills the canvas between meta bar and footer via flex. See below.

## Flex Pattern — Body Expands, Chrome Pins

The meta bar at top and footer at bottom are fixed-height. The body between them flexes.

```css
.slide {
  display: flex;
  flex-direction: column;
}
.body {
  flex: 1;                /* expand into available vertical space */
  display: flex;
  flex-direction: column;
  padding-top: 32px;
  padding-bottom: 20px;
  min-height: 0;          /* REQUIRED — allows children to shrink */
  overflow: hidden;
}
.footer { flex-shrink: 0; } /* pin to bottom, never compress */
```

**Good — body stretches:**

```html
<section class="slide">
  <div class="meta"> … </div>
  <div class="body">
    <div class="eyebrow">Portfolio</div>
    <h1>Complete portfolio for core banking.</h1>
    <div style="flex: 1; display: flex; align-items: stretch;">
      <!-- content grid that consumes all remaining vertical space -->
    </div>
  </div>
  <div class="footer"> … </div>
</section>
```

**Bad — body leaves dead space:**

```html
<!-- MISSING flex:1 on .body → content clings to top, bottom is white void -->
<section class="slide">
  <div class="meta"> … </div>
  <div class="body">
    <h1>Something</h1>
    <p>Two bullets.</p>
  </div>
  <div class="footer"> … </div>
</section>
```

## Main Content Grids

Use `flex: 1; min-height: 0` on the primary grid so it inherits the `.body` stretch.

```css
.body > .grid {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 36px;
  align-items: stretch;     /* columns match tallest sibling */
}
```

Row stacks distribute remaining space with `justify-content: space-between`:

```css
.body > .stack {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;  /* spread rows across vertical axis */
}
```

## Fixed-Height Cards — FORBIDDEN

Content decides card height. The canvas adapts to content, not the other way around.

**FORBIDDEN:**

```css
.card { height: 360px; }                         /* hard-coded */
.kpi  { min-height: 280px; }                     /* faux-dynamic */
.row  { height: calc(100% / 3); }                /* evenly-split by fiat */
```

**REQUIRED:**

```css
.card { display: flex; flex-direction: column; gap: 14px; }   /* content-sized */
.grid { align-items: stretch; }                               /* siblings match */
```

If a card looks cramped, **the content is wrong, not the card.** Rewrite the content. Split the slide. Do not force height.

## Table Padding

Tables are first-class editorial surfaces. Generous breathing room REQUIRED.

| Density | Row padding | Font size |
| --- | --- | --- |
| Default | `18px 20px` | `var(--t-small)` (22px) |
| Compact | `10px 16px` | 22px |
| Compact-tight | `7px 14px` | 18px |

```css
table.grid th, table.grid td {
  text-align: left;
  padding: 18px 20px;
  border-top: 1px solid var(--c-rule);
  vertical-align: top;
  color: var(--c-ink-2);
}
```

Row padding **MUST** fall in `14–20px` for default density. Anything tighter reads as web-UI, not editorial. Anything looser blows the slide height budget.

## Hero Numbers

When a slide's job is "here is one number," give the number the real estate.

| Context | Range | Example |
| --- | --- | --- |
| KPI tile value | 72–120px | `5.4M ARR` in a 4-tile row |
| Full-slide single number | 180–240px | Act divider ("01"), cover statistic |
| Inline display number | 120–150px | `--t-display`, 3-column breakdown |

```css
.kpi .value {
  font-family: 'Poppins', sans-serif;
  font-weight: 500;
  font-size: 96px;
  line-height: 0.95;
  letter-spacing: -0.03em;
}
```

MUST NOT shrink hero numbers to fit a caption. Shrink the caption.

## Dynamic Pagination

**HARD GATE: No hardcoded slide counts.** The total is computed at runtime from `<section>` count.

```javascript
// In the deck runtime (assets/deck-stage.js):
const sections = document.querySelectorAll('deck-stage > section');
const total = sections.length;
sections.forEach((section, i) => {
  const numEl = section.querySelector('.meta .num');
  if (numEl) {
    const current = String(i + 1).padStart(2, '0');
    const totalStr = String(total).padStart(2, '0');
    numEl.textContent = `${current} / ${totalStr}`;
  }
});
```

**FORBIDDEN** in hand-authored slide HTML:

```html
<!-- HARD GATE VIOLATION — hardcoded 17 -->
<span class="num">03 / 17</span>
```

**REQUIRED** in hand-authored slide HTML:

```html
<!-- Runtime fills this in -->
<span class="num"></span>
```

Authors MAY leave the `.num` span empty OR include a placeholder; the runtime overwrites it on load.

## Content Density Heuristic

The craft rule for every slide:

> **If content is sparse, make it larger. If dense, split into columns or stack with breathing room.**

| Symptom | Response |
| --- | --- |
| "This slide feels empty" | Headline → 88px. Lede → 34px. Add a mega number. |
| "This slide won't fit" | Split into two columns. Or cut content. Never shrink type. |
| "The card is cramped" | Remove half the content from the card. Or split into sibling cards. |
| "The footer is touching the content" | `.body` lost `flex: 1` or `min-height: 0`. Fix the flex, not the padding. |
| "The number feels small" | It is. Hero numbers are 72–240px — check the range. |

## Minimum Text Size

**HARD GATE: 24px floor on body-weight text.** The deck is viewed from 15+ feet. Below 24px, audiences squint.

Exceptions (MUST be used sparingly):

| Allowed <24px | Where | Why |
| --- | --- | --- |
| 18–22px | JetBrains Mono meta/caption text in `.pill`, `.footer`, small labels | Mono reads legibly at smaller sizes; these are chrome not content |
| 16–18px | Footer strip, in-table monospace row captions | Ambient chrome, audiences don't read these |
| 11–14px | Tag chips inside act-divider "card" pills | Incidental context only |

If a body paragraph or list item is below 24px, **the content is too long.** Trim.

## Slide Chrome Variants

The reference ships three slide backgrounds. Archetypes MUST pick one.

| Class | Background | Text color | Use |
| --- | --- | --- | --- |
| `.slide` | `--c-bg` (#FFF) | `--c-ink` | Default — most content slides |
| `.slide.paper` | `--c-bg-2` (#F2F2F2) | `--c-ink` | Paper variant — secondary surface for visual pacing |
| `.slide.dark` | `--c-panel` (#191A1B) | `--c-ink-inv` | Dark panel — act dividers, KPI walls, statement slides |
| `.slide.accent` | `--c-accent` (#FEED02) | `--c-accent-ink` | Amarelo accent — reserved for act openers and section breaks, sparingly |

`.slide.accent` is the rarest — use it for punctuation, not paragraphs.

## Overlay Placement — `position: fixed` Inside a Slide Is Broken

Slides are `position: absolute; inset: 0` inside the canvas — light-DOM children of `<deck-stage>`, positioned via shadow-DOM `::slotted()` rules. Inactive slides use `visibility: hidden; opacity: 0`; they remain laid out but invisible. This preserves state in `<video>`, `<iframe>`, embedded React trees, etc. across navigation — nothing tears down on slide switch.

**Consequence for authors:** the canvas has `transform: scale(s)` applied to fit the viewport. Per CSS spec, a `transform` on an ancestor creates a new containing block for any `position: fixed` descendants. That means `position: fixed` inside a slide is scoped to the canvas, not the viewport — it no longer covers the full window.

**The rule:** overlays that must cover the viewport (blank overlay, notes panel, modals, toast stacks) MUST live on `document.body`, not inside a slide. This is already how the controller handles `#deck-blank-overlay` and `#deck-notes-panel`. Follow the same convention for any new overlay.

## Canvas Self-Test

Before shipping any slide, walk this checklist:

```
[ ] 1. Is the slide exactly 1920×1080 with overflow hidden?
[ ] 2. Does .body have flex:1 and min-height:0?
[ ] 3. Does the footer sit at the bottom with flex-shrink:0?
[ ] 4. Is every body text ≥24px?
[ ] 5. Is the slide number placeholder empty (runtime fills it)?
[ ] 6. Are all card heights content-driven (no px height, no %)?
[ ] 7. Does the content fill the vertical canvas (no dead white space)?
[ ] 8. Is the meta bar present and populated with left+right variants?
[ ] 9. If the slide looks cramped, did you split instead of shrink?

If any checkbox is no → The slide is incomplete. Fix before shipping.
```
