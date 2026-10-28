# K-033: more yield-receiver builtins beyond K-029/K-030's covered set still
# produce invalid C (same-shape mismatch across concrete kinds) or silently
# wrong values. Found 2026-10-28 by re-running kilau's K-030 sweep
# (tools/yield-sweep/) against spinel 1c98820c4, digging into the K-029
# "unswept names" leftover. CRuby runs all of this cleanly.

def w_clear
  v = yield.clear
  p v
end
w_clear { [3, 1, 2] }
w_clear { ["b", "a"] }
w_clear { { a: 1 } }

def w_uniq
  v = yield.uniq
  p v
end
w_uniq { [3, 1, 2] }
w_uniq { ["b", "a"] }
w_uniq { { a: 1 } }

def w_flatten
  v = yield.flatten
  p v
end
w_flatten { [3, 1, 2] }
w_flatten { ["b", "a"] }

def w_minmax
  v = yield.minmax
  p v
end
w_minmax { [3, 1, 2] }
w_minmax { ["b", "a"] }

def w_itself
  v = yield.itself
  p v
end
w_itself { 7 }
w_itself { 2.5 }
w_itself { "abc" }
w_itself { :ab }
w_itself { [3, 1, 2] }
w_itself { ["b", "a"] }
w_itself { { a: 1 } }

def w_first
  v = yield.first
  p v
end
w_first { [3, 1, 2] }
w_first { { a: 1 } }

def w_shift
  v = yield.shift
  p v
end
w_shift { [3, 1, 2] }
w_shift { { a: 1 } }

def w_values_at
  v = yield.values_at(1)
  p v
end
w_values_at { [3, 1, 2] }
w_values_at { ["b", "a"] }

def w_capitalize
  v = yield.capitalize
  p v
end
w_capitalize { "abc" }
w_capitalize { :ab }
