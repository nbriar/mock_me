defmodule MockMeTest do
  @moduledoc false
  use ExUnit.Case
  doctest MockMe

  test "has a state agent started" do
    assert MockMe.set_test_case(:jwt, :success)
    assert MockMe.test_case_value(:jwt) == :success
  end

  test "reset_test_cases/0 resets state" do
    config_resp = %{flag: :success, body: "some-body"}

    config_route = %{
      name: :test_me,
      path: "/jwt",
      responses: [
        config_resp
      ]
    }

    Application.put_env(:mock_me, :routes, test_cases: [config_route])

    assert MockMe.set_test_case(:test_me, :wipe_me)
    assert MockMe.test_case_value(:test_me) == :wipe_me

    assert MockMe.reset_test_cases()
    assert MockMe.test_case_value(:test_me) == :success
  end

  # Need to write the actual integration tests

  test "some stuff" do
    HTTPoison.get!("http://localhost:9081") |> IO.inspect()
  end
end
