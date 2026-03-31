/* Phoenix Analytics tracker -- cookieloos, ~800 bytes */
(function () {
  var d = document, w = window;
  var endpoint = d.currentScript.dataset.api || "/api/collect";
  var siteToken = d.currentScript.dataset.site || "";

  function send(payload) {
    if (w.navigator.sendBeacon) {
      navigator.sendBeacon(endpoint, JSON.stringify(payload));
    } else {
      var r = new XMLHttpRequest();
      r.open("POST", endpoint, true);
      r.setRequestHeader("Content-Type", "application/json");
      r.send(JSON.stringify(payload));
    }
  }

  function base(type, extra) {
    return Object.assign({
      t: type,
      s: siteToken,
      u: w.location.href,
      r: d.referrer || null,
      w: w.innerWidth
    }, extra || {});
  }

  // Pageview
  send(base("pv"));

  // Klik-tracking (event delegation -- geen listeners per element)
  d.addEventListener("click", function (e) {
    var el = e.target.closest("[data-pa-event]");
    if (!el) return;
    send(base("ev", {
      n: el.dataset.paEvent,
      m: el.dataset.paMeta ? JSON.parse(el.dataset.paMeta) : null
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
    send(base("pv"));
  };
  w.addEventListener("popstate", function () { send(base("pv")); });
}());
