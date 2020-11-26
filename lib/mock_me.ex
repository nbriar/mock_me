defmodule MockMe do
  @moduledoc """
  Documentation for `MockMe`.
  """
  alias MockMe.State
  alias MockMe.Config

  @doc """
  To use this in your tests you can call:
  MockMe.set_test_case(:some_defined_case, :some_defined_result)
  """
  def set_test_case(endpoint, value) do
    Agent.update(State, &Map.put(&1, endpoint, value))
  end

  @doc """
  Used to reset the test state to the config defaults once tests in a module have been performed or before tests are run.
  """
  def reset_test_cases do
    Agent.update(State, fn _ ->
      get_state_from_config()
    end)
  end

  @spec test_case_value(any) :: atom()
  def test_case_value(name) do
    Agent.get(State, &Map.get(&1, name))
  end

  @spec all_test_cases :: map()
  def all_test_cases do
    Agent.get(State, fn state -> state end)
  end

  def get_state_from_config do
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
