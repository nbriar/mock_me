# MockMe

MockMe is a simple mock server used to mock out your third party services in your tests. Unlike many mocking
solutions, MockMe starts a real HTTP server and serves real static responses which may be toggled easily using
the `MockMe.set_response(:test, :result)` function in your tests.

Under the hood this package uses [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html) to manage the routes
and [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html) for the HTTP server.
The path in the routes can be any valid path accepted by [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html).
See the [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html) docs or examples for more information.

## Installation

This package can be installed
by adding `mock_me` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mock_me, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/mock_me](https://hexdocs.pm/mock_me).

  ## Philosophy

  Most applications today obtain data from external sources using TCP. Typically, when integrating with these sources
  you have a few options when writing tests:

  1. Not test the code which calls out to these services. Not an option in my opinion, but all too often this is the chosen path.
  1. Short circuit the code paths before reaching out to the external service using some type of function overwrite mechanism
  in your tests. While better than not testing, this path often leaves you with untested code paths which could become issues or throw errors later. It also leaves you
  in a place where your tests do not acurrately document your code.
  1. Use something like VCR which will make an initial request to the live third party service the first time and then playback that
  recorded response on subsequent requests. This is a valid strategy, but I've always found it cumbersome to setup and manage. I also like to know
  exactly what is being returned in requests.
  1. Use Liskov substitution to replace your API client interface with a mocked out module which mimics the behaviour of your adapter. While this is an excellent way
  to design your code, and a good idea to ensure your interface contracts, it falls short when doing integration tests because you're not actually testing the code
  that will be running in production.
  1. Set up your own mock server which will respond to real HTTP requests and thus test your entire code path just like it would perform in production.

  Of all the options I prefer the last and it's what I do in all my Elixir projects. If you do it from scratch, it's only 2 files and takes very little
  effort. However, I got tired of setting it up in all my projects so I built an abstration with simple configuration that will build the server and run
  it for you in your tests.

  This project is built based on my own personal use. I'm certain there are other use cases and options which you may want to build into it.
  If you would like to contribute, please head over to the [GitHub Repo](https://github.com/nbriar/mock_me) and request access to make pull requests.
  I hope you find this project as useful as I have.


  ## Setup

  The only things you need to do are:
  1. add `{:mock_me, "~> 0.1.0"}` to your dependencies you `mix.exs`
  1. configure your code to point to the mock server url `http://localhost:<port (9081)>`
  1. configure your routes in your `test/test_helper.exs` file
  1. start the `MockMe` server in your `/test/test_help.exs` file
  1. use `MockMe` in your tests

  ## Config

  _config/test.exs_

  ```
  config :mock_me, port: 9081
  ```

  This is only used if you want to change the port the mock server listens to. The default port is 9081.

  ## Dependencies

  Add `:mock_me` to your project dependencies.

_mix.exs_

```


def deps do
  [
    {:mock_me, "~> 0.1.0"}
  ]
end
  ```

  ## Initilization


_test/test_helpers.ex_

```


ExUnit.start()
MockMe.start()

routes = [
  %MockMe.Route{
    name: :swapi_people,
    path: "/swapi/people/:id",
    responses: [
      %MockMe.Response{
        flag: :success,
        body: MockMePhoenixExample.Test.Mocks.SWAPI.people(:success)
      },
      %MockMe.Response{flag: :not_found, body: "people-failure", status_code: 404}
    ]
  },
  %MockMe.Route{
    name: :swapi_starships,
    path: "/swapi/starships/:id",
    responses: [
      %MockMe.Response{
        flag: :success,
        body: MockMePhoenixExample.Test.Mocks.SWAPI.starships(:success)
      },
      %MockMe.Response{flag: :not_found, body: "starships-failure", status_code: 404}
    ]
  }
]

MockMe.add_routes(routes)
MockMe.start_server()
```

## Use

_test/mock_me_phoenix_example/services/starwars.exs_

```
defmodule MockMePhoenixExample.Services.StarWarsTest do
  use ExUnit.Case
  alias MockMePhoenixExample.Services.StarWars

  # setup_all %{} do
  #   # re-initializes the test case state
  #   MockMe.reset_flags()
  # end

  test "people/1 returns success" do
    MockMe.set_response(:swapi_people, :success)
    assert {:ok, _} = StarWars.people(1)
  end

  test "people/1 returns not found" do
    MockMe.set_response(:swapi_people, :not_found)
    assert {:not_found, _} = StarWars.people(1)
  end

  test "starships/1 returns success" do
    MockMe.set_response(:swapi_starships, :success)
    assert {:ok, _} = StarWars.starships(1)
  end

  test "starships/1 returns not found" do
    MockMe.set_response(:swapi_starships, :not_found)
    assert {:not_found, _} = StarWars.starships(1)
  end
end
```


