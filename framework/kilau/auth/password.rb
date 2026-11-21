require "securerandom"
require "openssl"

module Kilau
  # Password hashing: PBKDF2-HMAC-SHA256 with a per-password random salt.
  # A stored digest is "pbkdf2$sha256$<iterations>$<salt hex>$<hash hex>";
  # the iteration count travels with the digest so the default can rise
  # later without locking old users out.
  #
  # verify? never raises on bad input and never runs PBKDF2 before the
  # digest's shape and the plain's length are checked: a corrupted stored
  # value or a huge submitted password cannot make a login spin.
  # Length POLICY (a minimum, say) belongs to the model, not here.
  class Password
    MAX_BYTES = 1024

    # OWASP's PBKDF2-HMAC-SHA256 figure. bench/password_cost.rb (2026-11-21,
    # AC power): one digest takes ~642 ms under Spinel -O2 (Spinel runs its
    # PBKDF2 in Ruby, ~7.5x slower than CRuby's 85 ms), under the ~1 s limit.
    DEFAULT_ITERATIONS = 600_000

    SHAPE = /\Apbkdf2\$sha256\$[1-9][0-9]{0,8}\$[0-9a-f]{32}\$[0-9a-f]{64}\z/

    # A fixed digest no password verifies against (its hash is not the
    # PBKDF2 of any known input). verify? against it runs one full PBKDF2
    # at DEFAULT_ITERATIONS, so a login for an unknown email costs the same
    # as one for a known email with a wrong password. A constant, so there
    # is no lazy initialisation and no first-call race.
    DUMMY_DIGEST = "pbkdf2$sha256$#{DEFAULT_ITERATIONS}$" \
                   "00112233445566778899aabbccddeeff$" \
                   "5f4dcc3b5aa765d61d8327deb882cf99" \
                   "d41d8cd98f00b204e9800998ecf8427e"

    def self.dummy_digest
      DUMMY_DIGEST
    end

    def self.digest(plain, iterations = DEFAULT_ITERATIONS)
      raise ArgumentError, "password is required" if plain.nil? || plain.empty?
      raise ArgumentError, "password is longer than #{MAX_BYTES} bytes" if plain.bytesize > MAX_BYTES
      raise ArgumentError, "iterations must be at least 1" if iterations < 1
      salt = SecureRandom.random_bytes(16)
      hash = OpenSSL::PKCS5.pbkdf2_hmac(plain, salt, iterations, 32, "sha256")
      "pbkdf2$sha256$#{iterations}$#{salt.unpack1("H*")}$#{hash.unpack1("H*")}"
    end

    def self.verify?(plain, digest)
      return false if plain.nil? || plain.empty? || plain.bytesize > MAX_BYTES
      return false if digest.nil? || !digest.match?(SHAPE)
      parts = digest.split("$", -1)
      iterations = parts[2].to_i
      salt = [parts[3]].pack("H*")
      expected = parts[4]
      actual = OpenSSL::PKCS5.pbkdf2_hmac(plain, salt, iterations, 32, "sha256").unpack1("H*")
      OpenSSL.fixed_length_secure_compare(actual, expected)
    end
  end
end
