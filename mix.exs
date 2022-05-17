defmodule VerneMQTimePlugin.MixProject do
  use Mix.Project

  def project do
    [
      app: :vernemq_time_plugin,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:logger],
      env: [
        vmq_plugin_hooks: [
          {:on_publish, VerneMQTimePlugin, :on_publish, 6, []},
          {:on_publish_m5, VerneMQTimePlugin, :on_publish_m5, 7, []},
          {:on_subscribe, VerneMQTimePlugin, :on_subscribe, 3, []},
          {:on_subscribe_m5, VerneMQTimePlugin, :on_subscribe_m5, 4, []}
        ]
      ]
    ]
  end
end
