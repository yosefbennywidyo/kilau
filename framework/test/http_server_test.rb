require "kilau"
require "socket"
T = Kilau::Testing

class HelloController < Kilau::Controller
  def self.routes
    Kilau::Routes.new
      .add("/hello", get { |app_context, request| Kilau::Format.text("hello #{request.query("name").to_s}") })
      .add("/echo", post { |app_context, request| Kilau::Format.text(request.form_value("msg").to_s) })
  end
end

class HelloApp < Kilau::Hooks
  def routes = Kilau::AppRoutes.with_default_routes.add(HelloController.routes)
end

def read_response(sock)
  status_line = sock.gets
  return "closed" if status_line.nil?
  status = status_line.split(" ")[1]
  length = 0
  connection = ""
  while (line = sock.gets) && line != "\r\n"
    name, value = line.chomp.split(": ", 2)
    length = value.to_i if name == "content-length"
    connection = value if name == "connection"
  end
  body = length > 0 ? sock.read(length) : ""
  "#{status} #{connection} #{body}"
end

def one_shot(port, raw)
  sock = TCPSocket.new("127.0.0.1", port)
  sock.write(raw)
  answer = read_response(sock)
  sock.close
  answer
end

app_context = Kilau::AppContext.new(Kilau::DB::Pool.new(":memory:", 1), Kilau::Config.parse("app:\n  name: hello\n", "test.yaml"), "test")
server = Kilau::HTTP::Server.new(Kilau::Dispatcher.new(HelloApp.new.routes, app_context), "127.0.0.1", 0, false)
port = server.bind
T.check("bind on port 0 picks a free port") { port > 0 }
runner = Thread.new { server.run }

sock = TCPSocket.new("127.0.0.1", port)
sock.write("GET /hello?name=kilau HTTP/1.1\r\nHost: t\r\n\r\n")
T.check("a GET is served over the socket") { read_response(sock) == "200 keep-alive hello kilau" }
body = "msg=hi+there"
sock.write("POST /echo HTTP/1.1\r\nHost: t\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: #{body.size}\r\n\r\n#{body}")
T.check("a second request reuses the connection") { read_response(sock) == "200 keep-alive hi there" }
sock.write("GET /_ping HTTP/1.1\r\nHost: t\r\nConnection: close\r\n\r\n")
T.check("Connection: close is honoured") { read_response(sock) == "200 close {\"ok\":true}" && sock.gets.nil? }
sock.close

T.check("HTTP/1.0 without keep-alive closes") { one_shot(port, "GET /hello HTTP/1.0\r\n\r\n") == "200 close hello " }
T.check("a malformed request line gets 400 and a close") { one_shot(port, "BLAH\r\n\r\n").start_with?("400 close") }
T.check("an oversized body gets 413") { one_shot(port, "POST /echo HTTP/1.1\r\nContent-Length: 2000000\r\n\r\n").start_with?("413 close") }
T.check("an unknown path gets 404") { one_shot(port, "GET /nope HTTP/1.1\r\nConnection: close\r\n\r\n").start_with?("404 close") }

silent = TCPSocket.new("127.0.0.1", port)
silent.close
T.check("a client that sends nothing does not stop the server") { one_shot(port, "GET /hello?name=again HTTP/1.1\r\nConnection: close\r\n\r\n") == "200 close hello again" }

threads = []
20.times { |i| threads << Thread.new { one_shot(port, "GET /hello?name=t#{i} HTTP/1.1\r\nConnection: close\r\n\r\n") } }
answers = threads.map { |t| t.value }
T.check("20 concurrent connections are all served") { answers == (0...20).map { |i| "200 close hello t#{i}" } }

server.close
runner.join
T.check("close ends run") { true }
