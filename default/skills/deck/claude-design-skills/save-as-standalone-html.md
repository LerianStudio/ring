# Save as standalone HTML

**Category:** Export
**Output:** Single self-contained HTML file that works offline

## What it does

Bundles an HTML file and all its referenced assets — images, CSS, JS, fonts, external dependencies — into a single file. The output is completely self-contained: no network needed, no broken links, works when emailed, uploaded, or opened from a USB stick.

## When to use

- Sharing an interactive prototype with someone who doesn't have the source project
- Archiving a final artifact where you need exactly one file
- Sending a deck via email or chat (one attachment, no zip)
- Distribution to non-technical recipients — double-click and it works

For slide export to PowerPoint, use PPTX. For print, use Save as PDF.

## How it works

A deterministic browser-side bundler:

1. Parses the source HTML
2. Follows every reference: `<link>`, `<script src>`, `<img>`, `<video>`, CSS `url(...)`, `@font-face src`, etc.
3. Inlines each asset:
   - Images → base64 data URIs (or small SVG inlined as SVG)
   - CSS → inlined `<style>` tags
   - JS → inlined `<script>` tags
   - Fonts → base64 data URIs in `@font-face`
4. Writes the result as one HTML file

## Required: thumbnail template

The input HTML **must** contain a thumbnail template for the splash screen while the bundle unpacks, and as a no-JS fallback:

```html
<template id="__bundler_thumbnail">
  <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
    <rect width="100" height="100" fill="#0a0a0a"/>
    <text x="50" y="58" text-anchor="middle" font-size="40" fill="#f97316">H</text>
  </svg>
</template>
```

Simple iconographic SVG. 30% padding on each side. A glyph, 1–2 letters, or minimal icon.

## Call signature

```
super_inline_html({
  input_path: "deck.html",
  output_path: "deck-bundled.html"
})
```

## Trade-offs

**Wins:**
- True portability
- No broken links ever
- Survives email, chat uploads, offline viewing

**Loses:**
- File size grows — base64 is ~33% larger than binary
- Heavy pages (many fonts/images) can become 5–20MB
- Unpacking adds a brief splash moment on first load

## Don't

- Forget the `__bundler_thumbnail` template — the bundler will fail or show a generic splash
- Use for decks you're sending to PowerPoint — wrong format
- Inline a project with hundreds of images without warning the user about file size

## After bundling

The output file can be opened with `show_html` or presented for download via `present_fs_item_for_download`.
