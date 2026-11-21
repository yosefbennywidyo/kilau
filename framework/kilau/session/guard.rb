module Kilau
  class Session
    # Wraps anything with call(request) -> Response (the plain Dispatcher or
    # the one `kilau gen routes` generates): loads the session from its
    # cookie into request.session, refuses an unsafe request without a valid
    # CSRF token, and sets the session cookie when the handler changed the
    # session. It sits outside the dispatcher because the generated one
    # duplicates Dispatcher#call, so neither has to know about sessions.
    class Guard
      DEVELOPMENT_SECRET = "kilau-development-session-secret-do-not-use-in-production"
      MAX_AGE = 1209600

      # The dispatcher itself when the app does not use sessions (neither
      # session.secret nor session.enabled is set): old apps are unchanged.
      def self.wrap(dispatcher, app_context)
        config = app_context.config
        enabled = config.key?("session.enabled") && config.bool("session.enabled")
        return dispatcher unless config.key?("session.secret") || enabled
        secure = config.key?("session.secure") && config.bool("session.secure")
        new(dispatcher, secret_for(config, app_context.environment), secure)
      end

      # The configured secret (file or KILAU_SESSION_SECRET), never an empty
      # one. Without one only development and test get the fixed key, so a
      # production app cannot run on a key anyone can read in this repo.
      def self.secret_for(config, environment)
        if config.key?("session.secret")
          secret = config.string("session.secret")
          raise Config::Error, "session.secret must not be empty" if secret.empty?
          return secret
        end
        if environment == "production"
          raise Config::Error, "session.enabled needs session.secret (or KILAU_SESSION_SECRET) in production"
        end
        $stderr.puts "kilau: session.secret is not set; using the built-in development key (never in production)" if environment == "development"
        DEVELOPMENT_SECRET
      end

      def initialize(inner, secret, secure)
        @inner = inner
        @secret = secret
        @secure = secure
      end

      # Errors from this class's own work (reading the token can raise
      # BadRequest on broken percent-encoding) become responses the way
      # Dispatcher#call does it: that rescue is inside @inner, too late for them.
      def call(request)
        guarded(request)
      rescue Kilau::Error => e
        refused(request, Dispatcher.error_response(e.status, e.message))
      rescue StandardError => e
        $stderr.puts "kilau: #{e.class}: #{e.message}"
        refused(request, Dispatcher.error_response(500, "internal server error"))
      end

      private

      def guarded(request)
        session = Session.load(request.cookie(Session::COOKIE), @secret)
        request.session = session
        unless Csrf.safe_verb?(request.request_method) || Csrf.verify?(request)
          return refused(request, Dispatcher.error_response(403, "invalid authenticity token"))
        end
        response = @inner.call(request)
        response.add_set_cookie(Cookie.build(Session::COOKIE, session.to_cookie_value, MAX_AGE, @secure)) if session.changed?
        response
      end

      # A refusal of the guard's own carries no session cookie.
      def refused(request, response)
        request.request_method == "HEAD" ? response.without_body : response
      end
    end
  end
end
