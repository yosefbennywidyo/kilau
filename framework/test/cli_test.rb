require "kilau"
T = Kilau::Testing

class MNotes < Kilau::Migration
  def version = "20260101000001"

  def up(schema)
    schema.create_table("notes") do |t|
      t.pk_auto("id")
      t.string("title")
    end
  end

  def down(schema) = schema.drop_table("notes")
end

dir = "/tmp/kilau-cli-test"
db_path = dir + "/cli.sqlite3"
Dir.mkdir(dir) unless File.directory?(dir)
["", "-wal", "-shm"].each { |suffix| File.delete(db_path + suffix) if File.exist?(db_path + suffix) }
File.write(dir + "/development.yaml", "server:\n  host: \"127.0.0.1\"\n  port: 0\ndatabase:\n  path: #{db_path}\n  pool: 1\nlogger:\n  requests: false\n")
File.write(dir + "/broken.yaml", "database:\n  - nope\n")

hooks = Kilau::Hooks.new
migrations = [MNotes.new]
T.check("an unknown command exits 2") { Kilau::CLI.run(hooks, migrations, ["explode"], dir) == 2 }
T.check("db migrate uses the config's database") { Kilau::CLI.run(hooks, migrations, ["db", "migrate"], dir) == 0 }
T.check("db status reports it") { Kilau::CLI.run(hooks, migrations, ["db", "status"], dir) == 0 }
T.check("a missing config file exits 1") { Kilau::CLI.run(hooks, migrations, ["db", "status"], "/nonexistent-kilau-config") == 1 }
ENV["KILAU_ENV"] = "broken"
T.check("a malformed config exits 1") { Kilau::CLI.run(hooks, migrations, ["db", "status"], dir) == 1 }
["", "-wal", "-shm"].each { |suffix| File.delete(db_path + suffix) if File.exist?(db_path + suffix) }
