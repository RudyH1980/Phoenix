defmodule PhoenixAnalytics.Experiments do
  use Ash.Domain

  resources do
    resource PhoenixAnalytics.Experiments.Experiment
    resource PhoenixAnalytics.Experiments.Variant
    resource PhoenixAnalytics.Experiments.Assignment
  end

  # Deterministisch variant toewijzen zonder cookie
  # Zelfde session_hash + experiment_id geeft altijd dezelfde variant
  def assign_variant(session_hash, experiment_id, variants) do
    bucket = :erlang.phash2({session_hash, experiment_id}, 100)

    Enum.reduce_while(variants, 0, fn variant, acc ->
      new_acc = acc + variant.weight

      if bucket < new_acc do
        {:halt, variant}
      else
        {:cont, new_acc}
      end
    end)
  end
end
