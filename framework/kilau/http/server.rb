require "socket"

module Kilau
  module HTTP
    # One green thread per connection (spec §2.1); blocking socket I/O
    # parks only that thread. A connection serves requests until the
    # client asks to close, sends something unparsable, or goes away.
    class Server
      def initialize(dispatcher, host, port, log_requests)
        @dispatcher = dispatcher
        @host = host
        @port = port
        @log_requests = log_requests
        @listener = nil
      end

      # Opens the listening socket and returns its port (useful with 0).
      def bind
        listener = TCPServer.new(@host, @port)
        @listener = listener
        listener.addr[1]
      end

      # Accepts until close is called.
      def run
        listener = @listener
        raise ArgumentError, "call bind before run" if listener.nil?
        while true
          client = begin
            listener.accept
          rescue IOError, SystemCallError
            nil
          end
          break if client.nil?
          spawn_connection(client)
        end
        nil
      end

      def close
        listener = @listener
        listener.close unless listener.nil?
        nil
      end

      private

      # A method of its own so each thread gets its own `client`: a block
      # in the accept loop would share the loop's variable.
      def spawn_connection(client)
        Thread.new { serve(client) }
        nil
      end

      def serve(sock)
        while true
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          request = begin
            Parser.read_request(sock)
          rescue ParseError => e
            sock.write(Dispatcher.error_response(e.status, e.message).to_http(false))
            nil
          end
          break if request.nil?
          response = @dispatcher.call(request)
          keep = keep_alive?(request)
          sock.write(response.to_http(keep))
          log(request, response, started) if @log_requests
          break unless keep
        end
        nil
      rescue IOError, SystemCallError
        nil
      ensure
        begin
          sock.close
        rescue IOError, SystemCallError
          nil
        end
      end

      def keep_alive?(request)
        connection = request.header("connection").to_s.downcase
        return connection == "keep-alive" if request.http_version == "HTTP/1.0"
        connection != "close"
      end

      def log(request, response, started)
        ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
        puts "#{request.request_method} #{request.path} #{response.status} #{ms}ms"
        $stdout.flush
      end
    end
  end
end
