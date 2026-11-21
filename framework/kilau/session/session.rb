require "openssl"

module Kilau
  # A signed-cookie session: a Hash[String, String] carried in the cookie as
  # <hex(payload)>.<hex(hmac)>, where payload is Form.encode of the content
  # and hmac is HMAC-SHA256 of the hex payload under the app secret. A cookie
  # that fails any check (shape, hex, MAC, payload decoding) loads as an
  # empty session and never raises: a bad cookie is not an error response.
  class Session
    COOKIE = "kilau_session"

    def self.load(cookie_value, secret)
      session = new(secret)
      return session if cookie_value.nil?
      hex_payload = verified_hex(cookie_value, secret)
      return session if hex_payload.nil?
      begin
        session.replace(Form.decode([hex_payload].pack("H*")))
      rescue Kilau::Error::BadRequest
        # Verified yet not valid form text (Form.unescape refuses it): empty.
      end
      session
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
      @data[key] = value
      @changed = true
    end

    def delete(key)
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

    def to_cookie_value
      hex_payload = Form.encode(@data).unpack1("H*")
      "#{hex_payload}.#{OpenSSL::HMAC.hexdigest("SHA256", @secret, hex_payload)}"
    end

    def replace(data)
      @data = data
    end
  end
end
