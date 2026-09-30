module Kilau
  # Applies migrations in version order and records each version in
  # schema_migrations. Every migration runs in its own transaction, so a
  # failure leaves neither its tables nor its version behind.
  class Migrator
    def initialize(conn, migrations)
      versions = migrations.map { |m| m.version }
      duplicate = versions.find { |v| versions.count(v) > 1 }
      raise ArgumentError, "duplicate migration version #{duplicate}" unless duplicate.nil?
      @conn = conn
      @migrations = migrations.sort_by { |m| m.version }
      @schema = Schema.new(conn)
      @conn.exec_script("CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY)")
    end

    def applied_versions
      versions = []
      @conn.query("SELECT version FROM schema_migrations ORDER BY version", Sqlite::Binds.new) { |row| versions << row.text(0) }
      versions
    end

    # Returns the versions applied, oldest first.
    def migrate
      done = applied_versions
      applied = []
      @migrations.each do |migration|
        next if done.include?(migration.version)
        in_transaction do
          migration.up(@schema)
          @conn.execute("INSERT INTO schema_migrations (version) VALUES (?)", Sqlite::Binds.new.text(migration.version.to_s))
        end
        applied << migration.version
      end
      applied
    end

    # Rolls back the newest applied migration; returns its version, or nil.
    def rollback
      last = applied_versions.last
      return nil if last.nil?
      migration = @migrations.find { |m| m.version.to_s == last }
      raise Sqlite::Error, "no migration defines applied version #{last}" if migration.nil?
      in_transaction do
        migration.down(@schema)
        @conn.execute("DELETE FROM schema_migrations WHERE version = ?", Sqlite::Binds.new.text(last))
      end
      last
    end

    def status_lines
      done = applied_versions
      @migrations.map do |m|
        version = m.version.to_s
        state = done.include?(version) ? "up  " : "down"
        "#{state} #{version}"
      end
    end

    private

    def in_transaction
      @conn.exec_script("BEGIN")
      begin
        yield
        @conn.exec_script("COMMIT")
      rescue StandardError
        @conn.exec_script("ROLLBACK")
        raise
      end
    end
  end
end
