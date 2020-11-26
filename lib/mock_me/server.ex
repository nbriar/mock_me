defmodule MockMe.Server do
  @moduledoc """
  The primary module which defines the mock routes based on a dynamic config.
  """
  use Plug.Router
  use Plug.Debugger
  require Logger

  alias MockMe.Config

  plug(Plug.Logger, log: :error)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: Config.server(:accepts_content_types),
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  Enum.each(Config.routes(), fn route ->
    match route.path, via: route.method, assigns: %{route: route} do
      route = conn.assigns.route
      conn = Plug.Conn.put_resp_header(conn, "content-type", route.content_type)
      test_case_value = MockMe.test_case_value(route.name)

      response =
        Enum.find(route.responses, fn res ->
          res.flag == test_case_value
        end)

      case response do
        nil ->
          conn
          |> Plug.Conn.send_resp(
            500,
            Jason.encode!(%{
              data: "there's no mock for that test case [#{route.name}, #{test_case_value}]"
            })
          )

        res ->
          conn
          |> Plug.Conn.send_resp(
            res.status_code,
            res.body
          )
      end
    end
  end)

  match _ do
    send_resp(conn, 404, "there's no mock for that route")
  end
end
