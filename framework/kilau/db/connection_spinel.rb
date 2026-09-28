# Connection and Row over Spinel FFI. connection_cruby.rb defines the
# same API over the sqlite3 gem.
if RUBY_ENGINE == "spinel"
  module Kilau
    module DB
      # One result row. Valid only inside the Connection#query block that
      # yielded it: the statement is finalized when the block ends.
      class Row
        SQLITE_NULL = 5

        def initialize(stmt)
          @stmt = stmt
        end

        def null?(i) = Native.sqlite3_column_type(@stmt, i) == SQLITE_NULL
        def int(i) = Native.sqlite3_column_int64(@stmt, i)
        def int_or_nil(i) = null?(i) ? nil : int(i)
        def float(i) = Native.sqlite3_column_double(@stmt, i)
        def float_or_nil(i) = null?(i) ? nil : float(i)
        def text(i) = null?(i) ? "" : Native.sqlite3_column_text(@stmt, i)
        def text_or_nil(i) = null?(i) ? nil : Native.sqlite3_column_text(@stmt, i)
      end

      class Connection
        def self.open(path)
          handle = Native.kilau_sqlite_open(path, OPEN_FLAGS)
          raise Error, "sqlite open #{path}: out of memory" if handle == nil
          if Native.sqlite3_errcode(handle) != SQLITE_OK
            message = Native.sqlite3_errmsg(handle)
            Native.sqlite3_close_v2(handle)
            raise Error, "sqlite open #{path}: #{message}"
          end
          Native.sqlite3_busy_timeout(handle, BUSY_TIMEOUT_MS)
          new(handle)
        end

        def initialize(handle)
          @handle = handle
        end

        def exec_script(sql)
          if Native.sqlite3_exec(@handle, sql, 0, 0, 0) != SQLITE_OK
            raise Error, Native.sqlite3_errmsg(@handle)
          end
          nil
        end

        def execute(sql, binds)
          stmt = prepare(sql, binds)
          rc = Native.sqlite3_step(stmt)
          message = rc == SQLITE_DONE || rc == SQLITE_ROW ? nil : Native.sqlite3_errmsg(@handle)
          Native.sqlite3_finalize(stmt)
          raise Error, message if message
          Native.sqlite3_changes(@handle)
        end

        def query(sql, binds)
          stmt = prepare(sql, binds)
          row = Row.new(stmt)
          begin
            while true
              rc = Native.sqlite3_step(stmt)
              break if rc == SQLITE_DONE
              raise Error, Native.sqlite3_errmsg(@handle) if rc != SQLITE_ROW
              yield row
            end
          ensure
            Native.sqlite3_finalize(stmt)
          end
          nil
        end

        def last_insert_rowid = Native.sqlite3_last_insert_rowid(@handle)

        def close
          Native.sqlite3_close_v2(@handle)
          nil
        end

        private

        def prepare(sql, binds)
          stmt = Native.kilau_sqlite_prepare(@handle, sql)
          raise Error, "#{Native.sqlite3_errmsg(@handle)} (#{sql})" if stmt == nil
          i = 0
          while i < binds.size
            rc = bind(stmt, i + 1, binds, i)
            if rc != SQLITE_OK
              message = Native.sqlite3_errmsg(@handle)
              Native.sqlite3_finalize(stmt)
              raise Error, "bind #{i + 1}: #{message}"
            end
            i += 1
          end
          stmt
        end

        # -1, -1: length up to the NUL, and SQLITE_TRANSIENT so SQLite
        # copies the text before the GC may move or free it.
        def bind(stmt, index, binds, i)
          case binds.kind(i)
          when Binds::INT then Native.sqlite3_bind_int64(stmt, index, binds.int_at(i))
          when Binds::FLOAT then Native.sqlite3_bind_double(stmt, index, binds.float_at(i))
          when Binds::TEXT then Native.sqlite3_bind_text(stmt, index, binds.text_at(i), -1, -1)
          else Native.sqlite3_bind_null(stmt, index)
          end
        end
      end
    end
  end
end
