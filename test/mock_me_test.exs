defmodule MockMeTest do
  @moduledoc false
  use ExUnit.Case
  doctest MockMe

  describe "state agent" do
    test "has started" do
      assert MockMe.set_response(:jwt, :failure)
      assert MockMe.flag_value(:jwt) == :failure
    end

    test "set_response/2" do
      assert MockMe.set_response(:test_me, :failure)

      assert MockMe.flag_value(:test_me) == :failure
    end

    test "set_response/2 ignores unset flags" do
      assert MockMe.set_response(:no_flag, :bogus)

      assert MockMe.flag_value(:no_flag) == :bogus
    end

    test "reset_flags/0" do
      assert MockMe.set_response(:test_me, :wipe_me)

      assert MockMe.flag_value(:test_me) == :wipe_me

      assert MockMe.reset_flags()
      assert MockMe.flag_value(:test_me) == :success
    end
  end

  # Need to write the actual integration tests
  describe "integrations with test endpoints" do
    test "getting a success repsonse" do
      assert MockMe.set_response(:test_me, :success)

      assert {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} =
               HTTPoison.get("http://localhost:9081/test-path")

      assert "test-body" == resp_body
    end

    test "toggling the response" do
      assert MockMe.set_response(:test_me, :failure)

      assert {:ok, %HTTPoison.Response{status_code: 422, body: resp_body}} =
               HTTPoison.get("http://localhost:9081/test-path")

      assert "test-failure-body" == resp_body
    end

    test "invalid flag" do
      assert MockMe.set_response(:test_me, :invalid_flag)

      assert {:ok, %HTTPoison.Response{status_code: 500, body: resp_body}} =
               HTTPoison.get("http://localhost:9081/test-path")

      body = Jason.decode!(resp_body)
      assert body["data"] != nil
    end

    test "not defined route" do
      assert MockMe.set_response(:test_me, :invalid_flag)

      assert {:ok, %HTTPoison.Response{status_code: 404, body: resp_body}} =
               HTTPoison.get("http://localhost:9081/not-defined")

      assert resp_body =~ "has not been defined"
    end
  end
end
