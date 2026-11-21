class SessionsController < Kilau::Controller
  def self.routes
    Kilau::Routes.new
      .add("/login", get { |app_context, request| new_form(app_context, request) })
      .add("/login", post { |app_context, request| create(app_context, request) })
      .add("/logout", post { |app_context, request| destroy(app_context, request) })
  end

  def self.new_form(app_context, request) = Kilau::Format.render(Views::Sessions.new_form("", [], PageHelper.for(app_context, request)))

  # An unknown email and a wrong password answer identically, in body and in
  # cost: the unknown email still pays for one PBKDF2 against a dummy digest.
  def self.create(app_context, request)
    email = User.normalize_email(request.form_value("email").to_s)
    password = request.form_value("password").to_s
    user = User.find_by_email(app_context.db, email)
    if user.nil?
      Kilau::Password.verify?(password, Kilau::Password.dummy_digest)
    elsif user.authenticate?(password)
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
