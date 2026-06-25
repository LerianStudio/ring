# CSS patterns for diagrams

All color tokens, typography, and base styles are defined in `../templates/standard.html`. This reference shows reusable CSS patterns that build ON TOP of the standard foundation. When using these patterns, the standard template's `:root` variables are already available; reference them directly.

CSS patterns are low-level styling and layout references. For assembled semantic primitives such as summaries, legends, findings, rails, matrices, and evidence blocks, use `components.md`.

## Start from story, not cards

Do not begin with a grid of cards. Begin with the artifact brief: audience, physical scene, source facts, entities, relationships, hierarchy, one-sentence message, and non-invention boundary. Cards are a last-mile component, not an information architecture.

Default stance:
- Build a trustworthy product surface for technical judgment.
- Choose one physical-scene metaphor tied to the work: review desk, release control room, ledger workbench, incident war room, architecture map table, migration checklist, or operations console.
- Use restrained product color unless the source data earns richer color.
- Treat color as meaning, not decoration.

Do not use:
- Side-stripe accents. They are cheap salience and collapse every component into the same visual trick.
- Glassmorphism by default. Use solid product surfaces unless the scene explicitly needs layered overlays.
- Gradient text. It is poster behavior, not judgment-interface behavior.
- Identical card grids. Change density, grouping, size, and hierarchy according to the content.
- Radial-gradient-only atmosphere. Atmosphere must support a physical scene, not compensate for weak structure.
- Hero metrics unless the metric exists in the source data and deserves priority.

## Theme setup

The standard template (`../templates/standard.html`) defines both light and dark palettes via custom properties. You do NOT need to redefine the core tokens. For diagram-specific needs, add semantic aliases that map to the standard palette:

```css
/* Standard tokens are already defined by the template:
   --font-body, --font-mono, --bg, --surface, --surface-elevated,
   --surface-muted, --text, --text-secondary, --text-muted, --accent,
   --accent-dim, --success, --warning, --error, --info, --border,
   --border-strong, --border-subtle, --shadow-sm, --shadow-md, --shadow-lg,
   --sunglow-*, --de-york-*, --tangerine-*, --cod-gray-*
*/

/* Add diagram-specific semantic aliases in TEMPLATE-SPECIFIC STYLES */
:root {
  /* Map nodes to extended palette colors for variety */
  --node-a: var(--de-york-400);              /* #5BCD86 */
  --node-a-dim: rgba(91, 205, 134, 0.15);
  --node-b: var(--tangerine-500);            /* #F06E43 */
  --node-b-dim: rgba(240, 110, 67, 0.15);
  --node-c: var(--sunglow-400);              /* #FDCB28 */
  --node-c-dim: rgba(253, 203, 40, 0.2);
}

@media (prefers-color-scheme: dark) {
  :root {
    /* Node colors stay the same; dim variants may need slight adjustment */
    --node-a: var(--de-york-400);
    --node-a-dim: rgba(91, 205, 134, 0.15);
    --node-b: var(--tangerine-500);
    --node-b-dim: rgba(240, 110, 67, 0.15);
    --node-c: var(--sunglow-400);
    --node-c-dim: rgba(253, 203, 40, 0.15);
  }
}
```

## Background atmosphere

Flat backgrounds feel dead, but a radial glow alone is not design. Use subtle gradients or patterns built on the standard palette and tied to the physical scene.

```css
/* Radial glow behind focal area */
body {
  background: var(--bg);
  background-image: radial-gradient(ellipse at 50% 0%, var(--accent-dim) 0%, transparent 60%);
}

/* Faint dot grid */
body {
  background-color: var(--bg);
  background-image: radial-gradient(circle, var(--border) 1px, transparent 1px);
  background-size: 24px 24px;
}

/* Diagonal subtle lines */
body {
  background-color: var(--bg);
  background-image: repeating-linear-gradient(
    -45deg, transparent, transparent 40px,
    var(--border) 40px, var(--border) 41px
  );
}

/* Gradient mesh (pick 2-3 positioned radials from extended palette) */
body {
  background: var(--bg);
  background-image:
    radial-gradient(at 20% 20%, var(--node-a-dim) 0%, transparent 50%),
    radial-gradient(at 80% 60%, var(--node-b-dim) 0%, transparent 50%);
}
```

## Visual story patterns

### Summary band

CSS implementation for the summary band primitive defined in `components.md`. Intent, source requirements, and accessibility rules live there; this section only provides surface, spacing, and responsive layout.

```css
.summary-band {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(220px, 0.6fr);
  gap: 18px;
  align-items: stretch;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  padding: 22px;
}

.summary-band__message {
  font-size: 18px;
  line-height: 1.45;
  color: var(--text);
}

.summary-band__evidence {
  background: var(--surface-muted);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 14px;
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-secondary);
}

@media (max-width: 760px) {
  .summary-band { grid-template-columns: 1fr; }
}
```

### Decision rail

CSS implementation for the decision rail primitive defined in `components.md`. Use that reference for intent, source requirements, and ordered-list accessibility; use this section for spacing and marker styling.

```css
.decision-rail {
  display: grid;
  gap: 10px;
}

.decision-item {
  display: grid;
  grid-template-columns: 28px minmax(0, 1fr);
  gap: 12px;
  align-items: start;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 14px;
}

.decision-item__mark {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: var(--radius-full);
  background: var(--accent-dim);
  color: var(--accent-text);
  font-family: var(--font-mono);
  font-size: 12px;
  font-weight: 700;
}
```

### Swimlane canvas

CSS implementation for swimlane primitives defined in `components.md`. Use that reference for intent, source requirements, lane headings, and accessibility; use this section for canvas layout.

```css
.swimlane-canvas {
  display: grid;
  grid-template-columns: repeat(3, minmax(180px, 1fr));
  gap: 14px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.swimlane {
  min-width: 0;
  background: color-mix(in srgb, var(--surface) 86%, var(--surface-muted) 14%);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 14px;
}

.swimlane__title {
  font-family: var(--font-mono);
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  margin-bottom: 12px;
}
```

### Evidence block

CSS implementation for the evidence block and source excerpt primitives defined in `components.md`. Use that reference for intent, source requirements, quotation rules, and accessibility; use this section for proof-panel styling.

```css
.evidence-block {
  background: var(--surface-muted);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 14px 16px;
  font-size: 13px;
}

.evidence-block__source {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 8px;
}
```

### Comparison matrix

CSS implementation for the comparison matrix primitive defined in `components.md`. Use that reference for intent, source requirements, semantic table structure, and accessibility; use this section for table styling.

```css
.comparison-matrix {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.comparison-matrix th,
.comparison-matrix td {
  padding: 12px 14px;
  border-bottom: 1px solid var(--border);
  text-align: left;
  vertical-align: top;
}

.comparison-matrix tr:last-child td { border-bottom: 0; }
```

### Timeline spine

CSS implementation for timeline primitives defined in `components.md`. Use that reference for intent, source requirements, date handling, and accessibility; use this section for the spine and item styling.

```css
.timeline-spine {
  position: relative;
  display: grid;
  gap: 14px;
  padding-left: 24px;
}

.timeline-spine::before {
  content: '';
  position: absolute;
  top: 4px;
  bottom: 4px;
  left: 8px;
  width: 2px;
  background: var(--border);
}

.timeline-item {
  position: relative;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 14px;
}

.timeline-item::before {
  content: '';
  position: absolute;
  top: 18px;
  left: -22px;
  width: 10px;
  height: 10px;
  border-radius: var(--radius-full);
  background: var(--accent);
  box-shadow: 0 0 0 4px var(--bg);
}
```

## Section / node cards

The fundamental building block. A colored card representing a system component, pipeline step, or data entity. The standard template provides `.card` and `.card-elevated` base classes. These patterns extend them for diagram-specific use.

```css
.node {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 16px 20px;
  position: relative;
}

/* Colored top accent for semantic emphasis */
.node--accent-a {
  border-top: 3px solid var(--node-a);
}

/* --- Depth tiers: vary card depth to signal importance --- */

/* Elevated: source-backed counts, key sections, anything that should pop */
.node--elevated {
  background: var(--surface-elevated);
  box-shadow: var(--shadow-md);
}

/* Recessed: code blocks, secondary content, detail panels */
.node--recessed {
  background: var(--surface-muted);
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.06);
  border-color: var(--border);
}

/* Hero: executive summaries, focal elements that demand attention */
.node--hero {
  background: color-mix(in srgb, var(--surface) 92%, var(--accent) 8%);
  box-shadow: var(--shadow-lg);
  border-color: color-mix(in srgb, var(--border) 50%, var(--accent) 50%);
}

/* Avoid default glass effects. Use solid product surfaces unless the physical scene requires overlay layers. */

/* Section label (monospace, uppercase, small) */
.node__label {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: var(--node-a);
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Colored dot indicator */
.node__label::before {
  content: '';
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
}
```

## Overflow protection

Grid and flex children default to `min-width: auto`, which prevents them from shrinking below their content width. Long text, inline code badges, and non-wrapping elements will blow out containers.

### Global rules

```css
/* Every grid/flex child must be able to shrink */
.grid > *, .flex > *,
[style*="display: grid"] > *,
[style*="display: flex"] > * {
  min-width: 0;
}

/* Long text wraps instead of overflowing */
body {
  overflow-wrap: break-word;
}
```

### Side-by-side comparison panels

```css
.comparison {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.comparison > * {
  min-width: 0;
  overflow-wrap: break-word;
}

@media (max-width: 768px) {
  .comparison { grid-template-columns: 1fr; }
}
```

### Never use `display: flex` on `<li>` for marker characters

Using `display: flex` on a list item to position a `::before` marker creates an anonymous flex item for the remaining text content. That anonymous flex item gets `min-width: auto` and you **cannot** set `min-width: 0` on anonymous boxes. Lines with many inline `<code>` badges will overflow their container with no CSS fix possible.

Use absolute positioning for markers instead:

```css
/* WRONG: causes overflow with inline code badges */
li {
  display: flex;
  align-items: baseline;
  gap: 6px;
}
li::before {
  content: '>';
  flex-shrink: 0;
}

/* RIGHT: text wraps normally */
li {
  padding-left: 14px;
  position: relative;
}
li::before {
  content: '>';
  position: absolute;
  left: 0;
}
```

### List markers overlapping container borders

By default, `list-style-position: outside` places list markers (bullets, numbers) outside the content box. When lists are inside bordered containers (cards, callout boxes), the markers can overlap or extend beyond the border.

```css
/* WRONG: markers overlap container border */
.card ol, .card ul {
  padding-left: 20px;  /* not enough for outside markers */
}

/* RIGHT: use inside positioning */
.card ol, .card ul {
  list-style-position: inside;
}

/* OR: adequate padding for outside markers */
.card ol, .card ul {
  padding-left: 2em;  /* ~32px gives room for markers */
}

/* OR: custom markers with absolute positioning (most control) */
.card ol {
  list-style: none;
  padding-left: 0;
  counter-reset: item;
}
.card ol li {
  counter-increment: item;
  padding-left: 2em;
  position: relative;
}
.card ol li::before {
  content: counter(item) ".";
  position: absolute;
  left: 0;
  color: var(--accent);
  font-weight: 600;
}
```

**Rule of thumb:** Any `<ol>` or `<ul>` inside a bordered container needs either `list-style-position: inside` or `padding-left: 2em` minimum. The default 20px padding is not enough for outside-positioned markers.

## Code blocks

Code blocks need explicit whitespace preservation and a max-height constraint. Without these, code runs together and long files overwhelm the page.

### Basic pattern

```css
.code-block {
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.5;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 16px;
  overflow-x: auto;
  /* CRITICAL: preserve line breaks and indentation */
  white-space: pre-wrap;
  word-break: break-word;
}

/* Constrain height for long code */
.code-block--scroll {
  max-height: 400px;
  overflow-y: auto;
}
```

```html
<pre class="code-block code-block--scroll"><code>// Your code here
function example() {
  return true;
}</code></pre>
```

### With file header

```css
.code-file {
  border: 1px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
}

.code-file__header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-muted);
}

.code-file__body {
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.5;
  padding: 16px;
  background: var(--surface-elevated);
  white-space: pre-wrap;
  word-break: break-word;
  max-height: 500px;
  overflow: auto;
}
```

```html
<div class="code-file">
  <div class="code-file__header">
    <span>src/extension.ts</span>
  </div>
  <pre class="code-file__body"><code>export function activate() {
  // ...
}</code></pre>
</div>
```

For syntax coloring inside these blocks, use Highlight.js (see `./libraries.md`). For diff/review views, use `@pierre/diffs` instead.

### Implementation plans: don't dump full files

For implementation plans and architecture docs, **don't display entire source files inline**. Instead:

1. **Show structure, not code:**
   ```html
   <div class="file-structure">
     <div class="file-structure__path">src/extension.ts</div>
     <ul class="file-structure__outline">
       <li><code>BOOMERANG_INSTRUCTIONS</code> — System prompt for autonomous mode</li>
       <li><code>clearState()</code> — Reset extension state</li>
       <li><code>updateStatus()</code> — Update UI status indicator</li>
       <li><code>/boomerang</code> command — Start autonomous task</li>
       <li><code>before_agent_start</code> hook — Inject instructions</li>
       <li><code>agent_end</code> hook — Generate summary</li>
     </ul>
   </div>
   ```

2. **Use collapsible sections for full code:**
   ```html
   <details class="collapsible">
     <summary>Full implementation (87 lines)</summary>
     <pre class="code-file__body"><code>...</code></pre>
   </details>
   ```

3. **Show key snippets only:**
   ```html
   <p>The core logic intercepts task completion:</p>
   <pre class="code-block"><code>pi.on("agent_end", async () => {
     const summary = generateSummary(workEntries);
     boomerangComplete = true;
   });</code></pre>
   ```

**Anti-patterns:**
- Displaying full source files inline (100+ lines overwhelming the page)
- Code blocks without `white-space: pre-wrap` (code runs together into an unreadable wall)
- No height constraint on long code (page becomes endless scroll)

If someone needs the full file, put it in a collapsible section or link to it.

## Directory tree

For file structures, use `<pre>` with monospace + `white-space: pre`. Tree connectors (`├──`, `└──`, `│`) only work when vertically aligned — they become noise if text wraps.

```css
.dir-tree {
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.7;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 16px 20px;
  overflow-x: auto;
  white-space: pre;
}

.dir-tree .ann { color: var(--text-muted); font-size: 11px; font-style: italic; }
.dir-tree .hl  { color: var(--accent); font-weight: 600; }
```

```html
<pre class="dir-tree">my-project/
├── src/
│   ├── <span class="hl">index.ts</span>       <span class="ann">— entry point</span>
│   ├── services/
│   │   └── <span class="hl">api.py</span>     <span class="ann">(142 lines)</span>
│   └── utils/
├── tests/            <span class="ann">(14 test files)</span>
└── README.md</pre>
```

For labeled trees, wrap in a card. For side-by-side comparisons, put two cards in a grid:

```css
.dir-tree-card { border: 1px solid var(--border); border-radius: var(--radius-lg); overflow: hidden; }
.dir-tree-card__header {
  display: flex; align-items: center; gap: 8px;
  padding: 10px 16px; background: var(--surface); border-bottom: 1px solid var(--border);
  font-family: var(--font-mono); font-size: 11px; font-weight: 600;
  text-transform: uppercase; letter-spacing: 1.5px;
}
.dir-tree-card .dir-tree { border: none; border-radius: 0; }

/* Side-by-side: two .dir-tree-card in a grid */
.dir-compare { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; align-items: start; }
@media (max-width: 900px) { .dir-compare { grid-template-columns: 1fr; } }
```

**Never** render tree connectors inside wrapping text (`white-space: normal`), flex children, or grid items — the vertical pipes lose alignment and the hierarchy becomes unreadable.

## Diagram shell (D2 SVG pan/zoom engine)

D2 diagrams are static inline SVGs (see `./libraries.md` "D2 diagrams"). The canonical `.diagram-shell` wraps any inline `<svg>` in a toolbar plus a pan/zoom viewport. Copy this CSS from `../templates/diagram.html` — it is the source of truth. The engine is **SVG-agnostic**: it reads the SVG's `viewBox` and works on any inline SVG, which is why `slide-deck.html` reuses it unchanged.

### CSS

```css
.diagram-shell{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-lg);box-shadow:var(--shadow-sm);overflow:hidden;margin:8px 0 24px}
.diagram-toolbar{display:flex;gap:6px;align-items:center;padding:10px 14px;border-bottom:1px solid var(--border);background:var(--surface-muted)}
.diagram-toolbar .title{font-size:13px;font-weight:600;color:var(--text)}
.diagram-toolbar .spacer{flex:1}
.diagram-label{font-size:12px;color:var(--text-muted);font-family:var(--font-mono);min-width:42px;text-align:right}
.diagram-toolbar button{font:inherit;font-size:14px;width:30px;height:30px;display:inline-flex;align-items:center;justify-content:center;border:1px solid var(--border-strong);background:var(--surface);color:var(--text-secondary);border-radius:6px;cursor:pointer;transition:.15s}
.diagram-toolbar button:hover{border-color:var(--accent);color:var(--text)}
.diagram-viewport{position:relative;height:600px;overflow:hidden;cursor:grab;background-image:radial-gradient(circle at 1px 1px,var(--border) 1px,transparent 0);background-size:22px 22px}
.diagram-viewport.grabbing{cursor:grabbing}
.diagram-canvas{position:absolute;top:0;left:0;transform-origin:0 0;will-change:transform}
.diagram-canvas svg{display:block}
.diagram-shell:fullscreen{border-radius:0}
.diagram-shell:fullscreen .diagram-viewport{height:calc(100vh - 51px)}
```

### HTML

```html
<div class="diagram-shell">
  <div class="diagram-toolbar">
    <span class="title">Diagram name</span>
    <span class="spacer"></span>
    <span class="diagram-label">100%</span>
    <button data-a="out" title="Zoom out">−</button>
    <button data-a="in" title="Zoom in">+</button>
    <button data-a="one" title="100%">1:1</button>
    <button data-a="fit" title="Fit">⤢</button>
    <button data-a="full" title="Fullscreen">⛶</button>
  </div>
  <div class="diagram-viewport">
    <div class="diagram-canvas">
      <!-- Paste the D2-generated <svg> here (after stripping <?xml?>). -->
    </div>
  </div>
</div>
```

### Engine behavior

The generic engine (full implementation in `../templates/diagram.html`'s `<script>`) drives every `.diagram-shell` on the page. It removes the SVG's fixed `width`/`height`, reads the `viewBox` for natural dimensions, then provides:

- **Toolbar buttons:** zoom out (`−`), zoom in (`+`), reset to `1:1`, fit-to-viewport (`⤢`), and fullscreen (`⛶`).
- **Ctrl/Cmd + wheel** to zoom toward the cursor; plain wheel pans.
- **Drag to pan** (cursor switches to `grabbing`).
- **Double-click to fit.**
- **ResizeObserver** re-fits the diagram when the viewport resizes.

Zoom is capped to a sane range and the live percentage shows in `.diagram-label`. Because it keys off `viewBox` alone, paste any inline SVG into `.diagram-canvas` and it works with no wiring.

## Grid layouts

### Architecture diagram (2-column with sidebar)
```css
.arch-grid {
  display: grid;
  grid-template-columns: 260px 1fr;
  grid-template-rows: auto;
  gap: 20px;
  max-width: 1100px;
  margin: 0 auto;
}

.arch-grid__sidebar { grid-column: 1; }
.arch-grid__main { grid-column: 2; }
.arch-grid__full { grid-column: 1 / -1; }
```

### Pipeline (horizontal steps)
```css
.pipeline {
  display: flex;
  align-items: stretch;
  gap: 0;
  overflow-x: auto;
  padding-bottom: 8px;
}

.pipeline__step {
  min-width: 130px;
  flex-shrink: 0;
}

.pipeline__arrow {
  display: flex;
  align-items: center;
  padding: 0 4px;
  color: var(--border-strong);
  font-size: 18px;
  flex-shrink: 0;
}

/* Parallel branch within a pipeline */
.pipeline__parallel {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
```

### Content-weighted grid

Use a grid only after the story shape is known. Vary span, density, and grouping by importance; do not create identical cards because the data is mildly list-shaped.

```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}
```

### Data tables

Use real `<table>` elements for tabular data. The standard template provides base `.data-table` styles. These patterns extend them for diagram-specific needs. Wrap in a scrollable container for wide tables.

```css
/* Scrollable wrapper for wide tables */
.table-wrap {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.table-scroll {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}

/* Extended table styles (supplement the standard template's .data-table) */
.data-table th {
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--text-muted);
  white-space: nowrap;
}

/* Let text-heavy columns wrap naturally */
.data-table .wide {
  min-width: 200px;
  max-width: 500px;
}

/* Right-align numeric columns */
.data-table td.num,
.data-table th.num {
  text-align: right;
  font-variant-numeric: tabular-nums;
  font-family: var(--font-mono);
}

/* Alternating rows (subtle accent tint) */
.data-table tbody tr:nth-child(even) {
  background: var(--accent-dim);
}

/* Row hover */
.data-table tbody tr {
  transition: background 0.15s ease;
}

/* Last row: no bottom border (container handles it) */
.data-table tbody tr:last-child td {
  border-bottom: none;
}

/* Code inside cells */
.data-table code {
  font-family: var(--font-mono);
  font-size: 11px;
  background: var(--accent-dim);
  color: var(--accent);
  padding: 1px 5px;
  border-radius: 3px;
}

/* Secondary detail text */
.data-table small {
  display: block;
  color: var(--text-muted);
  font-size: 11px;
  margin-top: 2px;
}
```

#### Status indicators

Styled spans for match/gap/warning states. Never use emoji.

```css
.status {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: var(--radius-md);
  white-space: nowrap;
}

.status--match {
  background: var(--success-dim);
  color: var(--success);
}

.status--gap {
  background: var(--error-dim);
  color: var(--error);
}

.status--warn {
  background: var(--warning-dim);
  color: var(--warning);
}

.status--info {
  background: var(--info-dim);
  color: var(--info);
}

/* Dot variant (compact, no text) */
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

.status-dot--match { background: var(--success); }
.status-dot--gap { background: var(--error); }
.status-dot--warn { background: var(--warning); }
```

Usage in table cells:
```html
<td><span class="status status--match">Match</span></td>
<td><span class="status status--gap">Gap</span></td>
<td><span class="status status--warn">Partial</span></td>
```

#### Table summary row

For totals, counts, or aggregate status at the bottom:

```css
.data-table tfoot td {
  background: var(--surface-elevated);
  font-weight: 600;
  font-size: 12px;
  border-top: 2px solid var(--border-strong);
  border-bottom: none;
  padding: 12px 16px;
}
```

#### Sticky first column (for very wide tables)

```css
.data-table th:first-child,
.data-table td:first-child {
  position: sticky;
  left: 0;
  z-index: 1;
  background: var(--surface);
}

.data-table tbody tr:nth-child(even) td:first-child {
  background: color-mix(in srgb, var(--surface) 95%, var(--accent) 5%);
}
```

## Connectors

### CSS arrow (vertical, between stacked sections)
```css
.flow-arrow {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  color: var(--text-muted);
  font-family: var(--font-mono);
  font-size: 12px;
  padding: 6px 0;
}

/* Down arrow via SVG icon */
.flow-arrow svg {
  width: 20px;
  height: 20px;
  fill: none;
  stroke: var(--border-strong);
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}
```

Down arrow SVG (reuse inline):
```html
<svg viewBox="0 0 20 20"><path d="M10 4 L10 16 M6 12 L10 16 L14 12"/></svg>
```

### CSS arrow (horizontal, between inline steps)
Use `::after` or a literal arrow character:
```css
.h-arrow::after {
  content: '->';
  color: var(--border-strong);
  font-size: 18px;
  padding: 0 4px;
}
```

### SVG curved connector (between arbitrary nodes)
For connections that aren't simple vertical/horizontal, use an absolutely positioned SVG overlay:
```html
<svg class="connectors" style="position:absolute;inset:0;width:100%;height:100%;pointer-events:none;">
  <path d="M 150,100 C 150,200 350,100 350,200" fill="none" stroke="var(--accent)" stroke-width="1.5" stroke-dasharray="4 3"/>
  <!-- Arrowhead -->
  <polygon points="348,195 352,205 356,195" fill="var(--accent)"/>
</svg>
```

Position the parent container as `position: relative` to scope the SVG overlay.

## Animations

The standard template provides the base `fadeUp` keyframe and the `.animate` utility class. These additional patterns extend the animation toolkit.

### Staggered fade-in on load

The standard template defines `fadeUp` and `.animate` with `--i` stagger. For diagram-specific node animations:

```css
.node {
  animation: fadeUp 0.4s ease-out both;
  animation-delay: calc(var(--i, 0) * 0.05s);
}
```

Set `--i` per element in the HTML to control stagger order:

```html
<div class="node" style="--i: 0">First</div>
<div class="connector">...</div>
<div class="node" style="--i: 1">Second</div>
<div class="connector">...</div>
<div class="node" style="--i: 2">Third</div>
```

### Hover lift
```css
.node {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.node:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}
```

### Scale-fade (for source-backed counts, badges, status indicators)

```css
@keyframes fadeScale {
  from { opacity: 0; transform: scale(0.92); }
  to { opacity: 1; transform: scale(1); }
}

.source-count {
  animation: fadeScale 0.35s ease-out both;
  animation-delay: calc(var(--i, 0) * 0.06s);
}
```

### SVG draw-in (for connectors, progress rings, path elements)

```css
@keyframes drawIn {
  from { stroke-dashoffset: var(--path-length); }
  to { stroke-dashoffset: 0; }
}

/* Set --path-length to the path's getTotalLength() value */
.connector path {
  stroke-dasharray: var(--path-length);
  animation: drawIn 0.8s ease-in-out both;
  animation-delay: calc(var(--i, 0) * 0.1s);
}
```

### CSS counter (for source-backed counts without JS)

Uses `@property` to animate a custom property as an integer, then display it via `counter()`. No JS required. Falls back to showing the final value immediately in browsers without `@property` support.

```css
@property --count {
  syntax: '<integer>';
  initial-value: 0;
  inherits: false;
}

@keyframes countUp {
  to { --count: var(--target); }
}

.source-count__value--animated {
  --target: var(--source-count-total);
  counter-reset: val var(--count);
  animation: countUp 1.2s ease-out forwards;
}

.source-count__value--animated::after {
  content: counter(val);
}
```

### Choreography

Don't use the same animation for everything. Mix types by element role, with easing stagger (fast-then-slow, not linear):

- **Cards**: `fadeUp`, the default entrance, reliable and subtle
- **Source-backed counts / badges**: `fadeScale`, scale draws the eye to important numbers
- **SVG connectors**: `drawIn`, reveals flow direction, pairs with card stagger
- **Source-backed numbers**: `countUp`, counting motion signals "this number matters"
- **Stagger timing**: `calc(var(--i) * 0.06s)` with lower `--i` values on important elements so they appear first

### Respect reduced motion

The standard template already includes the global reduced-motion override. If you need it in a standalone context:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Sparklines and simple charts (pure SVG)

For simple inline visualizations without a library:

```html
<!-- Sparkline -->
<svg viewBox="0 0 100 30" style="width:100px;height:30px;">
  <polyline points="0,25 15,20 30,22 45,10 60,15 75,5 90,12 100,8"
    fill="none" stroke="var(--accent)" stroke-width="1.5" stroke-linecap="round"/>
</svg>

<!-- Progress bar -->
<div style="height:6px;background:var(--border);border-radius:3px;overflow:hidden;">
  <div style="height:100%;width:72%;background:var(--accent);border-radius:3px;"></div>
</div>
```

## Responsive breakpoint

The standard template includes base responsive overrides. For diagram-specific layouts:

```css
@media (max-width: 768px) {
  .arch-grid { grid-template-columns: 1fr; }
  .pipeline { flex-wrap: wrap; gap: 8px; }
  .pipeline__arrow { display: none; }
}
```

## Badges and tags

The standard template provides `.badge`, `.badge-success`, `.badge-warning`, `.badge-error`, `.badge-info`, `.badge-accent`, and `.badge-neutral`. For diagram-specific compact tags:

```css
.tag {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 500;
  padding: 2px 7px;
  border-radius: var(--radius-sm);
  background: var(--node-a-dim);
  color: var(--node-a);
}
```

## Lists inside nodes

For tool listings, feature lists, table columns:

```css
.node-list {
  list-style: none;
  padding: 0;
  margin: 0;
  font-size: 12px;
  line-height: 1.8;
}

.node-list li {
  padding-left: 14px;
  position: relative;
}

.node-list li::before {
  content: '>';
  color: var(--text-muted);
  font-weight: 600;
  position: absolute;
  left: 0;
}

.node-list code {
  font-family: var(--font-mono);
  font-size: 11px;
  background: var(--accent-dim);
  color: var(--accent);
  padding: 1px 5px;
  border-radius: 3px;
}
```

## Source-backed metric cells

Compact metric cells with trend indicator and label. Use only when the number exists in the source data and supports the artifact's decision. Do not fabricate totals to fill a row.

```css
.metric-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 16px;
}

.metric-cell {
  background: var(--surface-elevated);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px;
  box-shadow: var(--shadow-sm);
}

.metric-cell__value {
  font-size: 36px;
  font-weight: 700;
  letter-spacing: -1px;
  line-height: 1.1;
  font-variant-numeric: tabular-nums;
}

.metric-cell__label {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: var(--text-muted);
  margin-top: 6px;
}

.metric-cell__trend {
  font-family: var(--font-mono);
  font-size: 12px;
  margin-top: 4px;
}

.metric-cell__trend--up { color: var(--success); }
.metric-cell__trend--down { color: var(--error); }
```

```html
<div class="metric-row">
  <div class="metric-cell">
    <div class="metric-cell__value">SOURCE_COUNT</div>
    <div class="metric-cell__label">Source-backed label</div>
    <div class="metric-cell__trend metric-cell__trend--up">SOURCE_DELTA</div>
  </div>
  <!-- Add only source-backed metrics. -->
</div>
```

## Before / after panels

> **Deprecated: for diff views:** These CSS patterns are superseded by `@pierre/diffs` (see `./libraries.md`). MUST use `@pierre/diffs` for all code diff/review visualizations. These patterns are ONLY retained for non-diff before/after comparisons (e.g., configuration comparisons, text comparisons without syntax highlighting). For code diffs, `@pierre/diffs` provides superior syntax highlighting (Shiki), word-level inline diffs, split/unified toggle, and Shadow DOM isolation.

Two-column comparison with diff-colored headers. Use only for non-code before/after comparisons, migration notes, configuration snapshots, and text comparisons without syntax highlighting.

```css
.diff-panels {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
}

.diff-panels > * { min-width: 0; overflow-wrap: break-word; }

.diff-panel__header {
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
  padding: 10px 16px;
}

.diff-panel__header--before {
  background: var(--error-dim);
  color: var(--error);
  border-bottom: 2px solid var(--error);
}

.diff-panel__header--after {
  background: var(--success-dim);
  color: var(--success);
  border-bottom: 2px solid var(--success);
}

.diff-panel__body {
  padding: 16px;
  background: var(--surface);
  font-size: 13px;
  line-height: 1.6;
}

/* Highlight changed items within a panel */
.diff-changed {
  background: var(--accent-dim);
  border-radius: 3px;
  padding: 0 3px;
}

@media (max-width: 768px) {
  .diff-panels { grid-template-columns: 1fr; }
}
```

```html
<div class="diff-panels">
  <div class="diff-panel__header diff-panel__header--before">Before</div>
  <div class="diff-panel__header diff-panel__header--after">After</div>
  <div class="diff-panel__body">Previous implementation...</div>
  <div class="diff-panel__body">New implementation...</div>
</div>
```

### Code diff guidance

MUST use `@pierre/diffs` from `./libraries.md` for all code diff/review visualizations. Do not build code-level diff views with CSS panels, line counters, added/removed spans, or syntax-highlighting overrides.

Use the before/after panel pattern above only for non-code comparisons such as configuration values, prose revisions, policy changes, option tables, or source brief versus plan summaries.

## Collapsible sections

Native `<details>/<summary>` with styled disclosure. Zero JS, accessible. For lower-priority content: file maps, decision logs, reference sections.

```css
details.collapsible {
  border: 1px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
}

details.collapsible summary {
  padding: 14px 20px;
  background: var(--surface);
  font-family: var(--font-mono);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  list-style: none;
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--text);
  transition: background 0.15s ease;
}

details.collapsible summary:hover {
  background: var(--surface-elevated);
}

details.collapsible summary::-webkit-details-marker { display: none; }

/* Chevron indicator */
details.collapsible summary::before {
  content: '\25B8';
  font-size: 11px;
  color: var(--text-muted);
  transition: transform 0.15s ease;
}

details.collapsible[open] summary::before {
  transform: rotate(90deg);
}

details.collapsible .collapsible__body {
  padding: 16px 20px;
  border-top: 1px solid var(--border);
  font-size: 13px;
  line-height: 1.6;
}
```

```html
<details class="collapsible">
  <summary>File Map (14 files changed)</summary>
  <div class="collapsible__body">
    <!-- content here -->
  </div>
</details>
```

## Prose page elements

Patterns for documentation, articles, and other reading-first content. The key difference from visual explanations: optimize for sustained reading, not scanning.

### Body text settings

```css
/* Comfortable reading baseline */
.prose {
  font-size: clamp(17px, 1.1vw + 14px, 19px);
  line-height: 1.7;
  max-width: 65ch;  /* ~600-680px */
  text-wrap: pretty;
}

.prose p {
  margin-bottom: 1.5em;
}

/* Narrow column for essays/literary content */
.prose--narrow {
  max-width: 60ch;
  line-height: 1.8;
}

/* Wide column for technical content with code */
.prose--wide {
  max-width: 75ch;
  line-height: 1.6;
}
```

### Lead paragraph

Opening paragraph styled distinctly from body text.

```css
/* Larger size */
.lead {
  font-size: 20px;
  line-height: 1.6;
  color: var(--text);
  margin-bottom: 32px;
}

/* With drop cap */
.lead--dropcap::first-letter {
  float: left;
  font-family: var(--font-display);
  font-size: 64px;
  font-weight: 600;
  line-height: 0.85;
  padding-right: 12px;
  padding-top: 6px;
  color: var(--accent);
}
```

### Pull quotes

Key insights pulled out for emphasis. Use sparingly — one or two per article maximum.

```css
/* Border left — most versatile */
.pullquote {
  margin: 48px 0;
  padding-left: 24px;
  border-left: 3px solid var(--accent);
}
.pullquote p {
  font-size: 22px;
  font-style: italic;
  line-height: 1.4;
  color: var(--text);
  margin: 0;
}

/* Centered with quotation mark */
.pullquote--centered {
  margin: 56px 0;
  padding: 32px 40px;
  border-top: 1px solid var(--border);
  border-bottom: 1px solid var(--border);
  text-align: center;
  position: relative;
}
.pullquote--centered::before {
  content: '"';
  position: absolute;
  top: -12px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--bg);
  padding: 0 16px;
  font-family: var(--font-display);
  font-size: 48px;
  color: var(--accent);
  line-height: 1;
}
```

### Section dividers

```css
/* Horizontal rule */
hr {
  border: none;
  height: 1px;
  background: var(--border);
  margin: 48px 0;
}

/* Ornamental divider — use: <div class="divider">* * *</div> */
.divider {
  text-align: center;
  margin: 48px 0;
  color: var(--text-muted);
  font-size: 18px;
  letter-spacing: 12px;
}
```

### Article hero patterns

```css
/* Centered minimal — essays, personal posts */
.hero--centered {
  text-align: center;
  padding: 80px 24px 64px;
  max-width: 800px;
  margin: 0 auto;
}
.hero__category {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--accent);
  margin-bottom: 16px;
}
.hero__title {
  font-size: clamp(32px, 5vw, 48px);
  font-weight: 600;
  line-height: 1.15;
  margin-bottom: 16px;
}
.hero__subtitle {
  font-size: 20px;
  font-style: italic;
  color: var(--text-muted);
  max-width: 600px;
  margin: 0 auto 24px;
}
.hero__meta {
  font-size: 13px;
  color: var(--text-muted);
}

/* Left-aligned editorial — features, documentation */
.hero--editorial {
  padding: 100px 40px 60px;
  max-width: 1000px;
  margin: 0 auto;
}
.hero--editorial .hero__title {
  font-size: clamp(40px, 7vw, 72px);
  font-weight: 800;
  line-height: 1.0;
  letter-spacing: -2px;
}
```

### Callout boxes

For warnings, tips, notes, and key takeaways.

```css
.callout {
  padding: 16px 20px;
  border-radius: var(--radius);
  border-left: 4px solid var(--callout-border);
  background: var(--callout-bg);
  margin: 24px 0;
}

.callout--info {
  --callout-border: var(--accent);
  --callout-bg: color-mix(in srgb, var(--accent) 10%, transparent);
}

.callout--warning {
  --callout-border: var(--warning);
  --callout-bg: color-mix(in srgb, var(--warning) 10%, transparent);
}

.callout--success {
  --callout-border: var(--success);
  --callout-bg: color-mix(in srgb, var(--success) 10%, transparent);
}

.callout__title {
  font-weight: 600;
  margin-bottom: 8px;
  color: var(--callout-border);
}

/* Lists inside callouts need padding fix (see "List markers overlapping container borders") */
.callout ul, .callout ol {
  padding-left: 1.5em;
  margin: 8px 0 0 0;
}
```

### Prose anti-patterns

Avoid these in reading-first content:
- Body text smaller than 16px
- Line-height below 1.5
- Measure wider than 75ch (text spanning full viewport)
- Pull quotes every other paragraph
- Drop caps on every section
- Busy background patterns behind text

Note: a `data-theme` JS toggle is unnecessary here. The standard template bakes both palettes into `prefers-color-scheme`; prose inherits that dual theme for free.

## Generated images

For AI-generated illustrations embedded as base64 data URIs via `surf gemini --generate-image`. Use sparingly: hero banners, conceptual illustrations, educational diagrams, decorative accents.

### Hero banner

Full-width image cropped to a fixed height with a gradient fade into the page background. Place at the top of the page before the title, or between the title and the first content section.

```css
.hero-img-wrap {
  position: relative;
  border-radius: var(--radius-lg);
  overflow: hidden;
  margin-bottom: 24px;
}

.hero-img-wrap img {
  width: 100%;
  height: 240px;
  object-fit: cover;
  display: block;
}

/* Gradient fade into page background */
.hero-img-wrap::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 50%;
  background: linear-gradient(to top, var(--bg), transparent);
  pointer-events: none;
}
```

```html
<div class="hero-img-wrap">
  <img src="data:image/png;base64,..." alt="Descriptive alt text">
</div>
```

Generate with `--aspect-ratio 16:9` for hero banners.

### Inline illustration

Centered image with border, shadow, and optional caption. Use within content sections for conceptual or educational illustrations.

```css
.illus {
  text-align: center;
  margin: 24px 0;
}

.illus img {
  max-width: 480px;
  width: 100%;
  border-radius: var(--radius);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
}

.illus figcaption {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 8px;
}
```

```html
<figure class="illus">
  <img src="data:image/png;base64,..." alt="Descriptive alt text">
  <figcaption>How the message queue routes events between services</figcaption>
</figure>
```

Generate with `--aspect-ratio 1:1` or `--aspect-ratio 4:3` for inline illustrations.

### Side accent

Small image floated beside a section. Use when the illustration supports but doesn't dominate the content.

```css
.accent-img {
  float: right;
  max-width: 200px;
  margin: 0 0 16px 24px;
  border-radius: var(--radius);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
}

@media (max-width: 768px) {
  .accent-img {
    float: none;
    max-width: 100%;
    margin: 0 0 16px 0;
  }
}
```

```html
<img class="accent-img" src="data:image/png;base64,..." alt="Descriptive alt text">
```
