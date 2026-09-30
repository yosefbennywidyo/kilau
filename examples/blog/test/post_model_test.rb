require "kilau"
require_relative "../migration/migrator"
require_relative "../src/models/posts"
T = Kilau::Testing

db = Sqlite::Pool.new(":memory:", 1)
db.with { |conn| Kilau::Migrator.new(conn, MIGRATIONS).migrate }

post = Post.new
post.title = "a"
post.content = ""
T.check("an invalid post is not saved") { post.save(db) == false }
T.check("the title message is Indonesian") { post.errors["title"] == "minimal 2 karakter" }
T.check("the content message is Indonesian") { post.errors["content"] == "wajib diisi" }

post.title = "Halo Kilau"
post.content = "Pos pertama."
T.check("a valid post saves") { post.save(db) }
second = Post.new
second.title = "Kedua"
second.content = "Isi."
second.save(db)
T.check("all lists the newest first") { Post.all(db).map { |p| p.title } == ["Kedua", "Halo Kilau"] }
T.check("find_by_id reads the content back") { Post.find_by_id(db, post.id).content == "Pos pertama." }
T.check("find_by_id of a missing id is nil") { Post.find_by_id(db, 404).nil? }
db.close
