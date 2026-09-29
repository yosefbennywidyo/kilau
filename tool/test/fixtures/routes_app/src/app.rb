require_relative "controllers/notes"

class NotesApp < Kilau::Hooks
  def routes
    home = Kilau::Routes.new.add("/", Kilau::Controller.get { |app_context, request| Kilau::Format.render("home") })
    Kilau::AppRoutes.with_default_routes.add(home).add(NotesController.routes)
  end
end
