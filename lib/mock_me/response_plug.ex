defmodule MockMe.ResponsePlug do
  @moduledoc """
  Used to validate the jwt in the pipelines
  """
  import Plug.Conn
  require Logger
  def init(options), do: options

  def call(%{assigns: %{route: route}} = conn, _opts) do
    conn = put_resp_header(conn, "content-type", route.content_type)
    test_case_value = MockMe.test_case_value(route.name)

    response =
      Enum.find(route.responses, fn res ->
        res.flag == test_case_value
      end)

    case response do
      nil ->
        Logger.error("No mock for test_case [#{route.name}, #{test_case_value}]")

        conn
        |> send_resp(
          500,
          Jason.encode!(%{
            data: "there's no mock for that test case [#{route.name}, #{test_case_value}]"
          })
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
      %{error: message}
      |> Jason.encode!()
    )
  end
end
