defmodule PhoenixAnalyticsWeb.Live.Marketing.I18n do
  @moduledoc "Vertalingen voor de landingspagina. Standaardtaal: Nederlands."

  @langs ~w(nl en fr de es pt)a

  def langs, do: @langs

  def lang_label(:nl), do: "NL"
  def lang_label(:en), do: "EN"
  def lang_label(:fr), do: "FR"
  def lang_label(:de), do: "DE"
  def lang_label(:es), do: "ES"
  def lang_label(:pt), do: "PT"

  def valid_lang?(lang) when lang in @langs, do: true
  def valid_lang?(_), do: false

  def to_lang("nl"), do: :nl
  def to_lang("en"), do: :en
  def to_lang("fr"), do: :fr
  def to_lang("de"), do: :de
  def to_lang("es"), do: :es
  def to_lang("pt"), do: :pt
  def to_lang(_), do: :nl

  def t(lang, key), do: Map.get(translations(lang), key) || Map.get(translations(:nl), key) || ""

  defp translations(:nl) do
    %{
      nav_login: "Inloggen",
      nav_signup: "Start Gratis Trial",
      hero_badge: "Privacy-first · Cookieloos · AVG-compliant",
      hero_title: "Alles wat je nodig hebt.",
      hero_title_accent: "Niets wat vertraagt.",
      hero_sub:
        "Volledige, privacy-vriendelijke analytics die je website niet vertraagt. Geen cookies, geen cookiebanner, geen gedoe. Alleen heldere data.",
      hero_demo: "[ LIVE DEMO BEKIJKEN ]",
      hero_signup: "[ Gratis Starten ]",
      features_title: "Alles wat je nodig hebt. Niets wat vertraagt.",
      features_sub:
        "Gebouwd voor agencies en developers die geen compromis willen sluiten op snelheid of privacy.",
      feat1_title: "Volledige Controle",
      feat1_body:
        "Beheer 5 tot 500+ websites vanuit één snel dashboard. Filter de ruis, zie direct de waarheid.",
      feat1_items: [
        "Alle kernstatistieken",
        "Heatmaps",
        "A/B testing",
        "Lighthouse 4×100 tracker"
      ],
      feat2_title: "White Label Bureau Succes",
      feat2_body:
        "Jouw merk, onze 4×100 technologie. Bied premium analytics als dienst aan je klanten.",
      feat2_items: [
        "White-label dashboard",
        "Team accounts",
        "Prioriteitsondersteuning",
        "Aangepast domein"
      ],
      feat3_title: "Privacy-First Architectuur",
      feat3_body:
        "Geen cookies, geen compliance-kopzorgen. 100% AVG-compliant, 100% nauwkeurig, 0% vertraging.",
      feat3_items: [
        "Cookieloos",
        "AVG-compliant",
        "Geen cookiebanner nodig",
        "IP-hashing (geen raw opslag)"
      ],
      pricing_title: "Kies jouw niveau.",
      pricing_sub: "Transparante prijzen. Geen verborgen kosten. Op elk moment opzegbaar.",
      pricing_popular: "MEEST POPULAIR",
      tier1_name: "De Hobbyist",
      tier1_tagline: "Tot 5 websites. Start de reis.",
      tier1_period: "/jr",
      tier1_cta: "Start nu",
      tier1_items: [
        "Alle kernstatistieken",
        "Heatmaps",
        "A/B testing",
        "Lighthouse 4×100 tracker"
      ],
      tier2_name: "The Operator",
      tier2_tagline: "Tot 25 websites. White-label geactiveerd.",
      tier2_period: "/jr",
      tier2_cta: "Activeer Operator",
      tier2_items: [
        "Alles van De Hobbyist",
        "White-label dashboard",
        "Team accounts",
        "Prioriteitsondersteuning"
      ],
      tier3_name: "The Architect",
      tier3_tagline: "Tot 100 websites. Beheers de simulatie.",
      tier3_period: "/jr",
      tier3_cta: "Word The Architect",
      tier3_items: [
        "Alles van The Operator",
        "Aangepast domein",
        "SLA garantie",
        "Dedicated onboarding"
      ],
      pricing_footnote: "Jouw kracht groeit met je netwerk. Schaal naar behoefte.",
      cta_trigger:
        "Want elke milliseconde is een gemiste verkoop. Bekijk de 4×100 prestaties live.",
      cta_demo: "[ MAAK JE GRATIS ACCOUNT & BEHAAL 4×100 ]",
      cta_secondary: "Of maak een gratis account aan →",
      social_proof: "25.000+ websites vertrouwen op Neo Analytics",
      footer_version: "Versie"
    }
  end

  defp translations(:en) do
    %{
      nav_login: "Log in",
      nav_signup: "Start Free Trial",
      hero_badge: "Privacy-first · Cookieless · GDPR-compliant",
      hero_title: "Everything you need.",
      hero_title_accent: "Nothing that slows you down.",
      hero_sub:
        "Full, privacy-friendly analytics that won't slow down your website. No cookies, no banners, no hassle. Just clear data.",
      hero_demo: "[ WATCH LIVE DEMO ]",
      hero_signup: "[ Start Free ]",
      features_title: "Everything you need. Nothing you don't.",
      features_sub:
        "Built for agencies and developers who refuse to compromise on speed or privacy.",
      feat1_title: "Massive Control",
      feat1_body:
        "Manage 5 to 500+ sites from one low-latency dashboard. Filter the noise, see the truth instantly.",
      feat1_items: ["All core statistics", "Heatmaps", "A/B testing", "Lighthouse 4×100 tracker"],
      feat2_title: "White-Label Agency Power",
      feat2_body:
        "Your brand, our 4×100 tech. Provide elite analytics as a premium service to your clients.",
      feat2_items: [
        "White-label dashboard",
        "Team accounts",
        "Priority support",
        "Custom domain"
      ],
      feat3_title: "Privacy-First Architecture",
      feat3_body:
        "No cookies, no tracking headaches. 100% GDPR-compliant, 100% accurate, 0% lag.",
      feat3_items: [
        "Cookieless",
        "GDPR-compliant",
        "No cookie banner needed",
        "IP hashing (no raw storage)"
      ],
      pricing_title: "Choose your level.",
      pricing_sub: "Transparent pricing. No hidden costs. Cancel anytime.",
      pricing_popular: "MOST POPULAR",
      tier1_name: "The Initiate",
      tier1_tagline: "Up to 5 websites. Start the journey.",
      tier1_period: "/yr",
      tier1_cta: "Start Journey",
      tier1_items: [
        "All core statistics",
        "Heatmaps",
        "A/B testing",
        "Lighthouse 4×100 tracker"
      ],
      tier2_name: "The Operator",
      tier2_tagline: "Up to 25 websites. White-label activated.",
      tier2_period: "/yr",
      tier2_cta: "Activate Operator",
      tier2_items: [
        "Everything in Initiate",
        "White-label dashboard",
        "Team accounts",
        "Priority support"
      ],
      tier3_name: "The Architect",
      tier3_tagline: "Up to 100 websites. Master the simulation.",
      tier3_period: "/yr",
      tier3_cta: "Become The Architect",
      tier3_items: [
        "Everything in Operator",
        "Custom domain",
        "SLA guarantee",
        "Dedicated onboarding"
      ],
      pricing_footnote: "Your power grows with your network. Scale as you go.",
      cta_trigger: "Because every millisecond is a lost sale. See the 4×100 performance live.",
      cta_demo: "[ MAKE YOUR FREE ACCOUNT & ACHIEVE 4×100 ]",
      cta_secondary: "Or create a free account →",
      social_proof: "25,000+ websites trust Neo Analytics",
      footer_version: "Version"
    }
  end

  defp translations(:fr) do
    %{
      nav_login: "Se connecter",
      nav_signup: "Essai gratuit",
      hero_badge: "Privacy-first · Sans cookie · Conforme RGPD",
      hero_title: "Tout ce dont vous avez besoin.",
      hero_title_accent: "Rien qui vous ralentit.",
      hero_sub:
        "Analytics complet et respectueux de la vie privée, sans ralentir votre site. Sans cookies, sans bannière, sans tracas.",
      hero_demo: "[ VOIR LA DÉMO EN DIRECT ]",
      hero_signup: "[ Commencer gratuitement ]",
      features_title: "Tout ce dont vous avez besoin. Rien de superflu.",
      features_sub:
        "Conçu pour les agences et les développeurs qui refusent de compromettre vitesse et confidentialité.",
      feat1_title: "Contrôle total",
      feat1_body:
        "Gérez 5 à 500+ sites depuis un tableau de bord rapide. Filtrez le bruit, voyez la vérité instantanément.",
      feat1_items: [
        "Toutes les statistiques clés",
        "Heatmaps",
        "Tests A/B",
        "Tracker Lighthouse 4×100"
      ],
      feat2_title: "Puissance White-Label",
      feat2_body:
        "Votre marque, notre technologie 4×100. Proposez des analytics premium à vos clients.",
      feat2_items: [
        "Tableau de bord white-label",
        "Comptes d'équipe",
        "Support prioritaire",
        "Domaine personnalisé"
      ],
      feat3_title: "Architecture Privacy-First",
      feat3_body:
        "Sans cookies, sans casse-tête RGPD. 100% conforme, 100% précis, 0% de latence.",
      feat3_items: [
        "Sans cookie",
        "Conforme RGPD",
        "Pas de bannière cookie",
        "Hachage IP (pas de stockage brut)"
      ],
      pricing_title: "Choisissez votre niveau.",
      pricing_sub: "Tarifs transparents. Sans frais cachés. Résiliable à tout moment.",
      pricing_popular: "LE PLUS POPULAIRE",
      tier1_name: "L'Initié",
      tier1_tagline: "Jusqu'à 5 sites. Commencez le voyage.",
      tier1_period: "/an",
      tier1_cta: "Commencer",
      tier1_items: [
        "Toutes les statistiques clés",
        "Heatmaps",
        "Tests A/B",
        "Tracker Lighthouse 4×100"
      ],
      tier2_name: "The Operator",
      tier2_tagline: "Jusqu'à 25 sites. White-label activé.",
      tier2_period: "/an",
      tier2_cta: "Activer Operator",
      tier2_items: [
        "Tout de L'Initié",
        "Tableau de bord white-label",
        "Comptes d'équipe",
        "Support prioritaire"
      ],
      tier3_name: "The Architect",
      tier3_tagline: "Jusqu'à 100 sites. Maîtrisez la simulation.",
      tier3_period: "/an",
      tier3_cta: "Devenir The Architect",
      tier3_items: [
        "Tout de The Operator",
        "Domaine personnalisé",
        "Garantie SLA",
        "Onboarding dédié"
      ],
      pricing_footnote: "Votre puissance grandit avec votre réseau. Évoluez à votre rythme.",
      cta_trigger:
        "Car chaque milliseconde est une vente perdue. Voyez la performance 4×100 en action.",
      cta_demo: "[ CRÉEZ VOTRE COMPTE GRATUIT & ATTEIGNEZ 4×100 ]",
      cta_secondary: "Ou créez un compte gratuit →",
      social_proof: "25 000+ sites font confiance à Neo Analytics",
      footer_version: "Version"
    }
  end

  defp translations(:de) do
    %{
      nav_login: "Anmelden",
      nav_signup: "Kostenlos starten",
      hero_badge: "Privacy-first · Cookielos · DSGVO-konform",
      hero_title: "Alles, was Sie brauchen.",
      hero_title_accent: "Nichts, das verlangsamt.",
      hero_sub:
        "Vollständige, datenschutzfreundliche Analyse ohne Verlangsamung Ihrer Website. Keine Cookies, kein Banner, kein Aufwand.",
      hero_demo: "[ LIVE-DEMO ANSEHEN ]",
      hero_signup: "[ Kostenlos starten ]",
      features_title: "Alles, was Sie brauchen. Nichts, was Sie nicht brauchen.",
      features_sub:
        "Entwickelt für Agenturen und Entwickler, die keine Kompromisse bei Geschwindigkeit oder Datenschutz eingehen.",
      feat1_title: "Volle Kontrolle",
      feat1_body:
        "Verwalten Sie 5 bis 500+ Websites in einem schnellen Dashboard. Rauschen filtern, Wahrheit sofort sehen.",
      feat1_items: [
        "Alle Kernstatistiken",
        "Heatmaps",
        "A/B-Tests",
        "Lighthouse 4×100 Tracker"
      ],
      feat2_title: "White-Label Agentur-Power",
      feat2_body:
        "Ihre Marke, unsere 4×100 Technologie. Bieten Sie Premium-Analytics als Dienst an.",
      feat2_items: [
        "White-Label Dashboard",
        "Team-Accounts",
        "Prioritäts-Support",
        "Eigene Domain"
      ],
      feat3_title: "Privacy-First Architektur",
      feat3_body:
        "Keine Cookies, kein DSGVO-Kopfzerbrechen. 100% konform, 100% genau, 0% Verzögerung.",
      feat3_items: [
        "Cookielos",
        "DSGVO-konform",
        "Kein Cookie-Banner nötig",
        "IP-Hashing (kein Rohspeicher)"
      ],
      pricing_title: "Wählen Sie Ihr Niveau.",
      pricing_sub: "Transparente Preise. Keine versteckten Kosten. Jederzeit kündbar.",
      pricing_popular: "AM BELIEBTESTEN",
      tier1_name: "Der Einsteiger",
      tier1_tagline: "Bis zu 5 Websites. Starten Sie die Reise.",
      tier1_period: "/Jahr",
      tier1_cta: "Jetzt starten",
      tier1_items: [
        "Alle Kernstatistiken",
        "Heatmaps",
        "A/B-Tests",
        "Lighthouse 4×100 Tracker"
      ],
      tier2_name: "The Operator",
      tier2_tagline: "Bis zu 25 Websites. White-Label aktiviert.",
      tier2_period: "/Jahr",
      tier2_cta: "Operator aktivieren",
      tier2_items: [
        "Alles vom Einsteiger",
        "White-Label Dashboard",
        "Team-Accounts",
        "Prioritäts-Support"
      ],
      tier3_name: "The Architect",
      tier3_tagline: "Bis zu 100 Websites. Beherrschen Sie die Simulation.",
      tier3_period: "/Jahr",
      tier3_cta: "The Architect werden",
      tier3_items: [
        "Alles von The Operator",
        "Eigene Domain",
        "SLA-Garantie",
        "Dediziertes Onboarding"
      ],
      pricing_footnote: "Ihre Stärke wächst mit Ihrem Netzwerk. Skalieren Sie nach Bedarf.",
      cta_trigger:
        "Denn jede Millisekunde ist ein verlorener Verkauf. Sehen Sie die 4×100 Leistung live.",
      cta_demo: "[ KOSTENLOSES KONTO ERSTELLEN & 4×100 ERREICHEN ]",
      cta_secondary: "Oder erstellen Sie ein kostenloses Konto →",
      social_proof: "25.000+ Websites vertrauen Neo Analytics",
      footer_version: "Version"
    }
  end

  defp translations(:es) do
    %{
      nav_login: "Iniciar sesión",
      nav_signup: "Prueba gratuita",
      hero_badge: "Privacy-first · Sin cookies · Conforme RGPD",
      hero_title: "Todo lo que necesitas.",
      hero_title_accent: "Nada que te frene.",
      hero_sub:
        "Analytics completo y respetuoso con la privacidad sin ralentizar tu web. Sin cookies, sin banners, sin complicaciones.",
      hero_demo: "[ VER DEMO EN VIVO ]",
      hero_signup: "[ Empezar gratis ]",
      features_title: "Todo lo que necesitas. Nada que no necesites.",
      features_sub:
        "Diseñado para agencias y desarrolladores que no quieren comprometer velocidad ni privacidad.",
      feat1_title: "Control total",
      feat1_body:
        "Gestiona de 5 a 500+ sitios desde un panel de control rápido. Filtra el ruido, ve la verdad al instante.",
      feat1_items: [
        "Todas las estadísticas clave",
        "Mapas de calor",
        "Pruebas A/B",
        "Tracker Lighthouse 4×100"
      ],
      feat2_title: "Potencia White-Label",
      feat2_body:
        "Tu marca, nuestra tecnología 4×100. Ofrece analytics premium como servicio a tus clientes.",
      feat2_items: [
        "Panel white-label",
        "Cuentas de equipo",
        "Soporte prioritario",
        "Dominio personalizado"
      ],
      feat3_title: "Arquitectura Privacy-First",
      feat3_body:
        "Sin cookies, sin dolores de cabeza de privacidad. 100% conforme, 100% preciso, 0% latencia.",
      feat3_items: [
        "Sin cookies",
        "Conforme RGPD",
        "Sin banner de cookies",
        "Hash de IP (sin almacenamiento en bruto)"
      ],
      pricing_title: "Elige tu nivel.",
      pricing_sub: "Precios transparentes. Sin costes ocultos. Cancela cuando quieras.",
      pricing_popular: "MAS POPULAR",
      tier1_name: "El Iniciado",
      tier1_tagline: "Hasta 5 sitios. Empieza el viaje.",
      tier1_period: "/año",
      tier1_cta: "Empezar",
      tier1_items: [
        "Todas las estadísticas clave",
        "Mapas de calor",
        "Pruebas A/B",
        "Tracker Lighthouse 4×100"
      ],
      tier2_name: "The Operator",
      tier2_tagline: "Hasta 25 sitios. White-label activado.",
      tier2_period: "/año",
      tier2_cta: "Activar Operator",
      tier2_items: [
        "Todo de El Iniciado",
        "Panel white-label",
        "Cuentas de equipo",
        "Soporte prioritario"
      ],
      tier3_name: "The Architect",
      tier3_tagline: "Hasta 100 sitios. Domina la simulación.",
      tier3_period: "/año",
      tier3_cta: "Ser The Architect",
      tier3_items: [
        "Todo de The Operator",
        "Dominio personalizado",
        "Garantía SLA",
        "Onboarding dedicado"
      ],
      pricing_footnote: "Tu poder crece con tu red. Escala a tu ritmo.",
      cta_trigger:
        "Porque cada milisegundo es una venta perdida. Mira el rendimiento 4×100 en acción.",
      cta_demo: "[ CREA TU CUENTA GRATUITA Y LOGRA 4×100 ]",
      cta_secondary: "O crea una cuenta gratuita →",
      social_proof: "Más de 25.000 sitios confían en Neo Analytics",
      footer_version: "Versión"
    }
  end

  defp translations(:pt) do
    %{
      nav_login: "Entrar",
      nav_signup: "Teste gratuito",
      hero_badge: "Privacy-first · Sem cookies · Conforme RGPD",
      hero_title: "Tudo o que você precisa.",
      hero_title_accent: "Nada que te atrapalhe.",
      hero_sub:
        "Analytics completo e respeitoso à privacidade sem deixar seu site lento. Sem cookies, sem banners, sem complicações.",
      hero_demo: "[ VER DEMO AO VIVO ]",
      hero_signup: "[ Começar grátis ]",
      features_title: "Tudo o que você precisa. Nada que não precise.",
      features_sub:
        "Criado para agências e desenvolvedores que não abrem mão de velocidade nem privacidade.",
      feat1_title: "Controle total",
      feat1_body:
        "Gerencie de 5 a 500+ sites em um painel rápido. Filtre o ruído, veja a verdade instantaneamente.",
      feat1_items: [
        "Todas as estatísticas principais",
        "Mapas de calor",
        "Testes A/B",
        "Tracker Lighthouse 4×100"
      ],
      feat2_title: "Poder White-Label",
      feat2_body:
        "Sua marca, nossa tecnologia 4×100. Ofereça analytics premium como serviço aos seus clientes.",
      feat2_items: [
        "Painel white-label",
        "Contas de equipe",
        "Suporte prioritário",
        "Domínio personalizado"
      ],
      feat3_title: "Arquitetura Privacy-First",
      feat3_body:
        "Sem cookies, sem dores de cabeça de privacidade. 100% conforme, 100% preciso, 0% latência.",
      feat3_items: [
        "Sem cookies",
        "Conforme LGPD/RGPD",
        "Sem banner de cookies",
        "Hash de IP (sem armazenamento bruto)"
      ],
      pricing_title: "Escolha seu nível.",
      pricing_sub: "Preços transparentes. Sem custos ocultos. Cancele quando quiser.",
      pricing_popular: "MAIS POPULAR",
      tier1_name: "O Iniciante",
      tier1_tagline: "Até 5 sites. Comece a jornada.",
      tier1_period: "/ano",
      tier1_cta: "Começar",
      tier1_items: [
        "Todas as estatísticas principais",
        "Mapas de calor",
        "Testes A/B",
        "Tracker Lighthouse 4×100"
      ],
      tier2_name: "The Operator",
      tier2_tagline: "Até 25 sites. White-label ativado.",
      tier2_period: "/ano",
      tier2_cta: "Ativar Operator",
      tier2_items: [
        "Tudo de O Iniciante",
        "Painel white-label",
        "Contas de equipe",
        "Suporte prioritário"
      ],
      tier3_name: "The Architect",
      tier3_tagline: "Até 100 sites. Domine a simulação.",
      tier3_period: "/ano",
      tier3_cta: "Tornar-se The Architect",
      tier3_items: [
        "Tudo de The Operator",
        "Domínio personalizado",
        "Garantia SLA",
        "Onboarding dedicado"
      ],
      pricing_footnote: "Seu poder cresce com sua rede. Escale conforme necessário.",
      cta_trigger:
        "Pois cada milissegundo é uma venda perdida. Veja a performance 4×100 ao vivo.",
      cta_demo: "[ CRIE SUA CONTA GRÁTIS E ALCANCE 4×100 ]",
      cta_secondary: "Ou crie uma conta gratuita →",
      social_proof: "Mais de 25.000 sites confiam no Neo Analytics",
      footer_version: "Versão"
    }
  end
end
