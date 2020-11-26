defmodule MockMe.MixProject do
  use Mix.Project

  def project do
    [
      app: :mock_me,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      start_phases: [{:populate_state_from_config, []}],
      mod: {MockMe.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0.0", [only: [:dev, :test], runtime: false]},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.7", [only: [:dev, :test], runtime: false]},
      {:plug, "~> 1.11"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
