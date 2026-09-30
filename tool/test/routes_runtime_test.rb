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
T.check("a verb without a route is 404") { client.post("/notes", {}).status == 404 }
T.check("an empty segment does not bind a parameter") { client.get("/notes//tags/red").status == 404 }
T.check("_ping answers") { client.get("/_ping").body == "{\"ok\":true}" }
T.check("_health answers") { client.get("/_health").status == 200 }
db.close
