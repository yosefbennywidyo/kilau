module Kilau
  # Finds the route for a request and turns what the handler raises into
  # a status: Kilau::Error keeps its own, anything else is a logged 500.
  class Dispatcher
    OVERRIDABLE = ["PATCH", "PUT", "DELETE"]

    def initialize(app_routes, app_context)
      @routes = app_routes.routes
      @app_context = app_context
    end

    def call(request)
      override_method(request)
      @routes.each do |route|
        next unless route.verb == request.request_method
        params = route.match_path(request.path)
        next if params.nil?
        request.path_params = params
        return route.endpoint.call(@app_context, request)
      end
      Dispatcher.error_response(404, "no route for #{request.request_method} #{request.path}")
    rescue Kilau::Error => e
      Dispatcher.error_response(e.status, e.message)
    rescue StandardError => e
      $stderr.puts "kilau: #{e.class}: #{e.message}"
      Dispatcher.error_response(500, "internal server error")
    end

    def self.error_response(status, message)
      reason = Response::REASONS.fetch(status, "Error")
      body = "<!doctype html>\n<title>#{status} #{reason}</title>\n<h1>#{status} #{reason}</h1>\n<p>#{Html.escape(message)}</p>\n"
      Response.new(status, "text/html; charset=utf-8", body)
    end

    private

    # A browser form can only POST; _method=patch|put|delete says what it meant.
    def override_method(request)
      return nil unless request.request_method == "POST"
      wanted = request.form_value("_method")
      return nil if wanted.nil?
      verb = wanted.upcase
      request.override_method(verb) if OVERRIDABLE.include?(verb)
      nil
    end
  end
end
