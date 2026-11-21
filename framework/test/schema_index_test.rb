require "kilau"
T = Kilau::Testing

class MUsers < Kilau::Migration
  def version = "20260101000009"

  def up(schema)
    schema.create_table("people") do |t|
      t.pk_auto("id")
      t.string("email")
    end
    schema.add_unique_index("people", "email")
  end

  def down(schema) = schema.drop_table("people")
end

conn = Sqlite::Connection.open(":memory:")
Kilau::Migrator.new(conn, [MUsers.new]).migrate
insert = "INSERT INTO people (email) VALUES (?)"
conn.execute(insert, Sqlite::Binds.new.text("a@x.test"))
T.check("a second row with the same value is refused by the database") do
  T.raises_db_error? { conn.execute(insert, Sqlite::Binds.new.text("a@x.test")) }
end
T.check("a different value is accepted") { conn.execute(insert, Sqlite::Binds.new.text("b@x.test")) == 1 }
unique = false
conn.query("PRAGMA index_list(people)", Sqlite::Binds.new) { |row| unique = true if row.int(2) == 1 }
T.check("the index is reported as unique") { unique }
conn.close
