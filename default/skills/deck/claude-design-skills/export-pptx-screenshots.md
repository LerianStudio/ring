# Export as PPTX (screenshots)

**Category:** Export
**Output:** `.pptx` file with one full-bleed PNG per slide

## What it does

Exports an HTML deck as a PowerPoint file where each slide is a single full-bleed image. **Pixel-perfect visual fidelity** — whatever you see on screen is exactly what ends up in the file. But not editable: recipients can't change text, recolor shapes, or swap elements.

## When to use

- The design relies on CSS effects PowerPoint can't reproduce: filters, complex gradients, clip-paths, custom shadows, backdrop blur, SVG masks, animations frozen at a frame
- You need exact visual fidelity and recipients won't edit it
- Distribution-only decks (marketing, sales leave-behinds)

For editable text and shapes, use the editable export instead.

## How it works

For each slide, the exporter takes a high-quality DOM screenshot and embeds it as a single image sized to the slide. No text extraction, no shape conversion.

Speaker notes are still read automatically from `<script type="application/json" id="speaker-notes">` and attached by index.

## Prerequisites

Same as editable mode:
1. The deck must be showing in the user's preview pane
2. `resetTransformSelector: "deck-stage"` for `<deck-stage>` decks — disables scaling so capture sees authored-size geometry

## Call signature

```
gen_pptx({
  mode: "screenshots",
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

Same per-slide options as editable mode (`showJs`, `delay`, `hideSelectors`, `fontSwaps`, `googleFontImports`).

## Trade-offs

**Screenshots mode wins:**
- Exact visual fidelity
- No worries about CSS-to-PowerPoint translation
- Works with any design, no matter how exotic

**Screenshots mode loses:**
- Large file sizes (one high-res PNG per slide)
- No editability — text is pixels
- Not searchable, not translatable
- Can't swap colors or fonts downstream

## Don't

- Use screenshots mode by default — editable is usually the right choice
- Forget `resetTransformSelector` — you'll get tiny letterboxed captures
- Ship screenshots mode without telling the recipient the deck isn't editable
