defmodule MockMe.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias MockMe.Config

  def start(_type, _args) do
    children = [
      {MockMe.State, [%{}]},
      {Plug.Cowboy, scheme: :http, plug: MockMe.Server, options: [port: Config.server(:port)]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MockMe.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_phase(:populate_state_from_config, _, _) do
    MockMe.reset_test_cases()
  end
end
