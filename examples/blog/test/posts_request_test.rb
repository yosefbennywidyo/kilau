require "kilau"
require_relative "../migration/migrator"
require_relative "../src/app"
T = Kilau::Testing

db = Sqlite::Pool.new(":memory:", 1)
db.with { |conn| Kilau::Migrator.new(conn, MIGRATIONS).migrate }
app_context = Kilau::AppContext.new(db, Kilau::Config.parse("app:\n  name: blog\n", "test.yaml"), "test")
client = Kilau::Testing::Client.new(App.new, app_context)

home = client.get("/")
T.check("the root redirects to the post list") { home.status == 303 && home.location == "/posts" }
empty_list = client.get("/posts")
T.check("an empty list renders") { empty_list.status == 200 && empty_list.body.include?("<h1>Posts</h1>") }
T.check("the new form renders") { client.get("/posts/new").body.include?("name=\"post[title]\"") }

bad = client.post("/posts", { "post[title]" => "<", "post[content]" => "" })
T.check("an invalid post re-renders the form with 422") { bad.status == 422 && bad.body.include?("minimal 2 karakter") && bad.body.include?("wajib diisi") }
T.check("the re-rendered form keeps what was typed, escaped") { bad.body.include?("value=\"&lt;\"") }

created = client.post("/posts", { "post[title]" => "Halo <Kilau>", "post[content]" => "Isi & \"lainnya\"" })
T.check("a valid post redirects to it") { created.status == 303 && created.location == "/posts/1" }
shown = client.get("/posts/1")
T.check("show escapes the title") { shown.status == 200 && shown.body.include?("<h1>Halo &lt;Kilau&gt;</h1>") }
T.check("show escapes the content") { shown.body.include?("Isi &amp; &quot;lainnya&quot;") }
T.check("the list links to the post, escaped") { client.get("/posts").body.include?("<a href=\"/posts/1\">Halo &lt;Kilau&gt;</a>") }
T.check("the edit form holds the escaped title") { client.get("/posts/1/edit").body.include?("value=\"Halo &lt;Kilau&gt;\"") }

updated = client.patch("/posts/1", { "post[title]" => "Halo lagi", "post[content]" => "Baru" })
T.check("an update redirects to the post") { updated.status == 303 && updated.location == "/posts/1" }
T.check("the update is visible") { client.get("/posts/1").body.include?("<h1>Halo lagi</h1>") }
T.check("an invalid update re-renders with 422") { client.patch("/posts/1", { "post[title]" => "", "post[content]" => "x" }).status == 422 }
T.check("a missing post is 404") { client.get("/posts/99").status == 404 }
T.check("a non-numeric id is 400") { client.get("/posts/abc").status == 400 }

removed = client.delete("/posts/1")
T.check("delete redirects to the list") { removed.status == 303 && removed.location == "/posts" }
T.check("the deleted post is gone") { client.get("/posts/1").status == 404 }
T.check("_ping answers") { client.get("/_ping").body == "{\"ok\":true}" }
T.check("_health answers") { client.get("/_health").status == 200 }
db.close
