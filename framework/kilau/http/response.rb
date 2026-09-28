module Kilau
  class Response
    REASONS = {
      200 => "OK", 201 => "Created", 204 => "No Content", 303 => "See Other",
      400 => "Bad Request", 401 => "Unauthorized", 404 => "Not Found",
      413 => "Content Too Large", 422 => "Unprocessable Content",
      431 => "Request Header Fields Too Large", 500 => "Internal Server Error",
      503 => "Service Unavailable"
    }

    attr_reader :status, :headers, :body

    def initialize(status, content_type, body)
      @status = status
      @headers = { "content-type" => content_type }
      @body = body
    end

    def location = @headers["location"]

    # A CR or LF would let a value start another header or end the head.
    def set_header(name, value)
      if name.include?("\r") || name.include?("\n") || value.include?("\r") || value.include?("\n")
        raise ArgumentError, "header #{name.inspect} contains a line break"
      end
      @headers[name] = value
      nil
    end

    # Content-Length is the body's byte size; the whole body is written at
    # once (no streaming, spec §2.1).
    def to_http(keep_alive)
      out = "HTTP/1.1 #{@status} #{REASONS.fetch(@status, "Unknown")}\r\n"
      @headers.each { |name, value| out << "#{name}: #{value}\r\n" }
      out << "content-length: #{@body.bytesize}\r\n"
      out << "connection: #{keep_alive ? "keep-alive" : "close"}\r\n"
      out << "\r\n"
      out << @body
      out
    end
  end
end
