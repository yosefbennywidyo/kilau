require "kilau"
T = Kilau::Testing

class M2Gadgets < Kilau::Migration
  def version = "20260101000002"

  def up(schema)
    schema.create_table("gadgets") do |t|
      t.pk_auto("id")
      t.string("name")
    end
  end

  def down(schema) = schema.drop_table("gadgets")
end

class M1Widgets < Kilau::Migration
  def version = "20260101000001"

  def up(schema)
    schema.create_table("widgets") do |t|
      t.pk_auto("id")
      t.string("name")
      t.string_null("note")
      t.integer("qty")
      t.float("price")
      t.timestamps
    end
  end

  def down(schema) = schema.drop_table("widgets")
end

class M3Broken < Kilau::Migration
  def version = "20260101000003"

  def up(schema)
    schema.create_table("halfway") { |t| t.pk_auto("id") }
    schema.create_table("widgets") { |t| t.pk_auto("id") }
  end

  def down(schema) = nil
end

def table_exists?(conn, name)
  found = false
  conn.query("SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?", Kilau::DB::Binds.new.text(name)) { |row| found = true }
  found
end

conn = Kilau::DB::Connection.open(":memory:")
migrator = Kilau::Migrator.new(conn, [M2Gadgets.new, M1Widgets.new])
T.check("migrate applies pending migrations in version order") { migrator.migrate == ["20260101000001", "20260101000002"] }
T.check("migrate again applies nothing") { migrator.migrate.empty? }
T.check("status lists every migration as up") { migrator.status_lines == ["up   20260101000001", "up   20260101000002"] }

columns = []
conn.query("PRAGMA table_info(widgets)", Kilau::DB::Binds.new) { |row| columns << "#{row.text(1)} #{row.text(2)} #{row.int(3)}" }
T.check("create_table maps column types") do
  columns == ["id INTEGER 0", "name TEXT 1", "note TEXT 0", "qty INTEGER 1", "price REAL 1", "created_at INTEGER 1", "updated_at INTEGER 1"]
end

T.check("rollback undoes the newest migration") { migrator.rollback == "20260101000002" }
T.check("status shows the rolled back migration as down") { migrator.status_lines == ["up   20260101000001", "down 20260101000002"] }
T.check("the rolled back table is gone") { !table_exists?(conn, "gadgets") }

empty = Kilau::Migrator.new(Kilau::DB::Connection.open(":memory:"), [])
T.check("rollback with nothing applied returns nil") { empty.rollback.nil? }

duplicate = begin
  Kilau::Migrator.new(conn, [M1Widgets.new, M1Widgets.new])
  false
rescue ArgumentError
  true
end
T.check("duplicate versions are rejected") { duplicate }

broken = Kilau::Migrator.new(conn, [M1Widgets.new, M3Broken.new])
T.check("a failing migration raises") { T.raises_db_error? { broken.migrate } }
T.check("a failing migration is not recorded") { !broken.applied_versions.include?("20260101000003") }
T.check("a failing migration's earlier steps roll back") { !table_exists?(conn, "halfway") }
conn.close
