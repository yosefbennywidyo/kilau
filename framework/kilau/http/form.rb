require "uri"

module Kilau
  # application/x-www-form-urlencoded text as a flat Hash[String, String];
  # the last value of a repeated name wins.
  module Form
    def self.decode(text)
      out = {}
      text.split("&").each do |pair|
        next if pair.empty?
        eq = pair.index("=")
        name = eq.nil? ? pair : pair[0, eq]
        value = eq.nil? ? "" : pair[eq + 1, pair.size - eq - 1]
        out[unescape(name)] = unescape(value)
      end
      out
    end

    def self.encode(fields)
      fields.map { |name, value| "#{URI.encode_www_form_component(name)}=#{URI.encode_www_form_component(value)}" }.join("&")
    end

    # Every % must start two hex digits. Spinel's URI decodes "%zz" to a
    # NUL byte and keeps "%4" as written where CRuby raises
    # (docs/CATALOG.md K-011), so the check is done here for both.
    def self.unescape(text)
      i = text.index("%")
      until i.nil?
        pair = text[i + 1, 2].to_s
        raise Kilau::Error::BadRequest, "malformed percent-encoding" unless pair.match?(/\A[0-9A-Fa-f]{2}\z/)
        i = text.index("%", i + 3)
      end
      URI.decode_www_form_component(text)
    rescue ArgumentError
      raise Kilau::Error::BadRequest, "malformed percent-encoding"
    end
  end
end
