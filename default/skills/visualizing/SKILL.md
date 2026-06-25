---
name: ring:visualizing
description: "Generating self-contained, Lerian-branded HTML artifacts — D2 diagrams, comparison tables/matrices, code diffs, dashboards, slide decks, and plan/diff/recap reviews — from mandatory templates, then opening them in the browser. Use for architecture overviews, any table with 4+ rows or 3+ columns, slide presentations, or visual diff/plan/review output. Skip for simple tables that fit the terminal or text-only answers."
---

# Visual explainer

## When to use
- User asks for a visual explanation, architecture overview, or comparison table
- About to render a complex ASCII table (4+ rows or 3+ columns) in the terminal
- Need a branded, self-contained HTML visualization with Lerian styling
- User asks for a slide deck or presentation
- User asks for diff review, plan review, project recap, or dashboard visualization

## Skip when
- Output is a simple table (fewer than 4 rows and 3 columns) that fits well in terminal
- User explicitly requests plain text or markdown output
- The answer is better as ordinary markdown prose than as a durable artifact

Do not use the markdown/prose skip when the user explicitly asks for visual, diagram, artifact, topology, comparison, map, matrix, quadrant, slides, or axis output. In those cases, generate the visual artifact unless they also explicitly ask for text-only output.

Generate self-contained HTML files for technical diagrams, visualizations, and data tables. Always open the result in the browser. Never fall back to ASCII art when this skill is loaded.

**Proactive table rendering:** If the table has 4+ rows or 3+ columns, use an HTML page. Don't wait for the user to ask.

## Diagram engine: D2 (not Mermaid)

Topology/connection diagrams are rendered by the **D2 CLI** to a static inline SVG, then embedded in the page. D2 (ELK/dagre layout) produces clean, deterministic layouts; the SVG is static, so there is no render flicker, no foreignObject breakage, and no theme-refresh bug. Dark/light is baked INTO the SVG by D2.

**Prerequisite — the `d2` binary:**
```bash
command -v d2 || brew install d2     # or: curl -fsSL https://d2lang.com/install.sh | sh
```
If `d2` is not installed and cannot be installed, fall back to CSS-grid card layouts (architecture.html) for structure — never to ASCII art.

**Generation flow:**
1. Write `diagram.d2`, starting with the **Lerian D2 preamble** (in `./templates/diagram.html` and `./references/libraries.md`).
2. `d2 --theme=0 --dark-theme=200 --layout=elk diagram.d2 diagram.svg`
3. Strip the leading `<?xml ...?>` declaration; paste the `<svg>...</svg>` into `.diagram-canvas`.
4. The pan/zoom engine in `diagram.html` is SVG-agnostic — it reads `viewBox` and works as-is.

## Standard template (mandatory)

**MUST Read `./templates/standard.html` before generating any HTML.** Copy verbatim:
1. Complete `<style>` block (above "DO NOT MODIFY" marker)
2. `<header class="lerian-header">` with inline Lerian logo SVG
3. `<footer class="lerian-footer">` with logo, company name, "Generated with Ring"
4. Date auto-fill `<script>`

**Fixed (cannot change):** Inter font, Lerian color palette (sunglow accent, zinc neutrals), logo, footer, dark mode.
**Variable (customize per diagram):** Layout, secondary display font, background atmosphere, accent emphasis, animations.

## Template adaptation rules

- `./templates/standard.html` is the only copy foundation. Start every artifact from its foundation, header, footer, and date script.
- Diagram-specific templates are pattern references only. Borrow structural ideas, not their demo content.
- Never reuse sample titles, entities, metrics, file names, services, flows, status labels, or domain examples unless they are present in the user request or source data.
- Replace every demo label before delivery. If a title or metric would still make sense in an unrelated company, it is probably leaked demo content.
- Do not invent missing facts to make the visual feel complete. Empty space is better than fabricated certainty.

## Workflow

### 1. Build the artifact brief before style
- Audience: who is looking and what decision must they make?
- Physical scene: choose a surface metaphor tied to the work, such as incident war room, ledger workbench, release control room, architecture map table, review desk, or operations console.
- Source facts: list the facts explicitly present in the prompt, files, diff, logs, or source material.
- Entities: name the real systems, files, teams, actors, services, stages, or concepts.
- Relationships: define real dependencies, sequence, ownership, risk, contrast, or causality.
- Hierarchy: identify what deserves visual priority and what should recede.
- One-sentence message: state what the viewer should understand after 10 seconds.
- Non-invention boundary: name what cannot be inferred and must not appear.
- HTML evidence comment: write the artifact brief, visual thesis, and 3+ source-tied design choices into a top-level HTML comment near the top of the generated file, immediately after the template/source comment and before external fonts or styles. Use explicit labels such as `<!-- Artifact brief: ... -->`, `<!-- Visual thesis: ... -->`, and `<!-- Design choices: ... -->`.

### 2. Structure (must read before writing)
1. Read `./templates/standard.html` (ALWAYS first)
2. Read the diagram-specific template for the selected row below
3. Read `./references/components.md` when the selected diagram row lists it or when composing reusable primitives such as summaries, legends, callouts, findings, comparison matrices, rails, source excerpts, or evidence blocks. Very simple single-diagram artifacts that use no component primitives may skip it only when their selected row does not list it.

| Diagram type | Template to read | Required references |
|---|---|---|
| Architecture (text-heavy, CSS cards) | `./templates/architecture.html` | `./references/css-patterns.md`, `./references/components.md` |
| Architecture / flowchart / topology (D2) | `./templates/diagram.html` | `./references/libraries.md`, `./references/css-patterns.md`, `./references/components.md` |
| Data tables / comparisons | `./templates/data-table.html` | `./references/css-patterns.md`, `./references/components.md` |
| Code diffs / reviews | `./templates/code-diff.html` | `./references/css-patterns.md`, `./references/libraries.md`, `./references/responsive-nav.md`, `./references/components.md` |
| Slide decks / presentations | `./templates/slide-deck.html` | `./references/slide-patterns.md`, `./references/css-patterns.md` |
| Any page with 4+ sections | - | `./references/responsive-nav.md` |
| Any page using CDN libraries | - | `./references/libraries.md` (NEVER use CDN URLs from memory) |

### 3. Diagram types reference

| Type | Rendering approach |
|---|---|
| Architecture (connections matter) | **D2** with semantic `classes`, ELK layout |
| Architecture (rich card content) | CSS Grid cards + flow arrows |
| Flowchart / pipeline | **D2** (`elk` layout; `dagre` alternative) |
| Sequence diagram | **D2** `shape: sequence_diagram` |
| ER / schema | **D2** `shape: sql_table` |
| State machine | **D2** (nodes + edges, or `dagre` for compact states) |
| Mind map / hierarchy | **D2** (nested containers) |
| Data table / comparison | HTML `<table>` (semantic, accessible, copy-paste) |
| Timeline / roadmap | CSS central line + cards |
| Dashboard / metrics | CSS Grid + Chart.js (CDN from libraries.md) |
| Code diff / change review | `@pierre/diffs` (MANDATORY - no hand-rolled CSS diff panels) |
| Slide deck | `100dvh` slides using `./references/slide-patterns.md` |

**D2:** Always start the `.d2` source with the Lerian preamble (dual-theme `vars` + semantic `classes`). Apply roles with `shape.class: source` etc. Leave nodes unclassed to inherit the neutral theme. Render with `d2 --theme=0 --dark-theme=200 --layout=elk`. Copy the embed + pan/zoom pattern from `./templates/diagram.html`.

**Code diffs:** MUST use `@pierre/diffs` from `./references/libraries.md`. HTML strings embedded in `<script>` blocks: escape `</script>` as `<\/script>`.

**Comparison diagrams:** Default to semantic HTML tables, matrices, quadrants, or axis layouts. Generic card grids are banned unless each card encodes materially different, source-backed attributes that cannot be compared more clearly in a table, matrix, quadrant, or axis.

### 4. Diagram readability gate

- 1-12 nodes: one D2 diagram is usually fine.
- 13-20 nodes: use D2 containers for domains/layers, semantic classes, a legend, and explicit critical-path styling.
- 21+ nodes: split into multiple diagrams or a high-level overview plus focused detail diagrams. Pan/zoom is not a readability excuse.
- Node count means real source entities or concepts, not rendered boxes. Do not collapse multiple concepts into overloaded labels to bypass the threshold.
- Use D2 containers for real domains, layers, ownership, phases, or execution boundaries.
- Use semantic `classes` (source, process, datastore, decision, critical, external) to distinguish roles. Mark the critical path visually and explain it in nearby copy.
- Include a legend when color or stroke means something.
- Keep node labels short. Put explanation in adjacent evidence blocks, not inside giant nodes.

### 5. Style (applied on top of standard template foundation)

- Body font: ALWAYS Inter. MAY add secondary display font for headings only.
- Colors: Use standard template CSS custom properties (`--bg`, `--surface`, `--accent`, etc.). Prefer OKLCH for new raw colors. Do not introduce pure black or pure white hex tokens.
- Backgrounds: choose a physical-scene treatment tied to the content. Restrained product surfaces are the default; richer color must be earned by the data.
- Depth: 3+ distinct visual levels (hero/elevated, default surface, recessed/muted).
- Avoid banned shortcuts: no gradient text, no side-stripe accents, no default glassmorphism, no hero-metric template, no identical card grids, no lazy cards, no logo-only personality, no radial-gradient-only atmosphere.
- Animations: `fadeUp` for panels, `fadeScale` for source-backed counts/badges, `countUp` for real numbers. Respect `prefers-reduced-motion`.

### 6. Distinctiveness gate

Before writing HTML, define:
- Visual thesis: the organizing idea of the page, not just "nice dashboard".
- 3+ content-tied design choices: layout, typography scale, grouping, color semantics, density, annotation, or motion choices that only make sense for this source material.
- Red flags to reject: generic card grid, interchangeable title, logo-only personality, radial-gradient-only atmosphere, decorative color with no semantic role, and any hero metric not present in the source.

### 7. Deliver

Output to `~/.agent/diagrams/` with descriptive filename. For D2 diagrams, generate the `.svg` first, embed it, then open the page.

```bash
# macOS
open ~/.agent/diagrams/filename.html
# Linux
xdg-open ~/.agent/diagrams/filename.html
```

Tell the user the file path.

## Modes

These reuse the foundation, templates, and references above. They are output formats, not analysis engines.

- **Slide deck** — `./templates/slide-deck.html` + `./references/slide-patterns.md`. Use when the user asks for slides or a presentation. Inventory the source first and map every item to a slide; do not drop content to fit a fixed slide count — add slides. Diagram slides embed a D2 SVG.
- **Project recap** — a mental-model snapshot for context-switching back to a project: project identity, architecture (D2), recent activity, current state, risks/cognitive debt, key files, next steps. Every claim cited to source.
- **Fact-check** — verify a document against actual code: extract claims, inspect source / `git show`, classify each as verified / corrected / unsupported / unverifiable, and correct in place with a verification summary.
- **Diff review / Plan review (renderers)** — VISUAL renderings of a diff or a plan-vs-codebase (file map, architecture-impact diagram, before/after panels, risk matrix). These RENDER findings; they do **not** replace `ring:reviewing-code` (which dispatches the reviewer subagent pool) or `ring:writing-plans` (the planning engine). Correct composition: the engine produces findings → this mode renders them. Color language: red=removed, green=added, amber=modified/risk, blue=context.

## Quality checks (hard gates)

Verify before delivering:
- [ ] Standard template foundation present: search generated HTML for exact SVG logo path, "Generated with Ring", `font-family: 'Inter'`
- [ ] No token conflicts: template-specific CSS doesn't redefine `--bg`, `--surface`, `--text`, `--accent`, etc.
- [ ] Source fidelity: every title, entity, metric, relationship, status, component, file path, and flow is traceable to the user request or source data
- [ ] Primitive fidelity: any selected primitive from `./references/components.md` follows its intent, required source data, accessibility notes, and CSS reference
- [ ] Placeholder hygiene: all unused `SOURCE_*` placeholders are removed, and remaining rendered facts are replaced only with source-backed facts
- [ ] No primitive is filled to make the layout look complete; missing data is omitted or shown as an empty source state
- [ ] HTML evidence comment present near the top of the generated file with `Artifact brief:`, `Visual thesis:`, and `Design choices:` labels
- [ ] Artifact brief is visible in that HTML comment: audience, physical scene, source facts, entities, relationships, hierarchy, message, and non-invention boundary
- [ ] No demo leakage from templates: no copied sample service names, CI/CD flows, fake audit numbers, placeholder files, or invented metrics
- [ ] No invented metrics, components, flows, risks, owners, dates, or statuses
- [ ] Squint test: 3 distinct visual depth levels visible
- [ ] Distinctiveness: visual thesis plus 3+ design choices tied to the actual content
- [ ] Both themes (light + dark): look intentional, not broken
- [ ] No overflow: all grid/flex children have `min-width: 0`; `overflow-wrap: break-word` on panels
- [ ] D2 diagrams start with the Lerian preamble (dual-theme vars + semantic classes); rendered with `--theme=0 --dark-theme=200`
- [ ] D2 diagram is under the node limit or split; 21+ nodes never rely on pan/zoom as the readability solution
- [ ] D2 node count reflects real source entities/concepts; no overloaded labels hide multiple nodes to bypass limits
- [ ] D2 SVG is embedded inline (the `<?xml?>` declaration stripped); the pan/zoom shell from `diagram.html` is present
- [ ] Comparison visuals use a semantic table, matrix, quadrant, or axis unless a card grid encodes materially different source-backed attributes
- [ ] CDN URLs match `./references/libraries.md` (not from memory)
- [ ] Code diffs use `@pierre/diffs` (NOT hand-rolled CSS diff panels)
- [ ] Slide decks: each slide fits one `100dvh` viewport, nav chrome present, source coverage preserved
- [ ] No banned visual patterns: gradient text, side-stripe accents, default glassmorphism, hero-metric template, identical card grids, or pure black/white hex tokens
- [ ] File opens cleanly: 0 console errors

## File structure

Single self-contained `.html` file. No external assets except CDN links. Order: standard template foundation, diagram-specific styles below the "TEMPLATE-SPECIFIC STYLES" marker, content, optional CDN libraries.
