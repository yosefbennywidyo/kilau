# K-039 (2026-11-09, found by the per-site K-036 MISMATCH triage): Array#rfind
# (new in Ruby 4.0) has no arm for a poly array receiver, i.e. a receiver that
# holds an Integer array at one call site and a String array at another.
# CRuby prints `2` and `"a"`. Spinel compiles this and dies at run time with
# "undefined method 'rfind' for an instance of Array (NoMethodError)".
# The same shape through a bare yield receiver, `def w; p yield.rfind { |x| x != 3 }; end`
# with `w { [3, 1, 2] }; w { ["b", "a"] }`, fails at C compile time instead:
# "initializing 'sp_oint' with an expression of incompatible type 'const char *'".
# Typed (single-kind) receivers work, and so does `find` on the same poly receiver.
def w(a)
  p a.rfind { |x| x != 3 }
end
w([3, 1, 2])
w(["b", "a"])
