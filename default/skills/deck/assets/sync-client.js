'use strict';

(function (root) {
  function isExport() {
    try {
      return new URLSearchParams(root.location.search).get('export') === 'true';
    } catch (e) {
      return false;
    }
  }

  function stubConnection() {
    // Export mode runs under Puppeteer. No live-reload, no external sync —
    // Puppeteer must drive navigation deterministically with goto().
    return {
      send: function () {},
      close: function () {},
    };
  }

  function connect(url, handlers) {
    if (isExport()) return stubConnection();

    handlers = handlers || {};
    var ws = null;
    var closed = false;
    var attempt = 0;
    var reconnectTimer = null;

    function resolveUrl(u) {
      if (/^wss?:\/\//i.test(u)) return u;
      var proto = root.location.protocol === 'https:' ? 'wss:' : 'ws:';
      return proto + '//' + root.location.host + (u.charAt(0) === '/' ? u : '/' + u);
    }

    function scheduleReconnect() {
      if (closed) return;
      // Cap the exponent so delay tops out at ~10s even under sustained failure,
      // and add jitter so N clients reconnecting after a server restart don't
      // stampede in lockstep. Cap attempt itself to prevent unbounded growth.
      var capped = Math.min(attempt, 10);
      var base = Math.min(10000, 1000 * Math.pow(2, capped));
      var delay = base + Math.floor(Math.random() * 500);
      attempt = Math.min(attempt + 1, 30);
      reconnectTimer = setTimeout(open, delay);
    }

    function dispatch(msg) {
      switch (msg && msg.type) {
        case 'nav':    handlers.onNav    && handlers.onNav(msg); break;
        case 'blank':  handlers.onBlank  && handlers.onBlank(msg); break;
        case 'state':  handlers.onState  && handlers.onState(msg); break;
        case 'reload': handlers.onReload && handlers.onReload(msg); break;
      }
    }

    function open() {
      try {
        ws = new WebSocket(resolveUrl(url));
      } catch (e) {
        console.warn('[DeckSync] WebSocket construct failed:', e);
        scheduleReconnect();
        return;
      }
      ws.addEventListener('open', function () {
        attempt = 0;
        handlers.onOpen && handlers.onOpen();
      });
      ws.addEventListener('message', function (ev) {
        // Browsers deliver Blob/ArrayBuffer for binary frames — server only
        // sends JSON text, so anything non-string is noise. Drop silently.
        if (typeof ev.data !== 'string') return;
        var msg;
        try { msg = JSON.parse(ev.data); } catch (e) {
          console.warn('[DeckSync] bad message:', ev.data);
          return;
        }
        dispatch(msg);
      });
      ws.addEventListener('close', function () {
        handlers.onClose && handlers.onClose();
        scheduleReconnect();
      });
      ws.addEventListener('error', function (e) {
        console.warn('[DeckSync] socket error:', e && e.message ? e.message : e);
      });
    }

    open();

    return {
      send: function (msg) {
        if (!ws || ws.readyState !== 1) return false;
        try { ws.send(JSON.stringify(msg)); return true; }
        catch (e) { console.warn('[DeckSync] send failed:', e); return false; }
      },
      close: function () {
        closed = true;
        if (reconnectTimer) clearTimeout(reconnectTimer);
        if (ws) try { ws.close(); } catch (e) {}
      },
    };
  }

  root.DeckSync = { connect: connect };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = root.DeckSync;
  }
})(typeof window !== 'undefined' ? window : this);
