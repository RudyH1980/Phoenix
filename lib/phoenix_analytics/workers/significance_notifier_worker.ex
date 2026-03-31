defmodule PhoenixAnalytics.Workers.SignificanceNotifierWorker do
  @moduledoc """
  Elk uur: controleer alle lopende experimenten met een webhook_url.
  Stuur een HTTP POST als het resultaat significant is en nog geen notificatie
  is verstuurd in de afgelopen 24 uur (voorkomen van spam).
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query
  alias PhoenixAnalytics.{Experiments, Repo}
  alias PhoenixAnalytics.Experiments.Stats

  @impl Oban.Worker
  def perform(_job) do
    running_with_webhook =
      Repo.all(
        from e in "experiments",
          where: e.status == "running" and not is_nil(e.webhook_url),
          select: e.id
      )

    for experiment_id <- running_with_webhook do
      experiment =
        Ash.get!(Experiments.Experiment, experiment_id, load: [:variants, :assignments])

      check_and_notify(experiment)
    end

    :ok
  end

  defp check_and_notify(%{webhook_url: nil}), do: :skip
  defp check_and_notify(%{webhook_url: ""}), do: :skip

  defp check_and_notify(experiment) do
    if already_notified_today?(experiment), do: :skip, else: do_check(experiment)
  end

  defp already_notified_today?(%{webhook_notified_at: nil}), do: false

  defp already_notified_today?(%{webhook_notified_at: notified_at}) do
    cutoff = DateTime.add(DateTime.utc_now(), -24 * 3600, :second)
    DateTime.compare(notified_at, cutoff) == :gt
  end

  defp do_check(experiment) do
    variant_stats = Stats.variant_stats(experiment)

    if Stats.significance(variant_stats) == :significant do
      send_webhook(experiment, variant_stats)
    end
  end

  defp send_webhook(experiment, variant_stats) do
    winner =
      variant_stats
      |> Enum.max_by(& &1.rate)
      |> Map.get(:variant)
      |> Map.get(:name)

    payload = %{
      event: "ab_test_significant",
      experiment_id: experiment.id,
      experiment_name: experiment.name,
      winner: winner,
      variants:
        Enum.map(variant_stats, fn s ->
          %{name: s.variant.name, visitors: s.visitors, conversions: s.conversions, rate: s.rate}
        end),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case Req.post(experiment.webhook_url,
           json: payload,
           receive_timeout: 5_000,
           headers: [{"content-type", "application/json"}]
         ) do
      {:ok, %{status: status}} when status in 200..299 ->
        experiment
        |> Ash.Changeset.for_update(:mark_webhook_notified, %{})
        |> Ash.update()

      {:ok, %{status: status}} ->
        {:error, "Webhook gaf HTTP #{status} terug voor experiment #{experiment.id}"}

      {:error, reason} ->
        {:error, "Webhook mislukt voor experiment #{experiment.id}: #{inspect(reason)}"}
    end
  end
end
