'use strict';

(function () {
  if (typeof window === 'undefined') return;
  if (window.customElements && customElements.get('deck-stage')) return;

  const DEFAULT_W = 1920;
  const DEFAULT_H = 1080;
  const INPUT_TAG_RE = /^(INPUT|TEXTAREA|SELECT)$/;

  const SHADOW_CSS = `
    :host {
      display: block;
      position: relative;
      overflow: hidden;
    }

    .canvas {
      position: absolute;
      top: 0;
      left: 0;
      transform-origin: top left;
      z-index: 2;
    }

    ::slotted(*) {
      position: absolute !important;
      inset: 0 !important;
      visibility: hidden;
      opacity: 0;
    }

    ::slotted([data-deck-active]) {
      visibility: visible;
      opacity: 1;
    }

    /* Export mode (Puppeteer): flip to display-based hide/show so the
       captured page only paints the active slide. Template slides use
       display: flex, so the active rule restores that. */
    :host([noscale]) ::slotted(*) {
      display: none !important;
    }
    :host([noscale]) ::slotted([data-deck-active]) {
      display: flex !important;
    }

    .tap {
      position: absolute;
      top: 0;
      bottom: 0;
      width: 33.333%;
      z-index: 1;
      pointer-events: auto;
      background: transparent;
    }
    .tap-left  { left: 0; }
    .tap-right { right: 0; }

    @media (hover: hover) and (pointer: fine) {
      .tap { display: none; }
    }

    @media print {
      :host { overflow: visible; }
      .canvas {
        transform: none !important;
        position: static;
        width: 100%;
        height: auto;
      }
      ::slotted(*) {
        position: relative !important;
        inset: auto !important;
        visibility: visible !important;
        opacity: 1 !important;
        display: flex !important;
        page-break-after: always;
      }
      ::slotted(*:last-child) { page-break-after: auto; }
      .tap { display: none !important; }
    }
  `;

  class DeckStage extends HTMLElement {
    static get observedAttributes() { return ['noscale']; }

    constructor() {
      super();
      this._state = { slides: [], index: 0 };
      this._width = DEFAULT_W;
      this._height = DEFAULT_H;
      this._built = false;
      this._resizeObserver = null;
      this._mutationObserver = null;
      this._onKeydown = null;
      this._onTapLeft = null;
      this._onTapRight = null;
      this._canvasEl = null;
      this._tapLeftEl = null;
      this._tapRightEl = null;
    }

    connectedCallback() {
      this._width = this._readIntAttr('width', DEFAULT_W);
      this._height = this._readIntAttr('height', DEFAULT_H);

      this._buildShadow();
      this._injectPageStyle();
      this._collectSlides();

      this._resizeObserver = new ResizeObserver(() => this._applyScale());
      this._resizeObserver.observe(this);

      this._mutationObserver = new MutationObserver(() => this._onLightDomMutation());
      this._mutationObserver.observe(this, { childList: true });

      this._onKeydown = (e) => this._handleKeydown(e);
      document.addEventListener('keydown', this._onKeydown);

      this._onTapLeft = (e) => { e.preventDefault(); this.prev('tap'); };
      this._onTapRight = (e) => { e.preventDefault(); this.next('tap'); };
      this._tapLeftEl.addEventListener('click', this._onTapLeft);
      this._tapRightEl.addEventListener('click', this._onTapRight);

      this._applyScale();

      const initialIndex = Math.min(this._state.index, Math.max(0, this._state.slides.length - 1));
      this._state.index = initialIndex;
      const slide = this._state.slides[initialIndex] || null;
      this._activate(initialIndex);
      this._dispatchSlideChange({
        index: initialIndex,
        previousIndex: null,
        slide: slide,
        previousSlide: null,
        reason: 'init',
      });
    }

    disconnectedCallback() {
      if (this._resizeObserver) {
        this._resizeObserver.disconnect();
        this._resizeObserver = null;
      }
      if (this._mutationObserver) {
        this._mutationObserver.disconnect();
        this._mutationObserver = null;
      }
      if (this._onKeydown) {
        document.removeEventListener('keydown', this._onKeydown);
        this._onKeydown = null;
      }
      if (this._tapLeftEl && this._onTapLeft) {
        this._tapLeftEl.removeEventListener('click', this._onTapLeft);
      }
      if (this._tapRightEl && this._onTapRight) {
        this._tapRightEl.removeEventListener('click', this._onTapRight);
      }
      this._onTapLeft = null;
      this._onTapRight = null;
    }

    attributeChangedCallback(name, _prev, _next) {
      if (name === 'noscale' && this._built) {
        this._applyScale();
      }
    }

    get index()  { return this._state.index; }
    get length() { return this._state.slides.length; }

    goto(i, reason = 'api') {
      const total = this._state.slides.length;
      if (total === 0) return Promise.resolve();

      const target = Math.max(0, Math.min(total - 1, i | 0));
      const current = this._state.index;
      const noOp = target === current;

      const previousSlide = this._state.slides[current] || null;
      const previousIndex = current;

      if (!noOp) {
        this._state.index = target;
        this._activate(target);
        this._dispatchSlideChange({
          index: target,
          previousIndex: previousIndex,
          slide: this._state.slides[target] || null,
          previousSlide: previousSlide,
          reason: reason,
        });
      }

      // Export mode awaits double rAF — Puppeteer's page.pdf() fires as soon
      // as goto()'s promise resolves, and single-rAF occasionally paints the
      // previous frame's layout. Double-rAF guarantees layout + paint of the
      // new active slide before the PDF snapshot.
      if (this.hasAttribute('noscale')) {
        return new Promise((resolve) => {
          requestAnimationFrame(() => {
            requestAnimationFrame(() => resolve());
          });
        });
      }
      return new Promise((resolve) => {
        requestAnimationFrame(() => resolve());
      });
    }

    next(reason = 'api')  { return this.goto(this._state.index + 1, reason); }
    prev(reason = 'api')  { return this.goto(this._state.index - 1, reason); }
    reset(reason = 'api') { return this.goto(0, reason); }

    _readIntAttr(name, fallback) {
      const raw = this.getAttribute(name);
      if (raw == null || raw === '') return fallback;
      const n = parseInt(raw, 10);
      return Number.isFinite(n) && n > 0 ? n : fallback;
    }

    _buildShadow() {
      if (this._built) return;
      const root = this.shadowRoot || this.attachShadow({ mode: 'open' });

      const style = document.createElement('style');
      style.textContent = SHADOW_CSS;

      const canvas = document.createElement('div');
      canvas.className = 'canvas';
      canvas.style.width = this._width + 'px';
      canvas.style.height = this._height + 'px';
      const slot = document.createElement('slot');
      canvas.appendChild(slot);

      const tapLeft = document.createElement('div');
      tapLeft.className = 'tap tap-left';
      tapLeft.setAttribute('aria-hidden', 'true');

      const tapRight = document.createElement('div');
      tapRight.className = 'tap tap-right';
      tapRight.setAttribute('aria-hidden', 'true');

      root.appendChild(style);
      root.appendChild(canvas);
      root.appendChild(tapLeft);
      root.appendChild(tapRight);

      this._canvasEl = canvas;
      this._tapLeftEl = tapLeft;
      this._tapRightEl = tapRight;
      this._built = true;
    }

    // @page must live in the document head, not the shadow tree — @page is
    // scoped to the page context and shadow CSS cannot reach it. One style
    // node per document is enough even with multiple <deck-stage> instances.
    _injectPageStyle() {
      if (!document || !document.head) return;
      let node = document.head.querySelector('style[data-deck-stage-page]');
      if (!node) {
        node = document.createElement('style');
        node.setAttribute('data-deck-stage-page', '');
        document.head.appendChild(node);
      }
      node.textContent = '@page { size: ' + this._width + 'px ' + this._height + 'px; margin: 0; }';
    }

    _collectSlides() {
      this._state.slides = Array.from(this.querySelectorAll(':scope > *'));
    }

    _onLightDomMutation() {
      const previousActive = this._state.slides[this._state.index] || null;
      const previousIndex = this._state.index;

      this._collectSlides();

      const total = this._state.slides.length;
      if (total === 0) {
        this._state.index = 0;
        return;
      }

      let nextIndex;
      if (previousActive && this._state.slides.indexOf(previousActive) !== -1) {
        nextIndex = this._state.slides.indexOf(previousActive);
      } else {
        nextIndex = Math.max(0, Math.min(total - 1, previousIndex));
      }

      const nextActive = this._state.slides[nextIndex] || null;
      const elementChanged = nextActive !== previousActive;

      this._state.index = nextIndex;
      this._activate(nextIndex);

      if (elementChanged) {
        this._dispatchSlideChange({
          index: nextIndex,
          previousIndex: previousIndex,
          slide: nextActive,
          previousSlide: previousActive,
          reason: 'mutation',
        });
      }
    }

    _activate(i) {
      const slides = this._state.slides;
      for (let k = 0; k < slides.length; k++) {
        const el = slides[k];
        if (k === i) {
          el.setAttribute('data-deck-active', '');
          el.setAttribute('aria-hidden', 'false');
        } else {
          if (el.hasAttribute('data-deck-active')) el.removeAttribute('data-deck-active');
          el.setAttribute('aria-hidden', 'true');
        }
      }
    }

    _applyScale() {
      if (!this._canvasEl) return;

      if (this.hasAttribute('noscale')) {
        this._canvasEl.style.transform = '';
        this._canvasEl.style.left = '';
        this._canvasEl.style.top = '';
        return;
      }

      const hostW = this.clientWidth;
      const hostH = this.clientHeight;
      if (hostW === 0 || hostH === 0) return;

      const s = Math.min(hostW / this._width, hostH / this._height);
      const scaledW = this._width * s;
      const scaledH = this._height * s;
      const x = (hostW - scaledW) / 2;
      const y = (hostH - scaledH) / 2;

      this._canvasEl.style.left = '0px';
      this._canvasEl.style.top = '0px';
      this._canvasEl.style.transform = 'translate(' + x + 'px, ' + y + 'px) scale(' + s + ')';
    }

    _handleKeydown(e) {
      // Input-guard: skip when focus is inside editable surfaces or the event
      // was already handled by another listener. Controller layers handle
      // their own keys (F/S/G/B/R/Escape) and we must not eat those.
      if (e.defaultPrevented) return;
      const t = e.target;
      if (t && t.tagName && INPUT_TAG_RE.test(t.tagName)) return;
      if (t && t.isContentEditable) return;

      const key = e.key;
      let handled = true;

      switch (key) {
        case 'ArrowRight':
        case 'PageDown':
        case ' ':
        case 'Spacebar':
          this.next('keyboard');
          break;
        case 'ArrowLeft':
        case 'PageUp':
          this.prev('keyboard');
          break;
        case 'Home':
          this.goto(0, 'keyboard');
          break;
        case 'End':
          this.goto(this._state.slides.length - 1, 'keyboard');
          break;
        case '0':
          this.goto(9, 'keyboard');
          break;
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
          this.goto(parseInt(key, 10) - 1, 'keyboard');
          break;
        default:
          handled = false;
      }

      if (handled) e.preventDefault();
    }

    _dispatchSlideChange(detail) {
      const evt = new CustomEvent('slidechange', {
        bubbles: true,
        composed: true,
        detail: {
          index: detail.index,
          previousIndex: detail.previousIndex,
          total: this._state.slides.length,
          slide: detail.slide,
          previousSlide: detail.previousSlide,
          reason: detail.reason,
        },
      });
      this.dispatchEvent(evt);
    }
  }

  customElements.define('deck-stage', DeckStage);
})();
