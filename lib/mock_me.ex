defmodule MockMe do
  @moduledoc """
  MockMe is a simple mock server used to mock out your third party services in your tests. Unlike many mocking
  solutions, MockMe starts a real HTTP server and serves real static responses which may be toggled easily using
  the `MockMe.set_test_case(:test, :result)` function in your tests.

  # Need to give my theory on mocking third party APIs.

  What this package does isn't terribly difficult to set up on your own. In fact it can be accomplished in 2 files
  if you just want to set things up statically. After doing that very thing in several projects, I got tired of copying
  those files and changing the endpoints, so I decided to create this package.

  Largely, this package is config sugar around those 2 files and allows
  the developer to do some very minor setup while defining all mocked routes in the config file in a simple way that is readable
  and understandable.

  Under the hood this package uses [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html) to manage the routes
  and [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html) for the HTTP server.
  The path in the routes can be any valid path accepted by [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html).
  See the [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html) docs or examples for more information.

  The only things you need to do are:
  1. configure your code to point to the mock server url `http://localhost:<port (9081)>`
  1. configure your routes in your `test/test_helper.exs` file
  1. start the `MockMe` server in your `/test/test_help.exs` file
  1. use `MockMe` in your tests

  ## Example Config

   _config/test.exs_
    ```
    config :mock_me, port: 9081
    ```

    This is only used if you want to change the port the mock server listens to. The default port is 9081.

  ## Phoenix Example
    Need an example and link to the github repo

    _config/test.exs_
    ```
    config :mock_me_phoenix_example, swapi_url: "http://localhost:9081/swapi"
    ```

    _test/test_helpers.ex_
    ```
    ExUnit.start()
    MockMe.start()

    routes = [
      %MockMe.Route{
        name: :swapi_people,
        path: "/swapi/people/:id",
        responses: [
          %MockMe.Response{
            flag: :success,
            body: MockMePhoenixExample.Test.Mocks.SWAPI.people(:success)
          },
          %MockMe.Response{flag: :not_found, body: "people-failure", status_code: 404}
        ]
      },
      %MockMe.Route{
        name: :swapi_starships,
        path: "/swapi/starships/:id",
        responses: [
          %MockMe.Response{
            flag: :success,
            body: MockMePhoenixExample.Test.Mocks.SWAPI.starships(:success)
          },
          %MockMe.Response{flag: :not_found, body: "starships-failure", status_code: 404}
        ]
      }
    ]

    MockMe.add_routes(routes)
    MockMe.start_server()
    ```

    _lib/services/star_wars.ex_
    ```
    defmodule MockMePhoenixExample.StarWars do
      use HTTPoison.Base

      def base_url do
        Application.get_env(:mock_me_phoenix_example, :swapi_url)
      end

      def process_url(url) do
        base_url() <> url
      end

      def people(id) do
        case get("/people/id/") do
          {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
            {:ok, Jason.decode!(response_body)}

          {:ok, %HTTPoison.Response{status_code: 404}} ->
            {:not_found, "The person with id was not found"}

          {:ok, %HTTPoison.Response{status_code: status_code}} ->
            {:error, "Failed with status code: status_code"}

          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, "Failed with reason: reason"}
        end
      end
    end
    ```

    _test/support/mocks/swapi.ex_
    ```
    defmodule MockMePhoenixExample.Test.Mocks.SWAPI do
      def people(:success) do
        "{\"name\":\"Luke Skywalker\",\"height\":\"172\",\"mass\":\"77\",\"hair_color\":\"blond\",\"skin_color\":\"fair\",\"eye_color\":\"blue\",\"birth_year\":\"19BBY\",\"gender\":\"male\",\"homeworld\":\"http://swapi.dev/api/planets/1/\",\"films\":[\"http://swapi.dev/api/films/1/\",\"http://swapi.dev/api/films/2/\",\"http://swapi.dev/api/films/3/\",\"http://swapi.dev/api/films/6/\"],\"species\":[],\"vehicles\":[\"http://swapi.dev/api/vehicles/14/\",\"http://swapi.dev/api/vehicles/30/\"],\"starships\":[\"http://swapi.dev/api/starships/12/\",\"http://swapi.dev/api/starships/22/\"],\"created\":\"2014-12-09T13:50:51.644000Z\",\"edited\":\"2014-12-20T21:17:56.891000Z\",\"url\":\"http://swapi.dev/api/people/1/\"}"
      end

      def people(:failure) do
        %{error: "something went wrong"} |> Jason.encode!()
      end
    end
    ```


  ## Mix Application Example
    Need an example and link to the github repo

  ## Mix Package Example
    Need an example and link to the github repo
  """

  alias MockMe.Route
  alias MockMe.State

  @doc """
  Add routes to your server. This goes in your `test/test_helper.exs` file.

  Defined routes using the `MockMe.Route` struct.

  ### Example
  _test/test_helper.exs_
  ```
  route = %Route{
    name: :test_me,
    path: "/jwt",
    responses: [
      %Response{flag: :success, body: "some-body"}
    ]
  }

  MockMe.start(:state)
  MockMe.add_routes([route])
  MockMe.start(:server)
  ```
  """
  def add_routes(routes) do
    Enum.each(routes, fn route ->
      add_route(route)
    end)

    reset_test_cases()
  end

  @doc """
  Used to get the defined routes from state.
  """
  def routes do
    get_state()[:routes]
  end

  @doc """
  The primary function in your tests. Call this to toggle responses from the mock server.

  To use this in your tests you can call:

  `MockMe.set_test_case(:route_name, :route_flag)`

  The response with the defined `:flag` will be returned when the endpoint is called.
  """
  def set_test_case(route_name, response_flag) do
    Agent.update(State, fn state ->
      %{state | cases: Map.put(state[:cases], route_name, response_flag)}
    end)
  end

  @doc """
  Used to reset the test state to the config defaults once tests in a module have been performed or before tests are run.

  Use this in the `setup` block of your tests or inside a test which you need to be sure uses the defaults.

  ```
  setup do
    MockMe.reset_test_cases()
  end
  ```
  """
  def reset_test_cases do
    Agent.update(State, fn state ->
      %{state | cases: get_test_cases_from_routes(state[:routes])}
    end)
  end

  @doc """
  Called inside each endoint to determine which response to return.
  You should never need to call this in your code except in the case of troubleshooting.
  """
  @spec test_case_value(any) :: atom()
  def test_case_value(name) do
    Agent.get(State, fn state ->
      Map.get(state[:cases], name)
    end)
  end

  @doc """
  A convienience function to view the state of the mocks.
  Primarily used for troubleshooting. You shouldn't need this in any of your tests.
  """
  @spec get_state :: map()
  def get_state do
    Agent.get(State, fn state -> state end)
  end

  defp get_test_cases_from_routes(routes) do
    case routes do
      nil ->
        %{}

      routes ->
        Enum.reduce(routes, %{}, fn route, acc ->
          Map.put(acc, route.name, get_default_flag(route))
        end)
    end
  end

  defp get_default_flag(route) do
    if Enum.empty?(route.responses) do
      :success
    else
      res = route.responses |> List.first()
      res.flag
    end
  end

  @doc """
  Start the application state in the unit tests.
  This prepares the state to accept the configuration for your mocked routes.
  To add routes use the `MockMe.add_routes/1` functions.
  """
  def start do
    MockMe.Application.start(:normal, [])
    MockMe.reset_test_cases()
  end

  def start_server do
    build_server()

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        MockMe.DynamicSupervisor,
        {Plug.Cowboy,
         scheme: :http,
         plug: MockMe.Server,
         options: [port: Application.get_env(:mock_me, :port, 9081)]}
      )
  end

  defp build_server do
    contents =
      quote do
        use Plug.Router
        use Plug.Debugger
        require Logger

        alias MockMe.Config
        alias MockMe.ResponsePlug

        plug(Plug.Logger, log: :info)

        plug(:match)
        plug(:dispatch)

        Enum.each(MockMe.routes(), fn route ->
          match(route.path, via: route.method, to: ResponsePlug, assigns: %{route: route})
        end)

        match(_, to: ResponsePlug)
      end

    Module.create(MockMe.Server, contents, Macro.Env.location(__ENV__))
  end

  defp add_route(%Route{} = route) do
    Agent.update(State, fn state ->
      %{state | routes: [route | state[:routes]]}
    end)
  end
end
