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
      <nav class="pa-lp-nav" aria-label="Hoofdnavigatie">
        <span class="pa-lp-nav-brand">Neo Analytics</span>
        <div class="pa-lp-nav-links">
          <a href="/login" class="pa-btn pa-btn--ghost pa-btn--sm">Inloggen</a>
          <a href="/login" class="pa-btn pa-btn--primary pa-btn--sm">Gratis starten →</a>
        </div>
      </nav>

      <%!-- HERO --%>
      <section class="pa-lp-section pa-lp-hero" aria-label="Hero">
        <div class="pa-lp-hero-badge">Privacy-first · Cookieloos · GDPR-compliant</div>

        <h1 class="pa-lp-hero-title">
          The Simulation of Data, <span class="pa-lp-accent-green">Decoded.</span>
        </h1>

        <p class="pa-lp-hero-sub">
          Powered by AI. Driven by Data. Optimized for a 4&times;100 Lighthouse score.
          Built to be loved by Google and your customers.
        </p>

        <%!-- Lighthouse Gauge — inline SVG, geen externe afbeelding, LCP-veilig --%>
        <div class="pa-lp-gauge-wrap" role="img" aria-label="Lighthouse score 100 van 100">
          <svg class="pa-lp-gauge" width="160" height="160" viewBox="0 0 160 160" aria-hidden="true">
            <circle class="pa-lp-gauge-track" cx="80" cy="80" r="66" />
            <circle class="pa-lp-gauge-fill" cx="80" cy="80" r="66" />
          </svg>
          <div class="pa-lp-gauge-label">
            <span class="pa-lp-gauge-value">100</span>
            <span class="pa-lp-gauge-unit">/ 100</span>
          </div>
        </div>

        <div class="pa-lp-hero-ctas">
          <a
            href="/auth/demo"
            class="pa-btn pa-btn--matrix pa-btn--lg"
            aria-label="Open live demo van Neo Analytics"
          >
            [ ENTER THE MATRIX (LIVE DEMO) ]
          </a>
          <a href="/login" class="pa-btn pa-btn--ghost pa-btn--lg">[ Start Free ]</a>
        </div>
      </section>

      <%!-- AGENCY PITCH --%>
      <section class="pa-lp-section pa-lp-agency" aria-label="Agency waardepropositie">
        <div class="pa-lp-agency-inner">
          <div class="pa-lp-agency-copy">
            <h2 class="pa-lp-agency-title">
              Stop Juggling Slow <span class="pa-lp-accent-green">GA4</span> Accounts.
            </h2>
            <p class="pa-lp-agency-body">
              Neo Analytics is the white-label engine that gives you a unified hub for all your
              domains. Boost your clients' SEO by simply installing the fastest script on the
              market.
            </p>
          </div>
          <div class="pa-lp-agency-stats">
            <div class="pa-lp-stat-block" aria-label="Tracker size kleiner dan 1 kilobyte">
              <span class="pa-lp-stat-value">&lt;&nbsp;1KB</span>
              <span class="pa-lp-stat-label">Tracker size</span>
            </div>
            <div class="pa-lp-stat-block" aria-label="Lighthouse 4 keer 100 score">
              <span class="pa-lp-stat-value">4&times;100</span>
              <span class="pa-lp-stat-label">Lighthouse score</span>
            </div>
          </div>
        </div>
      </section>

      <%!-- FEATURE CARDS --%>
      <section class="pa-lp-section pa-lp-features" aria-label="Kernfeatures">
        <h2 class="pa-lp-section-title">Everything You Need. Nothing You Don't.</h2>
        <p class="pa-lp-section-sub">
          Built for agencies and developers who refuse to compromise on speed or privacy.
        </p>
        <div class="pa-lp-features-grid" role="list">
          <%!-- Card 1: Massive Control --%>
          <article class="pa-lp-feature-card" role="listitem">
            <div class="pa-lp-feature-icon">
              <svg
                width="32"
                height="32"
                viewBox="0 0 32 32"
                fill="none"
                aria-hidden="true"
                focusable="false"
              >
                <rect
                  x="2"
                  y="4"
                  width="28"
                  height="20"
                  rx="3"
                  stroke="currentColor"
                  stroke-width="1.5"
                  fill="none"
                />
                <path
                  d="M7 10l4 4-4 4M13 18h6"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <line
                  x1="8"
                  y1="28"
                  x2="24"
                  y2="28"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                />
              </svg>
            </div>
            <h3>Massive Control</h3>
            <p>
              Manage 5 to 500+ sites from one low-latency terminal. Filter the noise, see the
              truth instantly.
            </p>
          </article>

          <%!-- Card 2: White-Label Agency Power --%>
          <article class="pa-lp-feature-card" role="listitem">
            <div class="pa-lp-feature-icon">
              <svg
                width="32"
                height="32"
                viewBox="0 0 32 32"
                fill="none"
                aria-hidden="true"
                focusable="false"
              >
                <path
                  d="M16 3L4 8v8c0 7 5.5 11.5 12 13 6.5-1.5 12-6 12-13V8L16 3z"
                  stroke="currentColor"
                  stroke-width="1.5"
                  fill="none"
                  stroke-linejoin="round"
                />
                <path
                  d="M11 16l3 3 7-7"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
            </div>
            <h3>White-Label Agency Power</h3>
            <p>
              Your brand, our 4&times;100 tech. Provide elite analytics as a premium service to
              your clients.
            </p>
          </article>

          <%!-- Card 3: Privacy-First Architecture --%>
          <article class="pa-lp-feature-card" role="listitem">
            <div class="pa-lp-feature-icon">
              <svg
                width="32"
                height="32"
                viewBox="0 0 32 32"
                fill="none"
                aria-hidden="true"
                focusable="false"
              >
                <rect
                  x="8"
                  y="14"
                  width="16"
                  height="14"
                  rx="2"
                  stroke="currentColor"
                  stroke-width="1.5"
                  fill="none"
                />
                <path
                  d="M11 14V10a5 5 0 0110 0v4"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                />
                <circle cx="16" cy="21" r="1.5" fill="currentColor" />
                <line
                  x1="5"
                  y1="5"
                  x2="27"
                  y2="27"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  opacity="0.5"
                />
              </svg>
            </div>
            <h3>Privacy-First Architecture</h3>
            <p>No cookies, no tracking headaches. 100% compliant, 100% accurate, 0% lag.</p>
          </article>
        </div>
      </section>

      <%!-- PRICING --%>
      <section class="pa-lp-section pa-lp-pricing" aria-label="Prijzen">
        <h2 class="pa-lp-section-title">Choose Your Level in the Simulation.</h2>
        <p class="pa-lp-section-sub">
          Transparent pricing. No hidden costs. Cancel anytime.
        </p>

        <div class="pa-lp-pricing-grid" role="list">
          <%!-- Tier 1: The Initiate --%>
          <div class="pa-lp-pricing-card" role="listitem">
            <div class="pa-lp-pricing-name">The Initiate</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€99</span>
              <span class="pa-lp-pricing-period">/mo</span>
            </div>
            <p class="pa-lp-pricing-tagline">Tot 5 websites. Start the journey.</p>
            <ul class="pa-lp-pricing-features">
              <li>
                <span class="pa-lp-check" aria-hidden="true">✓</span> All core statistics
              </li>
              <li><span class="pa-lp-check" aria-hidden="true">✓</span> Heatmaps</li>
              <li><span class="pa-lp-check" aria-hidden="true">✓</span> A/B testing</li>
              <li>
                <span class="pa-lp-check" aria-hidden="true">✓</span> Lighthouse 4&times;100 tracker
              </li>
            </ul>
            <a
              href="/login"
              class="pa-btn pa-btn--ghost pa-btn--full"
              aria-label="Start Journey - The Initiate tier"
            >
              Start Journey
            </a>
          </div>

          <%!-- Tier 2: The Operator (featured) --%>
          <div class="pa-lp-pricing-card pa-lp-pricing-card--featured" role="listitem">
            <div class="pa-lp-pricing-badge">MOST POPULAR</div>
            <div class="pa-lp-pricing-name">The Operator</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€249</span>
              <span class="pa-lp-pricing-period">/mo</span>
            </div>
            <p class="pa-lp-pricing-tagline">Tot 25 websites. White-label geactiveerd.</p>
            <ul class="pa-lp-pricing-features">
              <li>
                <span class="pa-lp-check" aria-hidden="true">✓</span> Everything in Initiate
              </li>
              <li>
                <span class="pa-lp-check" aria-hidden="true">✓</span> White-label dashboard
              </li>
              <li><span class="pa-lp-check" aria-hidden="true">✓</span> Team accounts</li>
              <li><span class="pa-lp-check" aria-hidden="true">✓</span> Priority support</li>
            </ul>
            <a
              href="/login"
              class="pa-btn pa-btn--primary pa-btn--full"
              aria-label="Activate Operator - The Operator tier"
            >
              Activate Operator
            </a>
          </div>

          <%!-- Tier 3: The Architect --%>
          <div class="pa-lp-pricing-card" role="listitem">
            <div class="pa-lp-pricing-name">The Architect</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€499</span>
              <span class="pa-lp-pricing-period">/mo</span>
            </div>
            <p class="pa-lp-pricing-tagline">Tot 100 websites. Master the simulation.</p>
            <ul class="pa-lp-pricing-features">
              <li>
                <span class="pa-lp-check" aria-hidden="true">✓</span> Everything in Operator
              </li>
              <li><span class="pa-lp-check" aria-hidden="true">✓</span> Custom domain</li>
              <li><span class="pa-lp-check" aria-hidden="true">✓</span> SLA guarantee</li>
              <li>
                <span class="pa-lp-check" aria-hidden="true">✓</span> Dedicated onboarding
              </li>
            </ul>
            <a
              href="/login"
              class="pa-btn pa-btn--ghost pa-btn--full"
              aria-label="Become The Architect - The Architect tier"
            >
              Become The Architect
            </a>
          </div>
        </div>

        <p class="pa-lp-pricing-footnote">
          Your power grows with your network. Scale as you go.
        </p>
      </section>

      <%!-- FINAL CTA --%>
      <section class="pa-lp-section pa-lp-final-cta" aria-label="Call to action">
        <p class="pa-lp-final-cta-trigger">
          Because every millisecond is a lost sale. See the 100/100 performance in action.
        </p>
        <a
          href="/auth/demo"
          class="pa-btn pa-btn--matrix pa-btn--matrix-lg"
          aria-label="Open live demo van Neo Analytics"
        >
          [ ENTER THE MATRIX (LIVE DEMO) ]
        </a>
        <div class="pa-lp-final-cta-secondary">
          <a href="/login" class="pa-lp-final-cta-link">Or create a free account →</a>
        </div>
      </section>
    </div>
    """
  end
end
