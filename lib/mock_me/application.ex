defmodule MockMe.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {MockMe.State, [%{}]},
      {DynamicSupervisor, strategy: :one_for_one, name: MockMe.DynamicSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MockMe.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
