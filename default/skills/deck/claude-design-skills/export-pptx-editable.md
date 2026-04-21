# Export as PPTX (editable)

**Category:** Export
**Output:** `.pptx` file with native PowerPoint text boxes, shapes, and images

## What it does

Exports an HTML deck as an **editable** PowerPoint file. Text is real text (editable, recolorable, searchable). Shapes are real shapes. Images are embedded. Recipients can edit type, swap colors, move elements.

## When to use

- Recipient will edit the deck in PowerPoint or Keynote
- Text content needs to be searchable or translatable
- Brand team needs to swap colors, fonts, or logos downstream
- Default choice for any deck handoff

For pixel-perfect visual fidelity without edit-ability, use the screenshots export.

## How it works

The exporter runs a synthetic DOM capture per slide. It walks the DOM and emits:

- `<p>`, `<h1>`, `<span>` → native PowerPoint text boxes (with font, size, color, weight)
- `<div>` with backgrounds/borders → native shapes
- `<img>` → embedded images
- SVG → converted to PowerPoint shapes where possible, else rasterized

Speaker notes are read automatically from `<script type="application/json" id="speaker-notes">` and attached by index.

## Prerequisites

1. The deck must be showing in the user's preview pane (`show_to_user` first)
2. Slides must be authored-size geometry, not scaled. For `<deck-stage>` decks, pass `resetTransformSelector: "deck-stage"` — the component honors a `noscale` attribute that disables scaling during capture

## Call signature

```
gen_pptx({
  mode: "editable",
  width: 1920,
  height: 1080,
  slides: [
    { selector: "section[data-label='Cover']" },
    { selector: "section[data-label='Process']", showJs: "goToSlide(1)", delay: 600 },
    ...
  ],
  resetTransformSelector: "deck-stage",
  hideSelectors: [".overlay", ".tapzones"],
})
```

- `slides[].showJs` — sync expression that navigates to that slide (no await)
- `slides[].delay` — ms to wait after showJs before capture (default 600)
- `hideSelectors` — chrome to hide (nav arrows, progress bars)
- `fontSwaps` — substitute fonts via @font-face before capture so layout reflows
- `googleFontImports` — families to inject before capture (weights 400/500/600/700)

## Validation flags

The tool returns flags so you can detect a bad capture:

- `duplicate_adjacent` — `showJs` probably didn't navigate; fix the nav call
- `slide_size_mismatch` — selector or `resetTransformSelector` is wrong
- `no_speaker_notes` — fine if the deck has no notes

Read each flag's message and decide if it's expected for THIS deck.

## Don't

- Skip `resetTransformSelector` for scaled decks — captures will be tiny
- Forget to hide the deck overlay and tap zones — they'll appear in every slide
- Use editable mode if the design relies on CSS filters, complex gradients, or clip-paths — those don't translate to PowerPoint primitives. Use screenshots mode instead.

## After export

The page reloads automatically after capture. DOM mutations (hidden chrome, font swaps, transform reset) are reverted.
