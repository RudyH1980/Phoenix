/* Neo Analytics tracker -- cookieloos, ~1KB */
(function () {
  var d = document, w = window;
  var scriptSrc = d.currentScript.src;
  var scriptOrigin = scriptSrc.substring(0, scriptSrc.indexOf("/js/"));
  var endpoint = d.currentScript.dataset.api || (scriptOrigin + "/api/collect");
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
    try {
      fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        keepalive: true
      });
    } catch (e) {}
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

  // Sectie-tracking via data-pa-section attribuut (Intersection Observer)
  if (w.IntersectionObserver) {
    var seen = {};
    var observer = new w.IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var name = entry.target.dataset.paSection;
        if (!name || seen[name]) return;
        seen[name] = true;
        send(base("ev", { n: "section_view", m: { section: name } }));
      });
    }, { threshold: 0.3 });

    d.querySelectorAll("[data-pa-section]").forEach(function (el) {
      observer.observe(el);
    });
  }

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
