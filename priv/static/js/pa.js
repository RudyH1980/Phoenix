/* Phoenix Analytics tracker -- cookieloos, ~1KB */
(function () {
  var d = document, w = window;
  var endpoint = d.currentScript.dataset.api || "/api/collect";
  var siteToken = d.currentScript.dataset.site || "";

  // Stabiele visitor-ID via localStorage (geen cookie, geen cookiebanner nodig)
  function getVid() {
    try {
      var key = "pa_vid";
      var vid = localStorage.getItem(key);
      if (!vid) {
        vid = Math.random().toString(36).slice(2) + Date.now().toString(36);
        localStorage.setItem(key, vid);
      }
      return vid;
    } catch (e) {
      return "";
    }
  }

  var vid = getVid();

  function send(payload) {
    var body = JSON.stringify(payload);
    if (w.navigator.sendBeacon) {
      // sendBeacon stuurt standaard text/plain -- Blob forceert application/json zodat de server het correct parst
      var blob = new Blob([body], { type: "application/json" });
      navigator.sendBeacon(endpoint, blob);
    } else {
      var r = new XMLHttpRequest();
      r.open("POST", endpoint, true);
      r.setRequestHeader("Content-Type", "application/json");
      r.send(body);
    }
  }

  function base(type, extra) {
    return Object.assign({
      t: type,
      s: siteToken,
      u: w.location.href,
      r: d.referrer || null,
      w: w.innerWidth,
      vid: vid
    }, extra || {});
  }

  // Pageview
  send(base("pv"));

  // Tijd op pagina -- stuur bij weggaan
  var startTime = Date.now();
  function sendDuration() {
    var seconds = Math.round((Date.now() - startTime) / 1000);
    if (seconds < 2) return;
    send(base("ev", { n: "time_on_page", m: { seconds: seconds } }));
  }
  d.addEventListener("visibilitychange", function () {
    if (d.visibilityState === "hidden") sendDuration();
  });
  w.addEventListener("pagehide", sendDuration, { passive: true });

  // Custom event tracking via data-pa-event attribuut
  d.addEventListener("click", function (e) {
    var el = e.target.closest("[data-pa-event]");
    if (!el) return;
    send(base("ev", {
      n: el.dataset.paEvent,
      m: el.dataset.paMeta ? JSON.parse(el.dataset.paMeta) : null
    }));
  }, { passive: true });

  // Auto-click tracking: knoppen en links zonder data-pa-event
  d.addEventListener("click", function (e) {
    var el = e.target.closest("button, a, [role=button]");
    if (!el || el.dataset.paEvent) return;
    var label = (el.getAttribute("aria-label") || el.innerText || el.getAttribute("title") || "").trim().replace(/\s+/g, " ").slice(0, 64);
    if (!label) return;
    send(base("ev", {
      n: "click:" + el.tagName.toLowerCase(),
      m: { label: label, id: el.id || null }
    }));
  }, { passive: true });

  // Heatmap: alle klikken tracken met x/y% t.o.v. de pagina
  d.addEventListener("click", function (e) {
    var pageH = d.documentElement.scrollHeight;
    var x = Math.round(e.clientX / w.innerWidth * 100);
    var y = pageH > 0 ? Math.round((e.clientY + w.pageYOffset) / pageH * 100) : 0;
    send(base("ev", { n: "heatmap_click", m: { x: x, y: y } }));
  }, { passive: true });

  // SPA navigatie (pushState / replaceState)
  var _push = history.pushState;
  history.pushState = function () {
    _push.apply(this, arguments);
    startTime = Date.now();
    send(base("pv"));
  };
  w.addEventListener("popstate", function () {
    startTime = Date.now();
    send(base("pv"));
  });
}());
