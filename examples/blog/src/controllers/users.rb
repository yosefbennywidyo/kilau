class UsersController < Kilau::Controller
  def self.routes
    Kilau::Routes.new
      .add("/signup", get { |app_context, request| new_form(app_context, request) })
      .add("/signup", post { |app_context, request| create(app_context, request) })
  end

  def self.new_form(app_context, request) = Kilau::Format.render(Views::Users.new_form("", [], PageHelper.for(app_context, request)))

  def self.create(app_context, request)
    email = request.form_value("email").to_s
    result = User.register(app_context.db, email, request.form_value("password").to_s)
    user = result[0]
    if user.nil?
      return Kilau::Format.render(Views::Users.new_form(User.normalize_email(email), result[1], PageHelper.for(app_context, request)), status: 422)
    end
    request.session.reset
    request.session["user_id"] = user.id.to_s
    Kilau::Csrf.token(request.session)
    Kilau::Format.redirect("/posts")
  end
end
