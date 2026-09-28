require_relative "models/posts"
require_relative "views/posts"
require_relative "controllers/posts"

class App < Kilau::Hooks
  def routes
    home = Kilau::Routes.new.add("/", Kilau::Controller.get { |app_context, request| Kilau::Format.redirect("/posts") })
    Kilau::AppRoutes.with_default_routes.add(home).add(PostsController.routes)
  end
end
