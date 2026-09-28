module Kilau
  module HTTP
    # A request the parser refuses, with the status to answer it with.
    class ParseError < StandardError
      attr_reader :status

      def initialize(status, message)
        super(message)
        @status = status
      end
    end

    # Reads one HTTP/1.1 request from anything with gets and read(n).
    module Parser
      MAX_HEADER_BYTES = 8192
      MAX_BODY_BYTES = 1_048_576

      # Returns nil when the peer closed before sending a request line.
      def self.read_request(io)
        line = io.gets
        return nil if line.nil?
        size = line.bytesize
        raise ParseError.new(431, "request line too large") if size > MAX_HEADER_BYTES
        parts = line.strip.split(" ")
        unless parts.size == 3 && parts[0].match?(/\A[A-Z]+\z/) && parts[1].start_with?("/") && parts[2].start_with?("HTTP/1.")
          raise ParseError.new(400, "malformed request line")
        end

        headers = {}
        while true
          header = io.gets
          raise ParseError.new(400, "connection closed inside the headers") if header.nil?
          size += header.bytesize
          raise ParseError.new(431, "request headers too large") if size > MAX_HEADER_BYTES
          break if header == "\r\n" || header == "\n"
          colon = header.index(":")
          raise ParseError.new(400, "malformed header line") if colon.nil? || colon == 0
          headers[header[0, colon].strip.downcase] = header[colon + 1, header.size - colon - 1].strip
        end

        unless headers["transfer-encoding"].nil?
          raise ParseError.new(400, "chunked request bodies are not supported")
        end
        body = ""
        length_text = headers["content-length"]
        unless length_text.nil?
          raise ParseError.new(400, "invalid Content-Length") unless length_text.match?(/\A\d{1,18}\z/)
          length = length_text.to_i
          raise ParseError.new(413, "request body too large") if length > MAX_BODY_BYTES
          if length > 0
            read = io.read(length)
            raise ParseError.new(400, "body shorter than Content-Length") if read.nil? || read.bytesize < length
            body = read
          end
        end
        Request.new(parts[0], parts[1], parts[2], headers, body)
      end
    end
  end
end
