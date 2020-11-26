defmodule MockMe do
  @moduledoc """
  MockMe is a simple mock server used to mock out your third party services in your tests. Unlike many mocking
  solutions, MockMe starts a real HTTP server and serves real static responses which may be toggled easily using
  the `MockMe.set_test_case(:test, :result)` function in your tests.

  What this package does isn't terribly difficult to set up on your own in each project and can be accomplished in 2 files
  if you just want to set things up statically. After doing that very thing in several projects, I got tired of copying
  those files and changing the endpoints, so I decided to create this package.

  Largely, this package is config sugar around those 2 files and allows
  the developer to do some very minor setup while defining all mocked routes in the config file in a simple way that is readable
  and understandable.

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
        port: 9081,
        accepts_content_types: ["application/json"]
      ],
      #required
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
end
