defmodule TimeServer do
  @moduledoc """
  Simple GenServer for broadcasting time to MQTT topic
  """

  use GenServer

  @process_name :time_server_plugin
  @interval 1_000

  @spec start :: any()
  def start() do
    if is_nil(GenServer.whereis(@process_name)) do
      GenServer.start(__MODULE__, [], [name: @process_name])
    end
  end

  @spec publish_time(list()) :: any
  def publish_time(topic) when is_list(topic) do
    {_reg_fn, publish_fn, _sub_fn} = :vmq_reg.direct_plugin_exports(__MODULE__)
    current_time = System.system_time(:millisecond) |> Integer.to_string()
    publish_fn.(topic, current_time, %{qos: 0, retain: false})

    :ok
  end

  def publish_time(_), do: nil

  @impl true
  @spec init(any) :: {:ok, []}
  def init(_) do
    Process.send_after(@process_name, :publish_time, @interval)

    {:ok, []}
  end

  @impl true
  def handle_info(:publish_time, state) do
    Process.send_after(@process_name, :publish_time, @interval)
    publish_time()

    {:noreply, state}
  end

  defp publish_time() do
    publish_time(["time"])
  end

end
