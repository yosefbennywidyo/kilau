require "kilau"
T = Kilau::Testing

# The trie answers exactly the routes Route#match accepts, for every path.
def linear_indices(routes, path)
  found = []
  routes.each_with_index { |route, i| found << i unless route.match(path).nil? }
  found
end

def same_matches?(routes, trie, path)
  linear_indices(routes, path) == trie.matches(path).sort
end

ok = Kilau::Controller.get { |c, r| r }
routes = [
  Kilau::Route.new("GET", "/", ok),
  Kilau::Route.new("GET", "/notes", ok),
  Kilau::Route.new("GET", "/notes/bulk", ok),
  Kilau::Route.new("POST", "/notes/bulk", ok),
  Kilau::Route.new("GET", "/notes/:id", ok),
  Kilau::Route.new("PATCH", "/notes/:id", ok),
  Kilau::Route.new("GET", "/notes/:id/tags/:tag", ok),
  Kilau::Route.new("GET", "/users/:name/notes", ok),
  Kilau::Route.new("GET", "/_ping", ok),
]
trie = Kilau::RouteTrie.build(routes)
paths = ["/", "/notes", "/notes/", "/notes/bulk", "/notes/7", "/notes//tags/red", "/notes/7/tags/red",
         "/notes/7/edit", "/users/ann/notes", "/users//notes", "/_ping", "/nope", "/notes/bulk/x", "/notes/7/tags"]

T.check("the trie matches the routes Route#match accepts, for every sample path") do
  paths.all? { |path| same_matches?(routes, trie, path) }
end
T.check("a static segment and a param at the same depth are both returned, the static one listed too") do
  trie.matches("/notes/bulk").sort == linear_indices(routes, "/notes/bulk")
end
T.check("a path matching nothing returns no routes") { trie.matches("/nope").empty? }
T.check("the root route is reached by the empty path") { trie.matches("/") == [0] }
T.check("a trailing slash matches as Route#match does") { trie.matches("/notes/") == linear_indices(routes, "/notes/") }
T.check("an empty segment never binds a param") { trie.matches("/notes//tags/red").empty? }
