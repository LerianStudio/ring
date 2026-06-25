# External libraries (CDN)

All color tokens and base styles are defined in `../templates/standard.html`. This reference shows library integration patterns (D2, Chart.js, Highlight.js, anime.js) that build ON TOP of the standard foundation.

Optional CDN libraries for cases where pure CSS/HTML isn't enough. Only include what the diagram actually needs; most diagrams need zero external JS.

## D2 diagrams (replaces Mermaid)

Use for topology, connections, and flows: architecture maps, service graphs, pipelines, sequence-style flows, decision trees, state machines, ER-style entity maps. D2 (the [Terrastruct](https://d2lang.com) diagram language) renders to a **static inline SVG** via its CLI. Dark/light is baked INTO the SVG — no client-side diagram library, no render flicker, no `foreignObject` breakage, no theme-refresh bug. The canonical authoring template is `../templates/diagram.html`; mirror it.

**When to use D2 vs CSS-grid cards:** Reach for D2 when the artifact's message is the *shape of connections* — what flows into what, what depends on what, which path is critical. Reach for CSS-grid card layouts (see `./css-patterns.md`) when the content is rich and text-heavy per node (lists, code, prose, multi-field cards) where automatic graph layout would shrink the text into an unreadable thumbnail. Dashboards use CSS Grid + Chart.js; data tables use `<table>` elements. D2 owns the graph; CSS owns the document.

### Prerequisite: the `d2` binary

D2 is a build-time CLI, not a runtime dependency. Install it once:

```bash
command -v d2 || brew install d2     # or: curl -fsSL https://d2lang.com/install.sh | sh
```

### Lerian D2 preamble (copy verbatim as the head of every `.d2` file)

```
vars: { d2-config: { layout-engine: elk; theme-id: 0; dark-theme-id: 200; pad: 20 } }
classes: {
  source:    { style: { fill: "#FDCB28"; stroke: "#EDAC05"; font-color: "#27272A"; bold: true } }
  process:   { style: { fill: "#F4F4F5"; stroke: "#A1A1AA"; font-color: "#27272A" } }
  datastore: { shape: cylinder; style: { fill: "#5BCD86"; stroke: "#26934F"; font-color: "#1A1A1A" } }
  decision:  { shape: diamond;  style: { fill: "#FDE68A"; stroke: "#EAB308"; font-color: "#27272A" } }
  critical:  { style: { fill: "#F06E43"; stroke: "#C2410C"; font-color: "#FFFFFF"; bold: true } }
  external:  { style: { fill: "#E4E4E7"; stroke: "#71717A"; font-color: "#27272A"; stroke-dash: 4 } }
}
# apply with `myshape.class: source`; semantic edges: success "#26934F", error "#EF4444"
# leave nodes unclassed to inherit the neutral theme. Do NOT invent roles not in the source.
```

The preamble sets a dual theme directly in the SVG: `theme-id: 0` (light) and `dark-theme-id: 200` (dark). D2 emits both palettes gated by `prefers-color-scheme`, so the single static SVG switches automatically with the page.

### Semantic classes — when to use each

Apply a class with `myshape.class: source`. Leave a node unclassed to inherit the neutral theme; do NOT invent roles the source material does not support.

| Class | Shape / treatment | Use for |
|---|---|---|
| `source` | Sunglow fill, bold | Entry points, request origins, the thing that kicks off the flow |
| `process` | Neutral zinc fill | Ordinary processing steps, services, handlers |
| `datastore` | Green cylinder | Databases, caches, queues, any persisted store |
| `decision` | Amber diamond | Branch points, auth checks, conditional routing |
| `critical` | Tangerine fill, bold, white text | The main decision or execution route; the path that matters |
| `external` | Gray, dashed stroke | Third-party systems, boundaries outside the owned codebase |

Semantic edges: color a success edge `#26934F` (de-york) and an error/rejected edge `#EF4444`. Leave ordinary edges unstyled.

### Generation

1. Write `diagram.d2` starting with the Lerian preamble above, then your nodes and edges.
2. Render to SVG:
   ```bash
   d2 --theme=0 --dark-theme=200 --layout=elk diagram.d2 diagram.svg
   ```
3. Strip the leading `<?xml ...?>` declaration from `diagram.svg`.
4. Paste the resulting `<svg>...</svg>` into the `.diagram-canvas` div of `../templates/diagram.html` (replacing the demo SVG).

The pan/zoom engine in the template is SVG-agnostic: it reads the `viewBox` and works as-is. No wiring needed beyond pasting the SVG. The engine is documented in `./css-patterns.md` ("Diagram shell").

### Layout choice

- `elk` (default) — hierarchical, layered layouts. Best for top-down or left-right flows, pipelines, and dependency graphs. This is what the preamble and generation command use.
- `dagre` (alternative) — directed-graph layout; sometimes more compact for dense, less strictly-layered graphs. Swap by passing `--layout=dagre` and setting `layout-engine: dagre` in the preamble.

Pick one and keep it consistent within a single artifact.

### D2 syntax essentials

```
# Nodes get IDs; the readable label is the text after a colon, or the ID itself.
api: API Gateway
svc: Order Service
db: Orders DB

# Apply semantic classes
api.class: source
svc.class: process
db.class: datastore

# Edges
api -> svc: POST /orders
svc -> db: write

# Containers group related nodes (like subgraphs)
auth: {
  login -> validate -> token
}
auth -> api

# Styled edge for a critical/error path
svc -> db: rollback { style.stroke: "#EF4444" }
```

Keep IDs simple and alphanumeric; put readable names in the label. Group source-backed domains, layers, or phases into containers. Use the `critical` class and a colored edge for the main path. Do not let the diagram sprawl past readability — if a graph needs 25+ nodes to be honest, split it into multiple diagrams rather than one unreadable wall.

## Chart.js data visualizations

Use for bar charts, line charts, pie/doughnut charts, radar charts, and other data-driven visualizations in dashboard-type diagrams. Overkill for static numbers; use pure SVG/CSS for simple progress bars and sparklines.

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script>

<canvas id="myChart" width="600" height="300"></canvas>

<script>
  const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const textColor = isDark ? '#A1A1AA' : '#52525B';
  const gridColor = isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)';
  const fontFamily = getComputedStyle(document.documentElement)
    .getPropertyValue('--font-body').trim() || 'system-ui, sans-serif';

  new Chart(document.getElementById('myChart'), {
    type: 'bar',
    data: {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
      datasets: [{
        label: 'Feedback Items',
        data: [45, 62, 78, 91, 120],
        backgroundColor: isDark ? 'rgba(253, 203, 40, 0.6)' : 'rgba(237, 172, 5, 0.6)',
        borderColor: isDark ? '#FDCB28' : '#EDAC05',
        borderWidth: 1,
        borderRadius: 4,
      }]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { labels: { color: textColor, font: { family: fontFamily } } },
      },
      scales: {
        x: { ticks: { color: textColor, font: { family: fontFamily } }, grid: { color: gridColor } },
        y: { ticks: { color: textColor, font: { family: fontFamily } }, grid: { color: gridColor } },
      }
    }
  });
</script>
```

Wrap the canvas in a styled container:
```css
.chart-container {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 20px;
  position: relative;
}

.chart-container canvas {
  max-height: 300px;
}
```

## anime.js orchestrated animations

Use when a diagram has 10+ elements and you want a choreographed entrance sequence (staggered reveals, path drawing, count-up numbers). For simpler diagrams, CSS `animation-delay` staggering is sufficient.

```html
<script src="https://cdn.jsdelivr.net/npm/animejs@3.2.2/lib/anime.min.js"></script>

<script>
  const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (!prefersReduced) {
    anime({
      targets: '.node',
      opacity: [0, 1],
      translateY: [20, 0],
      delay: anime.stagger(80, { start: 200 }),
      easing: 'easeOutCubic',
      duration: 500,
    });

    anime({
      targets: '.connector path',
      strokeDashoffset: [anime.setDashoffset, 0],
      easing: 'easeInOutCubic',
      duration: 800,
      delay: anime.stagger(150, { start: 600 }),
    });

    document.querySelectorAll('[data-count]').forEach(el => {
      anime({
        targets: { val: 0 },
        val: parseInt(el.dataset.count),
        round: 1,
        duration: 1200,
        delay: 400,
        easing: 'easeOutExpo',
        update: (anim) => { el.textContent = anim.animations[0].currentValue; }
      });
    });
  }
</script>
```

When using anime.js, set initial opacity to 0 in CSS so elements don't flash before the animation:
```css
.node { opacity: 0; }

@media (prefers-reduced-motion: reduce) {
  .node { opacity: 1 !important; }
}
```

## Google Fonts typography

The standard template (`../templates/standard.html`) uses **Inter** as the body font (`--font-body`) and **'SF Mono'** / system monospace as the code font (`--font-mono`). You MUST NOT override these -- they ensure visual consistency across all diagrams.

You may optionally load a **secondary display font** for `h1`/`h2` headings to give a specific diagram personality. Always load with `display=swap` for fast rendering.

```html
<!-- Only load a display font; Inter (body) and mono are already in the standard template -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@500;600;700&display=swap" rel="stylesheet">
```

Define the display font as a separate variable; do NOT override `--font-body`:
```css
:root {
  --font-display: 'Sora', system-ui, sans-serif;
  /* --font-body and --font-mono are defined in standard.html; do not redeclare */
}

h1, h2 { font-family: var(--font-display); }
```

The standard template uses Inter as the body font (Lerian brand third-rail: MUST NOT override `--font-body`). The fonts below are suggestions for an optional secondary display font used for `h1`/`h2` headings only.

**Secondary display font suggestions** (rotate; never use the same pairing twice in a row):

| Display Font (h1/h2) | Pairs Well With (mono) | Feel |
|---|---|---|
| Instrument Serif | JetBrains Mono | Editorial, refined |
| Sora | IBM Plex Mono | Technical, precise |
| Fraunces | Source Code Pro | Warm, distinctive |
| Playfair Display | Roboto Mono | Elegant contrast |
| Bricolage Grotesque | Fragment Mono | Bold, characterful |
| Crimson Pro | Noto Sans Mono | Scholarly, serious |
| Red Hat Display | Red Hat Mono | Cohesive family |
| Manrope | Martian Mono | Soft, contemporary |
| Geist | Geist Mono | Vercel-inspired, sharp |

## Highlight.js syntax highlighting

Use for code blocks that need language-aware syntax coloring. Required for non-diff code blocks (inline snippets, implementation previews, standalone `<code>` elements). Lightweight; only load the languages you need.

**CDN (core + theme pair for light/dark):**
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/styles/github-dark.min.css"
      media="(prefers-color-scheme: dark)">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/styles/github.min.css"
      media="(prefers-color-scheme: light)">
<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/highlight.min.js"></script>
<script>hljs.highlightAll();</script>
```

**Selective language loading** (smaller bundle: load only what the page needs):
```html
<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/highlight.min.js"></script>
<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/languages/go.min.js"></script>
<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/languages/typescript.min.js"></script>
<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/languages/css.min.js"></script>
<script>hljs.highlightAll();</script>
```

> **Deprecated: for diff views:** The following CSS override is only needed if you use Highlight.js for non-diff before/after comparisons. For code diffs, use `@pierre/diffs` instead (see below); it handles syntax highlighting internally via Shiki.

**Theme integration with diff panels:** Override `.hljs` background to `transparent` so the diff line backgrounds (green/red tints) show through the syntax-highlighted code:

```css
.diff-panel__body .hljs,
.diff-code .hljs {
  background: transparent;
  padding: 0;
}
```

**When to use:** Any page displaying non-diff code blocks with syntax coloring: implementation previews, standalone code snippets, single-file code display. NOT for diff views (use `@pierre/diffs` instead). Not needed for diagrams, data tables, or architecture overviews unless they embed code snippets.

**Dark mode:** The `github` / `github-dark` theme pair with `prefers-color-scheme` media queries switches automatically. No JS needed for theme toggling.

> **Note:** Highlight.js is still used for non-diff code blocks (inline code snippets, implementation previews, standalone `<code>` elements). Use `@pierre/diffs` below only for diff/review views where you have old vs. new file content.

## @pierre/diffs code diff rendering

**CDN (ESM):** `https://cdn.jsdelivr.net/npm/@pierre/diffs@1.0.11/+esm`

> **Version Update:** When updating the `@pierre/diffs` version, update ALL files that reference it: `libraries.md`, `SKILL.md`, `css-patterns.md`, and `code-diff.html`. Search: `grep -r "@pierre/diffs" default/skills/visualizing/`

**What it is:** A professional code diff renderer built on Shiki. Provides split/unified views with syntax highlighting, word-level inline diffs, line selection, and dark/light theme support. Uses Shadow DOM for style isolation.

**Why ESM from CDN works:** jsDelivr's `+esm` endpoint rewrites bare module specifiers (`"shiki"` -&gt; `"/npm/shiki@3.22.0/+esm"`), resolving all transitive dependencies automatically. No bundler needed.

**MUST use this for all code diff/review visualizations.** Hand-rolled CSS diff panels are deprecated in favor of this library.

### Import pattern

```html
<script type="module">
  import { FileDiff } from 'https://cdn.jsdelivr.net/npm/@pierre/diffs@1.0.11/+esm';
</script>
```

### Basic usage

```js
const instance = new FileDiff({
  theme: { dark: 'pierre-dark', light: 'pierre-light' },
  themeType: 'system',           // Follow OS preference
  diffStyle: 'split',            // 'split' or 'unified'
  diffIndicators: 'bars',        // 'bars', 'classic', or 'none'
  lineDiffType: 'word-alt',      // Word-level inline highlighting
  overflow: 'scroll',            // 'scroll' or 'wrap'
  hunkSeparators: 'line-info',   // Show collapsed line count
});

instance.render({
  oldFile: { name: 'handler.go', contents: oldCode },
  newFile: { name: 'handler.go', contents: newCode },
  containerWrapper: document.getElementById('diff-container'),
});
```

### Lerian theme integration

The component renders inside Shadow DOM, so Lerian's page-level CSS tokens do NOT affect the diff rendering. However, CSS custom properties cascade into Shadow DOM. Use these on the container element:

```css
#diff-container {
  --diffs-font-family: var(--font-mono);  /* Map to Lerian mono token */
  --diffs-font-size: 13px;
  --diffs-line-height: 1.5;
  --diffs-tab-size: 4;
}
```

### Dual theme dark and light auto-switch

```js
const instance = new FileDiff({
  theme: { dark: 'pierre-dark', light: 'pierre-light' },
  themeType: 'system',  // Follows prefers-color-scheme automatically
});
```

To force a specific theme at runtime:
```js
instance.setThemeType('dark');  // or 'light' or 'system'
```

### Key options reference

| Option | Values | Default | Description |
|---|---|---|---|
| `theme` | string or `{ dark, light }` | none | Shiki theme name or dual-theme object |
| `themeType` | `'system'`, `'dark'`, `'light'` | `'system'` | Active theme selection |
| `diffStyle` | `'split'`, `'unified'` | `'split'` | Side-by-side or stacked |
| `diffIndicators` | `'bars'`, `'classic'`, `'none'` | `'bars'` | Change indicator style |
| `lineDiffType` | `'word-alt'`, `'word'`, `'char'`, `'none'` | `'word-alt'` | Inline diff granularity |
| `overflow` | `'scroll'`, `'wrap'` | `'scroll'` | Long line handling |
| `disableLineNumbers` | boolean | `false` | Hide line numbers |
| `disableFileHeader` | boolean | `false` | Hide file header bar |
| `disableBackground` | boolean | `false` | Disable colored line backgrounds |
| `enableLineSelection` | boolean | `false` | Click to select lines |
| `unsafeCSS` | string | none | **CAUTION:** Inject custom CSS into shadow DOM. MUST NOT use with user-supplied input; risk of CSS injection. |

### Instance methods

| Method | Description |
|---|---|
| `render({ oldFile, newFile, containerWrapper })` | Mount and render diff |
| `setThemeType('dark')` | Switch theme without re-render |
| `setOptions(opts)` | Full options replacement (then call `rerender()`) |
| `rerender()` | Force re-render after option changes |
| `cleanUp()` | Destroy instance, remove DOM elements |

### Language detection

Language is auto-detected from filename extension (`handler.go` -&gt; Go). Override with `lang` property:
```js
{ name: 'config', contents: '...', lang: 'yaml' }
```

### Performance notes

- First load fetches Shiki (~2MB+ with grammars); browser caches subsequent loads
- `render()` is synchronous (instant layout), syntax highlighting loads asynchronously
- Language grammars are loaded lazily on first encounter

### Gotchas

**`</script>` in code samples:** When code samples contain `</script>` (common in XSS vulnerability examples), the HTML parser terminates the `<script type="module">` block prematurely. MUST escape as `<\/script>` in all JavaScript string literals. This applies to template literals, single-quoted strings, and double-quoted strings alike. The backslash escape (`\/`) is valid JavaScript; `\/` evaluates to `/`.

```js
// WRONG: breaks the HTML parser:
const before = `<script>alert(1)</script>`;

// CORRECT: escaped for HTML embedding:
const before = `<script>alert(1)<\/script>`;
```
