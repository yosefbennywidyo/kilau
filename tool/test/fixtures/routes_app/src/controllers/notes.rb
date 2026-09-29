class NotesController < Kilau::Controller
  def self.routes
    Kilau::Routes.new.prefix("/notes/")
      .add("/", get { |c, r| list(c, r) })
      .add("/:id", get { |c, r| show(r.path_params.fetch("id")) })
      .add("/:id/tags/:tag", get { |app_context, request| Kilau::Format.render("#{request.path_params["id"]}/#{request.path_params["tag"]} {}") })
      .add("/:id", delete { |app_context, request| Kilau::Format.empty(204) })
  end

  def self.list(app_context, request) = Kilau::Format.render("notes")
  def self.show(id) = Kilau::Format.render("note #{id}")
end
