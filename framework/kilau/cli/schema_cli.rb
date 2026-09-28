module Kilau
  # The command line of an app's schema binary (bin/<app>_schema.rb):
  # migrate, rollback and status against one SQLite file. Until config
  # loading lands (docs/CATALOG.md K-002) the file comes from --db.
  module SchemaCLI
    USAGE = "usage: COMMAND [--db PATH]   (COMMAND: migrate | rollback | status)"
    DEFAULT_DB = "db/development.sqlite3"

    # Returns the process exit status: 0 on success, 1 when the database
    # cannot be opened or a migration fails, 2 on a usage error.
    def self.run(migrations, argv)
      command = argv[0]
      db_path = DEFAULT_DB
      i = 1
      while i < argv.size
        if argv[i] == "--db" && i + 1 < argv.size
          db_path = argv[i + 1]
          i += 2
        else
          $stderr.puts USAGE
          return 2
        end
      end
      unless command == "migrate" || command == "rollback" || command == "status"
        $stderr.puts USAGE
        return 2
      end

      conn = begin
        Kilau::DB::Connection.open(db_path)
      rescue Kilau::DB::Error => e
        $stderr.puts "error: #{e.message}"
        return 1
      end
      begin
        migrator = Migrator.new(conn, migrations)
        if command == "migrate"
          applied = migrator.migrate
          applied.each { |version| puts "migrated #{version}" }
          puts "nothing to migrate" if applied.empty?
        elsif command == "rollback"
          version = migrator.rollback
          puts(version.nil? ? "nothing to roll back" : "rolled back #{version}")
        else
          migrator.status_lines.each { |line| puts line }
        end
      rescue Kilau::DB::Error => e
        $stderr.puts "error: #{e.message}"
        return 1
      ensure
        conn.close
      end
      0
    end
  end
end
