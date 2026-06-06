# Component primitive atlas

This reference defines reusable semantic primitives for `ring:visualize`. It is not a page template and not a CSS dump. Use it to compose source-backed summaries, evidence, legends, decisions, comparisons, flows, findings, and review surfaces inside artifacts built from `../templates/standard.html`.

For low-level styling patterns, use `css-patterns.md`. For CDN and library usage, use `libraries.md`. For long artifacts with section navigation, use `responsive-nav.md`.

## Source discipline

Every primitive must be filled only with facts present in the user request, source files, diffs, logs, docs, or explicitly provided material.

Required rules:
- Do not invent entities, counts, statuses, risks, owners, paths, claims, dates, relationships, excerpts, labels, or references.
- Do not fill an unused placeholder to make a layout look complete.
- Remove unused `SOURCE_*` placeholders before delivery.
- If source data is missing, show a smaller primitive or an empty source state rather than fabricating content.
- Prefer one precise source-backed line over three polished guesses. The viewer is there for judgment, not interior decoration.

Placeholder-only slots:
- `SOURCE_ENTITY`
- `SOURCE_COUNT`
- `SOURCE_STATUS`
- `SOURCE_RELATIONSHIP`
- `SOURCE_RISK`
- `SOURCE_OWNER`
- `SOURCE_PATH`
- `SOURCE_CLAIM`
- `SOURCE_REFERENCE`
- `SOURCE_EXCERPT`
- `SOURCE_DECISION`
- `SOURCE_CHANGE`
- `SOURCE_SEVERITY`
- `SOURCE_ACTION`
- `SOURCE_DATE`
- `SOURCE_PHASE`
- `SOURCE_BOUNDARY`
- `SOURCE_EVIDENCE`

## Primitive contract

| Field | Requirement |
|---|---|
| Intent | State what judgment the primitive helps the viewer make. |
| Use when | Use only when the source contains the matching fact type. |
| Do not use when | Do not use as decoration, filler, or symmetry repair. |
| Required source data | Name the minimum facts needed before rendering the primitive. |
| Slots | Use only `SOURCE_*` placeholders during drafting and replace or remove before delivery. |
| Accessibility | Use semantic HTML first, visible labels, readable contrast, and keyboard-friendly controls. |
| CSS reference | Pull layout and surface styles from `css-patterns.md`; do not paste large CSS here. |

## Primitive index

| Primitive | Use for | Required source | CSS reference |
|---|---|---|---|
| Artifact evidence comment | Preserve source reasoning inside generated HTML. | Brief, thesis, source facts, non-invention boundary. | Not needed. |
| Summary band | Give the 10-second judgment. | Claim, status, evidence. | `css-patterns.md#summary-band` |
| Source summary row | Show compact source facts with equal scan weight. | Entity, count, status, reference. | `css-patterns.md` |
| Legend | Explain meaningful visual encoding. | Encoding labels and meanings. | `css-patterns.md`, `libraries.md` for Mermaid legends. |
| Evidence block | Keep proof beside claims. | Claim, excerpt or reference. | `css-patterns.md#evidence-block` |
| Callout | Surface one warning, constraint, or note. | Claim and severity or status. | `css-patterns.md` |
| Decision rail | Show ordered evidence-backed choices. | Decision, evidence, outcome. | `css-patterns.md#decision-rail` |
| Comparison matrix | Compare entities across shared criteria. | Entities, criteria, values. | `css-patterns.md`, `responsive-nav.md` for wide tables. |
| Axis map | Position items across two dimensions. | Entities and axis values. | `css-patterns.md` |
| Quadrant | Group axis-map items into four named regions. | Entity, x meaning, y meaning. | `css-patterns.md` |
| Swimlane | Align work by owner, phase, boundary, or system. | Owner or phase plus items. | `css-patterns.md#swimlane-canvas` |
| Timeline item | Show ordered events. | Date or phase, event, status. | `css-patterns.md` |
| Entity node | Represent a real source entity. | Entity name and role. | `css-patterns.md`, `libraries.md` for Mermaid. |
| Boundary group | Show ownership, domain, layer, or trust boundary. | Boundary name and member entities. | `css-patterns.md`, `libraries.md` for Mermaid subgraphs. |
| Connector legend | Explain lines and arrows. | Relationship labels and meanings. | `css-patterns.md`, `libraries.md` |
| Status badge set | Normalize status labels. | Status taxonomy and labels. | `css-patterns.md` |
| Finding card | Summarize a review finding. | Severity, claim, path, evidence, action. | `css-patterns.md` |
| Diff controls | Filter or navigate code review changes. | Files, statuses, counts, severities. | `libraries.md` for `@pierre/diffs`, `responsive-nav.md`. |
| Remediation row | Show concrete fix work. | Action, path, owner or status. | `css-patterns.md` |
| Source excerpt | Quote source material. | Excerpt and reference. | `css-patterns.md#evidence-block` |
| Empty source state | Admit missing source data. | Missing fact type and next needed source. | `css-patterns.md` |

## Status taxonomy

Use status labels consistently. Do not create new statuses unless the source already uses them or the artifact defines the mapping in a legend.

### Standard badges

| Badge | Meaning | Slot |
|---|---|---|
| `confirmed` | Source explicitly supports the claim. | `SOURCE_STATUS` |
| `partial` | Source supports part of the claim. | `SOURCE_STATUS` |
| `missing` | Required source data is absent. | `SOURCE_STATUS` |
| `blocked` | Progress depends on an unresolved source-backed blocker. | `SOURCE_STATUS` |
| `unknown` | Source does not establish the fact. Prefer removing the primitive when possible. | `SOURCE_STATUS` |

### Table statuses

| Status | Use for | Do not use for |
|---|---|---|
| `same` | Compared values match. | Assumed stability. |
| `changed` | Source shows a difference. | Visual emphasis without diff evidence. |
| `new` | Source shows a newly introduced item. | Newly noticed items. |
| `removed` | Source shows deletion or absence after prior presence. | Missing source data. |
| `needs review` | Evidence is incomplete but action is required. | Softening a known failure. |

### Severity badges

| Severity | Meaning | Required support |
|---|---|---|
| `critical` | Immediate correctness, security, data, or release risk. | Clear source-backed impact. |
| `high` | Serious issue likely to affect users, maintainers, or operations. | Evidence plus plausible impact. |
| `medium` | Material issue with bounded impact. | Evidence and affected path or entity. |
| `low` | Minor issue, polish, or limited maintainability concern. | Evidence and limited scope. |
| `info` | Context that helps interpretation. | Source reference or excerpt. |

## Primitive guidance

### Artifact evidence comment

Put the brief near the top of generated HTML. This is the audit trail for source fidelity.

```html
<!-- Artifact brief: SOURCE_CLAIM. Audience: SOURCE_OWNER. -->
<!-- Visual thesis: SOURCE_CLAIM. -->
<!-- Design choices: SOURCE_REFERENCE; SOURCE_REFERENCE; SOURCE_REFERENCE. -->
<!-- Non-invention boundary: SOURCE_CLAIM. -->
```

### Summary band

Use one message, one status, and one evidence pocket. If the source does not provide a status, omit the badge.

```html
<section class="summary-band" aria-labelledby="summary-title">
  <div>
    <h2 id="summary-title">SOURCE_CLAIM</h2>
    <p>SOURCE_EVIDENCE</p>
  </div>
  <aside aria-label="Source status">
    <span class="status-badge">SOURCE_STATUS</span>
    <p>SOURCE_REFERENCE</p>
  </aside>
</section>
```

### Source summary row

Use for compact facts from the same source level. Do not mix counts, risks, and owners unless the relationship is explicit.

```html
<ul class="source-summary-row" aria-label="Source summary">
  <li><strong>SOURCE_ENTITY</strong><span>SOURCE_STATUS</span></li>
  <li><strong>SOURCE_COUNT</strong><span>SOURCE_REFERENCE</span></li>
</ul>
```

### Legend

Use a legend whenever visual marks carry meaning.

```html
<dl class="legend" aria-label="Visual legend">
  <div><dt>SOURCE_STATUS</dt><dd>SOURCE_CLAIM</dd></div>
  <div><dt>SOURCE_RELATIONSHIP</dt><dd>SOURCE_CLAIM</dd></div>
</dl>
```

### Evidence block

Evidence should sit near the claim it supports. Prefer excerpts for disputed or high-risk claims.

```html
<aside class="evidence-block" aria-label="Evidence">
  <p>SOURCE_CLAIM</p>
  <cite>SOURCE_REFERENCE</cite>
</aside>
```

### Callout

Use sparingly. A page with five callouts has no callouts, just anxiety in boxes.

```html
<aside class="callout" role="note" aria-label="Source-backed note">
  <strong>SOURCE_SEVERITY</strong>
  <p>SOURCE_CLAIM</p>
</aside>
```

### Decision rail

Use an ordered list when sequence matters.

```html
<ol class="decision-rail" aria-label="Decision rail">
  <li class="decision-item">
    <span class="decision-item__mark">SOURCE_COUNT</span>
    <div><strong>SOURCE_DECISION</strong><p>SOURCE_EVIDENCE</p></div>
  </li>
</ol>
```

### Comparison matrix

Use a table when shared criteria matter more than visual drama.

```html
<table class="comparison-matrix">
  <caption>SOURCE_CLAIM</caption>
  <thead><tr><th scope="col">Criterion</th><th scope="col">SOURCE_ENTITY</th></tr></thead>
  <tbody><tr><th scope="row">SOURCE_CLAIM</th><td>SOURCE_STATUS</td></tr></tbody>
</table>
```

### Axis map

Use only when both axes are source-backed. Include a text fallback table for interpretation.

```html
<section class="axis-map" aria-labelledby="axis-title">
  <h2 id="axis-title">SOURCE_CLAIM</h2>
  <div class="axis-map__plot" role="img" aria-label="SOURCE_CLAIM">
    <span class="axis-map__point" style="--x: SOURCE_COUNT; --y: SOURCE_COUNT">SOURCE_ENTITY</span>
  </div>
  <table class="axis-map__fallback">
    <caption>Text fallback for SOURCE_CLAIM</caption>
    <thead><tr><th scope="col">Entity</th><th scope="col">X axis</th><th scope="col">Y axis</th></tr></thead>
    <tbody><tr><th scope="row">SOURCE_ENTITY</th><td>SOURCE_STATUS</td><td>SOURCE_RELATIONSHIP</td></tr></tbody>
  </table>
</section>
```

### Quadrant

Quadrants are useful only when placement criteria are explicit.

```html
<section class="quadrant" aria-labelledby="quadrant-title">
  <h2 id="quadrant-title">SOURCE_CLAIM</h2>
  <p>X axis: SOURCE_RELATIONSHIP. Y axis: SOURCE_RELATIONSHIP.</p>
  <article aria-label="Quadrant: SOURCE_STATUS"><h3>SOURCE_STATUS</h3><p>Meaning: SOURCE_CLAIM</p><p>SOURCE_ENTITY</p></article>
  <article aria-label="Quadrant: SOURCE_STATUS"><h3>SOURCE_STATUS</h3><p>Meaning: SOURCE_CLAIM</p><p>SOURCE_ENTITY</p></article>
</section>
```

### Swimlane

Use swimlanes to show ownership, phase, system, or boundary alignment.

```html
<section class="swimlane" aria-labelledby="lane-title">
  <h3 id="lane-title">SOURCE_OWNER</h3>
  <article><strong>SOURCE_ENTITY</strong><p>SOURCE_STATUS</p></article>
</section>
```

### Timeline item

Use `time` only for real dates. Use phase text when no date exists.

```html
<li class="timeline-item">
  <time datetime="SOURCE_DATE">SOURCE_DATE</time>
  <strong>SOURCE_CLAIM</strong>
  <p>SOURCE_STATUS</p>
</li>
```

### Entity node

Keep nodes short. Put evidence outside the node.

```html
<article class="entity-node" aria-label="SOURCE_ENTITY">
  <strong>SOURCE_ENTITY</strong>
  <span>SOURCE_STATUS</span>
</article>
```

### Boundary group

Use boundaries for real ownership, trust, domain, layer, or execution separation.

```html
<section class="boundary-group" aria-labelledby="boundary-title">
  <h2 id="boundary-title">SOURCE_BOUNDARY</h2>
  <p>Owner: SOURCE_OWNER</p>
  <div>SOURCE_ENTITY</div>
</section>
```

### Connector legend

Use when arrows or lines encode more than reading order.

```html
<dl class="connector-legend" aria-label="Connector legend">
  <div><dt>SOURCE_RELATIONSHIP</dt><dd>SOURCE_CLAIM</dd></div>
</dl>
```

### Status badge set

Badges must include text. Color is redundant support, not the meaning.

```html
<ul class="status-badge-set" aria-label="Statuses">
  <li><span class="status-badge">SOURCE_STATUS</span></li>
  <li><span class="severity-badge">SOURCE_SEVERITY</span></li>
</ul>
```

### Finding card

Use for reviews and audits. Require severity, claim, path or entity, evidence, and action.

```html
<article class="finding-card">
  <header><span class="severity-badge">SOURCE_SEVERITY</span><h3>SOURCE_CLAIM</h3></header>
  <p><code>SOURCE_PATH</code></p>
  <p>SOURCE_EVIDENCE</p>
  <p><strong>Action:</strong> SOURCE_ACTION</p>
</article>
```

### Diff controls

Use real controls when the user needs filtering or navigation. Use `@pierre/diffs` for code diffs; see `libraries.md`.

```html
<nav class="diff-controls" aria-label="Diff filters">
  <button type="button">SOURCE_STATUS</button>
  <button type="button">SOURCE_SEVERITY</button>
</nav>
```

### Remediation row

Use for sortable or scannable action plans.

```html
<tr class="remediation-row">
  <th scope="row">SOURCE_ACTION</th>
  <td><code>SOURCE_PATH</code></td>
  <td>SOURCE_OWNER</td>
  <td>SOURCE_STATUS</td>
</tr>
```

### Source excerpt

Quote only source material. Do not rewrite invented prose into a blockquote.

```html
<figure class="source-excerpt">
  <blockquote>SOURCE_EXCERPT</blockquote>
  <figcaption>SOURCE_REFERENCE</figcaption>
</figure>
```

### Empty source state

Use this when a missing source fact is itself useful to show. Otherwise remove the primitive.

```html
<aside class="empty-source-state" role="note">
  <strong>Missing source data</strong>
  <p>SOURCE_CLAIM</p>
  <p>Needed source: SOURCE_REFERENCE</p>
</aside>
```

## Red flags

- A primitive contains a `SOURCE_*` placeholder at delivery time.
- A primitive is present only to balance the grid.
- A badge status appears without source evidence or a defined taxonomy.
- A count appears because the layout wanted a number.
- A legend explains colors that do not encode source-backed meaning.
- A finding lacks severity, evidence, or an affected path or entity.
- A quadrant places an entity without source-backed axis values.
- A swimlane uses owners, phases, or boundaries not present in the source.
- A source excerpt is paraphrased but styled as a quotation.
- A comparison matrix has columns with empty or invented values.
- A callout repeats the summary instead of adding a source-backed constraint.
- A page looks complete because missing facts were silently filled. That is not design; it is paperwork with better lighting.
