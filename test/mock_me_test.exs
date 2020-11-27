defmodule MockMeTest do
  @moduledoc false
  use ExUnit.Case
  doctest MockMe

  test "has a state agent started" do
    assert MockMe.set_test_case(:jwt, :failure)
    assert MockMe.test_case_value(:jwt) == :failure
  end

  test "reset_test_cases/0 resets state" do
    assert MockMe.set_test_case(:test_me, :wipe_me)

    assert MockMe.test_case_value(:test_me) == :wipe_me

    assert MockMe.reset_test_cases()
    assert MockMe.test_case_value(:test_me) == :success
  end

  # Need to write the actual integration tests

  test "some stuff" do
    assert {:ok, %HTTPoison.Response{status_code: 200}} =
             HTTPoison.get("http://localhost:9081/test-path")
  end
end
