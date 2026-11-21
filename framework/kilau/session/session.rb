require "openssl"

module Kilau
  # A signed-cookie session: a Hash[String, String] carried in the cookie as
  # <hex(payload)>.<hex(hmac)>, where payload is Form.encode of the content
  # and hmac is HMAC-SHA256 of the hex payload under the app secret. A cookie
  # that fails any check (shape, hex, MAC, payload decoding) loads as an
  # empty session: a bad COOKIE never raises, bytes that are not valid text
  # included. A nil or empty secret and a cookie value that is not a String
  # do raise.
  #
  # The server enforces the lifetime: the payload carries the time it was
  # written (ISSUED_AT, a reserved key application code can neither read nor
  # write), and a cookie older than MAX_AGE seconds, or stamped more than
  # CLOCK_SKEW seconds in the future, or without a stamp, loads as an empty
  # session. The stamp is renewed whenever the cookie is written, so the
  # lifetime is absolute from the last change. Max-Age on the Set-Cookie
  # line is only the browser's copy of the same number.
  class Session
    COOKIE = "kilau_session"
    MAX_AGE = 1209600
    CLOCK_SKEW = 60
    ISSUED_AT = "_iat"

    def self.load(cookie_value, secret, now = Time.now.to_i)
      session = new(secret)
      return session if cookie_value.nil?
      return session unless cookie_value.valid_encoding?
      hex_payload = verified_hex(cookie_value, secret)
      return session if hex_payload.nil?
      begin
        data = Form.decode([hex_payload].pack("H*"))
        stamp = data.delete(ISSUED_AT)
        session.replace(data) if fresh?(stamp, now)
      rescue Kilau::Error::BadRequest
        # Verified yet not valid form text (Form.unescape refuses it): empty.
      end
      session
    end

    # A stamp is accepted when it is a plain number, not ahead of the clock
    # by more than CLOCK_SKEW, and less than MAX_AGE old.
    def self.fresh?(stamp, now)
      return false if stamp.nil? || !stamp.match?(/\A[0-9]{1,12}\z/)
      age = now - stamp.to_i
      age >= -CLOCK_SKEW && age < MAX_AGE
    end

    def self.reserved?(key)
      key.start_with?(ISSUED_AT)
    end

    # The hex payload, or nil unless the cookie is <even lowercase hex>.<64
    # lowercase hex> and the MAC matches. Both parts are checked for shape
    # before the constant-time compare, so it never sees unequal byte lengths.
    def self.verified_hex(cookie_value, secret)
      parts = cookie_value.split(".", -1)
      return nil unless parts.size == 2
      hex_payload = parts[0]
      mac = parts[1]
      return nil unless hex_payload.match?(/\A([0-9a-f]{2})+\z/)
      return nil unless mac.match?(/\A[0-9a-f]{64}\z/)
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, hex_payload)
      return nil unless OpenSSL.fixed_length_secure_compare(mac, expected)
      hex_payload
    end

    # A missing secret is a misconfiguration, never an anonymous session.
    def initialize(secret)
      raise ArgumentError, "session secret is required" if secret.nil? || secret.empty?
      @secret = secret
      @data = {}
      @changed = false
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      raise ArgumentError, "session key #{ISSUED_AT} is reserved" if Session.reserved?(key)
      @data[key] = value
      @changed = true
    end

    def delete(key)
      raise ArgumentError, "session key #{ISSUED_AT} is reserved" if Session.reserved?(key)
      @data.delete(key)
      @changed = true
    end

    def reset
      @data = {}
      @changed = true
      nil
    end

    def changed?
      @changed
    end

    def to_cookie_value(now = Time.now.to_i)
      stamped = @data.dup
      stamped[ISSUED_AT] = now.to_s
      hex_payload = Form.encode(stamped).unpack1("H*")
      "#{hex_payload}.#{OpenSSL::HMAC.hexdigest("SHA256", @secret, hex_payload)}"
    end

    def replace(data)
      @data = data.reject { |key, _| Session.reserved?(key) }
    end
  end
end
