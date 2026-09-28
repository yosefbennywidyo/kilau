require "kilau"
require_relative "support/widget_entity"
T = Kilau::Testing

class Widget < Entities::Widget
  include Kilau::Model

  def validate(errors)
    errors.add("name", "must be at least 2 characters") if name.to_s.length < 2
  end

  def self.find_by_id(db, id) = db.query_first(select_sql + " WHERE id = ? LIMIT 1", Kilau::DB::Binds.new.int(id)) { |row| from_row(row) }
  def self.all(db) = db.query_all(select_sql + " ORDER BY id", Kilau::DB::Binds.new) { |row| from_row(row) }
end

db = Kilau::DB::Pool.new(":memory:", 1)
db.exec_script("CREATE TABLE widgets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, note TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)")

widget = Widget.new
widget.name = "x"
T.check("an invalid save returns false") { widget.save(db) == false }
T.check("an invalid save leaves id nil") { widget.id.nil? }
T.check("the validation message is recorded") { widget.errors["name"] == "must be at least 2 characters" }

widget.name = "gear"
T.check("a valid save returns true") { widget.save(db) }
T.check("save assigns the row id") { widget.id == 1 }
T.check("errors are cleared after a valid save") { widget.errors.empty? }
T.check("save fills both timestamps") { widget.created_at > 0 && widget.updated_at >= widget.created_at }

widget.note = "oiled"
T.check("an update saves") { widget.save(db) }
found = Widget.find_by_id(db, 1)
T.check("find_by_id returns the updated row") { found.name == "gear" && found.note == "oiled" }
T.check("created_at survives an update") { found.created_at == widget.created_at }
T.check("find_by_id of a missing id is nil") { Widget.find_by_id(db, 99).nil? }

second = Widget.new
second.name = "cog"
second.save(db)
T.check("all returns rows in id order") { Widget.all(db).map { |w| w.name } == ["gear", "cog"] }
T.check("destroy removes the row") { second.destroy(db) && Widget.find_by_id(db, 2).nil? }
T.check("destroying an unsaved record is false") { Widget.new.destroy(db) == false }
gone = Widget.find_by_id(db, 1)
db.execute("DELETE FROM widgets WHERE id = ?", Kilau::DB::Binds.new.int(1))
gone.name = "renamed"
vanished = begin
  gone.save(db)
  "saved"
rescue Kilau::Error::NotFound => e
  e.message
end
T.check("updating a row deleted meanwhile raises NotFound") { vanished == "row 1 no longer exists" }
db.close
