defmodule MockMe.Route do
  @moduledoc """
  A struct for defining routes and their test cases
  """
  alias MockMe.Response
  @enforce_keys [:name, :path]

  defstruct [
    :name,
    :path,
    method: :get,
    content_type: ["application/json"],
    responses: [
      %Response{
        flag: :success,
        body: %{data: "Congrats! The request was a success."} |> Jason.encode!()
      }
    ]
  ]
end
