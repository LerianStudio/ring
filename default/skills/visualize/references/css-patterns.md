# CSS Patterns for Diagrams

All color tokens, typography, and base styles are defined in `../templates/standard.html`. This reference shows reusable CSS patterns that build ON TOP of the standard foundation. When using these patterns, the standard template's `:root` variables are already available — reference them directly.

## Theme Setup

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

## Background Atmosphere

Flat backgrounds feel dead. Use subtle gradients or patterns built on the standard palette.

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

## Section / Node Cards

The fundamental building block. A colored card representing a system component, pipeline step, or data entity. The standard template provides `.card` and `.card-elevated` base classes. These patterns extend them for diagram-specific use.

```css
.node {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 16px 20px;
  position: relative;
}

/* Colored accent border (left or top) */
.node--accent-a {
  border-left: 3px solid var(--node-a);
}

/* --- Depth tiers: vary card depth to signal importance --- */

/* Elevated: KPIs, key sections, anything that should pop */
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

/* Hero: executive summaries, focal elements — demands attention */
.node--hero {
  background: color-mix(in srgb, var(--surface) 92%, var(--accent) 8%);
  box-shadow: var(--shadow-lg);
  border-color: color-mix(in srgb, var(--border) 50%, var(--accent) 50%);
}

/* Glass: special-occasion overlay effect (use sparingly) */
.node--glass {
  background: color-mix(in srgb, var(--surface) 60%, transparent 40%);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-color: rgba(255, 255, 255, 0.1);
}

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

## Overflow Protection

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
/* WRONG — causes overflow with inline code badges */
li {
  display: flex;
  align-items: baseline;
  gap: 6px;
}
li::before {
  content: '>';
  flex-shrink: 0;
}

/* RIGHT — text wraps normally */
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

## Mermaid Zoom Controls

Mermaid diagrams are often too small to read comfortably, especially complex flowcharts and sequence diagrams. Add zoom controls to every `.mermaid-wrap` container.

### CSS

```css
.mermaid-wrap {
  position: relative;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 32px 24px;
  overflow: auto;
  scrollbar-width: thin;
  scrollbar-color: var(--border) transparent;
}
.mermaid-wrap::-webkit-scrollbar { width: 6px; height: 6px; }
.mermaid-wrap::-webkit-scrollbar-track { background: transparent; }
.mermaid-wrap::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
.mermaid-wrap::-webkit-scrollbar-thumb:hover { background: var(--text-muted); }

.mermaid-wrap .mermaid {
  transition: transform 0.2s ease;
  transform-origin: top center;
}

.zoom-controls {
  position: absolute;
  top: 8px;
  right: 8px;
  display: flex;
  gap: 2px;
  z-index: 10;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: 2px;
}

.zoom-controls button {
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-family: var(--font-mono);
  font-size: 14px;
  cursor: pointer;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s ease, color 0.15s ease;
}

.zoom-controls button:hover {
  background: var(--border);
  color: var(--text);
}

.mermaid-wrap.is-zoomed { cursor: grab; }
.mermaid-wrap.is-panning { cursor: grabbing; user-select: none; }

@media (prefers-reduced-motion: reduce) {
  .mermaid-wrap .mermaid { transition: none; }
}
```

### HTML

```html
<div class="mermaid-wrap">
  <div class="zoom-controls">
    <button onclick="zoomDiagram(this, 1.2)" title="Zoom in">+</button>
    <button onclick="zoomDiagram(this, 0.8)" title="Zoom out">&minus;</button>
    <button onclick="resetZoom(this)" title="Reset zoom">&#8634;</button>
  </div>
  <pre class="mermaid">
    graph TD
      A --> B
  </pre>
</div>
```

### JavaScript

Add once at the end of the page. Handles button clicks and scroll-to-zoom on all `.mermaid-wrap` containers:

```javascript
function updateZoomState(wrap) {
  var target = wrap.querySelector('.mermaid');
  var zoom = parseFloat(target.dataset.zoom || '1');
  wrap.classList.toggle('is-zoomed', zoom > 1);
}

function zoomDiagram(btn, factor) {
  var wrap = btn.closest('.mermaid-wrap');
  var target = wrap.querySelector('.mermaid');
  var current = parseFloat(target.dataset.zoom || '1');
  var next = Math.min(Math.max(current * factor, 0.3), 5);
  target.dataset.zoom = next;
  target.style.transform = 'scale(' + next + ')';
  updateZoomState(wrap);
}

function resetZoom(btn) {
  var wrap = btn.closest('.mermaid-wrap');
  var target = wrap.querySelector('.mermaid');
  target.dataset.zoom = '1';
  target.style.transform = 'scale(1)';
  updateZoomState(wrap);
}

document.querySelectorAll('.mermaid-wrap').forEach(function(wrap) {
  // Ctrl/Cmd + scroll to zoom
  wrap.addEventListener('wheel', function(e) {
    if (!e.ctrlKey && !e.metaKey) return;
    e.preventDefault();
    var target = wrap.querySelector('.mermaid');
    var current = parseFloat(target.dataset.zoom || '1');
    var factor = e.deltaY < 0 ? 1.1 : 0.9;
    var next = Math.min(Math.max(current * factor, 0.3), 5);
    target.dataset.zoom = next;
    target.style.transform = 'scale(' + next + ')';
    updateZoomState(wrap);
  }, { passive: false });

  // Click-and-drag to pan when zoomed
  var startX, startY, scrollL, scrollT;
  wrap.addEventListener('mousedown', function(e) {
    if (e.target.closest('.zoom-controls')) return;
    var target = wrap.querySelector('.mermaid');
    if (parseFloat(target.dataset.zoom || '1') <= 1) return;
    wrap.classList.add('is-panning');
    startX = e.clientX;
    startY = e.clientY;
    scrollL = wrap.scrollLeft;
    scrollT = wrap.scrollTop;
  });
  window.addEventListener('mousemove', function(e) {
    if (!wrap.classList.contains('is-panning')) return;
    wrap.scrollLeft = scrollL - (e.clientX - startX);
    wrap.scrollTop = scrollT - (e.clientY - startY);
  });
  window.addEventListener('mouseup', function() {
    wrap.classList.remove('is-panning');
  });
});
```

Scroll-to-zoom requires Ctrl/Cmd+scroll to avoid hijacking normal page scroll. Click-and-drag panning activates only when zoomed in (zoom > 1). Cursor changes to `grab`/`grabbing` to signal the behavior. The zoom range is capped at 0.3x-5x.

## Grid Layouts

### Architecture Diagram (2-column with sidebar)
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

### Card Grid (dashboard / metrics)
```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}
```

### Data Tables

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

#### Status Indicators

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

#### Table Summary Row

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

#### Sticky First Column (for very wide tables)

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

### CSS Arrow (vertical, between stacked sections)
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

### CSS Arrow (horizontal, between inline steps)
Use `::after` or a literal arrow character:
```css
.h-arrow::after {
  content: '->';
  color: var(--border-strong);
  font-size: 18px;
  padding: 0 4px;
}
```

### SVG Curved Connector (between arbitrary nodes)
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

### Staggered Fade-In on Load

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

### Hover Lift
```css
.node {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.node:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}
```

### Scale-Fade (for KPI cards, badges, status indicators)

```css
@keyframes fadeScale {
  from { opacity: 0; transform: scale(0.92); }
  to { opacity: 1; transform: scale(1); }
}

.kpi-card {
  animation: fadeScale 0.35s ease-out both;
  animation-delay: calc(var(--i, 0) * 0.06s);
}
```

### SVG Draw-In (for connectors, progress rings, path elements)

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

### CSS Counter (for hero numbers without JS)

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

.kpi-card__value--animated {
  --target: 247;
  counter-reset: val var(--count);
  animation: countUp 1.2s ease-out forwards;
}

.kpi-card__value--animated::after {
  content: counter(val);
}
```

### Choreography

Don't use the same animation for everything. Mix types by element role, with easing stagger (fast-then-slow, not linear):

- **Cards**: `fadeUp` — the default entrance, reliable and subtle
- **KPI / badges**: `fadeScale` — scale draws the eye to important numbers
- **SVG connectors**: `drawIn` — reveals flow direction, pairs with card stagger
- **Hero numbers**: `countUp` — counting motion signals "this number matters"
- **Stagger timing**: `calc(var(--i) * 0.06s)` with lower `--i` values on important elements so they appear first

### Respect Reduced Motion

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

## Sparklines and Simple Charts (Pure SVG)

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

## Responsive Breakpoint

The standard template includes base responsive overrides. For diagram-specific layouts:

```css
@media (max-width: 768px) {
  .arch-grid { grid-template-columns: 1fr; }
  .pipeline { flex-wrap: wrap; gap: 8px; }
  .pipeline__arrow { display: none; }
}
```

## Badges and Tags

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

## Lists Inside Nodes

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

## KPI / Metric Cards

Large hero number with trend indicator and label. For dashboards, review summaries, and impact sections.

```css
.kpi-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 16px;
}

.kpi-card {
  background: var(--surface-elevated);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px;
  box-shadow: var(--shadow-sm);
}

.kpi-card__value {
  font-size: 36px;
  font-weight: 700;
  letter-spacing: -1px;
  line-height: 1.1;
  font-variant-numeric: tabular-nums;
}

.kpi-card__label {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: var(--text-muted);
  margin-top: 6px;
}

.kpi-card__trend {
  font-family: var(--font-mono);
  font-size: 12px;
  margin-top: 4px;
}

.kpi-card__trend--up { color: var(--success); }
.kpi-card__trend--down { color: var(--error); }
```

```html
<div class="kpi-row">
  <div class="kpi-card">
    <div class="kpi-card__value">247</div>
    <div class="kpi-card__label">Lines Added</div>
    <div class="kpi-card__trend kpi-card__trend--up">+34%</div>
  </div>
  <!-- ... more cards -->
</div>
```

## Before / After Panels

> **⛔ DEPRECATED for diff views:** These CSS patterns are superseded by `@pierre/diffs` (see `./libraries.md`). MUST use `@pierre/diffs` for all code diff/review visualizations. These patterns are ONLY retained for non-diff before/after comparisons (e.g., configuration comparisons, text comparisons without syntax highlighting). For code diffs, `@pierre/diffs` provides superior syntax highlighting (Shiki), word-level inline diffs, split/unified toggle, and Shadow DOM isolation.

Two-column comparison with diff-colored headers. For review pages, migration docs, and feature comparisons.

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

### Code Diff Enhancements

> **⛔ DEPRECATED for diff views:** These CSS patterns are superseded by `@pierre/diffs` (see `./libraries.md`). MUST use `@pierre/diffs` for all code diff/review visualizations. These patterns are ONLY retained for non-diff before/after comparisons (e.g., configuration comparisons, text comparisons without syntax highlighting). For code diffs, `@pierre/diffs` provides superior syntax highlighting (Shiki), word-level inline diffs, split/unified toggle, and Shadow DOM isolation.

Extended patterns for code-level diff views with line numbers, added/removed indicators, severity badges, and finding cards. Use alongside the base `.diff-panels` above. See `./templates/code-diff.html` for a complete working example.

**Line numbers via CSS counter:**

```css
.diff-code {
  counter-reset: line;
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.5;
  overflow-x: auto;
}

.diff-line {
  counter-increment: line;
  display: block;
  padding: 1px 12px 1px 48px;
  position: relative;
  min-height: 20px;
  line-height: 20px;
  white-space: pre;
}

.diff-line::before {
  content: counter(line);
  position: absolute;
  left: 0;
  width: 40px;
  text-align: right;
  padding-right: 8px;
  color: var(--text-muted);
  opacity: 0.4;
  font-size: 12px;
  user-select: none;
}
```

**Added / removed / unchanged line indicators:**

```css
.diff-line--added {
  background: var(--success-dim);
}

.diff-line--removed {
  background: var(--error-dim);
  text-decoration: line-through;
  opacity: 0.7;
}

.diff-line--unchanged {
  opacity: 0.55;
}
```

**Hunk headers** (file path + line range):

```css
.diff-hunk-header {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
  background: var(--surface-muted);
  padding: 6px 16px;
  border-bottom: 1px solid var(--border);
  letter-spacing: 0.3px;
}
```

```html
<div class="diff-hunk-header">@@ internal/handler/user.go:45-62 @@</div>
```

**Severity badges:**

```css
.severity-badge {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: var(--radius-sm);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.severity-badge--critical { background: var(--error-dim); color: var(--error); }
.severity-badge--high { background: var(--warning-dim); color: var(--warning); }
.severity-badge--medium { background: var(--accent-dim); color: var(--accent); }
.severity-badge--low { background: var(--surface-muted); color: var(--text-muted); }
```

```html
<span class="severity-badge severity-badge--critical">Critical</span>
<span class="severity-badge severity-badge--high">High</span>
<span class="severity-badge severity-badge--medium">Medium</span>
<span class="severity-badge severity-badge--low">Low</span>
```

**Finding card** (wraps each finding's diff panel):

```css
.finding-card {
  border: 1px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
  margin-bottom: 24px;
}

.finding-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 20px;
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  flex-wrap: wrap;
}

.finding-id {
  font-family: var(--font-mono);
  font-size: 13px;
  font-weight: 600;
  color: var(--text);
}

.finding-category {
  font-size: 11px;
  color: var(--text-muted);
  background: var(--surface-muted);
  padding: 2px 8px;
  border-radius: var(--radius-sm);
}

.finding-file {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-muted);
  margin-left: auto;
}
```

```html
<div class="finding-card">
  <div class="finding-header">
    <span class="finding-id">FINDING-001</span>
    <span class="severity-badge severity-badge--critical">Critical</span>
    <span class="finding-category">Error Handling</span>
    <span class="finding-file">internal/handler/user.go:45-62</span>
  </div>
  <div class="diff-hunk-header">@@ internal/handler/user.go:45-62 @@</div>
  <div class="diff-panels">
    <div class="diff-panel__header diff-panel__header--before">Before</div>
    <div class="diff-panel__header diff-panel__header--after">After</div>
    <div class="diff-panel__body">
      <div class="diff-code">
        <span class="diff-line diff-line--removed">if err != nil {</span>
        <span class="diff-line diff-line--removed">    return err</span>
        <span class="diff-line diff-line--removed">}</span>
      </div>
    </div>
    <div class="diff-panel__body">
      <div class="diff-code">
        <span class="diff-line diff-line--added">if err != nil {</span>
        <span class="diff-line diff-line--added">    return fmt.Errorf("create user: %w", err)</span>
        <span class="diff-line diff-line--added">}</span>
      </div>
    </div>
  </div>
  <details class="collapsible">
    <summary>Why This Matters</summary>
    <div class="collapsible__body">
      <strong>Problem:</strong> Missing error context makes debugging impossible<br>
      <strong>Standard:</strong> golang.md -> Error Handling<br>
      <strong>Impact:</strong> Production incidents take 3x longer to diagnose
    </div>
  </details>
</div>
```

**Highlight.js background override** (⚠️ DEPRECATED for diff views — use `@pierre/diffs` instead, which handles syntax highlighting via Shiki in Shadow DOM):

```css
.diff-panel__body .hljs,
.diff-code .hljs {
  background: transparent;
  padding: 0;
}
```

## Collapsible Sections

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

## Generated Images

For AI-generated illustrations embedded as base64 data URIs via `surf gemini --generate-image`. Use sparingly — hero banners, conceptual illustrations, educational diagrams, decorative accents.

### Hero Banner

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

### Inline Illustration

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

### Side Accent

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
