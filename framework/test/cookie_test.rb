require "kilau"
T = Kilau::Testing

jar = Kilau::Cookie.parse("a=1; b=x=y; c=")
T.check("parse reads pairs, keeping = inside a value") { jar == { "a" => "1", "b" => "x=y", "c" => "" } }
T.check("parse of an empty header is empty") { Kilau::Cookie.parse("").empty? }
T.check("parse skips a piece without =") { Kilau::Cookie.parse("junk").empty? }
T.check("parse ignores spaces around ;") { Kilau::Cookie.parse("  a=1 ;b=2  ;  c=3") == { "a" => "1", "b" => "2", "c" => "3" } }

T.check("build writes the fixed attributes and Max-Age") do
  Kilau::Cookie.build("s", "v", 3600, false) == "s=v; Path=/; HttpOnly; SameSite=Lax; Max-Age=3600"
end
T.check("build can expire and mark Secure") do
  Kilau::Cookie.build("s", "", 0, true).end_with?("; Max-Age=0; Secure")
end
T.check("build omits Max-Age when negative") do
  Kilau::Cookie.build("s", "v", -1, false) == "s=v; Path=/; HttpOnly; SameSite=Lax"
end

res = Kilau::Format.text("x")
res.add_set_cookie("a=1; Path=/")
res.add_set_cookie("b=2; Path=/")
T.check("two Set-Cookie lines come out in order before content-length") do
  res.to_http(true) == "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\nset-cookie: a=1; Path=/\r\nset-cookie: b=2; Path=/\r\ncontent-length: 1\r\nconnection: keep-alive\r\n\r\nx"
end

def cookie_refused?(line)
  Kilau::Format.text("x").add_set_cookie(line)
  false
rescue ArgumentError
  true
end
T.check("a Set-Cookie line with CR or LF is refused") { cookie_refused?("x\r\ny") && cookie_refused?("x\ny") && cookie_refused?("x\ry") }

T.check("Forbidden is 403 with a default message") { e = Kilau::Error::Forbidden.new; e.status == 403 && e.message == "forbidden" }
T.check("a 403 response names Forbidden") { Kilau::Response.new(403, "text/plain", "").to_http(false).start_with?("HTTP/1.1 403 Forbidden\r\n") }

req = Kilau::Request.new("GET", "/", "HTTP/1.1", { "cookie" => "sid=abc; theme=dark" }, "")
T.check("Request#cookie reads the cookie header") { req.cookie("sid") == "abc" && req.cookie("theme") == "dark" }
T.check("Request#cookie is nil when absent") { req.cookie("nope").nil? }
T.check("Request#cookie is nil without a cookie header") { Kilau::Request.new("GET", "/", "HTTP/1.1", {}, "").cookie("sid").nil? }
