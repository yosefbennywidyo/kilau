require "kilau"
T = Kilau::Testing

# --- stubs: anything with call(request) -> Response is a dispatcher ---
class CountingStub
  attr_reader :calls

  def initialize = @calls = 0

  def call(request)
    @calls += 1
    # request.session is read afresh each time: a local bound to it, passed to
    # Csrf.token and written afterwards, stops Spinel's inference from
    # converging (a compiler finding, see the task report).
    if request.request_method == "GET" && request.path == "/form"
      Kilau::Format.text(Kilau::Csrf.token(request.session))
    elsif request.path == "/login"
      request.session["user"] = "7"
      Kilau::Format.text("in")
    else
      Kilau::Format.text("#{request.request_method} #{request.path} user=#{request.session["user"].to_s}")
    end
  end
end

class OtherStub
  def call(request) = Kilau::Format.text("other #{request.request_method}")
end

def config_for(text) = Kilau::Config.parse(text, "t.yaml")
def context_for(text, environment) = Kilau::AppContext.new(nil, config_for(text), environment)

SECRET_YAML = "session:\n  secret: guard-test-secret\n"
context = context_for(SECRET_YAML, "test")

def request_for(verb, target, cookie, form)
  body = Kilau::Form.encode(form)
  headers = { "host" => "kilau.test" }
  headers["cookie"] = cookie unless cookie.nil?
  unless body.empty?
    headers["content-type"] = "application/x-www-form-urlencoded"
    headers["content-length"] = body.bytesize.to_s
  end
  Kilau::Request.new(verb, target, "HTTP/1.1", headers, body)
end

def cookie_pair(response) = response.set_cookies[0].split(";")[0]

# --- wrap decisions ---
stub = CountingStub.new
T.check("wrap returns the dispatcher itself when sessions are not configured") do
  Kilau::Session::Guard.wrap(stub, context_for("app:\n  name: x\n", "test")).equal?(stub)
end
T.check("wrap returns the dispatcher itself in production when sessions are not configured") do
  Kilau::Session::Guard.wrap(stub, context_for("app:\n  name: x\n", "production")).equal?(stub)
end
T.check("wrap returns the dispatcher itself when session.enabled is false") do
  Kilau::Session::Guard.wrap(stub, context_for("session:\n  enabled: false\n", "test")).equal?(stub)
end
T.check("a secret in the file turns sessions on") { !Kilau::Session::Guard.wrap(stub, context).equal?(stub) }
T.check("session.enabled in test uses the built-in key silently") do
  !Kilau::Session::Guard.wrap(stub, context_for("session:\n  enabled: true\n", "test")).equal?(stub)
end
def config_error?
  yield
  false
rescue Kilau::Config::Error
  true
end
T.check("session.enabled in production without a secret raises Config::Error") do
  config_error? { Kilau::Session::Guard.wrap(CountingStub.new, context_for("session:\n  enabled: true\n", "production")) }
end
T.check("an empty secret raises Config::Error") do
  config_error? { Kilau::Session::Guard.wrap(CountingStub.new, context_for("session:\n  secret: \"\"\n", "production")) }
end
T.check("production accepts the secret from the environment") do
  ENV["KILAU_SESSION_SECRET"] = "env-secret-value"
  wrapped = Kilau::Session::Guard.wrap(CountingStub.new, context_for("session:\n  enabled: true\n", "production"))
  ENV.delete("KILAU_SESSION_SECRET")
  !wrapped.is_a?(CountingStub)
end
T.check("an empty secret from the environment raises Config::Error") do
  ENV["KILAU_SESSION_SECRET"] = ""
  refused = config_error? { Kilau::Session::Guard.wrap(CountingStub.new, context_for("app:\n  name: x\n", "production")) }
  ENV.delete("KILAU_SESSION_SECRET")
  refused
end

# --- the guard over a stub ---
inner = CountingStub.new
guard = Kilau::Session::Guard.wrap(inner, context)
form = guard.call(request_for("GET", "/form", nil, {}))
token = form.body
cookie = cookie_pair(form)
T.check("a GET that makes a token sets one session cookie") { form.set_cookies.size == 1 && cookie.start_with?("kilau_session=") && token.match?(/\A[0-9a-f]{64}\z/) }
T.check("the session cookie carries HttpOnly, SameSite and Max-Age, not Secure") do
  line = form.set_cookies[0]
  line.include?("; HttpOnly") && line.include?("SameSite=Lax") && line.include?("Max-Age=1209600") && !line.include?("Secure")
end
T.check("a GET that does not change the session sets no cookie") { guard.call(request_for("GET", "/other", cookie, {})).set_cookies.empty? }
T.check("the same session gets the same token again") { guard.call(request_for("GET", "/form", cookie, {})).body == token }

calls = inner.calls
no_token = guard.call(request_for("POST", "/things", cookie, {}))
T.check("a POST without a token is 403 and never reaches the dispatcher") { no_token.status == 403 && inner.calls == calls && no_token.body.include?("invalid authenticity token") }
T.check("a refusal carries no session cookie") { no_token.set_cookies.empty? }
T.check("a POST with the right token passes") do
  r = guard.call(request_for("POST", "/things", cookie, { "authenticity_token" => token }))
  r.status == 200 && r.body == "POST /things user=" && inner.calls == calls + 1
end
other = guard.call(request_for("GET", "/form", nil, {}))
T.check("another session's token is 403") do
  guard.call(request_for("POST", "/things", cookie, { "authenticity_token" => other.body })).status == 403
end
T.check("a POST without a session cookie is 403 even with a token") do
  guard.call(request_for("POST", "/things", nil, { "authenticity_token" => token })).status == 403
end
T.check("a wrong token of the same length is 403") { guard.call(request_for("POST", "/things", cookie, { "authenticity_token" => "0" * 64 })).status == 403 }
T.check("a token of another length is 403") { guard.call(request_for("POST", "/things", cookie, { "authenticity_token" => token[0, 63] })).status == 403 }
T.check("an empty token is 403") { guard.call(request_for("POST", "/things", cookie, { "authenticity_token" => "" })).status == 403 }
T.check("a tampered session cookie loses the token, so the POST is 403") do
  forged = cookie.sub(/.\z/) { |c| c == "0" ? "1" : "0" }
  guard.call(request_for("POST", "/things", forged, { "authenticity_token" => token })).status == 403
end
T.check("_method=patch without a token is 403") { guard.call(request_for("POST", "/things/1", cookie, { "_method" => "patch" })).status == 403 }
T.check("_method=delete without a token is 403") { guard.call(request_for("POST", "/things/1", cookie, { "_method" => "delete" })).status == 403 }
T.check("_method=patch with the token passes") do
  guard.call(request_for("POST", "/things/1", cookie, { "_method" => "patch", "authenticity_token" => token })).status == 200
end
T.check("a direct PATCH verb without a token is 403") { guard.call(request_for("PATCH", "/things/1", cookie, {})).status == 403 }
T.check("a direct DELETE verb without a token is 403") { guard.call(request_for("DELETE", "/things/1", cookie, {})).status == 403 }
T.check("a direct PUT verb with the token passes") do
  guard.call(request_for("PUT", "/things/1", cookie, { "authenticity_token" => token })).status == 200
end
T.check("GET, HEAD and OPTIONS need no token") do
  guard.call(request_for("GET", "/x", nil, {})).status == 200 && guard.call(request_for("HEAD", "/x", nil, {})).status == 200 && guard.call(request_for("OPTIONS", "/x", nil, {})).status == 200
end
T.check("a malformed percent-encoded form is a 400, not a crash") do
  bad = Kilau::Request.new("POST", "/things", "HTTP/1.1", { "content-type" => "application/x-www-form-urlencoded", "cookie" => cookie }, "a=%zz")
  r = guard.call(bad)
  r.status == 400 && r.set_cookies.empty?
end
T.check("a malformed form on HEAD-less POST does not reach the dispatcher") do
  before = inner.calls
  guard.call(Kilau::Request.new("POST", "/things", "HTTP/1.1", { "content-type" => "application/x-www-form-urlencoded" }, "%"))
  inner.calls == before
end
T.check("a HEAD request that sets the session keeps the cookie and drops the body") do
  head = guard.call(request_for("HEAD", "/login", nil, {}))
  head.set_cookies.size == 1 && head.status == 200
end

login = guard.call(request_for("GET", "/login", nil, {}))
T.check("a session value set by the handler comes back with the cookie") do
  guard.call(request_for("GET", "/who", cookie_pair(login), {})).body == "GET /who user=7"
end

# --- duck typing: a second dispatcher class with a different name ---
other_guard = Kilau::Session::Guard.wrap(OtherStub.new, context)
T.check("the guard wraps a second dispatcher class") do
  other_guard.call(request_for("GET", "/", nil, {})).body == "other GET" && other_guard.call(request_for("POST", "/", nil, {})).status == 403
end

# --- the guard over the real Dispatcher ---
class ThingsController < Kilau::Controller
  def self.routes
    Kilau::Routes.new.prefix("things")
      .add("/form", get { |app_context, request| Kilau::Format.text(Kilau::Csrf.token(request.session)) })
      .add("/", post { |app_context, request| Kilau::Format.text("created") })
      .add("/:id", patch { |app_context, request| Kilau::Format.text("patched #{request.path_int("id")}") })
      .add("/:id", delete { |app_context, request| Kilau::Format.empty(204) })
      .add("/forbidden", get { |app_context, request| raise Kilau::Error::Forbidden })
      .add("/cookie", get { |app_context, request| r = Kilau::Format.text("c"); r.add_set_cookie(Kilau::Cookie.build("theme", "dark", 100, false)); r })
      .add("/expire", get { |app_context, request| r = Kilau::Format.text("c"); r.add_set_cookie(Kilau::Cookie.build("theme", "dark", 0, false)); r })
      .add("/echo", get { |app_context, request| Kilau::Format.text("theme=#{request.cookie("theme").to_s} session=#{request.cookie("kilau_session").nil? ? "no" : "yes"}") })
      .add("/uncookie", get { |app_context, request| r = Kilau::Format.text("c"); r.add_set_cookie(Kilau::Cookie.build("theme", "", 0, false)); r })
  end
end

class ThingsApp < Kilau::Hooks
  def routes = Kilau::AppRoutes.new.add(ThingsController.routes)
end

real = Kilau::Session::Guard.wrap(Kilau::Dispatcher.new(ThingsApp.new.routes, context), context)
rform = real.call(request_for("GET", "/things/form", nil, {}))
rcookie = cookie_pair(rform)
T.check("over the real Dispatcher a GET form sets the cookie") { rform.status == 200 && rform.set_cookies.size == 1 }
T.check("over the real Dispatcher a POST without a token is 403") { real.call(request_for("POST", "/things", rcookie, {})).status == 403 }
T.check("over the real Dispatcher a POST with the token is created") { real.call(request_for("POST", "/things", rcookie, { "authenticity_token" => rform.body })).body == "created" }
T.check("over the real Dispatcher _method=patch needs and accepts the token") do
  real.call(request_for("POST", "/things/4", rcookie, { "_method" => "patch" })).status == 403 &&
    real.call(request_for("POST", "/things/4", rcookie, { "_method" => "patch", "authenticity_token" => rform.body })).body == "patched 4"
end
T.check("over the real Dispatcher _method=delete needs and accepts the token") do
  real.call(request_for("POST", "/things/4", rcookie, { "_method" => "delete" })).status == 403 &&
    real.call(request_for("POST", "/things/4", rcookie, { "_method" => "delete", "authenticity_token" => rform.body })).status == 204
end
T.check("over the real Dispatcher a Forbidden is 403 Forbidden") do
  r = real.call(request_for("GET", "/things/forbidden", nil, {}))
  r.status == 403 && r.to_http(false).start_with?("HTTP/1.1 403 Forbidden\r\n")
end

# --- Csrf unit ---
T.check("Csrf.token is stable within a session and 64 hex characters") do
  s = Kilau::Session.new("k")
  a = Kilau::Csrf.token(s)
  a == Kilau::Csrf.token(s) && a.match?(/\A[0-9a-f]{64}\z/) && s.changed?
end
T.check("two sessions get different tokens") { Kilau::Csrf.token(Kilau::Session.new("k")) != Kilau::Csrf.token(Kilau::Session.new("k")) }
T.check("Csrf.verify? is false without a session") { !Kilau::Csrf.verify?(request_for("POST", "/", nil, {})) }
T.check("eight threads draw eight distinct tokens") do
  draws = []
  lock = Mutex.new
  threads = []
  8.times { threads << Thread.new { v = SecureRandom.hex(32); lock.synchronize { draws << v } } }
  threads.each { |t| t.join }
  draws.size == 8 && draws.uniq.size == 8
end

# --- the client keeps cookies ---
rclient = Kilau::Testing::Client.new(ThingsApp.new, context)
T.check("the client refuses a POST before it has a token") { rclient.post("/things", {}).status == 403 }
ctoken = rclient.get("/things/form").body
T.check("the client sends its cookie back, so the token verifies") { rclient.post("/things", { "authenticity_token" => ctoken }).body == "created" }
T.check("the client patches and deletes with the token") do
  rclient.patch("/things/3", { "authenticity_token" => ctoken }).body == "patched 3" && rclient.delete("/things/3", { "authenticity_token" => ctoken }).status == 204
end
T.check("the client refuses a DELETE without a token") { rclient.delete("/things/3").status == 403 }
T.check("a second client has its own jar, so the first token fails there") do
  Kilau::Testing::Client.new(ThingsApp.new, context).post("/things", { "authenticity_token" => ctoken }).status == 403
end
T.check("a plain cookie is sent back on the next request, next to the session cookie") do
  rclient.get("/things/cookie")
  rclient.get("/things/echo").body == "theme=dark session=yes"
end
T.check("a Max-Age=0 line with a non-empty value deletes the cookie, the session cookie stays") do
  rclient.get("/things/expire")
  rclient.get("/things/echo").body == "theme= session=yes"
end
T.check("an empty value deletes the cookie too") do
  rclient.get("/things/cookie")
  rclient.get("/things/uncookie")
  rclient.get("/things/echo").body == "theme= session=yes"
end
T.check("the client exposes the response's set-cookie lines") { rclient.get("/things/cookie").set_cookies[0].start_with?("theme=dark;") }
