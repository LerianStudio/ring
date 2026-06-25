# Slide Deck Patterns

CSS patterns, JS engine, slide type layouts, transitions, navigation chrome, and the Lerian preset for self-contained HTML slide presentations. All slides are viewport-fit (100dvh), single-file, same philosophy as the scrollable templates.

The reusable foundation lives in `./templates/slide-deck.html` — copy that file and replace its skeleton slides. This doc explains the patterns inside it.

**When to use slides:** Only when the user explicitly requests them — `--slides`, "as a slide deck," "make a presentation," or equivalent. Never auto-select slide format; the default visualizing output is a scrollable page.

**Before generating**, also read `./references/css-patterns.md` for shared patterns (overflow protection, depth tiers, status badges), `./references/libraries.md` for Chart.js and font notes, and `./templates/diagram.html` for the D2 diagram-shell engine and the Lerian D2 preamble. Those patterns apply to slides too — this file adds slide-specific patterns on top.

## Lerian Branding in a Deck

A deck has no scrolling footer (every slide is exactly one viewport). Lerian identity is carried in two places, both already wired in `slide-deck.html`:

- **Title slide** — the full Lerian wordmark SVG (`viewBox="0 0 1090.88 280"`) above the deck title, in `currentColor` so it adapts to light/dark.
- **Persistent wordmark** — a small fixed bottom-left wordmark (logo mark + "Generated with Ring", linking to lerian.studio) visible on every slide, with backdrop-safe opacity.

Keep both. Do not introduce a different brand mark, a scrolling footer, or off-brand accent colors.

## Planning a Deck from a Source Document

When converting a plan, spec, review, or any structured document into slides, follow this process before writing any HTML. Skipping it leads to polished-looking decks that silently drop 30–40% of the source material.

**Step 1 — Inventory the source.** Read the entire source document and enumerate every section, subsection, card, table row, decision, specification, collapsible detail, and footnote. Count them. A plan with 7 sections, 6 decision cards, a 7-row file table, and an engine spec with 3 sub-specs and 2 collapsibles is ~25 distinct content items that all need slide real estate.

**Step 2 — Map source to slides.** Assign each inventory item to one or more slides. Every item must appear somewhere. Rules:
- If a section has 6 decisions, all 6 need slides — not the 2 that fit on one split slide.
- If a table has 7 rows, all 7 rows show up.
- Collapsible/expandable details in the source are not optional in the deck — they become their own slides.
- Subsections with multiple cards may need 2–3 slides to cover at readable density.
- Each plan section typically needs a divider slide + 1–3 content slides depending on density.

**Step 3 — Choose layouts.** For each planned slide, pick a slide type and spatial composition. Vary across the sequence (see Compositional Variety below). This is where narrative pacing happens — alternate dense slides with sparse ones.

**Step 4 — Plan images.** Run `which surf`. If surf-cli is available, plan 2–4 generated images for the deck. At minimum, target the **title slide** (16:9 background that sets the visual tone) and **one full-bleed slide** (immersive background for a key moment). Content slides with conceptual topics also benefit from a 1:1 illustration in the aside area. Generate these images early — before writing HTML — so you can embed them as base64 data URIs. See the Proactive Imagery section below. If surf isn't available, degrade to CSS gradients and SVG decorations — note the fallback in a comment but don't error.

**Step 5 — Verify before writing HTML.** Scan the inventory from Step 1. Is anything unmapped? Would a reader of the source document notice something missing from the deck? If yes, add slides. A source document with 7 sections typically produces 18–25 slides, not 10–13.

**The test:** After generating the deck, a reader who has never seen the source document should be able to reconstruct every major point from the slides alone. If they'd miss entire sections, the deck is incomplete.

## Slide Engine Base

The deck is a scroll-snap container. Each slide is exactly one viewport tall.

```html
<body>
<div class="deck">
  <section class="slide slide--title"> ... </section>
  <section class="slide slide--content"> ... </section>
  <section class="slide slide--diagram"> ... </section>
  <!-- one <section> per slide -->
</div>
</body>
```

```css
/* Scroll-snap container */
.deck {
  height: 100dvh;
  overflow-y: auto;
  scroll-snap-type: y mandatory;
  scroll-behavior: smooth;
  -webkit-overflow-scrolling: touch;
}

/* Individual slide */
.slide {
  height: 100dvh;
  scroll-snap-align: start;
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: clamp(40px, 6vh, 80px) clamp(40px, 8vw, 120px);
  isolation: isolate; /* contain z-index stacking */
}
```

## Typography Scale

Slide typography is 2–3× larger than scrollable pages. Page-sized text on a viewport-sized canvas looks like a mistake. Body font is **Inter** (Lerian brand body font — mandatory); mono is **JetBrains Mono**.

```css
.slide__display {
  font-size: clamp(48px, 10vw, 120px);
  font-weight: 800;
  letter-spacing: -3px;
  line-height: 0.95;
  text-wrap: balance;
}

.slide__heading {
  font-size: clamp(28px, 5vw, 48px);
  font-weight: 700;
  letter-spacing: -1px;
  line-height: 1.15;
  text-wrap: balance;
}

.slide__body {
  font-size: clamp(16px, 2.2vw, 22px);
  line-height: 1.6;
  text-wrap: pretty;
}

.slide__label {
  font-family: var(--font-mono);
  font-size: clamp(10px, 1.2vw, 13px);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: var(--accent);
}

.slide__subtitle {
  font-family: var(--font-mono);
  font-size: clamp(12px, 1.5vw, 18px);
  color: var(--text-dim);
  letter-spacing: 1px;
  text-transform: uppercase;
}
```

| Element | Size range | Notes |
|---------|-----------|-------|
| Display (title slides) | 48–120px | `10vw` preferred, weight 800 |
| Section numbers | 100–260px | Ultra-light (weight 200), decorative |
| Headings | 28–48px | `5vw` preferred, weight 700 |
| Body / bullets | 16–22px | `2.2vw` preferred, 1.6 line-height |
| Code blocks | 14–18px | `1.6vw` preferred, mono |
| Quotes | 24–48px | `4vw` preferred, weight 600 |
| Labels / captions | 10–14px | Mono, uppercase, dimmed |

## Cinematic Transitions

IntersectionObserver adds `.visible` when a slide enters the viewport. Slides animate in once and stay visible when scrolling back.

```css
/* Slide entrance — fade + lift + subtle scale */
.slide {
  opacity: 0;
  transform: translateY(40px) scale(0.98);
  transition:
    opacity 0.6s cubic-bezier(0.16, 1, 0.3, 1),
    transform 0.6s cubic-bezier(0.16, 1, 0.3, 1);
}

.slide.visible {
  opacity: 1;
  transform: none;
}

/* Staggered child reveals — add .reveal to each content element */
.slide .reveal {
  opacity: 0;
  transform: translateY(20px);
  transition:
    opacity 0.5s cubic-bezier(0.16, 1, 0.3, 1),
    transform 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

.slide.visible .reveal {
  opacity: 1;
  transform: none;
}

/* Stagger delays — up to 6 children per slide */
.slide.visible .reveal:nth-child(1) { transition-delay: 0.1s; }
.slide.visible .reveal:nth-child(2) { transition-delay: 0.2s; }
.slide.visible .reveal:nth-child(3) { transition-delay: 0.3s; }
.slide.visible .reveal:nth-child(4) { transition-delay: 0.4s; }
.slide.visible .reveal:nth-child(5) { transition-delay: 0.5s; }
.slide.visible .reveal:nth-child(6) { transition-delay: 0.6s; }

@media (prefers-reduced-motion: reduce) {
  .slide,
  .slide .reveal {
    opacity: 1 !important;
    transform: none !important;
    transition: none !important;
  }
}
```

## Navigation Chrome

All navigation is `position: fixed` with high z-index, layered above slides. Styled to be visible on any background.

### Progress Bar

```css
.deck-progress {
  position: fixed;
  top: 0;
  left: 0;
  height: 3px;
  background: var(--accent);
  z-index: 100;
  transition: width 0.3s ease;
  pointer-events: none;
}
```

### Nav Dots

```css
.deck-dots {
  position: fixed;
  right: clamp(12px, 2vw, 24px);
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  gap: 8px;
  z-index: 100;
}

.deck-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--text-dim);
  opacity: 0.3;
  border: none;
  padding: 0;
  cursor: pointer;
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.deck-dot:hover {
  opacity: 0.6;
}

.deck-dot.active {
  opacity: 1;
  transform: scale(1.5);
  background: var(--accent);
}
```

### Slide Counter

```css
.deck-counter {
  position: fixed;
  bottom: clamp(12px, 2vh, 24px);
  right: clamp(12px, 2vw, 24px);
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-dim);
  z-index: 100;
  font-variant-numeric: tabular-nums;
}
```

### Keyboard Hints

Auto-fade after first interaction or after 4 seconds.

```css
.deck-hints {
  position: fixed;
  bottom: clamp(12px, 2vh, 24px);
  left: 50%;
  transform: translateX(-50%);
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-dim);
  opacity: 0.6;
  z-index: 100;
  transition: opacity 0.5s ease;
  white-space: nowrap;
}

.deck-hints.faded {
  opacity: 0;
  pointer-events: none;
}
```

### Persistent Wordmark

The fixed bottom-left Lerian wordmark sits at the same z-index tier as the chrome. It uses the same backdrop/opacity treatment so it stays legible on any slide background and doesn't compete with the counter (which lives bottom-right).

### Chrome Visibility on Mixed Backgrounds

For decks where some slides are light and some dark (especially full-bleed slides), nav chrome needs to remain visible. Two approaches:

```css
/* Approach A: subtle backdrop on chrome elements */
.deck-dots,
.deck-counter {
  background: color-mix(in srgb, var(--bg) 70%, transparent 30%);
  padding: 6px;
  border-radius: 20px;
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
}

/* Approach B: text shadow for legibility on any background */
.deck-counter,
.deck-hints {
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}
```

## SlideEngine JavaScript

Add once at the end of the page. Handles navigation, chrome updates, and scroll-triggered reveals. Event delegation ensures slide-internal interactions (D2 diagram pan/zoom, scrollable code, overflow tables) don't trigger slide navigation. The full engine ships in `slide-deck.html`; this is the reference shape.

```javascript
function SlideEngine() {
  this.deck = document.querySelector('.deck');
  this.slides = [].slice.call(document.querySelectorAll('.slide'));
  this.current = 0;
  this.total = this.slides.length;
  this.buildChrome();
  this.bindEvents();
  this.observe();
  this.update();
}

SlideEngine.prototype.bindEvents = function() {
  var self = this;
  // Keyboard — skip if focus is inside interactive content
  document.addEventListener('keydown', function(e) {
    if (e.target.closest('.diagram-viewport,.table-scroll,.code-scroll,input,textarea,[contenteditable]')) return;
    if (['ArrowDown', 'ArrowRight', ' ', 'PageDown'].indexOf(e.key) > -1) { e.preventDefault(); self.next(); }
    else if (['ArrowUp', 'ArrowLeft', 'PageUp'].indexOf(e.key) > -1) { e.preventDefault(); self.prev(); }
    else if (e.key === 'Home') { e.preventDefault(); self.goTo(0); }
    else if (e.key === 'End') { e.preventDefault(); self.goTo(self.total - 1); }
    self.fadeHints();
  });
  // Touch swipe
  var touchY;
  this.deck.addEventListener('touchstart', function(e) { touchY = e.touches[0].clientY; }, { passive: true });
  this.deck.addEventListener('touchend', function(e) {
    var dy = touchY - e.changedTouches[0].clientY;
    if (Math.abs(dy) > 50) { dy > 0 ? self.next() : self.prev(); }
  });
};

SlideEngine.prototype.observe = function() {
  var self = this;
  var obs = new IntersectionObserver(function(entries) {
    entries.forEach(function(entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        self.current = self.slides.indexOf(entry.target);
        self.update();
      }
    });
  }, { threshold: 0.5 });
  this.slides.forEach(function(s) { obs.observe(s); });
};
```

**Usage:** Instantiate after the DOM is ready (and after Chart.js renders, if used). Diagrams need no library — they are static D2 SVGs. Always call `autoFit()` before `new SlideEngine()` so content is sized correctly before intersection observers fire. In `slide-deck.html` this is wired through a `DOMContentLoaded` bootstrap that runs `autoFit()`, initializes the D2 diagram-shells, then starts the engine.

## Auto-Fit

A single post-render function that handles all known content overflow cases. Agents can't perfectly predict how text reflows at every viewport size, so `autoFit()` is a required safety net. Call it after Chart.js renders (if used) but before SlideEngine init. Diagrams are static D2 SVGs handled by the separate D2 pan/zoom engine, not by `autoFit()`.

```javascript
function autoFit() {
  // KPI values: visually scale down text that overflows card width
  document.querySelectorAll('.slide__kpi-val').forEach(function(el) {
    if (el.scrollWidth > el.clientWidth) {
      var s = el.clientWidth / el.scrollWidth;
      el.style.transform = 'scale(' + s + ')';
      el.style.transformOrigin = 'left top';
    }
  });

  // Blockquotes: reduce font proportionally for long text
  document.querySelectorAll('.slide--quote blockquote').forEach(function(el) {
    var len = el.textContent.trim().length;
    if (len > 100) {
      var scale = Math.max(0.5, 100 / len);
      var fs = parseFloat(getComputedStyle(el).fontSize);
      el.style.fontSize = Math.max(16, Math.round(fs * scale)) + 'px';
    }
  });
}
```

Two cases, one function:
- **KPI values:** Long text strings at hero scale overflow card boundaries — `transform: scale()` shrinks visually without reflow.
- **Blockquotes:** Quotes longer than ~100 characters get proportionally smaller font. The 0.5 floor prevents unreadably small text; if it needs more than 50% shrink, it should have been a content slide.

## Slide Type Layouts

Ten slide types ship in `slide-deck.html`. Each has a defined HTML structure and CSS layout. The agent can adapt content per source material, but the structural patterns stay consistent. Class names are stable: `.slide--title`, `.slide--divider`, `.slide--content`, `.slide--split`, `.slide--diagram`, `.slide--dashboard`, `.slide--table`, `.slide--code`, `.slide--quote`, `.slide--bleed`.

### Title Slide

Full-viewport hero carrying the Lerian wordmark. Background treatment via gradient or surf-generated image. 80–120px display type.

```html
<section class="slide slide--title">
  <svg class="slide__decor" ...><!-- optional corner accent --></svg>
  <svg class="slide__logo reveal" viewBox="0 0 1090.88 280" ...><!-- Lerian wordmark --></svg>
  <h1 class="slide__display reveal">Deck Title</h1>
  <p class="slide__subtitle reveal">Subtitle or date</p>
</section>
```

```css
.slide--title {
  justify-content: center;
  align-items: center;
  text-align: center;
}
```

### Section Divider

Oversized decorative number (200px+, ultra-light weight) with heading. Breathing room between topics. SVG accent marks optional.

```html
<section class="slide slide--divider">
  <span class="slide__number">02</span>
  <div>
    <h2 class="slide__heading reveal">Section Title</h2>
    <p class="slide__subtitle reveal">Optional subheading</p>
  </div>
</section>
```

```css
.slide--divider .slide__number {
  font-size: clamp(100px, 22vw, 260px);
  font-weight: 200;
  line-height: 0.85;
  opacity: 0.08;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -55%);
  pointer-events: none;
  font-variant-numeric: tabular-nums;
  color: var(--accent);
}
```

### Content Slide

Heading + bullets or paragraphs. Asymmetric layout — content offset to one side. Max 5–6 bullets (2 lines each).

```html
<section class="slide slide--content">
  <div class="slide__inner">
    <div>
      <h2 class="slide__heading reveal">Heading</h2>
      <ul class="slide__bullets">
        <li class="reveal">First point</li>
        <li class="reveal">Second point</li>
      </ul>
    </div>
    <div class="slide__aside reveal">
      <!-- optional: illustration, icon, mini-diagram, accent SVG -->
    </div>
  </div>
</section>
```

```css
.slide--content .slide__inner {
  display: grid;
  grid-template-columns: 3fr 2fr; /* swap to 2fr 3fr for right-heavy */
  gap: clamp(24px, 4vw, 60px);
  align-items: center;
  width: 100%;
}
```

### Split Slide

Asymmetric two-panel (60/40 or 70/30). Before/after, text+diagram, text+image. Each panel has its own background tier. Zero padding on the slide itself — panels fill edge to edge.

```html
<section class="slide slide--split">
  <div class="slide__panels">
    <div class="slide__panel slide__panel--primary">
      <h2 class="slide__heading reveal">Left Panel</h2>
      <div class="slide__body reveal">Content...</div>
    </div>
    <div class="slide__panel slide__panel--secondary">
      <!-- diagram, image, code block, or contrasting content -->
    </div>
  </div>
</section>
```

```css
.slide--split { padding: 0; }

.slide--split .slide__panels {
  display: grid;
  grid-template-columns: 3fr 2fr;
  height: 100%;
}

.slide--split .slide__panel--primary { background: var(--surface); }
.slide--split .slide__panel--secondary { background: var(--surface2); }
```

### Diagram Slide

Full-viewport diagram, rendered by the **D2 CLI** to a STATIC inline SVG. Dark/light is baked into the SVG by D2 — there is no client-side diagram library. Max 8–10 nodes (presentation scale — fewer, larger than page diagrams). The generic SVG pan/zoom engine (toolbar + drag + wheel-zoom + fullscreen) ships in `slide-deck.html` and mirrors `./templates/diagram.html`.

**Generation.** Write a `.d2` file starting with the Lerian D2 preamble (the full preamble lives in `./templates/diagram.html`'s top comment — copy it verbatim), then render and embed:

```bash
command -v d2 || brew install d2     # or: curl -fsSL https://d2lang.com/install.sh | sh
d2 --theme=0 --dark-theme=200 --layout=elk diagram.d2 diagram.svg
# strip the leading <?xml ...?> declaration, then paste the <svg>...</svg> into .diagram-canvas
```

The Lerian D2 class roles: `source` (sunglow `#FDCB28` / `#EDAC05`), `process` (neutral zinc), `datastore` (green cylinder `#5BCD86` / `#26934F`), `decision` (amber diamond), `critical` (tangerine `#F06E43`), `external` (dashed neutral). Apply with `myshape.class: source`. Leave nodes unclassed to inherit the neutral theme; do not invent roles not in the source.

**When to use D2 vs CSS in slides.** D2 (ELK layout) produces clean, deterministic SVGs — static, no render flicker, no theme-refresh bug. The rule:

- **Use D2** for complex graphs: 8+ nodes, branching paths, cycles, multiple edge crossings — anything where automatic edge routing saves real effort.
- **Use CSS Pipeline** (below) for simple linear flows: A → B → C → D sequences, build steps, deployment stages. CSS cards give full control over sizing, typography, and fill the viewport naturally.
- **Never leave a small diagram alone on a slide.** If the diagram is small, either switch to CSS, or pair it with supporting content (description cards, bullet annotations, a summary panel) in a split layout. A slide with a tiny diagram and empty space is a failed slide.

**Structure.** The `.diagram-shell` flexes to fill the slide viewport (`flex:1; min-height:0`) instead of the page template's fixed 600px height. Toolbar buttons use `data-a` attributes (`out`/`in`/`one`/`fit`/`full`); the engine wires them per-shell.

```html
<section class="slide slide--diagram">
  <h2 class="slide__heading reveal">Diagram Title</h2>
  <div class="diagram-shell reveal">
    <div class="diagram-toolbar">
      <span class="title">Diagram name</span>
      <span class="spacer"></span>
      <span class="diagram-label">100%</span>
      <button data-a="out" title="Zoom out">&minus;</button>
      <button data-a="in" title="Zoom in">+</button>
      <button data-a="one" title="100%">1:1</button>
      <button data-a="fit" title="Fit">&#x2922;</button>
      <button data-a="full" title="Fullscreen">&#x26F6;</button>
    </div>
    <div class="diagram-viewport">
      <div class="diagram-canvas">
        <!-- paste D2-rendered <svg> here (xml declaration stripped) -->
      </div>
    </div>
  </div>
</section>
```

**Pan / zoom / fullscreen.** Drag to pan, Ctrl/Cmd+wheel to zoom, double-click to fit, the `1:1` button resets to 100%, and `⛶` toggles fullscreen on the shell. The engine reads the SVG `viewBox` and is source-agnostic — it works on any inline SVG, D2 or otherwise.

**No per-element CSS overrides needed.** Because the diagram is a static SVG with all styling (fills, strokes, fonts, dark/light) baked in by D2 at generation time, there are no runtime label/edge overrides to maintain. Tune node size and font through D2 (`--theme`, shape styles, `near` constraints), then re-render.

### CSS Pipeline Slide

For simple linear flows (build steps, deployment stages, data pipelines) where a D2 graph would render too small. CSS cards with arrow connectors give full control over sizing and fill the viewport naturally. Each step card expands to fill available space via `flex: 1`.

```html
<section class="slide" style="background-image:radial-gradient(...);">
  <p class="slide__label reveal">Pipeline Label</p>
  <h2 class="slide__heading reveal">Pipeline Title</h2>
  <div class="pipeline reveal">
    <div class="pipeline__step" style="border-top-color:var(--accent);">
      <div class="pipeline__num">01</div>
      <div class="pipeline__name">Step Name</div>
      <div class="pipeline__desc">What this step produces or does</div>
      <div class="pipeline__file">output-file.md</div>
    </div>
    <div class="pipeline__arrow">
      <svg viewBox="0 0 24 24" width="20" height="20"><path d="M5 12h14m-4-4l4 4-4 4" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
    </div>
    <div class="pipeline__step"> ... </div>
    <!-- repeat step + arrow pairs -->
  </div>
</section>
```

```css
.pipeline {
  display: flex;
  align-items: stretch;
  gap: 0;
  flex: 1;
  min-height: 0;
  margin-top: clamp(12px, 2vh, 24px);
}

.pipeline__step {
  flex: 1;
  background: var(--surface);
  border: 1px solid var(--border);
  border-top: 3px solid var(--accent);
  border-radius: 10px;
  padding: clamp(14px, 2.5vh, 28px) clamp(12px, 1.5vw, 22px);
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow-wrap: break-word;
}

.pipeline__num {
  font-size: clamp(10px, 1.2vw, 13px);
  font-weight: 600;
  color: var(--accent);
  letter-spacing: 1px;
}

.pipeline__name {
  font-size: clamp(16px, 2vw, 24px);
  font-weight: 700;
  margin: clamp(4px, 0.8vh, 8px) 0;
}

.pipeline__desc {
  font-size: clamp(12px, 1.3vw, 16px);
  color: var(--text-dim);
  line-height: 1.5;
  flex: 1;
}

.pipeline__file {
  font-size: clamp(10px, 1.1vw, 12px);
  color: var(--accent);
  background: var(--accent-dim);
  padding: 3px 8px;
  border-radius: 4px;
  margin-top: clamp(8px, 1.5vh, 16px);
  align-self: flex-start;
}

.pipeline__arrow {
  display: flex;
  align-items: center;
  padding: 0 clamp(3px, 0.4vw, 6px);
  color: var(--accent);
  flex-shrink: 0;
  opacity: 0.4;
}

@media (max-width: 768px) {
  .pipeline { flex-direction: column; }
  .pipeline__arrow { justify-content: center; padding: 4px 0; transform: rotate(90deg); }
}
```

Each `.pipeline__step` uses `flex: 1` to fill available width equally, and the pipeline container itself uses `flex: 1` to fill available vertical space. Step cards stretch to fill, so the content isn't floating in empty space. Max 5–6 steps — beyond that, split across two slides.

### Dashboard Slide

KPI cards at presentation scale (48–64px hero numbers). Mini-charts via Chart.js or SVG sparklines. Max 6 KPIs.

```html
<section class="slide slide--dashboard">
  <h2 class="slide__heading reveal">Metrics Overview</h2>
  <div class="slide__kpis">
    <div class="slide__kpi reveal">
      <div class="slide__kpi-val" style="color:var(--accent)">247</div>
      <div class="slide__kpi-label">Lines Added</div>
    </div>
    <!-- more KPI cards -->
  </div>
</section>
```

```css
.slide--dashboard .slide__kpis {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(clamp(140px, 20vw, 220px), 1fr));
  gap: clamp(12px, 2vw, 24px);
}

.slide__kpi-val {
  font-size: clamp(36px, 6vw, 64px);
  font-weight: 800;
  letter-spacing: -1.5px;
  line-height: 1.1;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
```

**KPI hero values should be short** — numbers, percentages, 1–3 word labels. Ideal length is 1–6 characters at hero scale. Longer strings like `store=false` break the layout at 64px. If you must show a longer value, put it in the label or body text instead. `autoFit()` scales down overflows as a safety net.

### Table Slide

18–20px cell text for projection readability. Max 8 rows per slide — overflow paginates to the next slide. Stronger alternating row contrast than page tables.

```html
<section class="slide slide--table">
  <h2 class="slide__heading reveal">Data Title</h2>
  <div class="table-wrap reveal" style="flex:1; min-height:0;">
    <div class="table-scroll">
      <table class="data-table"> ... </table>
    </div>
  </div>
</section>
```

```css
.slide--table .data-table { font-size: clamp(14px, 1.8vw, 20px); }
.slide--table .data-table th { font-size: clamp(10px, 1.3vw, 14px); }
```

### Code Slide

18px mono on a recessed dark background. Max 10 lines. Floating filename label. Centered on the viewport for focus.

```html
<section class="slide slide--code">
  <h2 class="slide__heading reveal">What Changed</h2>
  <div class="slide__code-block reveal">
    <span class="slide__code-filename">handler.go</span>
    <pre><code>func Handle(req Request) error {
  // highlighted code here
}</code></pre>
  </div>
</section>
```

```css
.slide__code-block {
  background: var(--code-bg);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: clamp(24px, 4vh, 48px) clamp(24px, 4vw, 48px);
  max-width: 900px;
  width: 100%;
  position: relative;
}

.slide__code-filename {
  position: absolute;
  top: -12px;
  left: 24px;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 4px;
  background: var(--accent);
  color: var(--bg);
}
```

### Quote Slide

36–48px weight-600 Inter with dramatic line-height. Oversized quotation mark as typographic decoration. Generous whitespace is the design. Max ~25 words / ~150 chars.

```html
<section class="slide slide--quote">
  <div class="slide__quote-mark reveal">&ldquo;</div>
  <blockquote class="reveal">
    The best code is the code you don't have to write.
  </blockquote>
  <cite class="reveal">&mdash; Attribution</cite>
</section>
```

```css
.slide--quote {
  justify-content: center;
  align-items: center;
  text-align: center;
  padding: clamp(60px, 10vh, 120px) clamp(60px, 12vw, 200px);
}

.slide--quote blockquote {
  font-size: clamp(24px, 4vw, 48px);
  font-weight: 600;
  line-height: 1.35;
  letter-spacing: -0.5px;
}
```

### Full-Bleed Slide

Background image (surf-generated or CSS gradient) dominates the viewport. Text overlay with gradient scrim ensuring contrast. Zero slide padding.

```html
<section class="slide slide--bleed">
  <div class="slide__bg" style="background-image:url('data:image/png;base64,...')"></div>
  <div class="slide__scrim"></div>
  <div class="slide__content">
    <h2 class="slide__heading reveal">Headline Over Image</h2>
    <p class="slide__subtitle reveal">Supporting text</p>
  </div>
</section>
```

```css
.slide--bleed { padding: 0; justify-content: flex-end; }

.slide__bg { position: absolute; inset: 0; background-size: cover; background-position: center; z-index: 0; }

.slide__scrim {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.75) 0%, rgba(0, 0, 0, 0.2) 40%, transparent 100%);
  z-index: 1;
}

/* When no generated image, use the Lerian CSS gradient fallback:
   deep zinc base with a warm sunglow-tinted corner glow. */
.slide__bg--gradient {
  background:
    radial-gradient(ellipse at 80% 20%, rgba(253, 203, 40, 0.22) 0%, transparent 55%),
    linear-gradient(135deg, oklch(22% 0.006 286.0) 0%, oklch(30% 0.010 286.0) 100%);
}
```

## Decorative SVG Elements

Inline SVG accents lift slides from functional to editorial. Use sparingly — one or two per slide, never on every slide. All accents use `var(--accent)` (sunglow) at low opacity.

### Corner Accent

```html
<svg class="slide__decor slide__decor--corner" width="120" height="120" viewBox="0 0 120 120">
  <line x1="120" y1="0" x2="120" y2="40" stroke="var(--accent)" stroke-width="2" opacity="0.2"/>
  <line x1="80" y1="0" x2="120" y2="0" stroke="var(--accent)" stroke-width="2" opacity="0.2"/>
</svg>
```

```css
.slide__decor { position: absolute; pointer-events: none; z-index: 0; }
.slide__decor--corner { top: 0; right: 0; }
```

### Per-Slide Background Variation

Vary gradient direction and accent glow position across slides to create visual rhythm. Don't use a uniform background for every slide.

```css
.slide:nth-child(odd) {
  background-image: radial-gradient(ellipse at 20% 80%, var(--accent-dim) 0%, transparent 50%);
}

.slide:nth-child(even) {
  background-image: radial-gradient(ellipse at 80% 20%, var(--accent-dim) 0%, transparent 50%);
}
```

## Proactive Imagery

Slides should reach for visuals before defaulting to text alone. If a slide could be more compelling with an image, chart, or diagram, add one.

**surf-cli integration:** Check `which surf` at the start of every slide deck generation. If available, **generate 2–4 images minimum** for any deck over 10 slides — a deck with AI-generated imagery is dramatically more compelling than one with only CSS gradients. Target these slides in priority order:

1. **Title slide** (always): background image that sets the deck's visual tone, matching the topic and the Lerian palette. Use `--aspect-ratio 16:9`.
2. **Full-bleed slide** (always if deck has one): immersive background for the deck's visual anchor moment.
3. **Content slides with conceptual topics** (1–2 if room): illustration in the `.slide__aside` area. Use `--aspect-ratio 1:1`.

**Generate images before writing HTML** so they're ready to embed:

```bash
# Check availability
which surf

# Generate (one per target slide) — pull colors from the Lerian palette
surf gemini "abstract dark zinc composition with warm sunglow (#FDCB28) accent light, technical, minimal, premium fintech feel" --generate-image /tmp/ve-slide-title.png --aspect-ratio 16:9

# Base64 encode for self-containment (macOS)
TITLE_IMG=$(base64 -i /tmp/ve-slide-title.png)
# Linux: TITLE_IMG=$(base64 -w 0 /tmp/ve-slide-title.png)

# Embed in the slide:
# <div class="slide__bg" style="background-image:url('data:image/png;base64,${TITLE_IMG}')"></div>

# Clean up
rm /tmp/ve-slide-title.png
```

**Prompt craft for slides:** Be specific about style, dominant colors, and mood. Pull colors from the Lerian palette. Examples:
- Title background: "abstract dark zinc-800 surface with warm sunglow (#FDCB28) light streaks, geometric, minimal, premium fintech"
- Full-bleed anchor: "deep zinc gradient with a single warm sunglow glow in the corner, cinematic depth, restrained and technical"
- Conceptual aside (1:1): "minimal line-art icon in sunglow on dark zinc, double-entry ledger motif, technical illustration"

**When surf fails or isn't available:** Degrade gracefully to CSS gradients and SVG decorations. Use the `.slide__bg--gradient` pattern. The deck stands on its own visually without generated images — they enhance, they don't carry. Note the fallback in an HTML comment (`<!-- surf unavailable, using CSS gradient fallback -->`) so future edits know to retry.

**Inline data visualizations:** Proactively add SVG sparklines next to numbers, mini-charts on dashboard slides, and small inline SVG accents on split slides even when not explicitly requested. A number with a sparkline next to it tells a better story than a number alone.

**When to skip images:** Pure structural or data-heavy decks (code reviews, table comparisons) may not need generated images. Never error on missing surf.

## Compositional Variety

Consecutive slides must vary their spatial approach. Three centered slides in a row means push one off-axis.

**Composition patterns to alternate between:**
- Centered (title slides, quotes)
- Left-heavy: content on the left 60%, breathing room on the right
- Right-heavy: content on the right 60%, visual or whitespace on the left
- Edge-aligned: content pushed to bottom or top, large empty space opposite
- Split: two distinct panels filling the viewport
- Full-bleed: background dominates, minimal overlaid text

Plan the slide sequence considering layout rhythm, not just content order. When outlining a deck, assign a composition to each slide before writing HTML.

## Presentation Readability

Slides get projected, screen-shared, viewed at distance. Design accordingly:

- **Minimum body text: 16px.** Nothing smaller except labels and captions.
- **One focal point per slide.** Not three competing elements.
- **Higher contrast than pages.** Dimmed text (`--text-dim`) should still be easily readable at distance — test against the background.
- **Nav chrome opacity.** Dots, progress bar, and the persistent wordmark must be visible on any slide background (light or dark) without being distracting. Use the backdrop blur or text-shadow approach from the Nav Chrome section.
- **Simpler diagrams.** Max 8–10 nodes; render with D2 at a presentation-readable size. The diagram should be legible without zoom at presentation distance; pan/zoom controls remain available for detail.

## Content Density Limits

Each slide must fit in exactly 100dvh. If content exceeds these limits, split across multiple slides — never scroll within a slide.

| Slide type | Max content |
|-----------|-------------|
| Title | 1 wordmark + 1 heading + 1 subtitle |
| Section Divider | 1 number + 1 heading + optional subhead |
| Content | 1 heading + 5–6 bullets (max 2 lines each) |
| Split | 1 heading + 2 panels, each follows its inner type's limits |
| Diagram | 1 heading + 1 D2-rendered SVG diagram (max 8–10 nodes) |
| Dashboard | 1 heading + 6 KPI cards. Hero values ≤6 chars (numbers, %, short labels). Longer strings belong in the label row. |
| Table | 1 heading + 8 rows; overflow paginates to next slide |
| Code | 1 heading + 10 lines of code |
| Quote | 1 short quote (~25 words / ~150 chars max) + 1 attribution. Longer quotes are content slides, not quote slides. |
| Full-Bleed | 1 heading + 1 subtitle over background |

## Responsive Height Breakpoints

Height-based scaling is more critical for slides than width. Each breakpoint progressively reduces padding, font sizes, and hides decorative elements.

```css
/* Compact viewports */
@media (max-height: 700px) {
  .slide { padding: clamp(24px, 4vh, 40px) clamp(32px, 6vw, 80px); }
  .slide__display { font-size: clamp(36px, 8vw, 72px); }
  .slide--divider .slide__number { font-size: clamp(80px, 16vw, 160px); }
}

/* Small tablets / landscape phones */
@media (max-height: 600px) {
  .slide__decor { display: none; } /* hide decorative SVGs */
  .slide--quote { padding: clamp(32px, 6vh, 60px) clamp(40px, 8vw, 100px); }
  .slide__quote-mark { display: none; }
}

/* Aggressive: landscape phones */
@media (max-height: 500px) {
  .slide { padding: clamp(16px, 3vh, 24px) clamp(24px, 5vw, 48px); }
  .deck-dots { display: none; } /* dots clutter tiny viewports */
  .slide__display { font-size: clamp(28px, 7vw, 48px); }
}

/* Width breakpoint for grids */
@media (max-width: 768px) {
  .slide--content .slide__inner { grid-template-columns: 1fr; }
  .slide--content .slide__aside { display: none; }
  .slide--split .slide__panels { grid-template-columns: 1fr; }
  .slide--dashboard .slide__kpis { grid-template-columns: repeat(2, 1fr); }
}
```

## The Lerian Preset

There is one canonical preset: the Lerian product-console palette in OKLCH with Inter as the body font and JetBrains Mono as mono. It is dark-first (presentations project better dark) with a light mode via `prefers-color-scheme`. These tokens are the same ones in `standard.html` — keep them in sync. Do not introduce alternate named presets or off-brand accent colors; the brand palette is a third rail, not a styling choice.

```css
/* Dark (default) */
:root {
  --font-body: 'Inter', ui-sans-serif, system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', 'Fira Code', ui-monospace, monospace;

  --bg: oklch(27.4% 0.006 286.0);              /* zinc-800 */
  --surface: oklch(37% 0.013 285.8);
  --surface2: oklch(33% 0.010 285.9);
  --surface-elevated: oklch(44.2% 0.017 285.8);

  --border: oklch(44.2% 0.017 285.8);
  --border-bright: oklch(55.2% 0.016 285.9);

  --text: oklch(96.7% 0.001 286.4);
  --text-dim: oklch(70.5% 0.015 286.1);

  --accent: oklch(84.8% 0.166 88.9);           /* sunglow #FDCB28 */
  --accent-dim: rgba(253, 203, 40, 0.15);

  --code-bg: oklch(22% 0.005 286.0);
  --code-text: oklch(90% 0.004 286.2);

  /* Semantic + node palette (de-york green, tangerine) */
  --success: oklch(72% 0.18 150.0);
  --error: oklch(68% 0.20 25.3);
  --info: oklch(70% 0.15 250.0);
  --de-york: oklch(75.6% 0.147 150.0);
  --tangerine: oklch(78.4% 0.106 43.7);
}

@media (prefers-color-scheme: light) {
  :root {
    --bg: oklch(96.7% 0.001 286.4);            /* zinc-100 */
    --surface: oklch(99% 0.002 286.4);
    --surface2: oklch(96% 0.003 286.4);
    --surface-elevated: oklch(98.5% 0.003 286.4);

    --border: oklch(91.9% 0.004 286.3);
    --border-bright: oklch(87.1% 0.006 286.3);

    --text: oklch(27.4% 0.006 286.0);
    --text-dim: oklch(44.2% 0.017 285.8);

    --accent: oklch(76.7% 0.159 83.8);         /* sunglow-500, darker for contrast */
    --accent-dim: rgba(237, 172, 5, 0.12);

    --code-bg: oklch(24% 0.006 286.0);
    --code-text: oklch(92% 0.003 286.2);
  }
}
```

Background: radial sunglow glow, position varied per slide for rhythm. Decorative corner marks in sunglow at low opacity. Title slides use Inter at max weight (800) and scale. Brand identity via the wordmark on the title slide and the persistent bottom-left wordmark. The full token set, SlideEngine, and D2 pan/zoom engine ship ready-to-use in `./templates/slide-deck.html`; the D2 diagram-shell and Lerian D2 preamble live in `./templates/diagram.html` — start there.
