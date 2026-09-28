require "kilau"
require_relative "../kilau_tool/entities_gen"
T = Kilau::Testing

base = "/tmp/kilau-entities-#{Process.pid}"
db_path = base + ".sqlite3"
out_dir = base + "-out"
File.delete(db_path) if File.exist?(db_path)
Dir.mkdir(out_dir) unless File.directory?(out_dir)

conn = Kilau::DB::Connection.open(db_path)
conn.exec_script(
  "CREATE TABLE posts (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);" \
  "CREATE TABLE tags (id INTEGER PRIMARY KEY AUTOINCREMENT, label TEXT NOT NULL);" \
  "CREATE TABLE schema_migrations (version TEXT PRIMARY KEY)"
)
conn.close

written = KilauTool::EntitiesGen.generate(db_path, out_dir)
T.check("one file per user table; schema_migrations and sqlite_ tables skipped") { written == [out_dir + "/posts.rb", out_dir + "/tags.rb"] }
print File.read(out_dir + "/posts.rb")

missing_db = begin
  KilauTool::EntitiesGen.generate(base + "-nope.sqlite3", out_dir)
  false
rescue ArgumentError
  true
end
T.check("a missing database raises instead of creating one") { missing_db && !File.exist?(base + "-nope.sqlite3") }

missing_dir = begin
  KilauTool::EntitiesGen.generate(db_path, base + "-no-dir")
  false
rescue ArgumentError
  true
end
T.check("a missing output directory raises") { missing_dir }

written.each { |path| File.delete(path) }
Dir.rmdir(out_dir)
File.delete(db_path)
