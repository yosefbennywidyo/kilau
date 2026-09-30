# K-023: a bare call inside a BasicObject subclass resolves to a method of a
# module included at the top level (spinel 8fec82476). An include at the top
# level adds the module to Object, which a BasicObject subclass does not
# inherit, so CRuby raises NoMethodError and this prints "NoMethodError"
# twice. Spinel answers "hi" and runs the yielding method, printing 1 twice.
# Every resolver of bare calls (infer_uncached, emit_call's top-level-include
# arm, emit_inline_call_x) looks the name up in comp_included_method_index
# without the caller's scope. Raised by CodeRabbit on
# yosefbennywidyo/spinel#7 (the K-021 fix) on 2026-09-30.
module T
  module_function
  def twice
    yield
    yield
  end
  def hello = "hi"
end
include T
class B < BasicObject
  def greet
    hello()
  rescue ::NoMethodError
    "NoMethodError"
  end
  def run
    twice { $stdout.puts 1 }
  rescue ::NoMethodError
    $stdout.puts "NoMethodError"
  end
end
$stdout.puts B.new.greet
B.new.run
