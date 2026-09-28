require "kilau"
require_relative "support/fake_io"
T = Kilau::Testing

def parse(raw) = Kilau::HTTP::Parser.read_request(FakeIO.new(raw))

def parse_status(raw)
  parse(raw)
  "parsed"
rescue Kilau::HTTP::ParseError => e
  e.status.to_s
end

def bad_request?
  yield
  false
rescue Kilau::Error::BadRequest
  true
end

get = parse("GET /posts?page=2&q=a+b HTTP/1.1\r\nHost: kilau.test\r\nX-Mixed-Case: yes\r\n\r\n")
T.check("the request line is split") { get.request_method == "GET" && get.path == "/posts" && get.http_version == "HTTP/1.1" }
T.check("the query string is kept apart from the path") { get.query_string == "page=2&q=a+b" }
T.check("query decodes + and names") { get.query("page") == "2" && get.query("q") == "a b" && get.query("none").nil? }
T.check("header names are case-insensitive") { get.header("x-mixed-case") == "yes" && get.header("HOST") == "kilau.test" }
T.check("a GET has an empty body") { get.body == "" }

form_body = "post%5Btitle%5D=Halo+Kilau&post%5Bcontent%5D=Isi%20%26%20lainnya&_method=patch&other=1"
post = parse("POST /posts/1 HTTP/1.1\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: #{form_body.size}\r\n\r\n#{form_body}")
T.check("the body is read to Content-Length") { post.body == form_body }
T.check("form groups a nested prefix") { post.form("post") == { "title" => "Halo Kilau", "content" => "Isi & lainnya" } }
T.check("form_value reads a top-level field") { post.form_value("_method") == "patch" && post.form_value("other") == "1" }
T.check("form of an absent prefix is empty") { post.form("user").empty? }
json = parse("POST /x HTTP/1.1\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n{}")
T.check("a non-form body is not decoded as a form") { json.form_value("{}").nil? && json.body == "{}" }

T.check("EOF before a request line is nil") { parse("").nil? }
T.check("a malformed request line is 400") { parse_status("BLAH\r\n\r\n") == "400" }
T.check("a request target without a leading slash is 400") { parse_status("GET posts HTTP/1.1\r\n\r\n") == "400" }
T.check("a header without a colon is 400") { parse_status("GET / HTTP/1.1\r\nNoColon\r\n\r\n") == "400" }
T.check("headers past 8 KB are 431") { parse_status("GET / HTTP/1.1\r\nX-Big: #{"a" * 9000}\r\n\r\n") == "431" }
T.check("a body past 1 MB is 413") { parse_status("POST / HTTP/1.1\r\nContent-Length: 2000000\r\n\r\n") == "413" }
T.check("a non-numeric Content-Length is 400") { parse_status("POST / HTTP/1.1\r\nContent-Length: abc\r\n\r\n") == "400" }
T.check("a body shorter than Content-Length is 400") { parse_status("POST / HTTP/1.1\r\nContent-Length: 10\r\n\r\nabc") == "400" }
T.check("a chunked body is 400") { parse_status("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n") == "400" }
T.check("headers cut off by EOF are 400") { parse_status("GET / HTTP/1.1\r\nHost: x\r\n") == "400" }

broken = parse("POST / HTTP/1.1\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 11\r\n\r\npost%5Bt%zz")
T.check("broken percent-encoding in a form is BadRequest") { bad_request? { broken.form("post") } }
T.check("broken percent-encoding in a query is BadRequest") { bad_request? { parse("GET /?q=%zz HTTP/1.1\r\n\r\n").query("q") } }

req = Kilau::Request.new("GET", "/posts/12", "HTTP/1.1", {}, "")
req.path_params = { "id" => "12", "slug" => "abc", "huge" => "99999999999999999999" }
T.check("path_int reads digits") { req.path_int("id") == 12 }
T.check("path_int of letters is BadRequest") { bad_request? { req.path_int("slug") } }
T.check("path_int of a huge number is BadRequest, not an overflow") { bad_request? { req.path_int("huge") } }
T.check("path_int of a missing param is BadRequest") { bad_request? { req.path_int("nope") } }
req.override_method("PATCH")
T.check("override_method changes the verb") { req.request_method == "PATCH" }
T.check("Form.encode round-trips through decode") { Kilau::Form.decode(Kilau::Form.encode({ "a b" => "c&d=é" })) == { "a b" => "c&d=é" } }
