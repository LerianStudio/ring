# Make tweakable

**Category:** Modify
**Output:** Adds in-design tweak controls to an existing artifact

## What it does

Turns a static design into one the user can live-edit via a floating Tweaks panel. Colors, type, copy, layout variants, feature flags — whatever dimension makes sense. Changes apply instantly and persist to disk.

## Protocol (order matters)

**Register the listener BEFORE announcing availability.** If you post `__edit_mode_available` first, the host's activate message can land before your handler exists and the toggle silently does nothing.

1. Register a `message` listener on `window` that handles:
   - `{type: '__activate_edit_mode'}` → show the Tweaks panel
   - `{type: '__deactivate_edit_mode'}` → hide it
2. Only once the listener is live, call:
   ```js
   window.parent.postMessage({type: '__edit_mode_available'}, '*')
   ```
3. When the user changes a value, apply it live **and** persist:
   ```js
   window.parent.postMessage({
     type: '__edit_mode_set_keys',
     edits: {fontSize: 18}
   }, '*')
   ```
   Partial updates are fine — only included keys are merged.

## Persisting defaults

Wrap tweakable defaults in comment markers so the host can rewrite them on disk:

```js
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "primaryColor": "#D97757",
  "fontSize": 16,
  "dark": false
}/*EDITMODE-END*/;
```

The block between markers **must be valid JSON** — double-quoted keys and strings. Exactly one such block in the root HTML, inside an inline `<script>`. When the host receives `__edit_mode_set_keys`, it parses the JSON, merges edits, and writes the file back. Changes survive reload.

## UI guidelines

- Title the panel **"Tweaks"** — matches the toolbar toggle naming
- Keep the surface small — floating panel bottom-right, or inline handles
- Hide controls entirely when Tweaks is off — the design should look final
- For variants of a single element: use Tweaks to cycle through options
- If the user didn't ask for specific tweaks, add 2–3 by default as creative exposure

## What makes a good tweak

- **Meaningful:** toggling it visibly changes the design's character
- **Bounded:** finite options (colors from a palette, type scale steps) beat open sliders
- **Named clearly:** "Primary color", not "Color 1"
- **Grouped:** cluster related tweaks (Typography, Layout, Copy)

## Don't

- Expose every CSS variable — be selective
- Build complex forms or deep nested settings
- Forget to persist — non-persisted tweaks feel broken on refresh
