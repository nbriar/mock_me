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
  1. configure your routes in your `config/test.exs` file
  1. start `MockMe` under your supervision tree for your tests

  ## Example Config

   _config/test.exs_
    ```
    # required
    config :mock_me,
      # optional - defaults
      server: [
        port: 9081
      ],
      # required
      routes: [
        %{
          # required
          name: :auth_jwt,
          # required
          path: "/jwt",
          # optional below here
          # these are the defaults except for :responses which will default to an empty array
          # :get, :post, :put, :patch, :delete and :options or a list [:get, :post]
          method: :get,
          # Any valid http content-type, this is the response type from the mock server
          content_type: "application/json",
          responses: [
            # recommended to create a test module which holds your response bodies
            # response bodies must already be serialized to a string
            # the first item in this list is considered the default case
            # :status_code is optional and defaults to 200
            %{flag: :success, body: "some-body", status_code: 200},
            %{flag: :not_found, body: "not-found", status_code: 404}
          ]
        }
      ]
    ```

  ## Phoenix Example
    Need an example and link to the github repo

    _config/test.exs_
    ```
    config :mock_me_phoenix_example, swapi_url: "http://localhost:9081/swapi"

    # Define your mocked Routes here
    config :mock_me,
      routes: [
        %{
          name: :swapi_people,
          path: "/swapi/people/1/",
          responses: [
            %{flag: :success, body: MockMePhoenixExample.Test.Mocks.SWAPI.people(:success), status_code: 200},
            %{flag: :not_found, body: MockMePhoenixExample.Test.Mocks.SWAPI.people(:failure), status_code: 404}
          ]
        }
      ]
    ```

    _test/test_helpers.ex_
    ```
    ExUnit.start()
    MockMe.start()
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
  alias MockMe.State
  alias MockMe.Config

  @doc """
  The primary function in your tests. Call this to toggle responses from the mock server.

  To use this in your tests you can call:

  `MockMe.set_test_case(:some_route_name, :some_route_flag)`
  """
  def set_test_case(route_name, response_flag) do
    Agent.update(State, &Map.put(&1, route_name, response_flag))
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
    Agent.update(State, fn _ ->
      get_state_from_config()
    end)
  end

  @doc """
  Called inside each endoint to determine which response to return. You should never need to call this in your code except in the case of troubleshooting.
  """
  @spec test_case_value(any) :: atom()
  def test_case_value(name) do
    Agent.get(State, &Map.get(&1, name))
  end

  @doc """
  A convienience function to view the state of the mocks.
  Primarily used for troubleshooting. You shouldn't need this in any of your tests.
  """
  @spec all_test_cases :: map()
  def all_test_cases do
    Agent.get(State, fn state -> state end)
  end

  defp get_state_from_config do
    Enum.reduce(Config.routes(), %{}, fn route, acc ->
      Map.put(acc, route.name, get_default_flag(route))
    end)
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
  Start the application in the unit tests.
  """
  def start() do
    MockMe.Application.start(:normal, [])
    MockMe.reset_test_cases()
  end
end
