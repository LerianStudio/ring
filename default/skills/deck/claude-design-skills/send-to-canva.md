# Send to Canva

**Category:** Export
**Output:** Editable Canva design

## What it does

Exports the HTML artifact as an editable design in Canva. The user gets a link to open the design in their Canva workspace, where they (or their brand team) can edit text, swap images, apply brand kits, and publish through Canva's distribution channels.

## When to use

- Recipient's team uses Canva as their primary design tool
- Brand team needs to apply a Canva brand kit downstream
- Marketing wants to publish through Canva's templates/social tools
- Non-designer stakeholders who prefer Canva over PowerPoint

For PowerPoint recipients, use the PPTX export. For print, use PDF.

## How it works

The flow uses a public file URL handoff:

1. The artifact is exposed via `get_public_file_url` — a short-lived (~1h) sandbox URL
2. Canva's import flow fetches from that URL
3. Canva converts the HTML into their native design format
4. User lands in Canva editor with the design ready to tweak

## Prerequisites

- Artifact must be self-contained or use publicly-fetchable assets (Canva can't reach cross-project paths)
- For best results, the design should be at standard presentation sizes (1920×1080, 1080×1080, 1920×1920, etc.)
- CSS effects Canva can't reproduce (filters, complex clip-paths) may flatten to images

## Trade-offs

**Wins:**
- Editable in Canva's native tools
- Recipient can apply brand kits
- Plugs into Canva's distribution (presentations, social, docs)

**Loses:**
- Some fidelity may be lost in HTML→Canva translation
- Complex layouts may need manual cleanup in Canva
- Requires the recipient to have a Canva account

## Process

1. Confirm the artifact is ready (final, self-contained)
2. Call `get_public_file_url` on the HTML
3. Guide the user through Canva's import flow using the URL
4. Tell them to verify the imported design before distributing

## Don't

- Use for interactive prototypes — Canva is a static design tool
- Export very complex artifacts (heavy animations, custom web components) — fidelity loss is high
- Rely on the public URL long-term — it expires in ~1 hour
