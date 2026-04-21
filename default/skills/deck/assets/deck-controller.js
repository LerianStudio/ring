'use strict';

(function () {
  const state = {
    stage: null,
    notes: [],
    notesPanel: null,
    notesOpen: false,
    blank: false,
    sync: null,
    lastHelloTotal: 0,
    exporting: false,
  };

  // suppressSend gates the slidechange handler from echoing remote events
  // (sync onNav/onState, presenter postMessage) back out to the wire,
  // which would cause a feedback loop.
  let suppressSend = false;

  function isExportMode() {
    try {
      const params = new URLSearchParams(window.location.search);
      return params.get('export') === 'true';
    } catch (e) {
      return false;
    }
  }

  function parseHashSlide() {
    const m = /^#slide=(\d+)$/.exec(window.location.hash || '');
    if (!m) return null;
    const n = parseInt(m[1], 10);
    return Number.isInteger(n) ? n : null;
  }

  function fillPagination(stage) {
    const paginated = Array.from(stage.querySelectorAll(':scope > *'))
      .filter(s => s.querySelector('.page-num'));
    const total = paginated.length;
    paginated.forEach((section, i) => {
      section.querySelectorAll('.page-num').forEach(n => { n.textContent = String(i + 1); });
      section.querySelectorAll('.page-total').forEach(n => { n.textContent = String(total); });
    });
  }

  function loadNotes(stage) {
    const el = document.getElementById('speaker-notes');
    if (!el) return [];
    try {
      const parsed = JSON.parse(el.textContent || '[]');
      if (!Array.isArray(parsed)) return [];
      if (parsed.length > 0 && parsed.length !== stage.length) {
        console.warn('[deck-controller] notes length ' + parsed.length +
          ' does not match slide count ' + stage.length);
      }
      return parsed;
    } catch (e) {
      console.warn('[deck-controller] failed to parse speaker-notes JSON:', e);
      return [];
    }
  }

  function ensureNotesPanel() {
    if (state.notesPanel) return state.notesPanel;
    const panel = document.createElement('div');
    panel.id = 'deck-notes-panel';
    panel.style.cssText = 'position:fixed;left:0;right:0;bottom:0;height:25vh;' +
      'background:rgba(0,0,0,0.88);color:#fff;' +
      'font-family:"IBM Plex Serif",Georgia,serif;font-size:22px;line-height:1.4;' +
      'padding:24px 32px;overflow-y:auto;z-index:9997;display:none;box-sizing:border-box;';
    document.body.appendChild(panel);
    state.notesPanel = panel;
    return panel;
  }

  function renderNotes() {
    if (!state.notesPanel || !state.notesOpen) return;
    const idx = state.stage.index;
    const text = state.notes[idx] || '';
    state.notesPanel.innerHTML = '';
    const chunks = String(text).split(/\n\n+/).filter(s => s.trim().length > 0);
    if (chunks.length === 0) {
      const p = document.createElement('p');
      p.style.opacity = '0.5';
      p.textContent = '(no notes for this slide)';
      state.notesPanel.appendChild(p);
      return;
    }
    chunks.forEach(chunk => {
      const p = document.createElement('p');
      p.style.margin = '0 0 12px 0';
      p.textContent = chunk;
      state.notesPanel.appendChild(p);
    });
  }

  function toggleNotes() {
    const panel = ensureNotesPanel();
    state.notesOpen = !state.notesOpen;
    panel.style.display = state.notesOpen ? 'block' : 'none';
    if (state.notesOpen) renderNotes();
  }

  function ensureBlankOverlay() {
    let el = document.getElementById('deck-blank-overlay');
    if (el) return el;
    el = document.createElement('div');
    el.id = 'deck-blank-overlay';
    el.style.cssText = 'position:fixed;inset:0;background:#000;z-index:9998;display:none;';
    document.body.appendChild(el);
    return el;
  }

  function setBlank(on, opts) {
    opts = opts || {};
    state.blank = !!on;
    ensureBlankOverlay().style.display = state.blank ? 'block' : 'none';
    if (!opts.silent && !suppressSend && state.sync) {
      state.sync.send({ type: 'blank', on: state.blank });
    }
  }

  function toggleFullscreen() {
    const doc = document;
    const el = doc.documentElement;
    if (!doc.fullscreenElement) {
      const p = el.requestFullscreen && el.requestFullscreen();
      if (p && typeof p.catch === 'function') p.catch(() => { /* user-gesture denied */ });
    } else {
      const p = doc.exitFullscreen && doc.exitFullscreen();
      if (p && typeof p.catch === 'function') p.catch(() => {});
    }
  }

  function promptGoto(stage) {
    const raw = window.prompt('Go to slide (1..' + stage.length + '):');
    if (raw == null) return;
    const n = parseInt(String(raw).trim(), 10);
    if (!Number.isInteger(n)) return;
    const clamped = Math.max(1, Math.min(stage.length, n));
    stage.goto(clamped - 1, 'api');
  }

  function isTypingTarget(target) {
    if (!target || !target.tagName) return false;
    if (/^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName)) return true;
    if (target.isContentEditable) return true;
    return false;
  }

  function handleKeydown(stage, e) {
    if (e.defaultPrevented) return;
    if (isTypingTarget(e.target)) return;
    const k = e.key;
    if (k === 'f' || k === 'F') { toggleFullscreen(); e.preventDefault(); return; }
    if (k === 's' || k === 'S') { toggleNotes(); e.preventDefault(); return; }
    if (k === 'g' || k === 'G') { promptGoto(stage); e.preventDefault(); return; }
    if (k === 'b' || k === 'B') { setBlank(!state.blank); e.preventDefault(); return; }
    if (k === 'r' || k === 'R') { return; /* reserved for presenter timer reset */ }
    if (k === 't' || k === 'T') {
      if (window.__deckFeedback && window.__deckFeedback.toggle) window.__deckFeedback.toggle();
      e.preventDefault();
      return;
    }
    if (k === 'h' || k === 'H') {
      if (window.__deckToolbar && window.__deckToolbar.toggle) window.__deckToolbar.toggle();
      e.preventDefault();
      return;
    }
    if (k === 'Escape') {
      if (document.fullscreenElement) {
        const p = document.exitFullscreen && document.exitFullscreen();
        if (p && typeof p.catch === 'function') p.catch(() => {});
        return;
      }
      if (state.notesOpen) { toggleNotes(); return; }
      if (state.blank) { setBlank(false); return; }
    }
  }

  function applyStagger(slideEl) {
    if (state.exporting) return;
    if (!slideEl) return;
    slideEl.classList.remove('slide-enter');
    void slideEl.offsetWidth;
    slideEl.classList.add('slide-enter');
    Array.from(slideEl.children).forEach((child, i) => {
      child.style.animationDelay = (i * 80) + 'ms';
    });
  }

  function writeHash(index) {
    if (state.exporting) return;
    const h = '#slide=' + (index + 1);
    if (window.location.hash === h) return;
    try { history.replaceState(null, '', h); } catch (e) { /* sandboxed iframe */ }
  }

  function onSlideChange(stage, e) {
    const d = e.detail || {};
    const reason = d.reason;

    if (d.total !== state.lastHelloTotal) {
      fillPagination(stage);
    }

    if (reason !== 'init') {
      writeHash(d.index);
      applyStagger(d.slide);
    }

    if (state.notesOpen) renderNotes();

    if (state.sync && !suppressSend && reason !== 'init') {
      // Re-announce total on hot-reload slide-count changes so the server
      // and remote clients stay in sync without a full reconnect.
      if (stage.length !== state.lastHelloTotal) {
        state.sync.send({ type: 'hello', total: stage.length });
        state.lastHelloTotal = stage.length;
      }
      state.sync.send({ type: 'nav', slide: d.index, total: stage.length });
    }
  }

  function connectSync(stage) {
    if (!window.DeckSync || typeof window.DeckSync.connect !== 'function') {
      console.warn('[deck-controller] DeckSync unavailable; sync disabled');
      return null;
    }
    return window.DeckSync.connect('/ws', {
      onOpen: () => {
        state.sync.send({ type: 'hello', total: stage.length });
        state.lastHelloTotal = stage.length;
      },
      onNav: (msg) => {
        if (!Number.isInteger(msg.slide)) return;
        suppressSend = true;
        stage.goto(msg.slide, 'api');
        suppressSend = false;
      },
      onBlank: (msg) => {
        suppressSend = true;
        setBlank(!!msg.on, { silent: true });
        suppressSend = false;
      },
      onState: (msg) => {
        suppressSend = true;
        if (Number.isInteger(msg.slide)) stage.goto(msg.slide, 'api');
        setBlank(!!msg.blank, { silent: true });
        suppressSend = false;
      },
      onReload: () => { location.reload(); },
    });
  }

  function onMessage(stage, event) {
    if (event.origin !== window.location.origin) return;
    const msg = event.data;
    if (!msg || typeof msg !== 'object') return;
    // Presenter iframes send 1-indexed slide numbers; component API is 0-indexed.
    if (msg.type === 'nav' && Number.isInteger(msg.slide)) {
      suppressSend = true;
      stage.goto(msg.slide - 1, 'api');
      suppressSend = false;
    }
  }

  function onHashChange(stage) {
    const n = parseHashSlide();
    if (n == null) return;
    const target = n - 1;
    if (target === stage.index) return;
    if (target < 0 || target >= stage.length) return;
    stage.goto(target, 'api');
  }

  function attach(stage) {
    state.stage = stage;
    state.exporting = isExportMode();

    if (state.exporting) {
      document.body.classList.add('exporting');
      stage.setAttribute('noscale', '');
    }

    fillPagination(stage);
    state.notes = loadNotes(stage);

    const hashN = parseHashSlide();
    if (hashN != null && (hashN - 1) !== stage.index &&
        hashN >= 1 && hashN <= stage.length) {
      stage.goto(hashN - 1, 'api');
    }

    window.__deck = {
      goto:    (n)  => stage.goto(n, 'api'),
      next:    ()   => stage.next('api'),
      prev:    ()   => stage.prev('api'),
      total:   ()   => stage.length,
      current: ()   => stage.index,
      blank:   (on) => setBlank(!!on),
    };

    stage.addEventListener('slidechange', (e) => onSlideChange(stage, e));
    document.addEventListener('keydown', (e) => handleKeydown(stage, e));
    window.addEventListener('message', (e) => onMessage(stage, e));
    window.addEventListener('hashchange', () => onHashChange(stage));

    if (!state.exporting) {
      state.sync = connectSync(stage);
    }

    // Notes and feedback panels share the bottom slot — close notes when
    // feedback opens. Cross-module contract via CustomEvent so feedback-panel
    // doesn't need to peek at controller state.
    document.addEventListener('deck-feedback-opening', () => {
      if (state.notesOpen) toggleNotes();
    });

    // Mount toolbar + feedback panel last (they depend on stage).
    if (window.__deckToolbar && window.__deckToolbar.mount) window.__deckToolbar.mount(stage);
    if (window.__deckFeedback && window.__deckFeedback.mount) window.__deckFeedback.mount(stage);
  }

  customElements.whenDefined('deck-stage').then(() => {
    const stage = document.querySelector('deck-stage');
    if (!stage) {
      console.warn('[deck-controller] no <deck-stage> element found');
      return;
    }
    attach(stage);
  });
})();
