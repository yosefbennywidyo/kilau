# SQLite through Spinel FFI. CRuby never loads this module (see
# connection_cruby.rb).
if RUBY_ENGINE == "spinel"
  module Kilau
    module DB
      module Native
        ffi_lib "sqlite3"
        # Out-params stay in C: a shared ffi_buffer for sqlite3** or
        # sqlite3_stmt** would race between threads.
        ffi_source <<~C
          typedef struct sqlite3 sqlite3;
          typedef struct sqlite3_stmt sqlite3_stmt;
          int sqlite3_open_v2(const char *, sqlite3 **, int, const char *);
          int sqlite3_prepare_v2(sqlite3 *, const char *, int, sqlite3_stmt **, const char **);
          void *kilau_sqlite_open(const char *path, int flags) {
            sqlite3 *db = 0;
            sqlite3_open_v2(path, &db, flags, 0);
            return db;
          }
          void *kilau_sqlite_prepare(void *db, const char *sql) {
            sqlite3_stmt *stmt = 0;
            sqlite3_prepare_v2((sqlite3 *)db, sql, -1, &stmt, 0);
            return stmt;
          }
        C
        ffi_func :kilau_sqlite_open, [:str, :int], :ptr
        ffi_func :kilau_sqlite_prepare, [:ptr, :str], :ptr
        ffi_func :sqlite3_close_v2, [:ptr], :int
        ffi_func :sqlite3_exec, [:ptr, :str, :ptr, :ptr, :ptr], :int, blocking: true
        ffi_func :sqlite3_errcode, [:ptr], :int
        ffi_func :sqlite3_errmsg, [:ptr], :str
        ffi_func :sqlite3_busy_timeout, [:ptr, :int], :int
        ffi_func :sqlite3_bind_int64, [:ptr, :int, :long], :int
        ffi_func :sqlite3_bind_double, [:ptr, :int, :double], :int
        ffi_func :sqlite3_bind_text, [:ptr, :int, :str, :int, :ptr], :int
        ffi_func :sqlite3_bind_null, [:ptr, :int], :int
        ffi_func :sqlite3_step, [:ptr], :int, blocking: true
        ffi_func :sqlite3_column_type, [:ptr, :int], :int
        ffi_func :sqlite3_column_int64, [:ptr, :int], :long
        ffi_func :sqlite3_column_double, [:ptr, :int], :double
        ffi_func :sqlite3_column_text, [:ptr, :int], :str
        ffi_func :sqlite3_finalize, [:ptr], :int
        ffi_func :sqlite3_changes, [:ptr], :int
        ffi_func :sqlite3_last_insert_rowid, [:ptr], :long
      end
    end
  end
end
