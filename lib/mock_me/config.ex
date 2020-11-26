defmodule MockMe.Config do
  @moduledoc """
  Maps and validates the config from the parent application.
  """
  alias MockMe.Route
  alias MockMe.Response

  def server(:port) do
    default = 9081
    config = Application.get_env(:mock_me, :server)

    case config do
      nil -> default
      conf -> conf[:port] || default
    end
  end

  def server(:accepts_content_types) do
    default = ["application/json"]
    config = Application.get_env(:mock_me, :server)

    case config do
      nil -> default
      conf -> conf[:accepts_content_types] || default
    end
  end

  def routes do
    routes_conf = Application.get_env(:mock_me, :routes)

    Enum.map(routes_conf[:test_cases], fn route ->
      %Route{
        name: route[:name],
        path: route[:path]
      }
      |> Map.merge(route)
      |> format_responses()
    end)
  end

  def format_responses(route) do
    responses =
      Enum.map(route.responses, fn res ->
        %Response{
          flag: res.flag,
          body: res.body
        }
        |> Map.merge(res)
      end)

    Map.put(route, :responses, responses)
  end
end
