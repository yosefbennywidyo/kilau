module Kilau
  module DB
    class Error < StandardError
    end

    SQLITE_OK = 0
    SQLITE_ROW = 100
    SQLITE_DONE = 101
    # SQLITE_OPEN_READWRITE | CREATE | URI | FULLMUTEX
    OPEN_FLAGS = 0x2 | 0x4 | 0x40 | 0x10000
    BUSY_TIMEOUT_MS = 5000

    # Rejects what neither backend can bind faithfully: a NUL byte would
    # truncate the text in C, and other classes have no SQLite type here.
    def self.check_binds(binds)
      binds.each do |value|
        case value
        when Integer, Float, nil
          nil
        when String
          raise Error, "a text bind cannot contain a NUL byte" if value.include?("\0")
        else
          raise Error, "cannot bind a #{value.class}"
        end
      end
      nil
    end
  end
end
