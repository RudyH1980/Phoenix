defmodule PhoenixAnalytics.PasskeyChallengeStore do
  @moduledoc false
  use GenServer

  @table :passkey_challenges
  @ttl_ms 5 * 60 * 1_000

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    :ets.new(@table, [:named_table, :public, :set])
    schedule_cleanup()
    {:ok, %{}}
  end

  def put(key, value) do
    expires = System.monotonic_time(:millisecond) + @ttl_ms
    :ets.insert(@table, {key, value, expires})
    :ok
  end

  def get(key) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@table, key) do
      [{^key, value, expires}] when expires > now -> {:ok, value}
      _ -> {:error, :not_found}
    end
  end

  def delete(key), do: :ets.delete(@table, key)

  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)
    :ets.select_delete(@table, [{{:_, :_, :"$1"}, [{:<, :"$1", now}], [true]}])
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup, do: Process.send_after(self(), :cleanup, 60_000)
end
