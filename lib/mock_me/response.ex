defmodule MockMe.Response do
  @moduledoc """
  Used to define how the mocked endpoint should respond.

  ## Example

    ```
    %Response{
      flag: :success,               #required
      body: "some-serialized-body", #required
      status_code: 200              #default
    }
    ```
  """
  @enforce_keys [:flag, :body]
  defstruct [:flag, :body, status_code: 200]
end
