# A Rack front for the Kilau blog, so the same app can run under CRuby
# behind Puma, Pitchfork or Falcon instead of Kilau's own HTTP server
# (bench/servers/README.md). It does only what Kilau::HTTP::Server does
# around the dispatcher: build a Kilau::Request, call the dispatcher, hand
# the status, headers and body back.
#
# The dispatcher and its SQLite pool are built on first use in each
# process: a connection opened before a fork must not be shared by the
# workers, and all three servers fork.
BLOG = File.expand_path("../../examples/blog", __dir__)
$LOAD_PATH.unshift(File.expand_path("../../framework", __dir__))
$LOAD_PATH.unshift(ENV.fetch("KILAU_SQLITE_LIB"))
Dir.chdir(BLOG)

require "kilau"
require File.join(BLOG, "src/app")
require File.join(BLOG, "build/gen/routes")

class KilauRack
  def initialize
    @pid = nil
    @dispatcher = nil
    @lock = Mutex.new
  end

  def call(env)
    request = Kilau::Request.new(env["REQUEST_METHOD"], target(env), env["SERVER_PROTOCOL"] || "HTTP/1.1", headers(env), body(env))
    response = dispatcher.call(request)
    out = response.headers.dup
    out["content-length"] = response.body.bytesize.to_s
    [response.status, out, env["REQUEST_METHOD"] == "HEAD" ? [] : [response.body]]
  end

  private

  def dispatcher
    return @dispatcher if @pid == Process.pid
    @lock.synchronize do
      if @pid != Process.pid
        environment = ENV.fetch("KILAU_ENV", "development")
        config = Kilau::Config.load("config/#{environment}.yaml")
        pool = Sqlite::Pool.new(config.string("database.path"), config.int("database.pool"))
        @dispatcher = RoutedApp.new.dispatcher(Kilau::AppContext.new(pool, config, environment))
        @pid = Process.pid
      end
    end
    @dispatcher
  end

  def target(env)
    query = env["QUERY_STRING"].to_s
    query.empty? ? env["PATH_INFO"] : "#{env["PATH_INFO"]}?#{query}"
  end

  # Kilau reads lower-case header names: HTTP_X_FOO becomes x-foo.
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
