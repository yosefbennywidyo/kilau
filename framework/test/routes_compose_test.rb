require "kilau"
T = Kilau::Testing

# Fase F: Routes#nest puts another group under the chain's prefix and a path;
# Routes#merge appends another group's routes as they are (Loco's nest/merge).
ok = Kilau::Controller.get { |app_context, request| Kilau::Format.text("ok") }
posts = Kilau::Routes.new.add("/", ok).add("/:id", ok)
comments = Kilau::Routes.new.add("/", ok)
blog = Kilau::Routes.new.prefix("blog").nest("/posts", posts).nest("/posts/:pid/comments", comments)
extra = Kilau::Routes.new.add("/_extra", ok)
all = Kilau::Routes.new.merge(blog).merge(extra)

T.check("nest puts a group under the chain prefix and the nest path") do
  blog.routes.map { |route| route.pattern } == ["/blog/posts", "/blog/posts/:id", "/blog/posts/:pid/comments"]
end
T.check("merge keeps the other group's patterns as they are") do
  all.routes.map { |route| route.pattern } == blog.routes.map { |route| route.pattern } + ["/_extra"]
end
T.check("nest does not change the nested group") { posts.routes.map { |route| route.pattern } == ["/", "/:id"] }

COMPOSED = all

class ComposedApp < Kilau::Hooks
  def routes = Kilau::AppRoutes.with_default_routes.add(COMPOSED)
end
db = Sqlite::Pool.new(":memory:", 1)
app_context = Kilau::AppContext.new(db, Kilau::Config.parse("app:\n  name: composed\n", "test.yaml"), "test")
client = Kilau::Testing::Client.new(ComposedApp.new, app_context)
T.check("a request reaches a nested route under its full path") { client.get("/blog/posts/7").status == 200 }
T.check("a request reaches a merged route") { client.get("/_extra").status == 200 }
T.check("a nested param route keeps its param under the nest path") { client.get("/blog/posts/7/comments").status == 200 }
T.check("a path under no nested group is 404") { client.get("/posts/7").status == 404 }
