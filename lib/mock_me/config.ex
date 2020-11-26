defmodule MockMe.Config do
  @moduledoc """
  Maps and validates the config from the parent application.



  ## Example

   _config/test.exs_
    ```
    # optional - defaults to this
    config :mock_me, :server,
      # whatever port you want the mock server to listen on
      port: 9081,
      # A list of accepted HTTP content-types
      accepts_content_types: ["application/json"]

    # required
    config :mock_me, :routes,
      test_cases: [
        %{
          # required
          name: :auth_jwt,
          # required
          path: "/jwt",
          # optional below here, these are the defaults except for responses which will default to an empty array
          # :get, :post, :put, :patch, :delete and :options or a list [:get, :post]
          method: :get,
          # Any valid http content-type, this is the response type from the mock server
          content_type: "application/json",
          responses: [
            # recommended to create a test module which holds your response bodies
            %{flag: :success, body: "some-body", status_code: 200},
            %{flag: :not_found, body: "not-found", status_code: 404}
          ]
        }
      ]
    ```
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
