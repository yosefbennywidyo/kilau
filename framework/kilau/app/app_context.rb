module Kilau
  # What every handler needs besides the request, built once at boot and
  # shared by every connection thread (spec §3.1).
  class AppContext
    attr_reader :db, :config, :environment

    def initialize(db, config, environment)
      @db = db
      @config = config
      @environment = environment
    end
  end

  # An app's hooks (Loco's Hooks): subclasses define routes.
  class Hooks
    def routes
      raise NotImplementedError, "an app must define routes"
    end

    # What serves the app's requests: the route table by default. An app
    # built with `kilau gen routes` overrides it with the generated
    # dispatcher, which calls each handler without a stored proc (K-012).
    def dispatcher(app_context) = Dispatcher.new(routes, app_context)
  end
end
