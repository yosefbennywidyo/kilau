# K-038 (2026-11-09): a bare `yield` written as an ARGUMENT of a constructor whose
# `initialize` uses `block_given?` or `yield` is lowered in the constructor's block
# context (no block) instead of the caller's, so it raises
# "no block given (yield) (LocalJumpError)". CRuby prints `false`.
# Originally seen as `yield.to_set` / `Set.new(yield)` because Set#initialize is such
# a constructor; it is not specific to Set or to to_set.
# Binding first (`x = yield; Foo.new(x)`) and plain methods (`f(yield)`) are fine.
# See repro/k038b_ctor_yield_arg_with_block_wrong_value.rb for the silent variant.
class Foo
  def initialize(e)
    @r = block_given?
  end
  def r; @r; end
end
def b
  p Foo.new(yield).r
end
b { 1 }
