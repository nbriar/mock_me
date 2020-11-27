defmodule MockMe.State do
  @moduledoc """
  Used to keep track of state for mocks in tests.
  Holds a map of route names and response flags which the server uses to determine which response to serve.

  ## Example

  ```
  %{
    routes: [
      %MockMe.Route{
        name: :test_me,
        path: "/test-path",
        responses: [
          %MockMe.Response{flag: :success, body: "test-body"},
          %MockMe.Response{flag: :failure, body: "test-failure-body"}
        ]
      }
    ],
    cases: %{
      test_me: :success
    }
  }
  ```
  These values are populated from `MockMe.add_routes/1` and then toggled using `MockMe.set_test_case(:route_name, :route_flag)`.
  """
  def child_spec(_) do
    %{
      id: __MODULE__,
      start:
        {__MODULE__, :start_link,
         [
           %{routes: [], cases: %{}}
         ]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link(initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end
end
