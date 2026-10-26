require "kilau"
T = Kilau::Testing

# A typed param (`:n<int>`) is checked before its handler runs: a value that is
# not a whole number answers 400, as path_int does (Rencana 5 Fase E, D-029).
class TypedController < Kilau::Controller
  def self.routes
    Kilau::Routes.new.prefix("typed")
      .add("/:n<int>", get { |app_context, request| Kilau::Format.text("n #{request.path_int("n")}") })
  end
end

class TypedApp < Kilau::Hooks
  def routes = Kilau::AppRoutes.with_default_routes.add(TypedController.routes)
end

db = Sqlite::Pool.new(":memory:", 1)
app_context = Kilau::AppContext.new(db, Kilau::Config.parse("app:\n  name: typed\n", "test.yaml"), "test")
client = Kilau::Testing::Client.new(TypedApp.new, app_context)

T.check("a typed param binds its value") { client.get("/typed/12").body == "n 12" }
T.check("a value that is not a whole number is a 400") { client.get("/typed/abc").status == 400 }
T.check("a typed param keeps its declared pattern in the table") { TypedApp.new.routes.routes.any? { |route| route.pattern == "/typed/:n<int>" } }
T.check("the type is not part of the shape: an untyped sibling of the same verb conflicts") do
  begin
    Kilau::AppRoutes.new.add(TypedController.routes).add(Kilau::Routes.new.prefix("typed").add("/:m", Kilau::Controller.get { |c, r| r }))
    false
  rescue ArgumentError
    true
  end
end
T.check("a path with no typed value still reaches a static route first") { client.get("/typed/12/x").status == 404 }
