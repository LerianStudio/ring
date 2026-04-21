'use strict';

// Feedback panel. T key or toolbar Tweak button opens it. Collects a note
// scoped to the currently active slide, POSTs to /feedback.
// Mutually exclusive with notes panel — emits 'deck-feedback-opening' on
// open so the controller can close its notes panel.

(function () {
  const state = {
    panelEl: null,
    textareaEl: null,
    slideLabelEl: null,
    statusEl: null,
    open: false,
    stage: null,
  };

  function mount(stage) {
    if (state.panelEl) return;
    state.stage = stage;
    buildDom();
  }

  function buildDom() {
    const panel = document.createElement('div');
    panel.id = 'deck-feedback-panel';
    panel.setAttribute('aria-label', 'Slide feedback');
    panel.style.cssText = [
      'position:fixed',
      'left:50%',
      'bottom:80px',
      'transform:translateX(-50%)',
      'width:min(640px, 90vw)',
      'background:#fff',
      'color:#191A1B',
      'border-radius:8px',
      'box-shadow:0 16px 48px rgba(0,0,0,0.35)',
      'z-index:9997',
      'display:none',
      "font-family:'IBM Plex Serif', Georgia, serif",
      'overflow:hidden',
    ].join(';') + ';';

    // Header
    const header = document.createElement('div');
    header.style.cssText = [
      'display:flex',
      'align-items:center',
      'justify-content:space-between',
      'padding:14px 18px',
      'border-bottom:1px solid #e4e4e7',
      'background:#fafafa',
    ].join(';') + ';';

    const title = document.createElement('div');
    title.style.cssText = 'display:flex;flex-direction:column;gap:2px;';

    const titleLabel = document.createElement('span');
    titleLabel.textContent = 'Feedback';
    titleLabel.style.cssText = [
      "font-family:'JetBrains Mono', ui-monospace, monospace",
      'font-size:11px',
      'letter-spacing:0.08em',
      'text-transform:uppercase',
      'opacity:0.6',
    ].join(';') + ';';

    const slideLabel = document.createElement('span');
    slideLabel.style.cssText = 'font-size:15px;font-weight:500;';
    state.slideLabelEl = slideLabel;

    title.appendChild(titleLabel);
    title.appendChild(slideLabel);

    const closeBtn = document.createElement('button');
    closeBtn.type = 'button';
    closeBtn.setAttribute('aria-label', 'Close feedback');
    closeBtn.textContent = '×';
    closeBtn.style.cssText = [
      'background:transparent',
      'border:0',
      'font-size:24px',
      'line-height:1',
      'cursor:pointer',
      'color:#191A1B',
      'padding:4px 8px',
    ].join(';') + ';';
    closeBtn.addEventListener('click', close);

    header.appendChild(title);
    header.appendChild(closeBtn);

    // Body
    const body = document.createElement('div');
    body.style.cssText = 'padding:16px 18px;';

    const textarea = document.createElement('textarea');
    textarea.rows = 6;
    textarea.placeholder = 'What do you want changed?';
    textarea.style.cssText = [
      'width:100%',
      'box-sizing:border-box',
      'padding:10px 12px',
      'font-family:inherit',
      'font-size:15px',
      'line-height:1.5',
      'border:1px solid #d4d4d8',
      'border-radius:4px',
      'resize:vertical',
      'outline:none',
      'color:inherit',
      'background:#fff',
    ].join(';') + ';';
    textarea.addEventListener('keydown', onTextareaKeydown);
    state.textareaEl = textarea;
    body.appendChild(textarea);

    // Footer
    const footer = document.createElement('div');
    footer.style.cssText = [
      'display:flex',
      'align-items:center',
      'justify-content:space-between',
      'padding:12px 18px 16px',
      'gap:12px',
    ].join(';') + ';';

    const helper = document.createElement('span');
    helper.textContent = 'Cmd/Ctrl+Enter to send · Esc to close';
    helper.style.cssText = [
      "font-family:'JetBrains Mono', ui-monospace, monospace",
      'font-size:11px',
      'letter-spacing:0.04em',
      'opacity:0.6',
    ].join(';') + ';';
    state.statusEl = helper;

    const sendBtn = document.createElement('button');
    sendBtn.type = 'button';
    sendBtn.textContent = 'Send to Claude';
    sendBtn.style.cssText = [
      'padding:8px 16px',
      'background:#191A1B',
      'color:#fff',
      'border:0',
      'border-radius:4px',
      'cursor:pointer',
      "font-family:'JetBrains Mono', ui-monospace, monospace",
      'font-size:12px',
      'letter-spacing:0.04em',
      'text-transform:uppercase',
    ].join(';') + ';';
    sendBtn.addEventListener('click', send);

    footer.appendChild(helper);
    footer.appendChild(sendBtn);

    panel.appendChild(header);
    panel.appendChild(body);
    panel.appendChild(footer);

    document.body.appendChild(panel);
    state.panelEl = panel;
  }

  function onTextareaKeydown(e) {
    if (e.key === 'Escape') {
      e.preventDefault();
      close();
      return;
    }
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault();
      send();
    }
  }

  function open() {
    if (!state.panelEl) return;
    // Announce intent so the controller can close the notes panel (mutex).
    // CustomEvent is the cross-module contract — avoids coupling to the
    // controller's internal state shape.
    document.dispatchEvent(new CustomEvent('deck-feedback-opening'));

    state.open = true;
    state.panelEl.style.display = 'block';
    refreshSlideContext();
    resetStatus();
    setTimeout(() => state.textareaEl && state.textareaEl.focus(), 50);
  }

  function close() {
    if (!state.open) return;
    state.open = false;
    state.panelEl.style.display = 'none';
  }

  function toggle() { state.open ? close() : open(); }

  function refreshSlideContext() {
    if (!state.stage || !state.slideLabelEl) return;
    const i = state.stage.index;
    const total = state.stage.length;
    const slide = state.stage.querySelectorAll(':scope > *')[i];
    const label = slide ? (slide.getAttribute('data-label') || '(no label)') : '';
    state.slideLabelEl.textContent = 'Slide ' + (i + 1) + ' / ' + total + ' — ' + label;
  }

  function resetStatus() {
    if (!state.statusEl) return;
    state.statusEl.textContent = 'Cmd/Ctrl+Enter to send · Esc to close';
    state.statusEl.style.color = '';
    state.statusEl.style.opacity = '0.6';
  }

  function flashSaved() {
    if (!state.statusEl) return;
    state.statusEl.textContent = 'Saved to feedback.jsonl';
    state.statusEl.style.color = '#207840';
    state.statusEl.style.opacity = '1';
    setTimeout(resetStatus, 1500);
  }

  function showError(msg) {
    if (!state.statusEl) return;
    state.statusEl.textContent = 'Error: ' + msg;
    state.statusEl.style.color = '#b02222';
    state.statusEl.style.opacity = '1';
  }

  async function send() {
    if (!state.textareaEl) return;
    const text = state.textareaEl.value.trim();
    if (!text) return;
    const i = state.stage.index;
    const slide = state.stage.querySelectorAll(':scope > *')[i];
    const label = slide ? (slide.getAttribute('data-label') || '') : '';
    try {
      const res = await fetch('/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ slideIndex: i, slideLabel: label, text: text }),
      });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const data = await res.json().catch(() => ({}));
      if (data && data.ok === false) throw new Error(data.error || 'save failed');
      state.textareaEl.value = '';
      flashSaved();
    } catch (e) {
      showError(e.message);
    }
  }

  // Keep the header label in sync when the user navigates with the panel open.
  document.addEventListener('slidechange', () => {
    if (state.open) refreshSlideContext();
  });

  window.__deckFeedback = { mount, open, close, toggle };
})();
