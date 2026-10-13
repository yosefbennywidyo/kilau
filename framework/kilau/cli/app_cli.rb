module Kilau
  # The app binary's command line (spec §5.2): `start` serves the app,
  # `db migrate|rollback|status` runs the schema commands against the
  # database the config names. The config is <config_dir>/<KILAU_ENV>.yaml,
  # development by default.
  module CLI
    USAGE = "usage: COMMAND   (start | routes | db migrate | db rollback | db status)"

    def self.run(hooks, migrations, argv, config_dir = "config")
      environment = ENV.fetch("KILAU_ENV", "development")
      config = Config.load("#{config_dir}/#{environment}.yaml")
      if argv.size == 1 && argv[0] == "start"
        start(hooks, config, environment)
      elsif argv.size == 1 && argv[0] == "routes"
        routes_table(hooks)
      elsif argv.size == 2 && argv[0] == "db"
        SchemaCLI.run(migrations, [argv[1], "--db", config.string("database.path")])
      else
        $stderr.puts USAGE
        2
      end
    rescue Config::Error, Sqlite::Error => e
      $stderr.puts "error: #{e.message}"
      1
    end

    # `blog routes` / `blog_routes routes` (Rencana 5 Fase A): every route
    # in dispatch order, VERB padded to fit DELETE and the pattern column
    # padded to the widest pattern this app declares.
    def self.routes_table(hooks)
      routes = hooks.routes.routes
      width = 0
      routes.each { |route| width = route.pattern.size if route.pattern.size > width }
      routes.each { |route| puts "#{route.verb.ljust(6)}  #{route.pattern.ljust(width)}  #{route.handler_label}" }
      0
    end

    def self.start(hooks, config, environment)
      pool = Sqlite::Pool.new(config.string("database.path"), config.int("database.pool"))
      app_context = AppContext.new(pool, config, environment)
      host = config.string("server.host")
      dispatcher = hooks.dispatcher(app_context)
      server = HTTP::Server.new(dispatcher, host, config.int("server.port"), config.bool("logger.requests"))
      port = server.bind
      puts "kilau: listening on http://#{host}:#{port} (#{environment})"
      $stdout.flush
      server.run
      0
    end
  end
end
