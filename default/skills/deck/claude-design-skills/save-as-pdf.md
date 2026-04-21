# Save as PDF

**Category:** Export
**Output:** Print-ready PDF

## What it does

Opens the HTML artifact in a new browser tab configured for printing. The user presses **Cmd+P** (Mac) or **Ctrl+P** (Windows), selects "Save as PDF", and gets a clean PDF export.

## When to use

- Final decks being distributed to recipients who don't need to edit
- Printing physical copies
- Archiving or sharing a static snapshot
- Quickest export format when no downstream editing is needed

For editable files, use PPTX instead. For a self-contained interactive HTML file, use Save as standalone HTML.

## How it works

The tool (`open_for_print`) opens the file in a fresh tab. The user's browser handles the rest via its built-in print dialog.

For decks using `<deck-stage>`, the component already injects a print stylesheet:

- `@page size: <width>px <height>px; margin: 0` matches the design size
- Each slide becomes one page with `break-after: page`
- Overlay, tap zones, and chrome are hidden via `@media print`
- `-webkit-print-color-adjust: exact` ensures backgrounds and colors render

Result: one slide per page at authored size, no margins, no chrome.

## Prerequisites

- File must be HTML (not JSX source)
- For decks: use the `deck-stage.js` starter — it ships with the print stylesheet
- For non-deck artifacts: add `@media print` styles yourself

## User instructions

When you surface the print-ready page, tell the user:

1. Press Cmd+P (Mac) or Ctrl+P (Windows)
2. Choose "Save as PDF" as the destination
3. In "More settings":
   - Margins: None (or Default if the artifact has its own padding)
   - Background graphics: ✓ enabled (critical for dark backgrounds)
4. Save

## Don't

- Use this for editable outputs — PDFs aren't editable
- Forget to check print styles on non-deck artifacts — default browser print often cuts things off
- Export a scaled deck without the `deck-stage.js` print rules — pages will be misaligned

## Alternative

For one-shot programmatic PDF generation without the user loop, there isn't a built-in tool — the print flow is the path. If the user wants automation, export to PPTX or standalone HTML instead.
