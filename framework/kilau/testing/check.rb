module Kilau
  # Assertions for snapshot tests: a passing check prints one line, a
  # failing one raises so the test program exits non-zero. Call them as
  # module methods (T = Kilau::Testing; T.check ...) or include the module
  # at the top level and call them bare. Spinel before matz/spinel#6029
  # never emitted a yielding method reached through a top-level include
  # (docs/CATALOG.md K-004), so the existing tests use the module form.
  module Testing
    module_function

    def check(label)
      raise "FAIL: #{label}" unless yield
      puts "ok #{label}"
    end

    def raises_db_error?
      yield
      false
    rescue Kilau::DB::Error
      true
    end
  end
end
