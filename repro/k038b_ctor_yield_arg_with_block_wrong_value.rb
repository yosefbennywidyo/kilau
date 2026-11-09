# K-038, silent variant (2026-11-09): same root cause as k038_*, but the constructor
# call carries a literal block. The `yield` in the argument then resolves to THAT
# block's context instead of the caller's, and the program prints `0 0` with no
# error. CRuby prints `50` and `70`.
class Foo
  def initialize(e)
    @r = yield(e)
  end
  def r; @r; end
end
def b
  p Foo.new(yield) { |x| x * 10 }.r
end
b { 5 }
b { 7 }
