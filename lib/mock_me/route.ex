defmodule MockMe.Route do
  @moduledoc """
  A struct for defining routes and their test cases

  ## Example
    ```
    %Route{
      name: :my_test_case,              #required
      path: "/my/test/case",            #required
      method: :get,                     # default
      content-type: "application/json", #default
      responses: [],                    #default
    }
    ```

    `name:` must be an atom which you use to identify this route in your tests

    `path:` must be a valid http url - usually the route for the api you're mocking

    `method:` may be either a single atom or a list of atoms - valid atoms are :get, :post, :put, :patch, :delete and :options

    `content-type:` must be a valid http response type, this is the content-type header for the response

    `responses:` must be an empty list or a list of %MockMe.Response{}
  """
  alias MockMe.Response
  @enforce_keys [:name, :path]

  defstruct [
    :name,
    :path,
    method: :get,
    content_type: "application/json",
    responses: [
      %Response{
        flag: :success,
        body: %{data: "Congrats! The request was a success."} |> Jason.encode!()
      }
    ]
  ]
end
