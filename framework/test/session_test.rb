require "kilau"
T = Kilau::Testing

SECRET = "s3cret-key-for-tests"

s = Kilau::Session.new(SECRET)
T.check("COOKIE names the session cookie") { Kilau::Session::COOKIE == "kilau_session" }
T.check("a new session is empty and unchanged") { s["a"].nil? && !s.changed? }
s["user_id"] = "42"
s["note"] = "a=b&c d%é"
T.check("[]= stores and marks changed") { s["user_id"] == "42" && s.changed? }

cookie = s.to_cookie_value
back = Kilau::Session.load(cookie, SECRET)
T.check("to_cookie_value round-trips through load") { back["user_id"] == "42" && back["note"] == "a=b&c d%é" }
T.check("load alone does not mark changed") { !back.changed? }
T.check("the cookie value is hex.hex") { cookie.match?(/\A[0-9a-f]+\.[0-9a-f]{64}\z/) }

back.delete("user_id")
T.check("delete removes the key and marks changed") { back["user_id"].nil? && back.changed? }
fresh = Kilau::Session.load(cookie, SECRET)
fresh.reset
T.check("reset empties and marks changed") { fresh["note"].nil? && fresh.changed? }

def empty_session?(value, secret)
  Kilau::Session.load(value, secret).to_cookie_value == Kilau::Session.new(secret).to_cookie_value
end

def raises?
  yield
  false
rescue StandardError
  true
end

dot = cookie.index(".")
payload = cookie[0, dot]
mac = cookie[dot + 1, cookie.size - dot - 1]
flip = ->(str, i) { str[0, i] + (str[i] == "0" ? "1" : "0") + str[i + 1, str.size - i - 1] }

# Tamper inside a value (the "42"): without verification the changed value
# would show, and empty_session? compares the whole session.
vs = Kilau::Session.new(SECRET)
vs["user_id"] = "42"
vcookie = vs.to_cookie_value
vdot = vcookie.index(".")
vpayload = vcookie[0, vdot]
vmac = vcookie[vdot + 1, vcookie.size - vdot - 1]
vpos = vpayload.size - 1
vflip = vpayload[0, vpos] + (vpayload[vpos] == "0" ? "1" : "0")
T.check("an untampered single-value cookie is not empty") { !empty_session?(vcookie, SECRET) }
T.check("a changed value (valid hex) gives an empty session") { empty_session?(vflip + "." + vmac, SECRET) }
T.check("a 64-character mac with a multibyte character gives an empty session") do
  empty_session?(payload + "." + ("é" + mac[0, 63]), SECRET)
end
T.check("a nil secret raises instead of making an anonymous session") do
  raises? { Kilau::Session.load(cookie, nil) }
end
ks = Kilau::Session.new(SECRET)
ks["a&b=c%d é"] = "v"
T.check("a key with & = % and a multibyte character round-trips") do
  Kilau::Session.load(ks.to_cookie_value, SECRET)["a&b=c%d é"] == "v"
end

T.check("a different secret does not open the cookie") { empty_session?(cookie, "other-secret") }
T.check("one payload character changed gives an empty session") { empty_session?(flip.call(payload, 3) + "." + mac, SECRET) }
T.check("one hmac character changed gives an empty session") { empty_session?(payload + "." + flip.call(mac, 5), SECRET) }
T.check("a truncated cookie gives an empty session") { empty_session?(cookie[0, cookie.size - 10], SECRET) }
T.check("a truncated payload gives an empty session") { empty_session?(payload[0, 4] + "." + mac, SECRET) }
T.check("a non-hex cookie gives an empty session") { empty_session?("zzzz." + "g" * 64, SECRET) }
T.check("a cookie without a dot gives an empty session") { empty_session?(payload + mac, SECRET) }
T.check("a nil cookie gives an empty session") { empty_session?(nil, SECRET) }
T.check("an empty cookie gives an empty session") { empty_session?("", SECRET) }
T.check("an empty mac gives an empty session") { empty_session?(payload + ".", SECRET) }
T.check("extra dots give an empty session") { empty_session?(cookie + ".00", SECRET) }
T.check("a missing payload with a valid-length mac gives an empty session") { empty_session?("." + mac, SECRET) }
T.check("a forged payload signed with another secret is refused") do
  forged = Kilau::Session.new("evil")
  forged["user_id"] = "1"
  empty_session?(forged.to_cookie_value, SECRET)
end

# A payload that verifies but is not valid form text still gives an empty
# session instead of an error.
bad = "257a7a"   # hex of "%zz"
bad_mac = OpenSSL::HMAC.hexdigest("SHA256", SECRET, bad)
T.check("a verified but malformed payload gives an empty session") { empty_session?(bad + "." + bad_mac, SECRET) }
