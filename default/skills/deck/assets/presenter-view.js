'use strict';

// Presenter view controller. HTML-first: presenter.html owns the DOM + CSS
// (including Amarelo accent, font stack). This file wires behaviour only —
// it queries existing elements and populates them. It MUST NOT rebuild DOM
// or inject colors/fonts from JS; the template is the source of truth.
(function () {
  var state = {
    notes: [],
    total: null,  // null until first state message (with server-provided total) arrives
    index: 0,
    blank: false,
    startedAt: Date.now(),
    timerHandle: null,
    thumbsInitialized: false,
    sync: null,
  };

  // DOM handles resolved at init()
  var dom = {
    notesBody: null,
    notesIndex: null,
    notesTotal: null,
    timer: null,
    thumbCurrent: null,
    thumbNext: null,
    thumbCurrentWrap: null,
    thumbNextWrap: null,
    body: null,
  };

  function extractNotes(html) {
    var re = /<script[^>]+id=["']speaker-notes["'][^>]*>([\s\S]*?)<\/script>/i;
    var m = re.exec(html);
    if (!m) {
      showNotesError('speaker-notes <script id="speaker-notes"> block not found in /deck.html');
      return [];
    }
    // Strip HTML comments before parsing — the export build sometimes wraps JSON in comments.
    var body = m[1].replace(/<!--[\s\S]*?-->/g, '').trim();
    try {
      return JSON.parse(body);
    } catch (e) {
      showNotesError('Speaker notes parse failed: ' + e.message + ' (check deck.html speaker-notes JSON)');
      return [];
    }
  }

  function showNotesError(msg) {
    console.warn('[presenter]', msg);
    if (dom.notesBody) dom.notesBody.textContent = msg;
  }

  // Count slides via DOMParser. Scoped to `deck-stage > section` so that
  // <section> inside comments, string literals in inline scripts, or nested
  // constructs don't inflate the count.
  function countSlides(html) {
    try {
      var doc = new DOMParser().parseFromString(html, 'text/html');
      return doc.querySelectorAll('deck-stage > section').length;
    } catch (e) {
      console.warn('[presenter] countSlides DOMParser failed:', e);
      return 0;
    }
  }

  function renderNotes() {
    if (!dom.notesBody) return;
    var total = (state.total == null) ? '–' : String(state.total);
    if (dom.notesIndex) dom.notesIndex.textContent = String(state.index + 1);
    if (dom.notesTotal) dom.notesTotal.textContent = total;

    var raw = state.notes[state.index];
    if (!raw) {
      dom.notesBody.textContent = '(no notes)';
      return;
    }
    // Split on blank lines → paragraphs. Plain text; no HTML injection.
    dom.notesBody.textContent = '';
    String(raw).split(/\n\n+/).forEach(function (p) {
      var el = document.createElement('p');
      el.textContent = p;
      dom.notesBody.appendChild(el);
    });
  }

  // Thumbnail iframes: initialise src once, then navigate via postMessage.
  // deck-stage.js (loaded inside each iframe) listens for {type:'nav', slide:N}.
  // Fallback: if the iframe isn't ready on first nav, we still have the hash
  // set in src, so it will land on the right slide.
  function updateThumbs() {
    var curIdx = state.index + 1;
    var nextIdx = (state.total != null)
      ? Math.min(state.total, state.index + 2)
      : state.index + 2;

    if (!state.thumbsInitialized) {
      if (dom.thumbCurrent) dom.thumbCurrent.src = '/?export=true#slide=' + curIdx;
      if (dom.thumbNext) dom.thumbNext.src = '/?export=true#slide=' + nextIdx;
      state.thumbsInitialized = true;
      return;
    }

    postNav(dom.thumbCurrent, curIdx);
    postNav(dom.thumbNext, nextIdx);

    // Dim the "next" thumbnail when we're on the last slide
    if (dom.thumbNextWrap) {
      var atEnd = (state.total != null && state.index >= state.total - 1);
      dom.thumbNextWrap.classList.toggle('dimmed', atEnd);
      dom.thumbNextWrap.classList.toggle('end', atEnd);
    }
  }

  function postNav(iframe, slide1) {
    if (!iframe) return;
    var win = iframe.contentWindow;
    if (!win) return;
    try {
      win.postMessage({ type: 'nav', slide: slide1 }, '*');
    } catch (e) {
      // Fallback: reset src. Rare; postMessage to a same-origin child is safe.
      iframe.src = '/?export=true#slide=' + slide1;
    }
  }

  function applyBlank() {
    if (dom.body) dom.body.style.opacity = state.blank ? '0.5' : '1';
  }

  function formatElapsed(ms) {
    var s = Math.floor(ms / 1000);
    var h = Math.floor(s / 3600);
    var m = Math.floor((s % 3600) / 60);
    var sec = s % 60;
    function pad(n) { return n < 10 ? '0' + n : String(n); }
    return pad(h) + ':' + pad(m) + ':' + pad(sec);
  }

  function tickTimer() {
    if (dom.timer) dom.timer.textContent = formatElapsed(Date.now() - state.startedAt);
  }

  function resetTimer() {
    state.startedAt = Date.now();
    tickTimer();
  }

  function onKey(e) {
    if (e.key === 'r' || e.key === 'R') {
      resetTimer();
      e.preventDefault();
    }
  }

  function resolveDom() {
    dom.body = document.body;
    dom.notesBody = document.querySelector('#notes-body');
    dom.notesIndex = document.querySelector('#notes-index');
    dom.notesTotal = document.querySelector('#notes-total');
    dom.timer = document.querySelector('#timer');
    dom.thumbCurrent = document.querySelector('#thumb-current');
    dom.thumbNext = document.querySelector('#thumb-next');
    dom.thumbCurrentWrap = document.querySelector('#thumb-current-wrap');
    dom.thumbNextWrap = document.querySelector('#thumb-next-wrap');
  }

  function init() {
    resolveDom();

    fetch('/deck.html', { cache: 'no-store' })
      .then(function (r) {
        if (!r.ok) {
          throw new Error('HTTP ' + r.status + ' fetching /deck.html');
        }
        return r.text();
      })
      .then(function (html) {
        state.notes = extractNotes(html);
        // Local fallback count from the HTML. Authoritative total will arrive
        // via the WS `state` message (server-provided) once connected.
        var localTotal = countSlides(html);
        if (localTotal > 0 && state.total == null) state.total = localTotal;

        renderNotes();
        updateThumbs();
        state.timerHandle = setInterval(tickTimer, 1000);
        tickTimer();
        document.addEventListener('keydown', onKey);

        state.sync = window.DeckSync.connect('/ws', {
          onNav: function (msg) {
            if (!Number.isInteger(msg.slide)) return;
            state.index = msg.slide;
            renderNotes();
            updateThumbs();
          },
          onBlank: function (msg) {
            state.blank = !!msg.on;
            applyBlank();
          },
          onState: function (msg) {
            if (Number.isInteger(msg.slide)) state.index = msg.slide;
            state.blank = !!msg.blank;
            if (Number.isInteger(msg.total)) state.total = msg.total;
            renderNotes();
            updateThumbs();
            applyBlank();
          },
          onReload: function () { location.reload(); },
        });
      })
      .catch(function (e) {
        console.error('[presenter] failed to load /deck.html:', e);
        showNotesError('Failed to load /deck.html: ' + e.message);
      });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
