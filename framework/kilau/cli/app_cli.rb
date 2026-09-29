module Kilau
  # The app binary's command line (spec §5.2): `start` serves the app,
  # `db migrate|rollback|status` runs the schema commands against the
  # database the config names. The config is <config_dir>/<KILAU_ENV>.yaml,
  # development by default.
  module CLI
    USAGE = "usage: COMMAND   (start | db migrate | db rollback | db status)"

    def self.run(hooks, migrations, argv, config_dir = "config")
      environment = ENV.fetch("KILAU_ENV", "development")
      config = Config.load("#{config_dir}/#{environment}.yaml")
      if argv.size == 1 && argv[0] == "start"
        start(hooks, config, environment)
      elsif argv.size == 2 && argv[0] == "db"
        SchemaCLI.run(migrations, [argv[1], "--db", config.string("database.path")])
      else
        $stderr.puts USAGE
        2
      end
    rescue Config::Error, Kilau::DB::Error => e
      $stderr.puts "error: #{e.message}"
      1
    end

    def self.start(hooks, config, environment)
      pool = Kilau::DB::Pool.new(config.string("database.path"), config.int("database.pool"))
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
