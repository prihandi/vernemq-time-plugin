defmodule VerneMQTimePlugin.TimeServer do
  @moduledoc """
  Simple GenServer for broadcasting time to MQTT topic
  """
  require Logger

  use GenServer

  @process_name {:global, :time_server_plugin}
  @interval 1_000


  @spec start_link(any, keyword()) :: GenServer.on_start()
  def start_link(init_args, opts \\ []) do
    opts = Keyword.merge(opts, [name: @process_name])
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  @spec start() :: GenServer.on_start()
  def start() do
    GenServer.start(__MODULE__, [], name: @process_name)
  end

  @spec publish_time(list()) :: any
  def publish_time(topic) when is_list(topic) do
    try do
      {_reg_fn, publish_fn, _sub_fn} = :vmq_reg.direct_plugin_exports(__MODULE__)
      current_time = System.system_time(:millisecond) |> Integer.to_string()
      publish_fn.(topic, current_time, %{qos: 0, retain: false})
    rescue
      _e ->
        :noop
        # Logger.info("error: #{inspect(e)}")
    end

    :ok
  end

  def publish_time(_), do: nil

  @impl true
  @spec init(any) :: {:ok, []}
  def init(_) do
    Process.send_after(self(), :publish_time, @interval)

    {:ok, []}
  end

  @impl true
  def handle_info(:publish_time, state) do
    Process.send_after(self(), :publish_time, @interval)
    publish_time(["time"])

    {:noreply, state}
  end
end
