module Kilau
  # Cookie header parsing and Set-Cookie line building. Values are taken
  # as-is (no percent-decoding): callers store URL-safe tokens.
  module Cookie
    module_function

    # "a=1; b=x=y" -> {"a"=>"1", "b"=>"x=y"}. A piece without "=" is skipped;
    # the first "=" splits name from value, so "=" may appear inside a value.
    # A name that appears twice keeps its FIRST value: a browser sends the
    # cookie with the more specific Path/Domain first, so the later one is the
    # one a sibling subdomain could have tossed in. A header that is not valid
    # text parses as no cookies at all.
    def parse(header)
      out = {}
      # A header with bytes that are not valid text is one stray byte away from
      # an exception in split; it carries no cookie we could have set.
      return out unless header.valid_encoding?
      header.split(";").each do |piece|
        piece = piece.strip
        eq = piece.index("=")
        next if eq.nil? || eq == 0
        name = piece[0, eq]
        out[name] = piece[eq + 1, piece.size - eq - 1] unless out.key?(name)
      end
      out
    end

    # Always Path=/; HttpOnly; SameSite=Lax. Max-Age only when >= 0 (0
    # expires the cookie), Secure only when asked.
    def build(name, value, max_age, secure)
      line = "#{name}=#{value}; Path=/; HttpOnly; SameSite=Lax"
      line << "; Max-Age=#{max_age}" if max_age >= 0
      line << "; Secure" if secure
      line
    end
  end
end
