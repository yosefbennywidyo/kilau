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
      MIN_SECRET_BYTES = 32

      # The dispatcher itself when the app does not use sessions (neither
      # session.secret nor session.enabled is set): old apps are unchanged.
      def self.wrap(dispatcher, app_context)
        config = app_context.config
        enabled = config.key?("session.enabled") && config.bool("session.enabled")
        return dispatcher unless config.key?("session.secret") || enabled
        secure = config.key?("session.secure") && config.bool("session.secure")
        new(dispatcher, secret_for(config, app_context.environment), secure)
      end

      def self.development_key_warning
        "kilau: session.secret is not set; using the built-in development key (never in production)"
      end

      # The configured secret (file or KILAU_SESSION_SECRET), never an empty
      # one. Without one only the environments named "development" and "test"
      # get the fixed key: every other name ("production", "staging", a typo)
      # must configure its own, so no deployment signs with a key anyone can
      # read in this repo. Outside those two a secret also has to be at least
      # MIN_SECRET_BYTES long: the cookie is an offline guessing oracle for
      # its key.
      def self.secret_for(config, environment)
        local = environment == "development" || environment == "test"
        if config.key?("session.secret")
          secret = config.string("session.secret")
          raise Config::Error, "session.secret must not be empty" if secret.empty?
          if !local && secret.bytesize < MIN_SECRET_BYTES
            raise Config::Error, "session.secret must be at least #{MIN_SECRET_BYTES} bytes outside development and test; generate one with: openssl rand -hex 32"
          end
          return secret
        end
        unless local
          raise Config::Error, "session.enabled needs session.secret (or KILAU_SESSION_SECRET) in #{environment}; generate one with: openssl rand -hex 32"
        end
        $stderr.puts development_key_warning if environment == "development"
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
        response.add_set_cookie(Cookie.build(Session::COOKIE, session.to_cookie_value, Session::MAX_AGE, @secure)) if session.changed?
        response
      end

      # A refusal of the guard's own carries no session cookie.
      def refused(request, response)
        request.request_method == "HEAD" ? response.without_body : response
      end
    end
  end
end
