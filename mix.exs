defmodule VerneMQTimePlugin.MixProject do
  use Mix.Project

  def project do
    [
      app: :vernemq_time_plugin,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [

      extra_applications: [:logger],
      mod: {VerneMQTimePlugin.Application, []},
      env: [
        vmq_plugin_hooks: [
          {:on_publish, VerneMQTimePlugin, :on_publish, 6, []},
          {:on_publish_m5, VerneMQTimePlugin, :on_publish_m5, 7, []}
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.3"}
    ]
  end
end
