defmodule MockMe.Response do
  @moduledoc """
  Used to define how the mocked endpoint should respond.
  """
  @enforce_keys [:flag, :body]
  defstruct [:flag, :body, status_code: 200]
end
