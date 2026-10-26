module Kilau
  # Finds the route for a request and turns what the handler raises into
  # a status: Kilau::Error keeps its own, anything else is a logged 500.
  class Dispatcher
    OVERRIDABLE = ["PATCH", "PUT", "DELETE"]

    def initialize(app_routes, app_context)
      @routes = app_routes.routes
      @trie = RouteTrie.build(@routes)
      @app_context = app_context
    end

    def call(request)
      Dispatcher.apply_override(request)
      verb = request.request_method
      match_verb = verb == "HEAD" ? "GET" : verb
      # The winners are the matching routes of the lowest specificity: a static
      # route beats a :param one at the same depth, whatever the declaration order (Fase C).
      best = nil
      winners = []
      # The trie names the matching routes; declaration order is kept, so the
      # first winner with the request's verb is the one declared first (Fase D).
      @trie.matches(request.path).sort.each do |index|
        route = @routes[index]
        if best.nil? || route.specificity < best
          best = route.specificity
          winners = [route]
        elsif route.specificity == best
          winners << route
        end
      end
      if winners.empty?
        response = Dispatcher.error_response(404, "no route for #{verb} #{request.path}")
        return verb == "HEAD" ? response.without_body : response
      end
      chosen = nil
      winners.each { |route| chosen = route if chosen.nil? && route.verb == match_verb }
      unless chosen.nil?
        bad = chosen.bad_param(request.path)
        raise Kilau::Error::BadRequest, "#{bad} must be a whole number" unless bad.nil?
        request.path_params = chosen.match(request.path)
        response = chosen.endpoint.call(@app_context, request)
        return verb == "HEAD" ? response.without_body : response
      end
      allowed = []
      winners.each { |route| allowed << route.verb }
      allowed << "HEAD" if allowed.include?("GET") && !allowed.include?("HEAD")
      allowed = allowed.uniq.sort
      return Dispatcher.options_response(allowed) if verb == "OPTIONS"
      response = Dispatcher.method_not_allowed(allowed, verb, request.path)
      verb == "HEAD" ? response.without_body : response
    rescue Kilau::Error => e
      response = Dispatcher.error_response(e.status, e.message)
      request.request_method == "HEAD" ? response.without_body : response
    rescue StandardError => e
      $stderr.puts "kilau: #{e.class}: #{e.message}"
      response = Dispatcher.error_response(500, "internal server error")
      request.request_method == "HEAD" ? response.without_body : response
    end

    def self.error_response(status, message)
      reason = Response::REASONS.fetch(status, "Error")
      body = "<!doctype html>\n<title>#{status} #{reason}</title>\n<h1>#{status} #{reason}</h1>\n<p>#{Html.escape(message)}</p>\n"
      Response.new(status, "text/html; charset=utf-8", body)
    end

    def self.method_not_allowed(allowed, verb, path)
      response = error_response(405, "method #{verb} not allowed for #{path}")
      response.set_header("allow", allowed.join(", "))
      response
    end

    def self.options_response(allowed)
      response = Format.empty(204)
      response.set_header("allow", allowed.join(", "))
      response
    end

    # A browser form can only POST; _method=patch|put|delete says what it meant.
    def self.apply_override(request)
      return nil unless request.request_method == "POST"
      wanted = request.form_value("_method")
      return nil if wanted.nil?
      verb = wanted.upcase
      request.override_method(verb) if OVERRIDABLE.include?(verb)
      nil
    end
  end
end
