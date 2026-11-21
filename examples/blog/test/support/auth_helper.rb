# Shared by the blog's request tests: the test config (a session secret, so
# the CSRF guard wraps the app) and the steps a browser takes through the
# forms: read the token out of a rendered form, sign up.
module AuthHelper
  CONFIG = "app:\n  name: blog\nsession:\n  secret: \"blog-test-session-secret-0123456789abcdef-0123\"\n"
  TOKEN = /name="authenticity_token" value="([0-9a-f]+)"/
  PASSWORD = "correct horse"

  # The session's token, as a form on `path` shows it ("" if it shows none).
  def self.token(client, path)
    found = client.get(path).body.match(TOKEN)
    found.nil? ? "" : found[1]
  end

  def self.sign_up(client, email, password)
    client.post("/signup", { "email" => email, "password" => password, "authenticity_token" => token(client, "/signup") })
  end
end
