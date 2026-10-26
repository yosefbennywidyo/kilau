module Kilau
  class Route
    attr_reader :verb, :pattern, :endpoint, :shape_key, :specificity
    attr_accessor :handler_label

    def initialize(verb, pattern, endpoint)
      @verb = verb
      @pattern = pattern
      @endpoint = endpoint
      @segments = Route.split(pattern)
      # Two routes share a shape_key when they have the same literal at every
      # static position, whatever their param names (Fase C).
      @shape_key = @segments.map { |segment| segment.start_with?(":") ? "\0" : segment }.join("/")
      # Bit set for each param segment, MSB = leftmost: a lower value is a more
      # static route, which wins at the same depth (Fase C).
      @specificity = 0
      i = 0
      while i < @segments.size
        @specificity |= (1 << (@segments.size - 1 - i)) if @segments[i].start_with?(":")
        i += 1
      end
    end

    def self.split(path) = path.split("/").reject { |segment| segment.empty? }

    # The name of a param segment: `:id` and `:id<int>` are both "id" (Fase E).
    def self.param_name(segment) = segment.delete_prefix(":").sub(/<int>\z/, "")

    # The name of the first typed (`<int>`) param whose value in path is not a
    # whole number, or nil. The dispatcher answers 400 for it, as path_int does.
    def bad_param(path)
      parts = path.split("/")
      parts.shift
      i = 0
      while i < @segments.size
        segment = @segments[i]
        if segment.start_with?(":") && segment.end_with?("<int>") && !parts[i].to_s.match?(/\A\d{1,18}\z/)
          return Route.param_name(segment)
        end
        i += 1
      end
      nil
    end

    # The :name segments of a matching path, or nil.
    def match(path)
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
          params[Route.param_name(segment)] = part
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
      app_context.db.query_first("SELECT 1", Sqlite::Binds.new) { |row| row.int(0) }
      Format.json("{\"ok\":true}")
    rescue Sqlite::Error
      Format.json("{\"ok\":false}", status: 503)
    end

    def initialize
      @routes = []
    end

    def add(routes)
      routes.routes.each do |route|
        conflict = nil
        @routes.each { |existing| conflict = existing if conflict.nil? && existing.verb == route.verb && existing.shape_key == route.shape_key }
        raise ArgumentError, "duplicate route: #{route.verb} #{route.pattern} conflicts with #{conflict.verb} #{conflict.pattern} (same shape)" unless conflict.nil?
        route.handler_label = "#{route.verb} #{route.pattern}##{@routes.size}"
        @routes << route
      end
      self
    end
  end
end
