defmodule MockMe.State do
  @moduledoc """
  Used to keep track of state for mocks in tests.
  Holds a map of route names and response flags which the server uses to determine which response to serve.

  ## Example

  ```
  %{
    auth_api_jwt: :success,
    auth_api_validate: :failure,
    auth_api_destroy: :success
  }
  ```
  These values are populated from the config and then toggled using the `MockMe.set_test_case(:route_name, :response)` function.
  """
  def child_spec(_) do
    %{
      id: __MODULE__,
      start:
        {__MODULE__, :start_link,
         [
           %{}
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
