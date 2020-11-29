defmodule MockMe.ResponsePlug do
  @moduledoc """
  Used to handle the toggling of the responses based on the route flag.
  """
  import Plug.Conn
  require Logger
  def init(options), do: options

  def call(%{assigns: %{route: route}} = conn, _opts) do
    conn = put_resp_header(conn, "content-type", route.content_type)
    flag_value = MockMe.flag_value(route.name)

    response =
      Enum.find(route.responses, fn res ->
        res.flag == flag_value
      end)

    case response do
      nil ->
        Logger.error("No mock for test_case [#{route.name}, #{flag_value}]")

        conn
        |> send_resp(
          500,
          "{\"data\":\"there's no mock for that test case [#{route.name}, #{flag_value}]\"}"
        )

      res ->
        conn
        |> send_resp(
          res.status_code,
          res.body
        )
    end
  end

  def call(conn, _opts) do
    message = "the route `#{conn.request_path}` has not been defined in your configuration"
    Logger.error(message)

    send_resp(
      conn,
      404,
      message
    )
  end
end
