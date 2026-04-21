# Wireframe

**Category:** Create
**Output:** Low-fidelity exploration of many ideas on a canvas

## Role

Fast, generative. Wireframes are for **volume** — exploring many approaches before committing to one. Think whiteboard, not mockup. Gray boxes, text labels, arrows, loose sketches.

## When to use

- Early-phase ideation when the direction is unclear
- Exploring 5+ options for a screen or flow
- Product strategy / UX thinking, not visual design
- User explicitly asks for wireframes, sketches, or low-fi

## Scaffolding

Use the **design canvas** starter (`copy_starter_component` with `kind: "design_canvas.jsx"`). It provides:

- `<DCSection id title>` — rows, each holding artboards
- `<DCArtboard id label width height>` — individual wireframe frames
- Pan/zoom, drag-reorder, fullscreen focus on any artboard (←/→/Esc)

Each artboard holds one wireframe. Artboards are static frames — never use `height: 100%` + `overflow: auto/scroll` on inner elements.

## Visual language

- Grayscale only (shades of gray, maybe one accent for emphasis)
- Simple borders, boxes, text labels
- Real copy, not lorem ipsum — copy carries the idea
- Annotations and arrows are welcome
- No shadows, gradients, or polish

## Storyboards

For flows: sequence of artboards across a row, each showing one step with a caption underneath. Arrows between steps to indicate transitions.

## Volume over polish

Give **many** options. 5–10 artboards is normal. Vary the approaches — different layouts, interaction models, information hierarchies, entry points. Users can pick and combine.

Wireframes are disposable. Don't agonize over any one. The value is in comparison.

## Don't

- Add real colors, imagery, or brand treatment — that's not a wireframe anymore
- Get precious about polish
- Give only 2–3 options
- Forget copy — label every element with its actual purpose

## Process

1. Ask what screen/flow to wireframe, how many approaches, what constraints
2. Drop in the design canvas starter
3. Build many artboards fast, varying the approach each time
4. Group related options into sections
