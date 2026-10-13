require "kilau"
T = Kilau::Testing

class NotesController < Kilau::Controller
  def self.routes
    Kilau::Routes.new.prefix("notes")
      .add("/", get { |app_context, request| list(app_context, request) })
      .add("/", post { |app_context, request| add(app_context, request) })
      .add("/bulk/import", post { |app_context, request| Kilau::Format.empty(204) })
      .add("/:id", get { |app_context, request| show(app_context, request) })
      .add("/:id", patch { |app_context, request| update(app_context, request) })
      .add("/:id", delete { |app_context, request| remove(app_context, request) })
  end

  def self.list(app_context, request) = Kilau::Format.text("notes page=#{request.query("page").to_s} env=#{app_context.environment}")
  def self.add(app_context, request) = Kilau::Format.redirect("/notes/#{request.form("note").fetch("title", "")}")
  def self.show(app_context, request) = Kilau::Format.text("note #{request.path_int("id")}")
  def self.update(app_context, request) = Kilau::Format.text("updated #{request.path_int("id")} to #{request.form("note").fetch("title", "")}")
  def self.remove(app_context, request) = Kilau::Format.empty(204)
end

class CrashController < Kilau::Controller
  def self.routes
    Kilau::Routes.new.prefix("crash")
      .add("/", get { |app_context, request| raise "boom" })
      .add("/missing", get { |app_context, request| raise Kilau::Error::NotFound, "no such <note>" })
      .add("/private", get { |app_context, request| raise Kilau::Error::Unauthorized })
  end
end

class NotesApp < Kilau::Hooks
  def routes = Kilau::AppRoutes.with_default_routes.add(NotesController.routes).add(CrashController.routes)
end

T.check("a Hooks without routes raises NotImplementedError") do
  begin
    Kilau::Hooks.new.routes
    false
  rescue NotImplementedError
    true
  end
end

route = Kilau::Route.new("GET", "/notes/:id/edit", NotesController.get { |app_context, request| Kilau::Format.empty(204) })
T.check("a route captures its params") { route.match("/notes/7/edit") == { "id" => "7" } }
T.check("a route refuses a different shape") { route.match("/notes/7").nil? && route.match("/notes//edit").nil? }
T.check("prefix and / make the prefix itself") { Kilau::Routes.new.prefix("/notes/").add("/", NotesController.get { |c, r| Kilau::Format.empty(204) }).routes[0].pattern == "/notes" }

app = NotesApp.new
labeled = app.routes.routes
T.check("a route's handler_label is nil before AppRoutes assigns it") { Kilau::Route.new("GET", "/x", NotesController.get { |c, r| Kilau::Format.empty(204) }).handler_label.nil? }
T.check("the first default route is labeled with index 0") { labeled[0].handler_label == "#{labeled[0].verb} #{labeled[0].pattern}#0" }
T.check("the second default route is labeled with index 1") { labeled[1].handler_label == "#{labeled[1].verb} #{labeled[1].pattern}#1" }
T.check("a route from the second composed controller keeps its own position") { labeled[labeled.size - 1].handler_label == "#{labeled[labeled.size - 1].verb} #{labeled[labeled.size - 1].pattern}##{labeled.size - 1}" }
T.check("every label in the app is unique") { labeled.map { |route| route.handler_label }.uniq.size == labeled.size }

db = Sqlite::Pool.new(":memory:", 1)
app_context = Kilau::AppContext.new(db, Kilau::Config.parse("app:\n  name: notes\n", "test.yaml"), "test")
client = Kilau::Testing::Client.new(NotesApp.new, app_context)

ping = client.get("/_ping")
T.check("_ping answers ok as JSON") { ping.status == 200 && ping.body == "{\"ok\":true}" && ping.headers["content-type"] == "application/json" }
T.check("_health answers ok with a working database") { client.get("/_health").body == "{\"ok\":true}" }
T.check("a GET reaches its handler with the query and app_context") { client.get("/notes?page=2").body == "notes page=2 env=test" }
created = client.post("/notes", { "note[title]" => "hello" })
T.check("a POST reads the nested form and redirects") { created.status == 303 && created.location == "/notes/hello" }
T.check("path params reach the handler") { client.get("/notes/7").body == "note 7" }
T.check("a non-numeric id is 400") { client.get("/notes/abc").status == 400 }
T.check("PATCH arrives as POST + _method") { client.patch("/notes/7", { "note[title]" => "new" }).body == "updated 7 to new" }
T.check("DELETE arrives as POST + _method") { client.delete("/notes/7").status == 204 }
T.check("HEAD on a static path matches GET's status with no body") do
  head = client.head("/notes")
  get = client.get("/notes")
  head.status == get.status && head.to_http(true).include?("content-length: #{get.body.bytesize}") && !head.to_http(true).end_with?(get.body)
end
T.check("HEAD on a parameterized path matches GET's status with no body") do
  head = client.head("/notes/7")
  get = client.get("/notes/7")
  head.status == get.status && head.to_http(true).include?("content-length: #{get.body.bytesize}") && !head.to_http(true).end_with?(get.body)
end
T.check("HEAD to a path with no GET is 405 with Allow: POST") { h = client.head("/notes/bulk/import"); h.status == 405 && h.headers["allow"] == "POST" }
T.check("HEAD to a path with no GET has no body on the wire") { client.head("/notes/bulk/import").to_http(true).end_with?("\r\n\r\n") }
T.check("HEAD to an unknown path has no body on the wire") { h = client.head("/nope"); h.status == 404 && h.to_http(true).end_with?("\r\n\r\n") }
T.check("POST to a GET+PATCH+DELETE-only path is 405 with Allow sorted and unique") do
  r = client.post("/notes/7", {})
  r.status == 405 && r.headers["allow"] == "DELETE, GET, HEAD, PATCH"
end
T.check("HEAD to a route that raises keeps the real status with no body") do
  head = client.head("/crash/missing")
  get = client.get("/crash/missing")
  head.status == get.status && head.to_http(true).end_with?("\r\n\r\n")
end
T.check("OPTIONS on a routed path is 204 with Allow sorted and unique") do
  r = client.options("/notes/7")
  r.status == 204 && r.headers["allow"] == "DELETE, GET, HEAD, PATCH"
end
T.check("OPTIONS on an unrouted path is 404") { client.options("/nope").status == 404 }
T.check("_method=get does not change the verb") { client.post("/notes/7", { "_method" => "get" }).status == 405 }
T.check("a POST where only GET is routed is 405") { client.post("/notes/7", {}).status == 405 }
T.check("an unknown path is 404") { client.get("/nope").status == 404 }
T.check("the 404 page escapes the path") { client.get("/<script>").body.include?("/&lt;script&gt;") }
T.check("broken percent-encoding in a form is 400") { client.post("/notes", { "raw" => "x" }).status == 303 && client.get("/notes?q=%zz").status == 400 }
missing = client.get("/crash/missing")
T.check("a raised NotFound is 404 with its message escaped") { missing.status == 404 && missing.body.include?("no such &lt;note&gt;") }
T.check("a raised Unauthorized is 401") { client.get("/crash/private").status == 401 }
crashed = client.get("/crash")
T.check("an unexpected exception is 500 without its message") { crashed.status == 500 && !crashed.body.include?("boom") }
db.close
