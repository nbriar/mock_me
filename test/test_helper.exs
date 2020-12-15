ExUnit.start()
MockMe.start()

Application.ensure_all_started(:hackney)

route = %MockMe.Route{
  name: :test_me,
  path: "/test-path",
  responses: [
    %MockMe.Response{flag: :success, body: "test-body"},
    %MockMe.Response{flag: :failure, body: "test-failure-body", status_code: 422}
  ]
}

MockMe.add_routes([route])
MockMe.start_server()

MockMe.reset_flags()
