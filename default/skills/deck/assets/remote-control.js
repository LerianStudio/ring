'use strict';

// Remote-control view controller. HTML-first: remote.html owns the DOM + CSS
// (including Amarelo accent, Poppins/JetBrains Mono fonts, safe-area insets,
// button layout). This file wires behaviour only — it queries existing
// elements and attaches listeners. It MUST NOT rebuild DOM or inject colors/
// fonts from JS; the template is the source of truth.
(function () {
  var state = {
    index: 0,
    total: null,  // null until server sends a state message with total
    blank: false,
    sync: null,
    wakeLock: null,
  };

  // DOM handles resolved at init()
  var dom = {
    banner: null,
    currentSlide: null,
    totalSlides: null,
    btnPrev: null,
    btnNext: null,
    btnBlank: null,
    btnGoto: null,
    btnFirst: null,
    btnLast: null,
    wakeLockStatus: null,
  };

  function buzz() {
    if (navigator.vibrate) try { navigator.vibrate(20); } catch (e) { /* iOS silently disallows */ }
  }

  function updateReadout() {
    if (dom.currentSlide) {
      dom.currentSlide.textContent = (state.total != null) ? String(state.index + 1) : '–';
    }
    if (dom.totalSlides) {
      dom.totalSlides.textContent = (state.total != null) ? String(state.total) : '–';
    }
    if (dom.btnBlank) {
      dom.btnBlank.textContent = state.blank ? 'Unblank' : 'Blank';
      dom.btnBlank.classList.toggle('active', state.blank);
    }
    // First/Last only meaningful when total is known
    var totalKnown = (state.total != null);
    if (dom.btnFirst) dom.btnFirst.disabled = !totalKnown;
    if (dom.btnLast) dom.btnLast.disabled = !totalKnown;
    if (dom.btnPrev) dom.btnPrev.disabled = !totalKnown;
    if (dom.btnNext) dom.btnNext.disabled = !totalKnown;
    if (dom.btnGoto) dom.btnGoto.disabled = !totalKnown;
  }

  function navigateDelta(delta) {
    if (state.total == null) return;
    var next = Math.max(0, Math.min(state.total - 1, state.index + delta));
    if (next === state.index) return;
    sendNav(next);
  }

  function sendNav(n) {
    if (!state.sync) return;
    var ok = state.sync.send({ type: 'nav', slide: n });
    if (ok) buzz();
  }

  function toggleBlank() {
    if (!state.sync) return;
    var ok = state.sync.send({ type: 'blank', on: !state.blank });
    if (ok) buzz();
  }

  function promptGoto() {
    if (state.total == null) return;
    var input = window.prompt('Go to slide (1..' + state.total + '):');
    if (input == null || input === '') return;
    var n = parseInt(input, 10);
    if (isNaN(n)) return;
    var idx = Math.max(0, Math.min(state.total - 1, n - 1));
    sendNav(idx);
  }

  function gotoFirst() {
    if (state.total == null) return;
    sendNav(0);
  }

  function gotoLast() {
    if (state.total == null) return;
    sendNav(state.total - 1);
  }

  function setBanner(text, kind) {
    if (!dom.banner) return;
    if (!text) {
      dom.banner.classList.remove('visible', 'error', 'ok');
      dom.banner.textContent = '';
      return;
    }
    dom.banner.textContent = text;
    dom.banner.classList.remove('error', 'ok');
    if (kind) dom.banner.classList.add(kind);
    dom.banner.classList.add('visible');
  }

  function flashBanner(text, kind, ms) {
    setBanner(text, kind);
    setTimeout(function () { setBanner('', ''); }, ms);
  }

  function setWakeLockStatus(msg) {
    if (dom.wakeLockStatus) dom.wakeLockStatus.textContent = msg || '';
  }

  // Wake Lock API: only available on HTTPS (secure context). On LAN HTTP —
  // the default deployment for a phone remote — request() rejects with
  // NotAllowedError. Show a subtle indicator so the user knows to keep the
  // screen awake manually.
  async function requestWakeLock() {
    if (!('wakeLock' in navigator)) {
      setWakeLockStatus('screen-sleep: on (no wake lock api)');
      return;
    }
    try {
      state.wakeLock = await navigator.wakeLock.request('screen');
      setWakeLockStatus('');
      if (state.wakeLock.addEventListener) {
        state.wakeLock.addEventListener('release', function () {
          state.wakeLock = null;
          setWakeLockStatus('screen-sleep: on');
        });
      }
    } catch (e) {
      // HTTP / insecure context, or missing user gesture.
      setWakeLockStatus('screen-sleep: on');
    }
  }

  function resolveDom() {
    dom.banner = document.querySelector('#status-banner');
    dom.currentSlide = document.querySelector('#current-slide');
    dom.totalSlides = document.querySelector('#total-slides');
    dom.btnPrev = document.querySelector('#btn-prev');
    dom.btnNext = document.querySelector('#btn-next');
    dom.btnBlank = document.querySelector('#btn-blank');
    dom.btnGoto = document.querySelector('#btn-goto');
    dom.btnFirst = document.querySelector('#btn-first');
    dom.btnLast = document.querySelector('#btn-last');
    dom.wakeLockStatus = document.querySelector('#wakelock-status');
  }

  function wireButtons() {
    if (dom.btnPrev) dom.btnPrev.addEventListener('click', function () { navigateDelta(-1); });
    if (dom.btnNext) dom.btnNext.addEventListener('click', function () { navigateDelta(1); });
    if (dom.btnBlank) dom.btnBlank.addEventListener('click', toggleBlank);
    if (dom.btnGoto) dom.btnGoto.addEventListener('click', promptGoto);
    if (dom.btnFirst) dom.btnFirst.addEventListener('click', gotoFirst);
    if (dom.btnLast) dom.btnLast.addEventListener('click', gotoLast);
  }

  function init() {
    resolveDom();
    wireButtons();
    updateReadout();

    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible' && !state.wakeLock) requestWakeLock();
    });
    document.body.addEventListener('click', function once() {
      if (!state.wakeLock) requestWakeLock();
      document.body.removeEventListener('click', once);
    });
    requestWakeLock();

    state.sync = window.DeckSync.connect('/ws', {
      onOpen: function () { flashBanner('connected', 'ok', 1200); },
      onClose: function () { setBanner('reconnecting…', 'error'); },
      onNav: function (msg) {
        if (!Number.isInteger(msg.slide)) return;
        state.index = msg.slide;
        // MUST NOT mutate state.total from nav — total is authoritative from state messages only.
        updateReadout();
      },
      onBlank: function (msg) {
        state.blank = !!msg.on;
        updateReadout();
      },
      onState: function (msg) {
        if (Number.isInteger(msg.slide)) state.index = msg.slide;
        state.blank = !!msg.blank;
        if (Number.isInteger(msg.total)) state.total = msg.total;
        updateReadout();
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
