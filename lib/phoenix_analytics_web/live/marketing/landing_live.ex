defmodule PhoenixAnalyticsWeb.Live.Marketing.LandingLive do
  use PhoenixAnalyticsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Neo Analytics — Privacy-First Web Analytics",
       canonical_url: "https://phoenix-analytics.fly.dev/"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-lp-wrapper">
      <%!-- NAV --%>
      <nav class="pa-lp-nav">
        <span class="pa-lp-nav-brand">Neo Analytics</span>
        <div class="pa-lp-nav-links">
          <a href="/login" class="pa-btn pa-btn--ghost pa-btn--sm">Inloggen</a>
          <a href="/login" class="pa-btn pa-btn--primary pa-btn--sm">Gratis starten →</a>
        </div>
      </nav>

      <%!-- HERO --%>
      <section class="pa-lp-section pa-lp-hero" data-pa-section="hero">
        <div class="pa-lp-hero-badge">Privacy-first · Cookieloos · GDPR-compliant</div>
        <h1 class="pa-lp-hero-title">
          Privacy-first analytics.<br />Geen cookiebanner nodig.
        </h1>
        <p class="pa-lp-hero-sub">
          Cookieloos, GDPR-compliant, Lighthouse 4&times;100. Alles in één platform.
        </p>
        <div class="pa-lp-hero-ctas">
          <a href="/login" class="pa-btn pa-btn--primary">Probeer gratis →</a>
          <a href="/auth/demo" class="pa-btn pa-btn--ghost">Bekijk de demo</a>
        </div>
        <div class="pa-lp-hero-metrics">
          <div class="pa-lp-hero-metric">
            <span class="pa-lp-hero-metric-value">0</span>
            <span class="pa-lp-hero-metric-label">Cookies</span>
          </div>
          <div class="pa-lp-hero-metric">
            <span class="pa-lp-hero-metric-value">100</span>
            <span class="pa-lp-hero-metric-label">Lighthouse score</span>
          </div>
          <div class="pa-lp-hero-metric">
            <span class="pa-lp-hero-metric-value">GDPR</span>
            <span class="pa-lp-hero-metric-label">Compliant</span>
          </div>
        </div>
      </section>

      <%!-- FEATURES GRID --%>
      <section class="pa-lp-section">
        <h2 class="pa-lp-section-title">Alles wat je nodig hebt, niets wat je niet wilt</h2>
        <p class="pa-lp-section-sub">
          Geen trackers, geen cookiebanner, geen privacy-hoofdpijn.
        </p>
        <div class="pa-lp-features-grid">
          <div class="pa-lp-feature-card">
            <div class="pa-lp-feature-icon">🍪</div>
            <h3>Geen cookiebanner</h3>
            <p>Cookieloos tracking. Volledig GDPR-compliant zonder toestemmingspopup.</p>
          </div>
          <div class="pa-lp-feature-card">
            <div class="pa-lp-feature-icon">⚗️</div>
            <h3>A/B Testing</h3>
            <p>Ingebouwd, deterministisch, geen cookie. Variant toewijzing via session hash.</p>
          </div>
          <div class="pa-lp-feature-card">
            <div class="pa-lp-feature-icon">🔥</div>
            <h3>Heatmaps</h3>
            <p>Klik-heatmaps per pagina. Zie direct waar bezoekers op klikken.</p>
          </div>
          <div class="pa-lp-feature-card">
            <div class="pa-lp-feature-icon">⚡</div>
            <h3>Lighthouse 4&times;100</h3>
            <p>Sneller dan de meeste analytics tools zelf. Geen render-blocking scripts.</p>
          </div>
          <div class="pa-lp-feature-card">
            <div class="pa-lp-feature-icon">📡</div>
            <h3>Realtime</h3>
            <p>Live bezoekers zichtbaar. Zie direct wie er op je site is.</p>
          </div>
          <div class="pa-lp-feature-card">
            <div class="pa-lp-feature-icon">🔒</div>
            <h3>Privacy-first</h3>
            <p>
              Geen PII, geen raw IP opslag. Sessies worden gehasht met dagelijks roterende sleutel.
            </p>
          </div>
        </div>
      </section>

      <%!-- VERGELIJKINGSTABEL --%>
      <section class="pa-lp-section">
        <h2 class="pa-lp-section-title">Neo Analytics vs. de rest</h2>
        <p class="pa-lp-section-sub">
          Zie in één oogopslag waarom privacy-first de slimme keuze is.
        </p>
        <div class="pa-lp-comparison-wrap">
          <table class="pa-lp-comparison-table">
            <thead>
              <tr>
                <th>Feature</th>
                <th class="pa-lp-col-featured">Neo Analytics</th>
                <th>Google Analytics</th>
                <th>Hotjar</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Cookieloos</td>
                <td class="pa-lp-col-featured pa-lp-check">✓</td>
                <td class="pa-lp-cross">✗</td>
                <td class="pa-lp-cross">✗</td>
              </tr>
              <tr>
                <td>GDPR zonder banner</td>
                <td class="pa-lp-col-featured pa-lp-check">✓</td>
                <td class="pa-lp-cross">✗</td>
                <td class="pa-lp-cross">✗</td>
              </tr>
              <tr>
                <td>A/B testing ingebouwd</td>
                <td class="pa-lp-col-featured pa-lp-check">✓</td>
                <td class="pa-lp-cross">✗</td>
                <td class="pa-lp-cross">✗</td>
              </tr>
              <tr>
                <td>Heatmaps ingebouwd</td>
                <td class="pa-lp-col-featured pa-lp-check">✓</td>
                <td class="pa-lp-cross">✗</td>
                <td class="pa-lp-check">✓</td>
              </tr>
              <tr>
                <td>Prijs</td>
                <td class="pa-lp-col-featured">
                  <span class="pa-lp-price-tag">Gratis te starten</span>
                </td>
                <td>Gratis / €€€</td>
                <td>€39/maand</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <%!-- PRICING --%>
      <section class="pa-lp-section">
        <h2 class="pa-lp-section-title">Simpele, eerlijke prijzen</h2>
        <p class="pa-lp-section-sub">
          Geen verborgen kosten. Opzeggen kan altijd.
        </p>
        <div class="pa-lp-pricing-grid">
          <div class="pa-lp-pricing-card">
            <div class="pa-lp-pricing-name">Free</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€0</span>
              <span class="pa-lp-pricing-period">voor altijd</span>
            </div>
            <ul class="pa-lp-pricing-features">
              <li><span class="pa-lp-check">✓</span> 1 website</li>
              <li><span class="pa-lp-check">✓</span> 10.000 paginaweergaven/maand</li>
              <li><span class="pa-lp-check">✓</span> Cookieloos</li>
              <li><span class="pa-lp-check">✓</span> GDPR-compliant</li>
            </ul>
            <a href="/login" class="pa-btn pa-btn--ghost pa-btn--full">Gratis starten</a>
          </div>

          <div class="pa-lp-pricing-card pa-lp-pricing-card--featured">
            <div class="pa-lp-pricing-badge">Meest gekozen</div>
            <div class="pa-lp-pricing-name">Pro</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€12</span>
              <span class="pa-lp-pricing-period">/maand</span>
            </div>
            <ul class="pa-lp-pricing-features">
              <li><span class="pa-lp-check">✓</span> 5 websites</li>
              <li><span class="pa-lp-check">✓</span> 100.000 paginaweergaven/maand</li>
              <li><span class="pa-lp-check">✓</span> A/B testing</li>
              <li><span class="pa-lp-check">✓</span> Heatmaps</li>
              <li><span class="pa-lp-check">✓</span> Realtime dashboard</li>
            </ul>
            <a href="/login" class="pa-btn pa-btn--primary pa-btn--full">Probeer gratis →</a>
          </div>

          <div class="pa-lp-pricing-card">
            <div class="pa-lp-pricing-name">Agency</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€39</span>
              <span class="pa-lp-pricing-period">/maand</span>
            </div>
            <ul class="pa-lp-pricing-features">
              <li><span class="pa-lp-check">✓</span> Onbeperkte websites</li>
              <li><span class="pa-lp-check">✓</span> Onbeperkte paginaweergaven</li>
              <li><span class="pa-lp-check">✓</span> Alles uit Pro</li>
              <li><span class="pa-lp-check">✓</span> Prioriteit support</li>
            </ul>
            <a href="/login" class="pa-btn pa-btn--ghost pa-btn--full">Contact opnemen</a>
          </div>
        </div>
      </section>

      <%!-- FOOTER CTA --%>
      <section class="pa-lp-section pa-lp-footer-cta">
        <h2 class="pa-lp-footer-cta-title">Klaar om te starten?</h2>
        <p class="pa-lp-footer-cta-sub">
          Voeg één script toe en je hebt direct inzicht. Geen cookies, geen gedoe.
        </p>
        <a href="/login" class="pa-btn pa-btn--primary pa-btn--lg">Maak gratis account →</a>
      </section>
    </div>
    """
  end
end
