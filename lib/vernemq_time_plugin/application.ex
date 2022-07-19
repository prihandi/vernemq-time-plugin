defmodule VerneMQTimePlugin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: VerneMQTimePlugin.ClusterSupervisor]]}
    ]

    opts = [strategy: :one_for_one, name: GlobalBackgroundJob.Supervisor]
    res = Supervisor.start_link(children, opts)

    VerneMQTimePlugin.TimeServer.start()
    res
  end

  defp topologies do
    [
      background_job: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end
