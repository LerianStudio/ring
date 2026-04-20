'use strict';

(function () {
  var state = {
    slides: [],
    paginated: [],
    index: 0,
    blank: false,
    notes: [],
    notesOpen: false,
    exporting: false,
    sync: null,
    suppressSend: false,
    helloTotal: 0,
  };

  function qs(sel, root) { return (root || document).querySelector(sel); }
  function qsa(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  function readNotes() {
    var el = document.getElementById('speaker-notes');
    if (!el) return [];
    try { return JSON.parse(el.textContent || '[]'); }
    catch (e) {
      console.warn('[deck] speaker-notes JSON parse failed:', e);
      return [];
    }
  }

  function fillPagination() {
    state.paginated = state.slides.filter(function (s) {
      return s.querySelector('.page-num');
    });
    var total = state.paginated.length;
    state.paginated.forEach(function (section, i) {
      qsa('.page-num', section).forEach(function (n) { n.textContent = String(i + 1); });
      qsa('.page-total', section).forEach(function (n) { n.textContent = String(total); });
    });
    // Safety: if slide count changed since last hello (e.g., hot-reload),
    // re-announce total so the server-side state.total stays in sync.
    if (state.sync && state.slides.length !== state.helloTotal) {
      sendHello();
    }
  }

  function sendHello() {
    if (!state.sync) return;
    state.sync.send({ type: 'hello', total: state.slides.length });
    state.helloTotal = state.slides.length;
  }

  function applyStagger(section) {
    if (state.exporting) return;
    section.classList.remove('slide-enter');
    // reflow then re-add so animation restarts
    void section.offsetWidth;
    section.classList.add('slide-enter');
    var children = qsa(':scope > *', section);
    children.forEach(function (child, i) {
      child.style.animationDelay = (i * 80) + 'ms';
    });
  }

  function show(index) {
    if (index < 0) index = 0;
    if (index > state.slides.length - 1) index = state.slides.length - 1;
    state.slides.forEach(function (section, i) {
      section.style.display = i === index ? '' : 'none';
      section.setAttribute('aria-hidden', i === index ? 'false' : 'true');
    });
    state.index = index;
    var current = state.slides[index];
    if (current) applyStagger(current);
    updateNotesPanel();
    updateHash();
  }

  function updateHash() {
    if (state.exporting) return;
    try {
      var h = '#slide=' + (state.index + 1);
      if (location.hash !== h) history.replaceState(null, '', h);
    } catch (e) {
      // ignore: history.replaceState fails in sandboxed iframe / data: URL
    }
  }

  function readHashSlide() {
    var m = /#slide=(\d+)/.exec(location.hash || '');
    if (!m) return null;
    var n = parseInt(m[1], 10);
    if (isNaN(n)) return null;
    return Math.max(0, Math.min(state.slides.length - 1, n - 1));
  }

  function doubleRaf() {
    return new Promise(function (resolve) {
      requestAnimationFrame(function () { requestAnimationFrame(resolve); });
    });
  }

  function gotoIndex(n, opts) {
    opts = opts || {};
    if (n === state.index) {
      return state.exporting ? doubleRaf() : Promise.resolve();
    }
    show(n);
    if (!opts.silent && state.sync && !state.suppressSend) {
      // Include total as belt-and-suspenders: server uses it to refresh state.total if changed.
      state.sync.send({ type: 'nav', slide: state.index, total: state.slides.length });
    }
    // Double rAF: Puppeteer must await until the slide is actually painted,
    // not just flagged display:block. Two frames guarantees layout + paint.
    return state.exporting ? doubleRaf() : Promise.resolve();
  }

  function setBlank(on, opts) {
    opts = opts || {};
    state.blank = !!on;
    var overlay = qs('#deck-blank-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.id = 'deck-blank-overlay';
      overlay.style.cssText = 'position:fixed;inset:0;background:#000;z-index:9998;display:none;';
      document.body.appendChild(overlay);
    }
    overlay.style.display = state.blank ? 'block' : 'none';
    if (!opts.silent && state.sync && !state.suppressSend) {
      state.sync.send({ type: 'blank', on: state.blank });
    }
  }

  function ensureNotesPanel() {
    var panel = qs('#deck-notes-panel');
    if (panel) return panel;
    panel = document.createElement('div');
    panel.id = 'deck-notes-panel';
    panel.style.cssText = [
      'position:fixed', 'left:0', 'right:0', 'bottom:0', 'height:25vh',
      'background:rgba(0,0,0,0.88)', 'color:#fff',
      "font-family:'IBM Plex Serif', Georgia, serif", 'font-size:22px', 'line-height:1.4',
      'padding:24px 32px', 'overflow-y:auto', 'z-index:9997', 'display:none',
      'box-sizing:border-box'
    ].join(';') + ';';
    document.body.appendChild(panel);
    return panel;
  }

  function updateNotesPanel() {
    if (!state.notesOpen) return;
    var panel = ensureNotesPanel();
    var raw = state.notes[state.index] || '';
    var paragraphs = String(raw).split(/\n\n+/).map(function (p) {
      var d = document.createElement('p');
      d.textContent = p;
      d.style.margin = '0 0 12px 0';
      return d;
    });
    panel.innerHTML = '';
    paragraphs.forEach(function (p) { panel.appendChild(p); });
  }

  function toggleNotes() {
    state.notesOpen = !state.notesOpen;
    var panel = ensureNotesPanel();
    panel.style.display = state.notesOpen ? 'block' : 'none';
    if (state.notesOpen) updateNotesPanel();
  }

  function toggleFullscreen() {
    if (!document.fullscreenElement) {
      var p = document.documentElement.requestFullscreen && document.documentElement.requestFullscreen();
      if (p && p.catch) p.catch(function () {
        // ignore: fullscreen unavailable or denied by user gesture policy
      });
    } else {
      if (document.exitFullscreen) document.exitFullscreen().catch(function () {
        // ignore: fullscreen unavailable or denied by user gesture policy
      });
    }
  }

  function promptGoto() {
    var input = window.prompt('Go to slide (1..' + state.slides.length + '):');
    if (input == null || input === '') return;
    var n = parseInt(input, 10);
    if (isNaN(n)) return;
    gotoIndex(Math.max(0, Math.min(state.slides.length - 1, n - 1)));
  }

  function onKey(e) {
    if (e.defaultPrevented) return;
    if (e.target && /^(INPUT|TEXTAREA|SELECT)$/.test(e.target.tagName)) return;
    switch (e.key) {
      case 'ArrowRight':
      case ' ':
      case 'Spacebar':
        gotoIndex(state.index + 1); e.preventDefault(); break;
      case 'ArrowLeft':
        gotoIndex(state.index - 1); e.preventDefault(); break;
      case 'f': case 'F':
        toggleFullscreen(); e.preventDefault(); break;
      case 's': case 'S':
        toggleNotes(); e.preventDefault(); break;
      case 'g': case 'G':
        promptGoto(); e.preventDefault(); break;
      case 'b': case 'B':
        setBlank(!state.blank); e.preventDefault(); break;
      case 'Escape':
        if (document.fullscreenElement && document.exitFullscreen) {
          document.exitFullscreen().catch(function () {
            // ignore: fullscreen unavailable or denied by user gesture policy
          });
        }
        if (state.notesOpen) toggleNotes();
        if (state.blank) setBlank(false);
        break;
    }
  }

  function onHashChange() {
    var n = readHashSlide();
    if (n != null && n !== state.index) gotoIndex(n, { silent: true });
  }

  function onPostMessage(event) {
    if (event.origin !== window.location.origin) return;
    var msg = event.data;
    if (!msg || typeof msg !== 'object') return;
    if (msg.type === 'nav' && Number.isInteger(msg.slide)) {
      gotoIndex(msg.slide, { silent: true });
    }
  }

  function init() {
    state.slides = qsa('deck-stage > section');
    state.notes = readNotes();
    state.exporting = new URLSearchParams(location.search).get('export') === 'true';

    if (state.slides.length === 0) {
      console.error('[deck-stage] No <deck-stage> > <section> elements found — deck.html is empty or malformed.');
      return;
    }

    if (state.exporting) {
      document.body.classList.add('exporting');
    }

    fillPagination();

    if (state.notes.length > 0 && state.notes.length !== state.slides.length) {
      console.warn('[deck-stage] Speaker-notes length ' + state.notes.length + ' != slide count ' + state.slides.length + ' — presenter will show "(no notes)" for missing slides.');
    }

    var initial = readHashSlide();
    show(initial == null ? 0 : initial);

    window.__deck = {
      goto: function (n) { return gotoIndex(n); },
      next: function () { return gotoIndex(state.index + 1); },
      prev: function () { return gotoIndex(state.index - 1); },
      total: function () { return state.slides.length; },
      current: function () { return state.index; },
      blank: function (on) { setBlank(on); },
    };

    window.addEventListener('message', onPostMessage);
    window.addEventListener('hashchange', onHashChange);

    if (state.exporting) return;

    document.addEventListener('keydown', onKey);

    state.sync = window.DeckSync.connect('/ws', {
      onOpen: function () {
        sendHello();
      },
      onNav: function (msg) {
        if (!Number.isInteger(msg.slide)) return;
        state.suppressSend = true;
        gotoIndex(msg.slide, { silent: true });
        state.suppressSend = false;
      },
      onBlank: function (msg) {
        state.suppressSend = true;
        setBlank(!!msg.on, { silent: true });
        state.suppressSend = false;
      },
      onState: function (msg) {
        state.suppressSend = true;
        if (typeof msg.slide === 'number') gotoIndex(msg.slide, { silent: true });
        setBlank(!!msg.blank, { silent: true });
        state.suppressSend = false;
      },
      onReload: function () { location.reload(); },
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
