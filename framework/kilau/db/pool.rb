module Kilau
  module DB
    # N connections in a Thread::Queue. A caller checks one out for the
    # length of a block; nothing holds a connection between calls.
    class Pool
      attr_reader :size

      def initialize(path, size)
        raise ArgumentError, "pool size must be at least 1, got #{size}" if size < 1
        @size = size
        @idle = Thread::Queue.new
        first = Connection.open(path)
        first.exec_script("PRAGMA journal_mode=WAL")
        @idle << first
        (size - 1).times { @idle << Connection.open(path) }
      end

      def with
        conn = @idle.pop
        begin
          yield conn
        ensure
          @idle << conn
        end
      end

      def exec_script(sql) = with { |conn| conn.exec_script(sql) }
      def execute(sql, binds) = with { |conn| conn.execute(sql, binds) }

      # The row id comes from the connection that ran the insert.
      def insert(sql, binds)
        with do |conn|
          conn.execute(sql, binds)
          conn.last_insert_rowid
        end
      end

      def query_all(sql, binds)
        out = []
        with { |conn| conn.query(sql, binds) { |row| out << yield(row) } }
        out
      end

      # Maps the first row, or returns nil. Every row is still stepped, so
      # give the query a LIMIT 1. The result is collected in an array, not
      # assigned to a local from the nested blocks: reached from a handler,
      # Spinel lost that assignment and answered nil (docs/CATALOG.md K-016).
      def query_first(sql, binds)
        found = []
        with { |conn| conn.query(sql, binds) { |row| found << yield(row) if found.empty? } }
        found.first
      end

      def close
        @size.times { @idle.pop.close }
        nil
      end
    end
  end
end
