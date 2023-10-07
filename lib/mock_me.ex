defmodule MockMe do
  @moduledoc File.read!(Path.expand("./README.md"))
             |> String.split("<!-- README START -->")
             |> Enum.at(1)
             |> String.split("<!-- README END -->")
             |> List.first()

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
