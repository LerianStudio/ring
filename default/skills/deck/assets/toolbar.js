'use strict';

// Floating toolbar ("harness") on the deck. Lives on document.body, not in
// shadow DOM — the canvas scale transform would warp fixed-position elements.
// Hidden in export mode and fullscreen. Five buttons: Tweak, Presenter, PDF,
// PPTX, Remote.

(function () {
  const state = {
    mounted: false,
    toolbarEl: null,
    hiddenByUser: false,
    exportInFlight: null,
    stage: null,
    toastEl: null,
    modalEl: null,
  };

  const SVG_NS = 'http://www.w3.org/2000/svg';

  function mount(stage) {
    if (state.mounted) return;
    state.stage = stage;
    buildDom();
    attachListeners();
    syncVisibility();
    state.mounted = true;
  }

  function buildDom() {
    const root = document.createElement('div');
    root.id = 'deck-toolbar';
    root.setAttribute('aria-label', 'Deck toolbar');
    root.style.cssText = [
      'position:fixed',
      'bottom:16px',
      'left:50%',
      'transform:translateX(-50%)',
      'z-index:9996',
      'display:inline-flex',
      'align-items:center',
      'gap:8px',
      'padding:8px 12px',
      'background:rgba(25,26,27,0.88)',
      'color:#fff',
      'border-radius:999px',
      'box-shadow:0 8px 32px rgba(0,0,0,0.25)',
      "font-family:'JetBrains Mono', ui-monospace, monospace",
      'font-size:12px',
      'letter-spacing:0.04em',
      'text-transform:uppercase',
      'user-select:none',
      'backdrop-filter:blur(6px)',
    ].join(';') + ';';

    root.appendChild(makeButton('tweak', 'T', 'Tweak', svgIcon('chat'), onTweakClick));
    root.appendChild(divider());
    root.appendChild(makeButton('presenter', null, 'Presenter', svgIcon('monitor'), onPresenterClick));
    root.appendChild(divider());
    root.appendChild(makeButton('pdf', null, 'PDF', svgIcon('pdf'), onExportPdfClick));
    root.appendChild(makeButton('pptx', null, 'PPTX', svgIcon('pptx'), onExportPptxClick));
    root.appendChild(divider());
    root.appendChild(makeButton('remote', null, 'Remote', svgIcon('phone'), onRemoteClick));

    document.body.appendChild(root);
    state.toolbarEl = root;
  }

  function makeButton(id, shortcut, label, iconEl, onClick) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.dataset.btn = id;
    btn.setAttribute('aria-label', label + (shortcut ? ' (' + shortcut + ')' : ''));
    btn.style.cssText = [
      'display:inline-flex',
      'align-items:center',
      'gap:6px',
      'padding:6px 12px',
      'background:transparent',
      'color:inherit',
      'border:0',
      'border-radius:999px',
      'cursor:pointer',
      'font:inherit',
      'letter-spacing:inherit',
      'text-transform:inherit',
      'line-height:1',
      'transition:background 120ms ease',
    ].join(';') + ';';
    btn.addEventListener('mouseenter', () => { btn.style.background = 'rgba(255,255,255,0.12)'; });
    btn.addEventListener('mouseleave', () => { btn.style.background = 'transparent'; });
    btn.addEventListener('click', onClick);

    btn.appendChild(iconEl);

    const text = document.createElement('span');
    text.textContent = shortcut ? label + ' (' + shortcut + ')' : label;
    text.dataset.role = 'label';
    btn.appendChild(text);

    return btn;
  }

  function divider() {
    const d = document.createElement('span');
    d.setAttribute('aria-hidden', 'true');
    d.style.cssText = 'width:1px;height:16px;background:rgba(255,255,255,0.2);display:inline-block;';
    return d;
  }

  function svgIcon(kind) {
    const svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('width', '14');
    svg.setAttribute('height', '14');
    svg.setAttribute('viewBox', '0 0 24 24');
    svg.setAttribute('fill', 'none');
    svg.setAttribute('stroke', 'currentColor');
    svg.setAttribute('stroke-width', '2');
    svg.setAttribute('stroke-linecap', 'round');
    svg.setAttribute('stroke-linejoin', 'round');
    svg.setAttribute('aria-hidden', 'true');

    const paths = iconPaths(kind);
    paths.forEach(d => {
      const p = document.createElementNS(SVG_NS, 'path');
      p.setAttribute('d', d);
      svg.appendChild(p);
    });
    return svg;
  }

  function iconPaths(kind) {
    switch (kind) {
      case 'chat':
        return ['M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z'];
      case 'monitor':
        return [
          'M3 4h18v12H3z',
          'M8 20h8',
          'M12 16v4',
        ];
      case 'pdf':
        return [
          'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z',
          'M14 2v6h6',
          'M12 18v-6',
          'M9 15l3 3 3-3',
        ];
      case 'pptx':
        return [
          'M3 5h18v14H3z',
          'M3 10h18',
          'M9 5v14',
        ];
      case 'phone':
        return ['M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.37 1.9.72 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.35 1.85.59 2.81.72A2 2 0 0 1 22 16.92z'];
    }
    return [];
  }

  function attachListeners() {
    document.addEventListener('fullscreenchange', syncVisibility);
    // Export mode flips body.exporting mid-run under Puppeteer; watch class
    // attribute so the toolbar disappears before the snapshot fires.
    new MutationObserver(syncVisibility).observe(document.body, {
      attributes: true,
      attributeFilter: ['class'],
    });
  }

  function syncVisibility() {
    if (!state.toolbarEl) return;
    const exporting = document.body.classList.contains('exporting');
    const fullscreen = !!document.fullscreenElement;
    const shouldHide = exporting || fullscreen || state.hiddenByUser;
    state.toolbarEl.style.display = shouldHide ? 'none' : 'inline-flex';
  }

  function show() { state.hiddenByUser = false; syncVisibility(); }
  function hide() { state.hiddenByUser = true; syncVisibility(); }
  function toggle() { state.hiddenByUser = !state.hiddenByUser; syncVisibility(); }

  function onTweakClick() {
    if (window.__deckFeedback && window.__deckFeedback.toggle) {
      window.__deckFeedback.toggle();
    }
  }

  function onPresenterClick() {
    window.open('/presenter', '_blank', 'noopener,noreferrer');
  }

  function onExportPdfClick() {
    runExport('pdf', '/export/pdf', 'deck.pdf');
  }

  function onExportPptxClick() {
    runExport('pptx', '/export/pptx', 'deck.pptx');
  }

  function onRemoteClick() {
    fetch('/lan-url')
      .then(r => r.ok ? r.json() : { url: location.origin + '/remote' })
      .then(data => showRemoteModal(data.url || location.origin + '/remote'))
      .catch(() => showRemoteModal(location.origin + '/remote'));
  }

  function setBtnBusy(btn, busy) {
    if (!btn) return;
    const label = btn.querySelector('[data-role="label"]');
    if (busy) {
      btn.disabled = true;
      btn.style.opacity = '0.55';
      btn.style.cursor = 'wait';
      if (label) {
        btn.dataset.prevLabel = label.textContent;
        label.textContent = 'Generating...';
      }
    } else {
      btn.disabled = false;
      btn.style.opacity = '';
      btn.style.cursor = 'pointer';
      if (label && btn.dataset.prevLabel) {
        label.textContent = btn.dataset.prevLabel;
        delete btn.dataset.prevLabel;
      }
    }
  }

  async function runExport(kind, endpoint, filename) {
    if (state.exportInFlight) return;
    state.exportInFlight = kind;
    const btn = state.toolbarEl.querySelector('[data-btn="' + kind + '"]');
    setBtnBusy(btn, true);
    try {
      const res = await fetch(endpoint, { method: 'POST' });
      if (!res.ok) {
        const txt = await res.text().catch(() => '');
        throw new Error('HTTP ' + res.status + (txt ? ': ' + txt : ''));
      }
      const blob = await res.blob();
      triggerDownload(blob, filename);
      showToast(kind.toUpperCase() + ' ready', 'ok');
    } catch (e) {
      showToast('Export failed: ' + e.message, 'error');
    } finally {
      setBtnBusy(btn, false);
      state.exportInFlight = null;
    }
  }

  function triggerDownload(blob, filename) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  }

  function showToast(text, kind) {
    if (state.toastEl) {
      state.toastEl.remove();
      state.toastEl = null;
    }
    const toast = document.createElement('div');
    toast.setAttribute('role', 'status');
    toast.textContent = text;
    const bg = kind === 'error' ? 'rgba(176,34,34,0.95)' : 'rgba(32,120,64,0.95)';
    toast.style.cssText = [
      'position:fixed',
      'bottom:72px',
      'left:50%',
      'transform:translateX(-50%)',
      'z-index:9999',
      'padding:10px 16px',
      'background:' + bg,
      'color:#fff',
      'border-radius:6px',
      'box-shadow:0 6px 20px rgba(0,0,0,0.3)',
      "font-family:'JetBrains Mono', ui-monospace, monospace",
      'font-size:12px',
      'letter-spacing:0.04em',
      'text-transform:uppercase',
    ].join(';') + ';';
    document.body.appendChild(toast);
    state.toastEl = toast;
    setTimeout(() => {
      if (state.toastEl === toast) {
        toast.remove();
        state.toastEl = null;
      }
    }, 2000);
  }

  function showRemoteModal(url) {
    if (state.modalEl) state.modalEl.remove();

    const overlay = document.createElement('div');
    overlay.style.cssText = [
      'position:fixed',
      'inset:0',
      'z-index:9999',
      'background:rgba(0,0,0,0.5)',
      'display:flex',
      'align-items:center',
      'justify-content:center',
    ].join(';') + ';';

    const card = document.createElement('div');
    card.style.cssText = [
      'background:#fff',
      'color:#191A1B',
      'border-radius:8px',
      'padding:24px',
      'min-width:320px',
      'max-width:90vw',
      'box-shadow:0 16px 48px rgba(0,0,0,0.35)',
      "font-family:'IBM Plex Serif', Georgia, serif",
    ].join(';') + ';';

    const title = document.createElement('h3');
    title.textContent = 'Remote Control';
    title.style.cssText = 'margin:0 0 12px 0;font-size:18px;';
    card.appendChild(title);

    const hint = document.createElement('p');
    hint.textContent = 'Open this URL on your phone:';
    hint.style.cssText = 'margin:0 0 8px 0;font-size:14px;opacity:0.75;';
    card.appendChild(hint);

    const urlBox = document.createElement('code');
    urlBox.textContent = url;
    urlBox.style.cssText = [
      'display:block',
      'padding:10px 12px',
      'background:#f4f4f5',
      'border-radius:4px',
      'font-family:"JetBrains Mono", ui-monospace, monospace',
      'font-size:13px',
      'word-break:break-all',
      'margin-bottom:16px',
    ].join(';') + ';';
    card.appendChild(urlBox);

    const row = document.createElement('div');
    row.style.cssText = 'display:flex;gap:8px;justify-content:flex-end;';

    const copy = document.createElement('button');
    copy.type = 'button';
    copy.textContent = 'Copy';
    copy.style.cssText = buttonCss('#191A1B', '#fff');
    copy.addEventListener('click', () => {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(
          () => showToast('URL copied', 'ok'),
          () => showToast('Copy failed', 'error')
        );
      } else {
        showToast('Clipboard unavailable', 'error');
      }
    });

    const close = document.createElement('button');
    close.type = 'button';
    close.textContent = 'Close';
    close.style.cssText = buttonCss('#fff', '#191A1B', '#191A1B');
    close.addEventListener('click', () => {
      overlay.remove();
      state.modalEl = null;
    });

    row.appendChild(copy);
    row.appendChild(close);
    card.appendChild(row);
    overlay.appendChild(card);

    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        overlay.remove();
        state.modalEl = null;
      }
    });

    document.body.appendChild(overlay);
    state.modalEl = overlay;
  }

  function buttonCss(bg, fg, border) {
    return [
      'padding:8px 16px',
      'background:' + bg,
      'color:' + fg,
      'border:1px solid ' + (border || bg),
      'border-radius:4px',
      'cursor:pointer',
      'font-family:"JetBrains Mono", ui-monospace, monospace',
      'font-size:12px',
      'letter-spacing:0.04em',
      'text-transform:uppercase',
    ].join(';') + ';';
  }

  window.__deckToolbar = { mount, show, hide, toggle };
})();
