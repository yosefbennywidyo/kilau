module Kilau
  # Responses a handler returns (loco_rs::controller::format).
  module Format
    def self.render(html, status: 200) = Response.new(status, "text/html; charset=utf-8", html)
    def self.json(text, status: 200) = Response.new(status, "application/json", text)
    def self.text(text, status: 200) = Response.new(status, "text/plain; charset=utf-8", text)
    def self.empty(status) = Response.new(status, "text/plain; charset=utf-8", "")

    # 303, so a browser follows a POST, PATCH or DELETE with a GET.
    def self.redirect(path)
      response = Response.new(303, "text/plain; charset=utf-8", "")
      response.set_header("location", path)
      response
    end
  end
end
