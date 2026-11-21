module Kilau
  # What every page of an app needs to draw itself, in one object so a
  # template takes a single extra argument: who is signed in (an empty email
  # is a guest), the CSRF token its forms carry, and the layout's name (a
  # hook for apps with more than one layout; no template reads it yet).
  # The email is plain text here; the template escapes it.
  class Page
    attr_reader :user_email, :token, :layout

    def initialize(user_email, token, layout = "web")
      @user_email = user_email
      @token = token
      @layout = layout
    end

    def signed_in? = !@user_email.empty?

    # The token is read from request.session at the call, never through a
    # local the caller writes to afterwards (Spinel's inference does not
    # converge for that shape).
    def self.for(request, user_email = "") = new(user_email, Csrf.token(request.session), "web")
  end
end
