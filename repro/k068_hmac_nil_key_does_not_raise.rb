# K-068: OpenSSL::HMAC with a nil key (reached through a parameter that also gets Strings) or a nil data argument raises TypeError in CRuby; Spinel treats nil as "" and returns the digest of the empty string
require "openssl"
def mac(key, data)
  OpenSSL::HMAC.hexdigest("SHA256", key, data)
end
def try(label)
  r = begin
    yield
  rescue => e
    e.class
  end
  puts "#{label}: #{r}"
end
try("string key") { mac("k", "x") }
try("nil key through the parameter") { mac(nil, "x") }
try("nil data") { OpenSSL::HMAC.hexdigest("SHA256", "k", nil) }
try("literal nil key") { OpenSSL::HMAC.hexdigest("SHA256", nil, "x") }
