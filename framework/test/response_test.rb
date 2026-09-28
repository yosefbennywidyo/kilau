require "kilau"
T = Kilau::Testing

T.check("escape covers the five HTML metacharacters") { Kilau::Html.escape("<a href=\"x\">'&'</a>") == "&lt;a href=&quot;x&quot;&gt;&#39;&amp;&#39;&lt;/a&gt;" }
T.check("escape leaves plain text alone") { Kilau::Html.escape("Halo Kilau é") == "Halo Kilau é" }

page = Kilau::Format.render("<p>é</p>")
T.check("render is 200 text/html") { page.status == 200 && page.headers["content-type"] == "text/html; charset=utf-8" }
T.check("render takes a status") { Kilau::Format.render("x", status: 422).status == 422 }
T.check("to_http writes the status line, headers, length and body") do
  page.to_http(true) == "HTTP/1.1 200 OK\r\ncontent-type: text/html; charset=utf-8\r\ncontent-length: 9\r\nconnection: keep-alive\r\n\r\n<p>é</p>"
end
T.check("to_http can close the connection") { page.to_http(false).include?("\r\nconnection: close\r\n") }

moved = Kilau::Format.redirect("/posts/1")
T.check("redirect is 303 with a location") { moved.status == 303 && moved.location == "/posts/1" && moved.body == "" }
T.check("redirect names See Other") { moved.to_http(true).start_with?("HTTP/1.1 303 See Other\r\n") }
T.check("json sets its content type") { Kilau::Format.json("{}").headers["content-type"] == "application/json" }
T.check("json takes a status") { Kilau::Format.json("{}", status: 503).status == 503 }
T.check("text sets its content type") { Kilau::Format.text("hi").headers["content-type"] == "text/plain; charset=utf-8" }
T.check("empty has no body") { Kilau::Format.empty(204).body == "" && Kilau::Format.empty(204).status == 204 }
T.check("location is nil without a redirect") { page.location.nil? }
T.check("an unknown status still serializes") { Kilau::Response.new(299, "text/plain", "").to_http(false).start_with?("HTTP/1.1 299 Unknown\r\n") }

def header_refused?(name, value)
  Kilau::Format.text("x").set_header(name, value)
  false
rescue ArgumentError
  true
end
T.check("a header value with CR or LF is refused") { header_refused?("location", "/x\r\nset-cookie: a=b") && header_refused?("location", "/x\ny") }
T.check("a header name with CR or LF is refused") { header_refused?("x-a\r\nx-b", "v") }
T.check("NotFound is 404 with a default message") { e = Kilau::Error::NotFound.new; e.status == 404 && e.message == "not found" }
T.check("BadRequest is 400") { Kilau::Error::BadRequest.new("x").status == 400 }
T.check("Unauthorized is 401") { Kilau::Error::Unauthorized.new.status == 401 }
caught = begin
  raise Kilau::Error::NotFound, "post not found"
rescue Kilau::Error => e
  "#{e.status} #{e.message}"
end
T.check("a subclass rescued as Kilau::Error keeps its status") { caught == "404 post not found" }
