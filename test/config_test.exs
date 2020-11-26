defmodule MockMe.ConfigTest do
  @moduledoc false
  use ExUnit.Case
  doctest MockMe

  alias MockMe.Config
  alias MockMe.Route
  alias MockMe.Response

  test "server(:port) pulls returns from config" do
    Application.put_env(:mock_me, :server, port: 9000)

    assert Config.server(:port) == 9000
  end

  test "server(:port) pulls returns default" do
    Application.put_env(:mock_me, :server, port: nil)
    assert Config.server(:port) == 9081
  end

  test "server(:accepts_content_types) pulls returns from config" do
    Application.put_env(:mock_me, :server, accepts_content_types: ["some/application"])

    assert Config.server(:accepts_content_types) == ["some/application"]
  end

  test "server(:accepts_content_types) pulls returns default" do
    Application.put_env(:mock_me, :server, accepts_content_types: nil)
    assert Config.server(:accepts_content_types) == ["application/json"]
  end

  test "routes/0 gets a list of MockMe.Routes" do
    routes = [
      %{
        name: :auth_jwt,
        path: "/jwt"
      }
    ]

    Application.put_env(:mock_me, :routes, routes)

    assert [%Route{} | _] = Config.routes()
  end

  test "routes/0 translates the responses to MockMe.Response" do
    config_resp = %{flag: :success, body: "some-body"}

    config_route = %{
      name: :auth_jwt,
      path: "/jwt",
      responses: [
        config_resp
      ]
    }

    Application.put_env(:mock_me, :routes, [config_route])
    [route | _] = Config.routes()

    [resp | _] = route.responses

    assert %Response{} = resp
    assert resp.body == config_resp.body
  end
end
