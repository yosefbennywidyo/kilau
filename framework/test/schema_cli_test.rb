require "kilau"
T = Kilau::Testing

class MPosts < Kilau::Migration
  def version = "20260928000001"

  def up(schema)
    schema.create_table("posts") do |t|
      t.pk_auto("id")
      t.string("title")
    end
  end

  def down(schema) = schema.drop_table("posts")
end

path = "/tmp/kilau-schema-cli-#{Process.pid}.sqlite3"
File.delete(path) if File.exist?(path)
migrations = [MPosts.new]

T.check("an unknown command exits 2") { Kilau::SchemaCLI.run(migrations, ["explode"]) == 2 }
T.check("--db without a path exits 2") { Kilau::SchemaCLI.run(migrations, ["status", "--db"]) == 2 }
T.check("an unopenable database exits 1 with a message") { Kilau::SchemaCLI.run(migrations, ["status", "--db", "/nonexistent-kilau-dir/x.sqlite3"]) == 1 }
T.check("migrate exits 0") { Kilau::SchemaCLI.run(migrations, ["migrate", "--db", path]) == 0 }
T.check("status exits 0") { Kilau::SchemaCLI.run(migrations, ["status", "--db", path]) == 0 }
T.check("rollback exits 0") { Kilau::SchemaCLI.run(migrations, ["rollback", "--db", path]) == 0 }
T.check("rollback with nothing applied exits 0") { Kilau::SchemaCLI.run(migrations, ["rollback", "--db", path]) == 0 }
File.delete(path)
