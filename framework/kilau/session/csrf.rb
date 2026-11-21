require "securerandom"
require "openssl"

module Kilau
  # CSRF protection by a per-session token (the synchronizer pattern): the
  # token lives in the signed session, a form carries it in the field
  # authenticity_token, and an unsafe request is accepted only when the two
  # match. SameSite=Lax on the session cookie is a second layer, not a
  # replacement for this.
  module Csrf
    FIELD = "authenticity_token"
    SAFE_VERBS = ["GET", "HEAD", "OPTIONS"]

    module_function

    # The session's token, made on first use. Making it marks the session
    # changed, which is why the GET that renders a form sets the cookie.
    def token(session)
      existing = session["csrf"]
      return existing unless existing.nil? || existing.empty?
      fresh = SecureRandom.hex(32)
      session["csrf"] = fresh
      fresh
    end

    def safe_verb?(verb) = SAFE_VERBS.include?(verb)

    # False for a missing session token, a missing field, a different length
    # (checked first: fixed_length_secure_compare needs equal lengths) or a
    # different value. The field is read whatever the verb: a form that
    # overrides POST to PATCH is checked on the wire verb, POST, before the
    # dispatcher applies the override.
    def verify?(request)
      session = request.session
      return false if session.nil?
      expected = session["csrf"]
      given = request.form_value(FIELD)
      return false if expected.nil? || given.nil?
      return false if expected.empty? || expected.bytesize != given.bytesize
      OpenSSL.fixed_length_secure_compare(expected, given)
    end
  end
end
