require_relative "../kilau"

module Kilau
  # A Kilau app as a Rack application, for running it under CRuby behind
  # Puma, Falcon, Pitchfork or any other Rack server:
  #
  #   # config.ru
  #   require "kilau/rack_app"
  #   require_relative "src/app"
  #   run Kilau::RackApp.new(App.new)
  #
  # CRuby only, and not loaded by `require "kilau"`: a Spinel binary serves
  # itself with Kilau::HTTP::Server. This does what that server does around
  # the dispatcher (build a Request, call the dispatcher, hand back the
  # Response) and leaves sockets, keep-alive and processes to the Rack
  # server. It needs no rack gem; it only speaks the protocol.
  #
  # The config is read as Kilau::CLI reads it: <config_dir>/<KILAU_ENV>.yaml,
  # with KILAU_* overrides. server.host, server.port and logger.requests
  # belong to the Rack server here and are ignored.
  class RackApp
    def initialize(hooks, config_dir = "config")
      @hooks = hooks
      @config_dir = config_dir
      @dispatcher = nil
      @pid = nil
      @lock = Mutex.new
    end

    def call(env)
      verb = env["REQUEST_METHOD"]
      request = Request.new(verb, target(env), env["SERVER_PROTOCOL"] || "HTTP/1.1", headers(env), body(env))
      response = dispatcher.call(request)
      out = response.headers.dup
      out["content-length"] = response.body.bytesize.to_s
      [response.status, out, verb == "HEAD" ? [] : [response.body]]
    end

    private

    # Built on first use and again in each forked child: the pool's SQLite
    # connections must not be shared across a fork, and preloading servers
    # fork after the app object exists.
    def dispatcher
      return @dispatcher if @pid == Process.pid
      @lock.synchronize do
        if @pid != Process.pid
          environment = ENV.fetch("KILAU_ENV", "development")
          config = Config.load("#{@config_dir}/#{environment}.yaml")
          pool = Sqlite::Pool.new(config.string("database.path"), config.int("database.pool"))
          @dispatcher = @hooks.dispatcher(AppContext.new(pool, config, environment))
          @pid = Process.pid
        end
      end
      @dispatcher
    end

    def target(env)
      query = env["QUERY_STRING"].to_s
      query.empty? ? env["PATH_INFO"] : "#{env["PATH_INFO"]}?#{query}"
    end

    # Kilau reads lower-case header names: HTTP_USER_AGENT is user-agent.
    def headers(env)
      out = {}
      env.each do |name, value|
        out[name[5, name.size - 5].downcase.tr("_", "-")] = value if name.start_with?("HTTP_")
      end
      out["content-type"] = env["CONTENT_TYPE"] if env["CONTENT_TYPE"]
      out["content-length"] = env["CONTENT_LENGTH"] if env["CONTENT_LENGTH"]
      out
    end

    def body(env)
      input = env["rack.input"]
      input.nil? ? "" : input.read.to_s
    end
  end
end
