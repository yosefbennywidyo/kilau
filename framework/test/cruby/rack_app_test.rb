# Kilau::RackApp puts a Kilau app behind any Rack server. It is CRuby
# only (a Spinel binary serves itself), so this test lives outside
# test/*.rb, which `spin test` compiles; `make test-cruby` runs it.
require "kilau"
require "kilau/rack_app"
require "stringio"
T = Kilau::Testing

class EchoHooks < Kilau::Hooks
  attr_reader :built

  def initialize
    @built = 0
  end

  def routes
    echo = Kilau::Routes.new.prefix("echo")
    echo = echo.add("/", Kilau::Controller.get { |app_context, request| Kilau::Format.text("q=#{request.query("q")} agent=#{request.header("user-agent")} env=#{app_context.environment}") })
    echo = echo.add("/", Kilau::Controller.post { |app_context, request| Kilau::Format.text("name=#{request.form("item")["name"]}", status: 201) })
    echo = echo.add("/go", Kilau::Controller.get { |app_context, request| Kilau::Format.redirect("/echo") })
    Kilau::AppRoutes.with_default_routes.add(echo)
  end

  def dispatcher(app_context)
    @built += 1
    super
  end
end

dir = "/tmp/kilau-rack-test"
db_path = dir + "/rack.sqlite3"
Dir.mkdir(dir) unless File.directory?(dir)
["", "-wal", "-shm"].each { |suffix| File.delete(db_path + suffix) if File.exist?(db_path + suffix) }
File.write(dir + "/development.yaml", "server:\n  host: \"127.0.0.1\"\n  port: 0\ndatabase:\n  path: #{db_path}\n  pool: 2\nlogger:\n  requests: false\n")

def env(verb, path, query = "", extra = {})
  { "REQUEST_METHOD" => verb, "PATH_INFO" => path, "QUERY_STRING" => query, "SERVER_PROTOCOL" => "HTTP/1.1",
    "rack.input" => StringIO.new("") }.merge(extra)
end

hooks = EchoHooks.new
app = Kilau::RackApp.new(hooks, dir)
T.check("nothing is built before the first request") { hooks.built == 0 }

status, headers, body = app.call(env("GET", "/echo", "q=a%20b", "HTTP_USER_AGENT" => "probe"))
T.check("a GET answers the handler's status and body") { status == 200 && body == ["q=a b agent=probe env=development"] }
T.check("the headers are lower-case and carry the body's byte length") do
  headers["content-type"] == "text/plain; charset=utf-8" && headers["content-length"] == body[0].bytesize.to_s
end

form = "item%5Bname%5D=teh"
status, headers, body = app.call(env("POST", "/echo", "", "CONTENT_TYPE" => "application/x-www-form-urlencoded", "CONTENT_LENGTH" => form.bytesize.to_s, "rack.input" => StringIO.new(form)))
T.check("a POST body reaches the form decoder") { status == 201 && body == ["name=teh"] }

status, headers, body = app.call(env("GET", "/echo/go"))
T.check("a redirect keeps its location header") { status == 303 && headers["location"] == "/echo" }

status, headers, body = app.call(env("HEAD", "/echo", "q=x"))
T.check("HEAD sends no body but the GET's content-length") { status == 200 && body == [] && headers["content-length"] == "q=x agent= env=development".bytesize.to_s }

status, headers, body = app.call(env("GET", "/nowhere"))
T.check("an unknown path is the dispatcher's 404") { status == 404 }

status, headers, body = app.call(env("DELETE", "/echo"))
T.check("a verb the path does not route is 405 with Allow") { status == 405 && headers["allow"] == "GET, HEAD, POST" }

status, headers, body = app.call({ "REQUEST_METHOD" => "GET", "PATH_INFO" => "/_ping", "QUERY_STRING" => "" })
T.check("a request without rack.input is served") { status == 200 && body == ["{\"ok\":true}"] }

T.check("one process builds the dispatcher once") { hooks.built == 1 }

# A forking server (Puma's workers, Pitchfork, Falcon) must not share the
# parent's SQLite connections: the child builds its own.
# Here the parent has already served requests, so the sqlite3 gem closes the
# inherited connections in the child and warns, naming its own install path;
# a preloading server forks before any request and never sees that.
SQLite3::ForkSafety.suppress_warnings!
reader, writer = IO.pipe
pid = fork do
  reader.close
  child_status, _, _ = app.call(env("GET", "/_ping"))
  writer.write("#{child_status} #{hooks.built}")
  writer.close
  exit!(0)
end
writer.close
answer = reader.read
Process.wait(pid)
T.check("a forked child builds its own dispatcher") { answer == "200 2" }
T.check("the parent keeps the one it had") { hooks.built == 1 }
