# K-021: a module_function method that yields and rescues, called bare after
# a top-level include with a block that always raises, compiles to invalid C
# (spinel 35ddccadb): "invalid argument type 'void' to unary expression" at the
# caller's `unless yield`. CRuby prints "ok x". The same call through the module
# (`T.check { T.raises? { raise ... } }`) works, and so does a bare `raises?`
# whose block does not raise. Found 2026-09-30 while lifting Kilau's K-004
# workaround. The top-level-include inlining of module_function methods is new
# in matz/spinel#6029.
class DbErr < StandardError; end
module T
  module_function
  def check(label)
    raise "FAIL: #{label}" unless yield
    puts "ok #{label}"
  end
  def raises?
    yield
    false
  rescue DbErr
    true
  end
end
include T
check("x") { raises? { raise DbErr, "boom" } }
