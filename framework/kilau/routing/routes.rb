module Kilau
  class Route
    attr_reader :verb, :pattern, :endpoint

    def initialize(verb, pattern, endpoint)
      @verb = verb
      @pattern = pattern
      @endpoint = endpoint
      @segments = Route.split(pattern)
    end

    def self.split(path) = path.split("/").reject { |segment| segment.empty? }

    # The :name segments of a matching path, or nil.
    def match_path(path)
      parts = path.split("/")
      parts.shift
      return nil if parts.size != @segments.size && !(parts.empty? && @segments.empty?)
      params = {}
      i = 0
      while i < @segments.size
        segment = @segments[i]
        part = parts[i].to_s
        if segment.start_with?(":")
          return nil if part.empty?
          params[segment[1, segment.size - 1]] = part
        elsif segment != part
          return nil
        end
        i += 1
      end
      params
    end
  end

  # One controller's routes under a prefix (Loco's Routes::new().prefix()).
  class Routes
    attr_reader :routes

    def initialize
      @prefix = ""
      @routes = []
    end

    def prefix(name)
      trimmed = Route.split(name).join("/")
      @prefix = trimmed.empty? ? "" : "/" + trimmed
      self
    end

    def add(path, endpoint)
      full = @prefix + (path == "/" ? "" : path)
      @routes << Route.new(endpoint.verb, full.empty? ? "/" : full, endpoint)
      self
    end
  end

  # Every route of the app, the defaults first (Loco's AppRoutes).
  class AppRoutes
    attr_reader :routes

    def self.with_default_routes
      defaults = Routes.new
        .add("/_ping", Controller.get { |app_context, request| AppRoutes.ping(app_context, request) })
        .add("/_health", Controller.get { |app_context, request| AppRoutes.health(app_context, request) })
      new.add(defaults)
    end

    def self.ping(app_context, request) = Format.json("{\"ok\":true}")

    def self.health(app_context, request)
      app_context.db.query_first("SELECT 1", Kilau::DB::Binds.new) { |row| row.int(0) }
      Format.json("{\"ok\":true}")
    rescue Kilau::DB::Error
      Format.json("{\"ok\":false}", status: 503)
    end

    def initialize
      @routes = []
    end

    def add(routes)
      routes.routes.each { |route| @routes << route }
      self
    end
  end
end
