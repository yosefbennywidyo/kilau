require "kilau"
require_relative "fixtures/routes_app/src/app"
require_relative "fixtures/routes"
T = Kilau::Testing

# Runs the committed output of routes_gen_test.rb: the generated dispatcher
# must answer as the route table would.
db = Sqlite::Pool.new(":memory:", 1)
app_context = Kilau::AppContext.new(db, Kilau::Config.parse("app:\n  name: notes\n", "test.yaml"), "test")
client = Kilau::Testing::Client.new(RoutedNotesApp.new, app_context)

T.check("the table matches the app's routes") { KilauRoutes::TABLE == NotesApp.new.routes.routes.map { |route| "#{route.verb} #{route.pattern}" } }
T.check("a route declared in the app answers") { client.get("/").body == "home" }
T.check("the prefix alone reaches its / route") { client.get("/notes").body == "notes" }
T.check("a trailing slash matches as in the table") { client.get("/notes/").body == "notes" }
T.check("a path parameter is bound") { client.get("/notes/7").body == "note 7" }
T.check("two path parameters are bound, and braces in a body survive") { client.get("/notes/7/tags/red").body == "7/red {}" }
T.check("_method=delete reaches the DELETE route") { client.delete("/notes/7").status == 204 }
T.check("an unknown path is 404") { client.get("/notes/7/edit").status == 404 }
T.check("a verb without a route is 405 with Allow") { r = client.post("/notes", {}); r.status == 405 && r.headers["allow"] == "GET, HEAD" }
T.check("an empty segment does not bind a parameter") { client.get("/notes//tags/red").status == 404 }
T.check("HEAD to an unknown path has no body on the wire") { h = client.head("/notes/7/edit"); h.status == 404 && h.to_http(true).end_with?("\r\n\r\n") }
T.check("HEAD on a static path matches GET's status with no body") do
  head = client.head("/notes"); get = client.get("/notes")
  head.status == get.status && head.to_http(true).include?("content-length: #{get.body.bytesize}") && !head.to_http(true).end_with?(get.body)
end
T.check("HEAD on a parameterized path matches GET's status with no body") do
  head = client.head("/notes/7"); get = client.get("/notes/7")
  head.status == get.status && head.to_http(true).include?("content-length: #{get.body.bytesize}")
end
T.check("OPTIONS on a routed path is 204 with Allow") { r = client.options("/notes/7"); r.status == 204 && r.headers["allow"] == "DELETE, GET, HEAD" }
T.check("OPTIONS on an unrouted path is 404") { client.options("/totally/unknown/path").status == 404 }
T.check("_ping answers") { client.get("/_ping").body == "{\"ok\":true}" }
T.check("_health answers") { client.get("/_health").status == 200 }
db.close
