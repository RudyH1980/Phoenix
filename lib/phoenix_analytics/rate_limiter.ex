defmodule PhoenixAnalytics.RateLimiter do
  @moduledoc """
  Rate limiting via Hammer (ETS-backed).
  Limieten:
  - /api/collect: 60 requests/minuut per IP
  - Inloggen: 5 pogingen/15 minuten per IP
  """
  use Hammer, backend: :ets
end
