require "kilau"
T = Kilau::Testing
P = Kilau::Password

def raises?
  yield
  false
rescue StandardError
  true
end

IT = 1000
d = P.digest("correct horse", IT)
T.check("digest has the pbkdf2 shape") { d.match?(/\Apbkdf2\$sha256\$1000\$[0-9a-f]{32}\$[0-9a-f]{64}\z/) }
T.check("verify? accepts the right password") { P.verify?("correct horse", d) }
T.check("verify? rejects a wrong password") { !P.verify?("correct horsf", d) }
T.check("verify? rejects a prefix of the password") { !P.verify?("correct hors", d) }
T.check("two digests of one password differ (salt)") { P.digest("correct horse", IT) != d }
T.check("the other digest verifies too") { P.verify?("correct horse", P.digest("correct horse", IT)) }

# The iteration count is recorded and used: rewriting it breaks verification.
other = d.sub("$1000$", "$1001$")
T.check("the recorded iteration count is used") { !P.verify?("correct horse", other) }
d2 = P.digest("correct horse", 2000)
T.check("another count is recorded and verifies") { d2.include?("$2000$") && P.verify?("correct horse", d2) }
T.check("DEFAULT_ITERATIONS is the digest default") { P::DEFAULT_ITERATIONS >= 100_000 && P::DEFAULT_ITERATIONS <= 600_000 }

# Broken digests: false, never a raise.
parts = d.split("$")
bad = [
  "x", "", nil, "pbkdf2$sha256$0$aa$bb",
  d.upcase, d + "$extra", d + "\n", "\n" + d,
  "pbkdf2$sha256$1234567890$#{parts[3]}$#{parts[4]}",
  "pbkdf2$sha256$01000$#{parts[3]}$#{parts[4]}",
  "pbkdf2$sha1$1000$#{parts[3]}$#{parts[4]}",
  "pbkdf2$sha256$1000$#{parts[3].upcase}$#{parts[4]}",
  "pbkdf2$sha256$1000$#{parts[3]}$#{parts[4].upcase}",
  "pbkdf2$sha256$1000$#{parts[3][0, 30]}$#{parts[4]}",
  "pbkdf2$sha256$1000$#{parts[3]}$#{parts[4][0, 62]}"
]
bad.each_with_index do |b, i|
  r = nil
  err = raises? { r = P.verify?("correct horse", b) }
  T.check("broken digest #{i} is false and does not raise") { !err && r == false }
end
T.check("nil plain is false") { P.verify?(nil, d) == false }
T.check("empty plain is false") { P.verify?("", d) == false }

# Over-long plain: a 999_999_999-iteration digest would take minutes if run.
huge = "pbkdf2$sha256$999999999$#{parts[3]}$#{parts[4]}"
T.check("a 1025-byte plain returns false without hashing") { P.verify?("a" * 1025, huge) == false }
T.check("a 1024-byte plain digests and verifies") do
  long = "a" * 1024
  P.verify?(long, P.digest(long, 10))
end
T.check("a multibyte plain over 1024 bytes is refused by bytes") { raises? { P.digest("é" * 513, 10) } }
T.check("digest raises on a 1025-byte plain") { raises? { P.digest("a" * 1025, 10) } }
T.check("digest raises on nil") { raises? { P.digest(nil, 10) } }
T.check("digest raises on empty") { raises? { P.digest("", 10) } }
T.check("digest raises on zero iterations") { raises? { P.digest("pw", 0) } }
T.check("digest raises on negative iterations") { raises? { P.digest("pw", -5) } }
T.check("MAX_BYTES is 1024") { P::MAX_BYTES == 1024 }

# The dummy digest never verifies and has the default count.
dd = P.dummy_digest
T.check("dummy_digest has the shape and the default count") do
  dd.match?(/\Apbkdf2\$sha256\$#{P::DEFAULT_ITERATIONS}\$[0-9a-f]{32}\$[0-9a-f]{64}\z/)
end
T.check("dummy_digest is stable") { P.dummy_digest == dd }
T.check("nothing verifies against dummy_digest") do
  r1 = P.verify?("hunter2hunter2", dd)
  r2 = P.verify?("correct horse", dd)
  r3 = P.verify?("", dd)
  r4 = P.verify?(nil, dd)
  r1 == false && r2 == false && r3 == false && r4 == false
end

# RFC 7914 section 11: PBKDF2-HMAC-SHA-256, P="passwd", S="salt", c=1, dkLen=64.
rfc = OpenSSL::PKCS5.pbkdf2_hmac("passwd", "salt", 1, 64, "sha256").unpack1("H*")
T.check("RFC 7914 vector") do
  rfc == "55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783"
end
