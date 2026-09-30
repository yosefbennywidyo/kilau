require "kilau"
T = Kilau::Testing

# An app may serve its requests with another dispatcher (the one `kilau gen
# routes` writes): the test client and Kilau::CLI ask the hooks for it.
class FixedDispatcher
  def call(request) = Kilau::Format.text("fixed #{request.request_method} #{request.path}")
end

class FixedApp < Kilau::Hooks
  def routes = Kilau::AppRoutes.with_default_routes
  def dispatcher(app_context) = FixedDispatcher.new
end

class TableApp < Kilau::Hooks
  def routes = Kilau::AppRoutes.with_default_routes
end

db = Sqlite::Pool.new(":memory:", 1)
app_context = Kilau::AppContext.new(db, Kilau::Config.parse("app:\n  name: hooks\n", "test.yaml"), "test")

T.check("the client uses the dispatcher the hooks give") { Kilau::Testing::Client.new(FixedApp.new, app_context).get("/x").body == "fixed GET /x" }
T.check("by default the dispatcher is the route table") { Kilau::Testing::Client.new(TableApp.new, app_context).get("/_ping").body == "{\"ok\":true}" }

def form_post(body)
  headers = { "host" => "kilau.test", "content-type" => "application/x-www-form-urlencoded", "content-length" => body.bytesize.to_s }
  Kilau::Request.new("POST", "/x", "HTTP/1.1", headers, body)
end

patched = form_post("_method=patch")
Kilau::Dispatcher.apply_override(patched)
T.check("apply_override turns POST with _method=patch into PATCH") { patched.request_method == "PATCH" }
kept = form_post("_method=get")
Kilau::Dispatcher.apply_override(kept)
T.check("apply_override leaves POST with _method=get alone") { kept.request_method == "POST" }
db.close
