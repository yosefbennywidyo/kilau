# Connection and Row over the sqlite3 gem, for running Kilau's tests under
# CRuby. Kernel.require keeps the gem out of Spinel's parse-time require
# resolution, which a plain require in this dead branch would hit
# (docs/CATALOG.md K-003). Kernel.require is the core require, which
# skips RubyGems' override, so `gem` activates the gem's load path first.
if RUBY_ENGINE == "spinel"
  # connection_spinel.rb
else
  gem "sqlite3"
  Kernel.require "sqlite3"

  module Kilau
    module DB
      class Row
        def initialize(values)
          @values = values
        end

        def null?(i) = @values[i].nil?
        def int(i) = @values[i].to_i
        def int_or_nil(i) = null?(i) ? nil : int(i)
        def float(i) = @values[i].to_f
        def float_or_nil(i) = null?(i) ? nil : float(i)
        def text(i) = @values[i].to_s
        def text_or_nil(i) = null?(i) ? nil : text(i)
      end

      class Connection
        def self.open(path)
          db = SQLite3::Database.new(path, flags: OPEN_FLAGS)
          db.busy_timeout = BUSY_TIMEOUT_MS
          new(db)
        rescue SQLite3::Exception => e
          raise Error, "sqlite open #{path}: #{e.message}"
        end

        def initialize(db)
          @db = db
        end

        def exec_script(sql)
          @db.execute_batch(sql)
          nil
        rescue SQLite3::Exception => e
          raise Error, e.message
        end

        def execute(sql, binds)
          DB.check_binds(binds)
          @db.execute(sql, binds)
          @db.changes
        rescue SQLite3::Exception => e
          raise Error, e.message
        end

        def query(sql, binds)
          DB.check_binds(binds)
          rows = begin
            @db.execute(sql, binds)
          rescue SQLite3::Exception => e
            raise Error, e.message
          end
          rows.each { |values| yield Row.new(values) }
          nil
        end

        def last_insert_rowid = @db.last_insert_row_id

        def close
          @db.close
          nil
        end
      end
    end
  end
end
