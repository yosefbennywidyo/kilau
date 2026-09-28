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
  end
end
