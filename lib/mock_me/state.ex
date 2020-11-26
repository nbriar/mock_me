defmodule MockMe.State do
  @moduledoc """
  Used to set state for mocks in tests.
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
