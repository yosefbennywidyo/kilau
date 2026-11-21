require_relative "models/posts"
require_relative "models/users"
require_relative "views/posts"
require_relative "views/sessions"
require_relative "views/users"
require_relative "controllers/page_helper"
require_relative "controllers/posts"
require_relative "controllers/sessions"
require_relative "controllers/users"

class App < Kilau::Hooks
  def routes
    home = Kilau::Routes.new.add("/", Kilau::Controller.get { |app_context, request| Kilau::Format.redirect("/posts") })
    Kilau::AppRoutes.with_default_routes.add(home).add(PostsController.routes).add(SessionsController.routes).add(UsersController.routes)
  end
end
