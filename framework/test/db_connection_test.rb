require "kilau"
T = Kilau::Testing
B = Kilau::DB::Binds

class Boom < StandardError
end

conn = Kilau::DB::Connection.open(":memory:")
conn.exec_script("CREATE TABLE items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, note TEXT, qty INTEGER, price REAL)")

changes = conn.execute("INSERT INTO items (name, note, qty, price) VALUES (?, ?, ?, ?)", B.new.text("it's ünïcode").null.int(3).float(1.5))
T.check("insert reports one change") { changes == 1 }
T.check("last_insert_rowid is the new id") { conn.last_insert_rowid == 1 }
conn.execute("INSERT INTO items (name, note, qty, price) VALUES (?, ?, ?, ?)", B.new.text("x" * 10_000).text("long").int(0).float(0.0))
conn.execute("INSERT INTO items (name) VALUES (?)", B.new.text("third"))

names = []
conn.query("SELECT name FROM items ORDER BY id", B.new) { |row| names << row.text(0) }
GC.start
T.check("text with a quote and unicode round-trips") { names[0] == "it's ünïcode" }
T.check("10 KB text round-trips") { names[1].size == 10_000 }
T.check("text read in a block outlives the statement") { names[2] == "third" }

conn.query("SELECT name, note, qty, price FROM items WHERE id = ?", B.new.int(1)) do |row|
  T.check("int reads an INTEGER column") { row.int(2) == 3 }
  T.check("float reads a REAL column") { row.float(3) == 1.5 }
  T.check("null? sees NULL") { row.null?(1) }
  T.check("text reads NULL as empty") { row.text(1) == "" }
  T.check("text_or_nil reads NULL as nil") { row.text_or_nil(1).nil? }
  T.check("int_or_nil reads a value") { row.int_or_nil(2) == 3 }
end
conn.query("SELECT qty, price FROM items WHERE id = ?", B.new.int(3)) do |row|
  T.check("int_or_nil reads NULL as nil") { row.int_or_nil(0).nil? }
  T.check("float_or_nil reads NULL as nil") { row.float_or_nil(1).nil? }
end

T.check("update reports every changed row") { conn.execute("UPDATE items SET qty = 9", B.new) == 3 }
T.check("a syntax error raises Kilau::DB::Error") { T.raises_db_error? { conn.execute("SELEC 1", B.new) } }
T.check("too many binds raise Kilau::DB::Error") { T.raises_db_error? { conn.execute("SELECT ?", B.new.int(1).int(2)) } }
T.check("a NOT NULL violation raises Kilau::DB::Error") { T.raises_db_error? { conn.execute("INSERT INTO items (name) VALUES (?)", B.new.null) } }
T.check("a NUL byte in text raises instead of truncating") { T.raises_db_error? { conn.execute("INSERT INTO items (name) VALUES (?)", B.new.text("a\0b")) } }
T.check("a nil given to text raises") { T.raises_db_error? { B.new.text(nil) } }

escaped = begin
  conn.query("SELECT id FROM items", B.new) { |row| raise Boom, "stop" }
  false
rescue Boom
  true
end
T.check("an exception in the query block propagates") { escaped }
count = 0
conn.query("SELECT count(*) FROM items", B.new) { |row| count = row.int(0) }
T.check("the connection still works after it") { count == 3 }
conn.close

T.check("opening in a missing directory raises Kilau::DB::Error") { T.raises_db_error? { Kilau::DB::Connection.open("/nonexistent-kilau-dir/x.sqlite3") } }
