---
name: ring:visualize
description: Generate beautiful, self-contained HTML artifacts for diagrams, reviews, plans, recaps, and complex tables. Use for technical visual judgment; skip for plain markdown, simple tables, mermaid.live links, or explicitly text-only output.
---

# Visual explainer

## When to use
- User asks for a visual explanation, architecture overview, or comparison table
- About to render a complex ASCII table (4+ rows or 3+ columns) in the terminal
- Need a branded, self-contained HTML visualization with Lerian styling
- User asks for diff review, plan review, project recap, or dashboard visualization

## Skip when
- User needs a lightweight, shareable mermaid.live URL (visualize generates self-contained HTML, not mermaid.live links)
- Output is a simple table (fewer than 4 rows and 3 columns) that fits well in terminal
- User explicitly requests plain text or markdown output
- The answer is better as ordinary markdown prose than as a durable artifact

Do not use the markdown/prose skip when the user explicitly asks for visual, diagram, artifact, topology, comparison, map, matrix, quadrant, or axis output. In those cases, generate the visual artifact unless they also explicitly ask for text-only output.

Generate self-contained HTML files for technical diagrams, visualizations, and data tables. Always open the result in the browser. Never fall back to ASCII art when this skill is loaded.

**Proactive table rendering:** If the table has 4+ rows or 3+ columns, use an HTML page. Don't wait for the user to ask.

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
2. Read diagram-specific template:
3. Read `./references/components.md` when the selected diagram row lists it or when composing reusable primitives such as summaries, legends, callouts, findings, comparison matrices, rails, source excerpts, or evidence blocks. Very simple single-diagram artifacts that use no component primitives may skip it only when their selected row does not list it.

| Diagram type | Template to read | Required references |
|---|---|---|
| Architecture (text-heavy, CSS cards) | `./templates/architecture.html` | `./references/css-patterns.md`, `./references/components.md` |
| Architecture/flowchart (topology) | `./templates/mermaid-flowchart.html` | `./references/libraries.md`, `./references/css-patterns.md`, `./references/components.md` |
| Data tables / comparisons | `./templates/data-table.html` | `./references/css-patterns.md`, `./references/components.md` |
| Code diffs / reviews | `./templates/code-diff.html` | `./references/css-patterns.md`, `./references/libraries.md`, `./references/responsive-nav.md`, `./references/components.md` |
| Any page with 4+ sections | - | `./references/responsive-nav.md` |
| Any page using CDN libraries | - | `./references/libraries.md` (NEVER use CDN URLs from memory) |

### 3. Diagram types reference

| Type | Rendering approach |
|---|---|
| Architecture (connections matter) | **Mermaid** `graph TD/LR` with `themeVariables` |
| Architecture (rich card content) | CSS Grid cards + flow arrows |
| Flowchart / pipeline | **Mermaid** `graph TD/LR` |
| Sequence diagram | **Mermaid** `sequenceDiagram` |
| ER / schema | **Mermaid** `erDiagram` |
| State machine | **Mermaid** `stateDiagram-v2` (simple labels) or `flowchart LR` (special chars) |
| Mind map | **Mermaid** `mindmap` |
| Data table / comparison | HTML `<table>` (semantic, accessible, copy-paste) |
| Timeline / roadmap | CSS central line + cards |
| Dashboard / metrics | CSS Grid + Chart.js (CDN from libraries.md) |
| Code diff / change review | `@pierre/diffs` (MANDATORY - no hand-rolled CSS diff panels) |

**Mermaid:** Always use `theme: 'base'` with custom `themeVariables` matching the Lerian palette. Add zoom controls (+/-/reset + Ctrl+scroll) to every `.mermaid-wrap`. Copy pattern from `./references/css-patterns.md`.

**Code diffs:** MUST use `@pierre/diffs` from `./references/libraries.md`. HTML strings embedded in `<script>` blocks: escape `</script>` as `<\/script>`.

**Comparison diagrams:** Default to semantic HTML tables, matrices, quadrants, or axis layouts. Generic card grids are banned unless each card encodes materially different, source-backed attributes that cannot be compared more clearly in a table, matrix, quadrant, or axis.

### 4. Mermaid readability gate

- 1-12 nodes: one Mermaid diagram is usually fine.
- 13-20 nodes: use subgraphs, semantic classes, a legend, and explicit critical-path styling.
- 21+ nodes: split into multiple diagrams or a high-level overview plus focused detail diagrams. Zoom is not a readability excuse.
- Node count means real source entities or concepts, not rendered boxes. Do not collapse multiple concepts into overloaded labels to bypass the threshold.
- Use `subgraph` blocks for real domains, layers, ownership, phases, or execution boundaries.
- Use `classDef` and `class` to distinguish semantic roles such as source, decision, risk, critical path, external dependency, datastore, or output.
- Mark the critical path visually and explain it in nearby copy.
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

Output to `~/.agent/diagrams/` with descriptive filename.

```bash
# macOS
open ~/.agent/diagrams/filename.html
# Linux
xdg-open ~/.agent/diagrams/filename.html
```

Tell the user the file path.

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
- [ ] Swap test: diagram-specific styles define at least 1 background atmosphere, 2+ semantic color aliases, and component classes
- [ ] Distinctiveness: visual thesis plus 3+ design choices tied to the actual content
- [ ] Both themes (light + dark): look intentional, not broken
- [ ] No overflow: all grid/flex children have `min-width: 0`; `overflow-wrap: break-word` on panels
- [ ] Mermaid is under the node limit or split; 21+ nodes never rely on zoom as the readability solution
- [ ] Mermaid node count reflects real source entities/concepts; no overloaded labels hide multiple nodes to bypass limits
- [ ] Mermaid uses semantic classes, subgraphs where helpful, a critical-path treatment, and a legend when colors/strokes carry meaning
- [ ] Mermaid zoom controls present on every `.mermaid-wrap`
- [ ] Comparison visuals use a semantic table, matrix, quadrant, or axis unless a card grid encodes materially different source-backed attributes
- [ ] CDN URLs match `./references/libraries.md` (not from memory)
- [ ] Code diffs use `@pierre/diffs` (NOT hand-rolled CSS diff panels)
- [ ] No banned visual patterns: gradient text, side-stripe accents, default glassmorphism, hero-metric template, identical card grids, lazy cards, or pure black/white hex tokens
- [ ] File opens cleanly: 0 console errors

## File structure

Single self-contained `.html` file. No external assets except CDN links. Order: standard template foundation, diagram-specific styles below the "TEMPLATE-SPECIFIC STYLES" marker, content, optional CDN libraries.
