# Responsive section navigation

> All color tokens and base styles are defined in `../templates/standard.html`. This reference shows the responsive navigation TOC pattern that builds ON TOP of the standard foundation.

Navigation pattern for multi-section pages (reviews, recaps, dashboards). Provides a sticky sidebar TOC on desktop and a sticky horizontal scrollable bar on mobile. Use it only for 4+ meaningful sections or decision surfaces; otherwise skip it and preserve focus.

## Layout structure

The page uses a two-column CSS Grid: sidebar (TOC) + main content. On mobile it collapses to single-column with the TOC becoming a horizontal bar.

```html
<body>
<div class="wrap">

  <nav class="toc" id="toc">
    <div class="toc-title">Contents</div>
    <a href="#s1">1. First section</a>
    <a href="#s2">2. Second section</a>
    <!-- one link per section -->
  </nav>

  <div class="main">
    <h1>Page title</h1>
    <p class="subtitle">Subtitle text</p>

    <div id="s1" class="sec-head ...">1. First section</div>
    <!-- section content -->

    <div id="s2" class="sec-head ...">2. Second section</div>
    <!-- section content -->
  </div><!-- /main -->

</div><!-- /wrap -->
</body>
```

Key structural rules:
- `<nav class="toc">` is the **first child** of `.wrap`
- All page content goes inside `<div class="main">`
- Every section heading gets an `id="s1"`, `id="s2"`, etc.
- TOC links use `href="#s1"` matching those IDs
- Keep TOC link text short (truncate long section names)

## CSS

### Wrap (grid layout)

```css
.wrap {
  max-width: 1400px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 170px 1fr;
  gap: 0 40px;
}
.main { min-width: 0; }
```

### TOC desktop sticky sidebar

```css
.toc {
  position: sticky;
  top: 24px;
  align-self: start;
  padding: 14px 0;
  grid-row: 1 / -1;
  max-height: calc(100dvh - 48px);
  overflow-y: auto;
}
.toc::-webkit-scrollbar { width: 3px; }
.toc::-webkit-scrollbar-thumb { background: var(--surface-elevated); border-radius: 2px; }

.toc-title {
  font-family: var(--font-mono);
  font-size: 9px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--text-muted);
  padding: 0 0 10px;
  margin-bottom: 8px;
  border-bottom: 1px solid var(--border);
}

.toc a {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
  text-decoration: none;
  padding: 4px 8px;
  border-radius: 5px;
  box-shadow: inset 0 0 0 0 transparent;
  transition: all 0.15s;
  line-height: 1.4;
  margin-bottom: 1px;
}
.toc a:hover { color: var(--text); background: var(--surface-elevated); }
.toc a.active {
  color: var(--text);
  background: var(--surface-elevated);
  font-weight: 600;
  box-shadow: inset 0 0 0 1px var(--accent), var(--shadow-sm);
}
```

Replace `var(--accent)` with your page's primary accent color variable (e.g., `var(--tangerine-500)`, `var(--info)`).

### TOC mobile sticky horizontal bar

```css
@media (max-width: 1000px) {
  .wrap { grid-template-columns: 1fr; padding-top: 0; }
  body { padding-top: 0; }

  .toc {
    position: sticky;
    top: 0;
    z-index: 200;
    max-height: none;
    display: flex;
    gap: 4px;
    align-items: center;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    background: var(--bg);
    border-bottom: 1px solid var(--border);
    padding: 10px 0;
    margin: 0 -40px;
    padding-left: 40px;
    padding-right: 40px;
    grid-row: auto;
  }
  .toc::-webkit-scrollbar { display: none; }
  .toc-title { display: none; }

  .toc a {
    white-space: nowrap;
    flex-shrink: 0;
    border-bottom: 2px solid transparent;
    border-radius: 4px 4px 0 0;
    padding: 6px 10px;
    font-size: 10px;
  }
  .toc a.active {
    border-bottom-color: var(--accent);
    background: var(--surface);
    box-shadow: none;
  }

  .main { padding-top: 20px; }

  /* Offset scroll target so headings clear the sticky bar */
  .sec-head { scroll-margin-top: 52px; }
}
```

Adjust `margin: 0 -40px` and `padding-left/right: 40px` to match your `body` padding so the bar bleeds edge-to-edge.

## JavaScript scroll spy

Place before `</body>`, after any Mermaid init:

```html
<script>
(function() {
  const toc = document.getElementById('toc');
  const links = toc.querySelectorAll('a');
  const sections = [];

  links.forEach(link => {
    const id = link.getAttribute('href').slice(1);
    const el = document.getElementById(id);
    if (el) sections.push({ id, el, link });
  });

  function setActive(link) {
    links.forEach(l => l.classList.remove('active'));
    link.classList.add('active');
    if (window.innerWidth <= 1000) {
      link.scrollIntoView({
        behavior: 'smooth', block: 'nearest', inline: 'center'
      });
    }
  }

  const initialId = window.location.hash ? window.location.hash.slice(1) : null;
  const initial = sections.find(s => s.id === initialId) || sections[0];
  if (initial) setActive(initial.link);

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const match = sections.find(s => s.el === entry.target);
        if (match) setActive(match.link);
      }
    });
  }, { rootMargin: '-10% 0px -80% 0px' });

  sections.forEach(s => observer.observe(s.el));

  links.forEach(link => {
    link.addEventListener('click', e => {
      e.preventDefault();
      const id = link.getAttribute('href').slice(1);
      const el = document.getElementById(id);
      if (el) {
        setActive(link);
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        history.replaceState(null, '', '#' + id);
      }
    });
  });
})();
</script>
```

## Adaptation notes

- The `.toc-title` text, link labels, accent color, and section IDs change per page. Everything else is copy-paste.
- Use the TOC only for 4+ meaningful sections or decision surfaces. For fewer sections, skip it entirely; it adds clutter without value.
- Do not create fake sections just to justify a nav shell.
- The `grid-template-columns: 170px 1fr` width works for most TOCs. If section names are longer, go up to `200px`.
- The `rootMargin: '-10% 0px -80% 0px'` means a section is "active" when its heading enters the top 10-20% of the viewport. This works well with sticky headers.
- On mobile, the horizontal bar uses `overflow-x: auto` with hidden scrollbar. The active tab auto-scrolls into the center of the bar as the user scrolls the page.
