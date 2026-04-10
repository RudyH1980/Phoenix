defmodule PhoenixAnalyticsWeb.Live.Marketing.LandingLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalyticsWeb.Live.Marketing.I18n

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Neo Analytics — Privacy-First Web Analytics",
       canonical_url: "https://phoenix-analytics.fly.dev/",
       lang: :nl
     )}
  end

  @impl true
  def handle_params(%{"lang" => lang_str}, _uri, socket) do
    lang = I18n.to_lang(lang_str)
    {:noreply, assign(socket, lang: lang)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  defp t(assigns, key), do: I18n.t(assigns.lang, key)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-lp-wrapper">
      <%!-- NAV --%>
      <nav class="pa-lp-nav" aria-label="Hoofdnavigatie">
        <span class="pa-lp-nav-brand">neo analytics</span>
        <div class="pa-lp-nav-links">
          <div class="pa-lp-lang-switcher" role="navigation" aria-label="Taalswitch">
            <%= for lang <- I18n.langs() do %>
              <a
                href={"/?lang=#{lang}"}
                class={"pa-lp-lang-btn#{if @lang == lang, do: " active", else: ""}"}
                aria-current={if @lang == lang, do: "true", else: "false"}
                aria-label={"Schakel over naar #{I18n.lang_label(lang)}"}
              >
                {I18n.lang_label(lang)}
              </a>
            <% end %>
          </div>
          <a href="/login" class="pa-btn pa-btn--ghost pa-btn--sm">{t(assigns, :nav_login)}</a>
          <a href="/login" class="pa-btn pa-btn--primary pa-btn--sm">{t(assigns, :nav_signup)}</a>
        </div>
      </nav>

      <%!-- HERO --%>
      <section class="pa-lp-section pa-lp-hero" aria-label="Hero">
        <div class="pa-lp-hero-badge">{t(assigns, :hero_badge)}</div>

        <h1 class="pa-lp-hero-title">
          {t(assigns, :hero_title)}
          <span class="pa-lp-accent-green">{t(assigns, :hero_title_accent)}</span>
        </h1>

        <p class="pa-lp-hero-sub">{t(assigns, :hero_sub)}</p>

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
            {t(assigns, :hero_demo)}
          </a>
          <a href="/login" class="pa-btn pa-btn--ghost pa-btn--lg">{t(assigns, :hero_signup)}</a>
        </div>

        <%!-- Hero metrics --%>
        <div class="pa-lp-hero-metrics" aria-label="Kerngetallen">
          <div class="pa-lp-hero-metric">
            <span class="pa-lp-hero-metric-value">&lt;&nbsp;1KB</span>
            <span class="pa-lp-hero-metric-label">Tracker size</span>
          </div>
          <div class="pa-lp-hero-metric-sep" aria-hidden="true"></div>
          <div class="pa-lp-hero-metric">
            <span class="pa-lp-hero-metric-value">4&times;100</span>
            <span class="pa-lp-hero-metric-label">Lighthouse</span>
          </div>
          <div class="pa-lp-hero-metric-sep" aria-hidden="true"></div>
          <div class="pa-lp-hero-metric">
            <span class="pa-lp-hero-metric-value">0</span>
            <span class="pa-lp-hero-metric-label">Cookies</span>
          </div>
        </div>
      </section>

      <%!-- FEATURE CARDS --%>
      <section class="pa-lp-section pa-lp-features" aria-label="Kernfeatures">
        <h2 class="pa-lp-section-title">{t(assigns, :features_title)}</h2>
        <p class="pa-lp-section-sub">{t(assigns, :features_sub)}</p>
        <div class="pa-lp-features-grid" role="list">
          <%!-- Card 1: Volledige Controle --%>
          <article class="pa-lp-feature-card" role="listitem">
            <div class="pa-lp-feature-icon" aria-hidden="true">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none" focusable="false">
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
            <h3>{t(assigns, :feat1_title)}</h3>
            <p>{t(assigns, :feat1_body)}</p>
            <ul class="pa-lp-feature-list">
              <%= for item <- t(assigns, :feat1_items) do %>
                <li><span class="pa-lp-check" aria-hidden="true">✓</span> {item}</li>
              <% end %>
            </ul>
          </article>

          <%!-- Card 2: White Label --%>
          <article class="pa-lp-feature-card" role="listitem">
            <div class="pa-lp-feature-icon" aria-hidden="true">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none" focusable="false">
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
            <h3>{t(assigns, :feat2_title)}</h3>
            <p>{t(assigns, :feat2_body)}</p>
            <ul class="pa-lp-feature-list">
              <%= for item <- t(assigns, :feat2_items) do %>
                <li><span class="pa-lp-check" aria-hidden="true">✓</span> {item}</li>
              <% end %>
            </ul>
          </article>

          <%!-- Card 3: Privacy-First --%>
          <article class="pa-lp-feature-card" role="listitem">
            <div class="pa-lp-feature-icon" aria-hidden="true">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none" focusable="false">
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
              </svg>
            </div>
            <h3>{t(assigns, :feat3_title)}</h3>
            <p>{t(assigns, :feat3_body)}</p>
            <ul class="pa-lp-feature-list">
              <%= for item <- t(assigns, :feat3_items) do %>
                <li><span class="pa-lp-check" aria-hidden="true">✓</span> {item}</li>
              <% end %>
            </ul>
          </article>
        </div>
      </section>

      <%!-- PRICING --%>
      <section class="pa-lp-section pa-lp-pricing" aria-label="Prijzen">
        <h2 class="pa-lp-section-title">{t(assigns, :pricing_title)}</h2>
        <p class="pa-lp-section-sub">{t(assigns, :pricing_sub)}</p>

        <div class="pa-lp-pricing-grid" role="list">
          <%!-- Tier 1 --%>
          <div class="pa-lp-pricing-card" role="listitem">
            <div class="pa-lp-pricing-name">{t(assigns, :tier1_name)}</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€99</span>
              <span class="pa-lp-pricing-period">{t(assigns, :tier1_period)}</span>
            </div>
            <p class="pa-lp-pricing-tagline">{t(assigns, :tier1_tagline)}</p>
            <ul class="pa-lp-pricing-features">
              <%= for item <- t(assigns, :tier1_items) do %>
                <li><span class="pa-lp-check" aria-hidden="true">✓</span> {item}</li>
              <% end %>
            </ul>
            <a href="/login" class="pa-btn pa-btn--ghost pa-btn--full">
              {t(assigns, :tier1_cta)}
            </a>
          </div>

          <%!-- Tier 2: featured --%>
          <div class="pa-lp-pricing-card pa-lp-pricing-card--featured" role="listitem">
            <div class="pa-lp-pricing-badge">{t(assigns, :pricing_popular)}</div>
            <div class="pa-lp-pricing-name">{t(assigns, :tier2_name)}</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€249</span>
              <span class="pa-lp-pricing-period">{t(assigns, :tier2_period)}</span>
            </div>
            <p class="pa-lp-pricing-tagline">{t(assigns, :tier2_tagline)}</p>
            <ul class="pa-lp-pricing-features">
              <%= for item <- t(assigns, :tier2_items) do %>
                <li><span class="pa-lp-check" aria-hidden="true">✓</span> {item}</li>
              <% end %>
            </ul>
            <a href="/login" class="pa-btn pa-btn--primary pa-btn--full">
              {t(assigns, :tier2_cta)}
            </a>
          </div>

          <%!-- Tier 3 --%>
          <div class="pa-lp-pricing-card" role="listitem">
            <div class="pa-lp-pricing-name">{t(assigns, :tier3_name)}</div>
            <div class="pa-lp-pricing-price">
              <span class="pa-lp-pricing-amount">€499</span>
              <span class="pa-lp-pricing-period">{t(assigns, :tier3_period)}</span>
            </div>
            <p class="pa-lp-pricing-tagline">{t(assigns, :tier3_tagline)}</p>
            <ul class="pa-lp-pricing-features">
              <%= for item <- t(assigns, :tier3_items) do %>
                <li><span class="pa-lp-check" aria-hidden="true">✓</span> {item}</li>
              <% end %>
            </ul>
            <a href="/login" class="pa-btn pa-btn--ghost pa-btn--full">
              {t(assigns, :tier3_cta)}
            </a>
          </div>
        </div>

        <p class="pa-lp-pricing-footnote">{t(assigns, :pricing_footnote)}</p>
      </section>

      <%!-- FINAL CTA --%>
      <section class="pa-lp-section pa-lp-final-cta" aria-label="Call to action">
        <p class="pa-lp-social-proof">{t(assigns, :social_proof)}</p>
        <p class="pa-lp-final-cta-trigger">{t(assigns, :cta_trigger)}</p>
        <a
          href="/auth/demo"
          class="pa-btn pa-btn--matrix pa-btn--matrix-lg"
          aria-label="Open live demo van Neo Analytics"
        >
          {t(assigns, :cta_demo)}
        </a>
        <div class="pa-lp-final-cta-secondary">
          <a href="/login" class="pa-lp-final-cta-link">{t(assigns, :cta_secondary)}</a>
        </div>
      </section>
    </div>
    """
  end
end
