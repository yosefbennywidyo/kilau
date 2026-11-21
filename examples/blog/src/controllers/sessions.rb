class SessionsController < Kilau::Controller
  def self.routes
    Kilau::Routes.new
      .add("/login", get { |app_context, request| new_form(app_context, request) })
      .add("/login", post { |app_context, request| create(app_context, request) })
      .add("/logout", post { |app_context, request| destroy(app_context, request) })
  end

  def self.new_form(app_context, request) = Kilau::Format.render(Views::Sessions.new_form("", [], PageHelper.for(app_context, request)))

  # An unknown email and a wrong password answer identically, in body and in
  # cost. There is ONE verify? call whatever the user: an unknown email is
  # checked against a dummy digest, so the PBKDF2 always runs and the
  # response time does not tell whether the address exists. verify? comes
  # first in the && so no later edit can make it conditional on the user.
  # (An empty or over-long password is refused before the PBKDF2 for every
  # user alike, so that shortcut tells nothing about any address.)
  def self.create(app_context, request)
    email = User.normalize_email(request.form_value("email").to_s)
    password = request.form_value("password").to_s
    user = User.find_by_email(app_context.db, email)
    digest = user.nil? ? Kilau::Password.dummy_digest : user.password_digest
    ok = Kilau::Password.verify?(password, digest) && !user.nil?
    if ok
      # A fresh session before the login is stored, so a session id planted
      # beforehand is worthless (session fixation).
      request.session.reset
      request.session["user_id"] = user.id.to_s
      Kilau::Csrf.token(request.session)
      return Kilau::Format.redirect("/posts")
    end
    Kilau::Format.render(Views::Sessions.new_form(email, ["email atau sandi salah"], PageHelper.for(app_context, request)), status: 422)
  end

  def self.destroy(app_context, request)
    request.session.reset
    Kilau::Format.redirect("/")
  end
end
