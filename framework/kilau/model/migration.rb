module Kilau
  # A schema change. A subclass names its version and builds the change
  # with Schema and TableBuilder; the Migrator records the version.
  class Migration
    def version
      raise NotImplementedError, "a migration must define version"
    end

    def up(schema)
      raise NotImplementedError, "a migration must define up"
    end

    def down(schema)
      raise NotImplementedError, "a migration must define down"
    end
  end

  class Schema
    def initialize(conn)
      @conn = conn
    end

    def create_table(name)
      table = TableBuilder.new
      yield table
      @conn.exec_script("CREATE TABLE #{name} (#{table.to_sql})")
    end

    def drop_table(name)
      @conn.exec_script("DROP TABLE #{name}")
    end
  end

  # Column types of spec §5.1. A timestamp is INTEGER epoch seconds,
  # because Spinel has no Time.parse (docs/CATALOG.md K-001).
  class TableBuilder
    def initialize
      @columns = []
    end

    def pk_auto(name) = add(name, "INTEGER PRIMARY KEY AUTOINCREMENT")
    def string(name) = add(name, "TEXT NOT NULL")
    def string_null(name) = add(name, "TEXT")
    def text(name) = add(name, "TEXT NOT NULL")
    def integer(name) = add(name, "INTEGER NOT NULL")
    def float(name) = add(name, "REAL NOT NULL")
    def timestamp(name) = add(name, "INTEGER NOT NULL")

    def timestamps
      timestamp("created_at")
      timestamp("updated_at")
    end

    def to_sql = @columns.join(", ")

    private

    def add(name, sql)
      @columns << "#{name} #{sql}"
      nil
    end
  end
end
