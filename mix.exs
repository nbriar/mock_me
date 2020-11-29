defmodule MockMe.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :mock_me,
      version: "0.1.2",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "MockMe",
      description: description(),
      package: package(),
      source_url: "https://github.com/nbriar/mock_me"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MockMe.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0.0", [only: [:dev, :test], runtime: false]},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:httpoison, "~> 1.7", [only: [:dev, :test], runtime: false]},
      {:plug, "~> 1.11"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end

  defp description() do
    """
    MockMe is a simple mock server used to mock out your third party services in your tests. Unlike many mocking
    solutions, MockMe starts a real HTTP server and serves real static responses which may be toggled easily using
    the `MockMe.set_response(:test, :result)` function in your tests.
    """
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/nbriar/mock_me",
        "ExampleApp" => "https://github.com/nbriar/mock_me_phoenix_example"
      }
    ]
  end
end
