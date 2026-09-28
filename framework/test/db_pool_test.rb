require "kilau"
T = Kilau::Testing
B = Kilau::DB::Binds

class Boom < StandardError
end

def remove_db(path)
  ["", "-wal", "-shm"].each { |suffix| File.delete(path + suffix) if File.exist?(path + suffix) }
end

path = "/tmp/kilau-pool-test-#{Process.pid}.sqlite3"
remove_db(path)

rejected = begin
  Kilau::DB::Pool.new(path, 0)
  false
rescue ArgumentError
  true
end
T.check("pool size must be at least 1") { rejected }

pool = Kilau::DB::Pool.new(path, 4)
T.check("pool reports its size") { pool.size == 4 }
pool.exec_script("CREATE TABLE hits (id INTEGER PRIMARY KEY AUTOINCREMENT, worker INTEGER NOT NULL)")
T.check("insert returns the new row id") { pool.insert("INSERT INTO hits (worker) VALUES (?)", B.new.int(0)) == 1 }
T.check("with returns the block value") { pool.with { |conn| 42 } == 42 }

threads = []
50.times { |w| threads << Thread.new { pool.insert("INSERT INTO hits (worker) VALUES (?)", B.new.int(w + 1)) } }
ids = threads.map { |t| t.value }
T.check("50 concurrent inserts all get distinct ids") { ids.uniq.size == 50 }
total = pool.query_first("SELECT count(*) FROM hits", B.new) { |row| row.int(0) }
T.check("count after the concurrent inserts is 51") { total == 51 }
workers = pool.query_all("SELECT worker FROM hits WHERE worker > ? ORDER BY worker", B.new.int(48)) { |row| row.int(0) }
T.check("query_all maps every row") { workers == [49, 50] }
missing = pool.query_first("SELECT worker FROM hits WHERE worker < ? LIMIT 1", B.new.int(0)) { |row| row.int(0) }
T.check("query_first returns nil when no row matches") { missing.nil? }
mode = pool.query_first("PRAGMA journal_mode", B.new) { |row| row.text(0) }
T.check("the file pool runs in WAL mode") { mode == "wal" }
pool.close
remove_db(path)

small = Kilau::DB::Pool.new(":memory:", 1)
escaped = begin
  small.with { |conn| raise Boom, "stop" }
  false
rescue Boom
  true
end
T.check("an exception inside with propagates") { escaped }
T.check("the connection returns to the pool after it") { small.with { |conn| 7 } == 7 }
small.close
