# Design Tokens — Lerian Editorial Deck

The canonical token set for every `ring:deck` output. These tokens are **editorial** — optimized for 1920×1080 projected/screened decks viewed from 15+ feet — and are **deliberately distinct** from `ring:visualize`'s product-console palette (sunglow `#FDCB28`, Inter). Ring canonicalizes two Lerian design systems side by side; MUST NOT cross-pollinate.

## Color Palette

Every color used by the reference. MUST declare all of these on `:root`. Naming follows the Portuguese source labels ("Amarelo", "Preto", etc.) where the reference uses them.

### Ink (text + neutrals)

| Token | Hex | Role |
| --- | --- | --- |
| `--c-ink` | `#191A1B` | Preto — primary text, near-black |
| `--c-ink-2` | `#3E3C37` | Cinza Escuro — secondary text / body paragraphs |
| `--c-ink-3` | `#8B877C` | Cinza Médio — tertiary / meta / eyebrow |
| `--c-ink-inv` | `#FFFFFF` | Inverse ink — text on dark panels |

### Surfaces

| Token | Hex | Role |
| --- | --- | --- |
| `--c-bg` | `#FFFFFF` | Page / default slide background |
| `--c-bg-2` | `#F2F2F2` | Cinza Claro — secondary surface (paper slide variant) |
| `--c-bg-warm` | `#F0EFE9` | Papel Quente — warm-paper surface with a hint of earth. Highlighted-but-not-primary. |
| `--c-card` | `#FFFFFF` | Card background |
| `--c-panel` | `#191A1B` | Dark panel background (act dividers, inverted slides) |

**`--c-bg-warm` vs `--c-bg-2` — when to use which.** Both are "paper," not white. They are NOT interchangeable.

| Token | Role | Use when |
| --- | --- | --- |
| `--c-bg-2` `#F2F2F2` | Neutral paper — cool, stylistically flat | Whole-slide `.slide.paper` background; soft row dividers (`--c-rule-2`); unemphasized secondary surface |
| `--c-bg-warm` `#F0EFE9` | Warm paper — hint of earth, earning-attention | Highlighted rows inside a cooler surface (e.g., `.warm` funnel stages between default and `.hot`); accent-adjacent tint states; "this is still paper but the reader should notice it" |

MUST NOT redefine `--c-bg-2` as warm, and MUST NOT use `--c-bg-warm` as the whole-slide paper surface. `.slide.paper` is cool-paper by convention; warming it breaks the pacing signal (see `slide-archetypes.md` — `content-paper` uses the cool `#F2F2F2` to say "pause and discuss").

### Rules (dividers)

| Token | Hex | Role |
| --- | --- | --- |
| `--c-rule` | `#CECECE` | Cinza — primary hairline |
| `--c-rule-2` | `#F2F2F2` | Cinza Claro — soft divider |

### Accent — Lerian Amarelo (brand primary)

| Token | Hex | Role |
| --- | --- | --- |
| `--c-accent` | `#FEED02` | **Amarelo — Lerian brand primary.** REQUIRED as the single chromatic anchor. |
| `--c-accent-ink` | `#191A1B` | Text on accent — Preto. |
| `--c-accent-2` | `#50F769` | Verde — supporting signal, row highlights, positive deltas. |

### Signal palette

| Token | Hex | Role |
| --- | --- | --- |
| `--c-green` | `#50F769` | Positive / go / shipped |
| `--c-red` | `#FF6760` | Negative / block / risk |
| `--c-blue` | `#2ED8FE` | Informational / neutral signal |

## Typography

Three families. MUST import via the same Google Fonts URL as the reference. MUST NOT add display fonts beyond this set without updating this document.

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&family=IBM+Plex+Serif:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

| Family | Weights | Role |
| --- | --- | --- |
| Poppins | 400, 500, 600, 700 | Display — headlines (h1, h2, h3), KPI values, wordmark. Letter-spacing `-0.02em` to `-0.04em`. |
| IBM Plex Serif | 400, 500, 600 | Body — paragraphs, ledes, table cells. The editorial voice of the deck. |
| JetBrains Mono | 400, 500 | Meta — eyebrows, meta bar, footer, table headers, numeric cells, pills. Letter-spacing `0.04em` to `0.14em`, UPPERCASE. |

```css
body {
  font-family: 'IBM Plex Serif', 'Inter', -apple-system, sans-serif;
  font-feature-settings: "tnum";
  -webkit-font-smoothing: antialiased;
}
h1, h2, h3 { font-family: 'Poppins', -apple-system, sans-serif; font-weight: 600; letter-spacing: -0.02em; }
.eyebrow, .meta, .footer, code, .mono { font-family: 'JetBrains Mono', monospace; }
```

## Type Scale

Ranges cover hero/display through meta. The reference's `:root` defines the default set; archetypes MUST choose values within these ranges. Minimum text floor: **24px** on any body-weight content (deck is read from ≥15ft).

| Role | Range | Reference default | Usage |
| --- | --- | --- | --- |
| Hero / mega | 180–220px | 240px (`--t-mega`), 180px (act dividers) | Cover + act-divider numbers |
| Display | 120–150px | 150px (`--t-display`) | One-number-per-slide KPI walls |
| h1 | 64–88px | 88px (`--t-h1`) | Primary slide headline, line-height 0.98 |
| h2 | 48–64px | 56px (`--t-h2`) | Sub-headlines, line-height 1.02 |
| h3 | 40–48px | 44px (`--t-h3`) | Card titles, section openers |
| Lede | 28–34px | 34px (`--t-body-lg`) | Subtitle paragraph under h1 |
| Body | 24–28px | 28px (`--t-body`) | Paragraphs, table cells, list items — **24px floor** |
| Small | 22px | 22px (`--t-small`) | Secondary table cells, captions |
| Eyebrow | 13–22px | 22px (`--t-eyebrow`) | UPPERCASE labels above h1; mono; letter-spacing `0.14em` |
| KPI value | 72–120px | 96px (`.kpi .value`) | Single-figure tiles, line-height 0.95 |

**HARD GATE:** body and list text MUST NOT fall below 24px. If content is too long to fit, split the slide — do not shrink the type.

## Spacing Scale

The reference uses two canvas-margin variables plus ad-hoc flex gaps. Archetypes MUST reuse them.

| Token | Value | Role |
| --- | --- | --- |
| `--pad-x` | `100px` | Horizontal canvas margin (80px in `[data-density="compact"]`) |
| `--pad-y` | `90px` | Vertical canvas margin (72px in compact) |
| Slide padding | `64px var(--pad-x) 48px` | Top 64px, sides `--pad-x`, bottom 48px |
| Meta → body | `padding-top: 32px` | `.body` top inset |
| Body → footer | `padding-bottom: 20px` | `.body` bottom inset |
| Gap — large | `60px` | Between major columns |
| Gap — medium | `36px` | Between related blocks |
| Gap — small | `20px` | Within a block (card internals) |
| Row gap | `14–20px` | Table row padding |

## Radii

The reference uses three radii. Sharp-to-soft, editorial to chrome.

| Radius | Use |
| --- | --- |
| `0` (none) | Default — slide chrome, tables, rules |
| `2px` | Tick marks, small inline badges |
| `4px` | Cards, deployment blocks, dashed service rails |
| `999px` | Pills, dots, wordmark accent dot, act-divider chip tags |

REQUIRED: no intermediate (`8px`, `12px`, `16px`) radii. The aesthetic is flat editorial, not rounded product UI.

## Meta Bar (top strip)

Every content slide MUST render this strip at the top. Three variants — default (light), `.slide.dark`, `.slide.accent`.

```html
<div class="meta">
  <div class="left">
    <span class="wordmark">lerian<span class="dot"></span></span>
    <span>· Act 01 — Traction & Product</span>
  </div>
  <div class="right">
    <span>Board Meeting № 01</span>
    <span class="num">03 / 17</span>
  </div>
</div>
```

```css
.meta {
  display: flex; align-items: center; justify-content: space-between;
  font-family: 'JetBrains Mono', monospace;
  font-size: var(--t-eyebrow);
  letter-spacing: 0.04em;
  color: var(--c-ink-3);
  text-transform: uppercase;
}
.meta .num { font-weight: 500; color: var(--c-ink); }
.slide.dark .meta { color: rgba(255,255,255,0.55); }
.slide.accent .meta { color: rgba(25,26,27,0.62); }
```

- `.meta .num` — current/total slide index. MUST be populated by runtime (no hardcoded `NN / 17`). See `layout-rules.md`.
- `.meta .dot` — 8×8 `border-radius: 999px` dot. Amarelo (`--c-accent`) on light variants.

## Footer Strip

Every content slide MUST render this strip at the bottom.

```html
<div class="footer">
  <div>Confidential — Lerian Board</div>
  <div>April 22, 2026</div>
</div>
```

```css
.footer {
  display: flex; justify-content: space-between; align-items: center;
  font-family: 'JetBrains Mono', monospace;
  font-size: 16px;
  letter-spacing: 0.04em;
  color: var(--c-ink-3);
  text-transform: uppercase;
  border-top: 1px solid var(--c-rule);
  padding-top: 16px;
  flex-shrink: 0;
}
.slide.dark .footer { color: rgba(255,255,255,0.42); border-color: rgba(255,255,255,0.12); }
.slide.accent .footer { color: rgba(25,26,27,0.55); border-color: rgba(25,26,27,0.18); }
```

- Left: document context ("Confidential — Lerian Board").
- Right: date (static or runtime-injected). Format: Month DD, YYYY.
- `flex-shrink: 0` — footer MUST NOT compress when content fills the slide.

## Canonical `:root` Block

Every deck template MUST paste this block verbatim at the top of its `<style>`.

```css
:root {
  /* Ink */
  --c-ink:       #191A1B;
  --c-ink-2:     #3E3C37;
  --c-ink-3:     #8B877C;
  --c-ink-inv:   #FFFFFF;

  /* Surfaces */
  --c-bg:        #FFFFFF;
  --c-bg-2:      #F2F2F2;
  --c-bg-warm:   #F0EFE9;
  --c-card:      #FFFFFF;
  --c-panel:     #191A1B;

  /* Rules */
  --c-rule:      #CECECE;
  --c-rule-2:    #F2F2F2;

  /* Accent — Lerian Amarelo */
  --c-accent:    #FEED02;
  --c-accent-ink:#191A1B;
  --c-accent-2:  #50F769;

  /* Signal */
  --c-green:     #50F769;
  --c-red:       #FF6760;
  --c-blue:      #2ED8FE;

  /* Type scale (1920x1080) */
  --t-eyebrow:   22px;
  --t-small:     22px;
  --t-body:      28px;
  --t-body-lg:   34px;
  --t-h3:        44px;
  --t-h2:        56px;
  --t-h1:        88px;
  --t-display:   150px;
  --t-mega:      240px;

  /* Spacing */
  --pad-x:       100px;
  --pad-y:       90px;
}

[data-density="compact"] {
  --pad-x:    80px;
  --pad-y:    72px;
  --t-body:   26px;
  --t-body-lg:30px;
  --t-h2:     48px;
  --t-h1:     72px;
}
```

## Design Rationale (footnote)

Claude Design proposed a warm-paper + lime `#D6F24B` palette. **Rejected:** `#FEED02` Amarelo is Lerian brand primary in the reference. Layout discipline + type-scale ranges from the same directive are incorporated — palette is not.

## Wordmark Sync

The Lerian wordmark has two canonical copies and two usage patterns inside the deck itself.

**Canonical copies (must stay byte-identical):**

1. `default/skills/deck/assets/lerian-wordmark.svg` — standalone file served over `/assets/lerian-wordmark.svg`.
2. `default/skills/visualize/templates/standard.html` (lines 629–633) — visualize's inline copy inside `<header class="lerian-header">`.

**Two patterns inside the deck skill — both equally valid:**

- **`<img>` pattern (archetype reuse).** `templates/slide-cover.html` uses `<img src="assets/lerian-wordmark.svg" alt="Lerian" …>`. Prefer this when the template is being reused as a detached archetype and the asset is served alongside it.
- **Inline SVG pattern (self-contained baseline).** `templates/deck.html` inlines the `<svg viewBox="0 0 1090.88 280" …>` directly in its own cover slide. Prefer this when shipping a single-file baseline deck that must render without an external asset pipeline.

If Lerian rebrands, MUST update all three locations (the standalone SVG file, `deck.html`'s inline cover SVG, and visualize's inline copy). The viewBox (`0 0 1090.88 280`) and path data MUST match byte-for-byte across all three. Any drift is a compliance failure.

## Derived Tints — `color-mix()` Technique

When a slide needs a tint that sits *between* two canonical tokens (pale banner, soft ink, dark-with-accent-warmth), REQUIRED: derive it with `color-mix()` in the `oklab` color space rather than adding a new token. OKlab is perceptually uniform — a 40% mix reads as 40% to the eye, which sRGB gets wrong. This keeps the palette closed-set while allowing intermediate shades.

**Canonical recipes:**

| Recipe | CSS | Use |
| --- | --- | --- |
| Pale accent banner | `color-mix(in oklab, var(--c-accent) 40%, white)` | Unqualified / potential states (funnel monetary overlay, early-stage emphasis) |
| Soft ink | `color-mix(in oklab, var(--c-ink) 60%, white)` | Secondary body text where `--c-ink-2` feels too heavy; hover-adjacent states |
| Dark with accent warmth | `color-mix(in oklab, var(--c-accent) 20%, var(--c-ink))` | Near-black panel with a hint of editorial warmth — use sparingly |

**HARD GATE:** MUST use `in oklab`, not `in srgb`. The sRGB interpolation flattens Amarelo mixes to a muddy yellow-green. OKlab keeps the hue true.

```css
/* Pale banner inside a funnel monetary overlay */
background: color-mix(in oklab, var(--c-accent) 40%, white);
color: var(--c-ink);

/* Soft ink caption */
color: color-mix(in oklab, var(--c-ink) 60%, white);
```

**Browser support is a deliberate non-concern.** The deck targets current Chrome via Puppeteer export (`references/export.md`) and evergreen browsers for the presenter runtime. `color-mix()` has been baseline-supported since 2023. MUST NOT add `@supports` fallbacks or inline the mixed hex — the whole point is avoiding token sprawl. If the runtime target changes, revisit this section.

**Anti-pattern:** defining `--c-accent-pale: #FFF7A0` as a new token for one use. If the tint exists at a single point in the deck, derive it. If it shows up in 3+ places across archetypes, then promote it to a token and update this file.

## Provisional Home

Canonical source should move to Figma once Lerian has a design-system repo. Until then, this file is the source of truth. Drift from here is drift from Lerian brand.
