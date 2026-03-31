defmodule PhoenixAnalytics.Experiments.Stats do
  @moduledoc """
  Conversieratio berekening per variant.
  Chi-square significantie test (twee varianten).
  """

  import Ecto.Query
  alias PhoenixAnalytics.Repo

  def variant_stats(experiment) do
    variants = experiment.variants

    Enum.map(variants, fn variant ->
      visitors =
        Repo.one(
          from a in "assignments",
            where: a.experiment_id == ^experiment.id and a.variant_id == ^variant.id,
            select: count(a.id)
        ) || 0

      conversions =
        Repo.one(
          from e in "events",
            where:
              e.experiment_id == ^experiment.id and
                e.variant_name == ^variant.name and
                e.event_name == ^experiment.goal_event,
            select: count(e.id, :distinct),
            group_by: e.session_hash
        ) || 0

      rate = if visitors > 0, do: Float.round(conversions / visitors * 100, 2), else: 0.0

      %{
        variant: variant,
        visitors: visitors,
        conversions: conversions,
        rate: rate
      }
    end)
  end

  # Chi-square significantie test voor twee varianten
  # Geeft :significant, :not_significant, of :insufficient_data terug
  def significance([a, b]) do
    total_visitors = a.visitors + b.visitors
    total_conversions = a.conversions + b.conversions

    if total_visitors < 200 or total_conversions < 20 do
      :insufficient_data
    else
      expected_a = total_conversions * (a.visitors / total_visitors)
      expected_b = total_conversions * (b.visitors / total_visitors)

      chi_sq =
        :math.pow(a.conversions - expected_a, 2) / max(expected_a, 0.001) +
          :math.pow(b.conversions - expected_b, 2) / max(expected_b, 0.001)

      # Chi-square kritieke waarde bij p=0.05, df=1 = 3.841
      if chi_sq >= 3.841, do: :significant, else: :not_significant
    end
  end

  def significance(_), do: :insufficient_data
end
