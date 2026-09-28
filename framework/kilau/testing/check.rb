module Kilau
  # Assertions for snapshot tests: a passing check prints one line, a
  # failing one raises so the test program exits non-zero. Tests call
  # them as module methods (T = Kilau::Testing; T.check ...): a block-
  # taking method reached through a top-level include is never emitted
  # by Spinel (docs/CATALOG.md K-004).
  module Testing
    def self.check(label)
      raise "FAIL: #{label}" unless yield
      puts "ok #{label}"
    end
  end
end
