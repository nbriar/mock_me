defmodule MockMe do
  @moduledoc """
  MockMe is a simple mock server used to mock out your third party services in your tests. Unlike many mocking
  solutions, MockMe starts a real HTTP server and serves real static responses which may be toggled easily using
  the `MockMe.set_response(:test, :result)` function in your tests.

  Under the hood this package uses [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html) to manage the routes
  and [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html) for the HTTP server.
  The path in the routes can be any valid path accepted by [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html).
  See the [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html) docs or examples for more information.

  ## Philosophy

  Most applications today obtain data from external sources using TCP. Typically, when integrating with these sources
  you have a few options when writing tests:

  1. Not test the code which calls out to these services. Not an option in my opinion, but all too often this is the chosen path.
  1. Short circuit the code paths before reaching out to the external service using some type of function overwrite mechanism
  in your tests. While better than not testing, this path often leaves you with untested code paths which could become issues or throw errors later. It also leaves you
  in a place where your tests do not acurrately document your code.
  1. Use something like VCR which will make an initial request to the live third party service the first time and then playback that
  recorded response on subsequent requests. This is a valid strategy, but I've always found it cumbersome to setup and manage. I also like to know
  exactly what is being returned in requests.
  1. Use Liskov substitution to replace your API client interface with a mocked out module which mimics the behaviour of your adapter. While this is an excellent way
  to design your code, and a good idea to ensure your interface contracts, it falls short when doing integration tests because you're not actually testing the code
  that will be running in production.
  1. Set up your own mock server which will respond to real HTTP requests and thus test your entire code path just like it would perform in production.

  Of all the options I prefer the last and it's what I do in all my Elixir projects. If you do it from scratch, it's only 2 files and takes very little
  effort. However, I got tired of setting it up in all my projects so I built an abstration with simple configuration that will build the server and run
  it for you in your tests.

  This project is built based on my own personal use. I'm certain there are other use cases and options which you may want to build into it.
  If you would like to contribute, please head over to the [GitHub Repo](https://github.com/nbriar/mock_me) and request access to make pull requests.
  I hope you find this project as useful as I have.


  ## Setup

  The only things you need to do are:
  1. add `{:mock_me, "~> 0.1.0"}` to your dependencies you `mix.exs`
  1. configure your code to point to the mock server url `http://localhost:<port (9081)>`
  1. configure your routes in your `test/test_helper.exs` file
  1. start the `MockMe` server in your `/test/test_help.exs` file
  1. use `MockMe` in your tests

  ## Config

   _config/test.exs_
    ```
    config :mock_me, port: 9081
    ```

    This is only used if you want to change the port the mock server listens to. The default port is 9081.

  ## Dependencies

    Add `:mock_me` to your project dependencies.

    _mix.exs_
    ```
    def deps do
      [
        {:mock_me, "~> 0.1.0"}
      ]
    end
    ```

  ## Initilization

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

  ## Use

    _test/mock_me_phoenix_example/services/starwars.exs_
    ```
    defmodule MockMePhoenixExample.Services.StarWarsTest do
      use ExUnit.Case
      alias MockMePhoenixExample.Services.StarWars

      # setup_all %{} do
      #   # re-initializes the test case state
      #   MockMe.reset_flags()
      # end

      test "people/1 returns success" do
        MockMe.set_response(:swapi_people, :success)
        assert {:ok, _} = StarWars.people(1)
      end

      test "people/1 returns not found" do
        MockMe.set_response(:swapi_people, :not_found)
        assert {:not_found, _} = StarWars.people(1)
      end

      test "starships/1 returns success" do
        MockMe.set_response(:swapi_starships, :success)
        assert {:ok, _} = StarWars.starships(1)
      end

      test "starships/1 returns not found" do
        MockMe.set_response(:swapi_starships, :not_found)
        assert {:not_found, _} = StarWars.starships(1)
      end
    end
  ```
  """

  alias MockMe.Route
  alias MockMe.State

  @doc """
  Add routes to your server. This goes in your `test/test_helper.exs` file.

  Defined routes using the `MockMe.Route` struct.

  The first response in the list of responses is considered the default response and will be used
  in the case where you haven't set a flag in your tests or when `reset_flags/0` is called.

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

  MockMe.start()
  MockMe.add_routes([route])
  MockMe.start_server()
  ```
  """
  def add_routes(routes) do
    Enum.each(routes, fn route ->
      add_route(route)
    end)

    reset_flags()
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

  `MockMe.set_response(:route_name, :route_flag)`

  The response with the defined `:flag` will be returned when the endpoint is called.
  """
  def set_response(route_name, response_flag) do
    Agent.update(State, fn state ->
      %{state | cases: Map.put(state[:cases], route_name, response_flag)}
    end)
  end

  @doc """
  Used to reset the test state to the config defaults once tests in a module have been performed or before tests are run.

  Use this in the `setup` block of your tests or inside a test which you need to be sure uses the defaults.

  ```
  setup do
    MockMe.reset_flags()
  end
  ```
  """
  def reset_flags do
    Agent.update(State, fn state ->
      %{state | cases: get_test_cases_from_routes(state[:routes])}
    end)
  end

  @doc """
  Called inside each endoint to determine which response to return.
  You should never need to call this in your code except in the case of troubleshooting.
  """
  @spec flag_value(any) :: atom()
  def flag_value(name) do
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
    MockMe.reset_flags()
  end

  @doc """
  Used to start the mock server after routes have been added to state using `add_routes/1`
  """
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
