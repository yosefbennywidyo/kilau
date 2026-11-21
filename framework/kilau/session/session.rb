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
      begin
        data = verified_data(cookie_value, secret)
        session.replace(data) unless data.nil?
      rescue StandardError
        # A payload that verifies yet will not decode: treat as empty.
      end
      session
    end

    # The decoded content, or nil unless the cookie is well formed and its
    # MAC matches. The MAC is compared only at equal length, in constant time.
    def self.verified_data(cookie_value, secret)
      parts = cookie_value.split(".", -1)
      return nil unless parts.size == 2
      hex_payload = parts[0]
      mac = parts[1]
      return nil if hex_payload.empty? || !hex_payload.match?(/\A[0-9a-f]+\z/)
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, hex_payload)
      return nil unless mac.size == expected.size
      return nil unless OpenSSL.fixed_length_secure_compare(mac, expected)
      return nil if hex_payload.size.odd?
      Form.decode([hex_payload].pack("H*"))
    end

    def initialize(secret)
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
