defmodule PhoenixAnalytics.Workers.TokenCleanupWorker do
  @moduledoc """
  Verwijdert verlopen magic link tokens (AVG: 24u TTL).
  Draait dagelijks om 03:00 via Oban Cron.
  """
  use Oban.Worker, queue: :default

  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    cutoff = DateTime.add(DateTime.utc_now(), -24 * 60 * 60, :second)

    {count, _} =
      PhoenixAnalytics.Repo.delete_all(
        from t in "magic_tokens", where: t.inserted_at < ^cutoff
      )

    {:ok, %{deleted: count}}
  end
end
