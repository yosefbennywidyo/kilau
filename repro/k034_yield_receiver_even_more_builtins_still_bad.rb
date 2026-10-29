# K-034: a further 16 builtins on a `yield` receiver with mixed concrete
# kinds still produce invalid C (same family/shape as K-029/K-030/K-033 --
# a name never widened to poly across its different sites). CRuby runs all
# of this cleanly. Found 2026-10-29 re-running the K-030/K-033 sweep
# (tools/yield-sweep/sweep.sh) against spinel master 8ad86746d, right after
# K-033's two PRs (#10476/#10481) landed -- this is the next layer the same
# sweep turns up once those are fixed. Not every failing name from the
# sweep is included here, only a representative subset; `docs/CATALOG.md`
# K-034 has the full 16-name list.
def w
  v = yield.clear
  p v
end
w { "abc" }
w { [3, 1, 2] }
w { ["b", "a"] }
w { { a: 1 } }

def w2
  v = yield.compact
  p v
end
w2 { [3, 1, 2] }
w2 { ["b", "a"] }
w2 { { a: 1 } }

def w3
  v = yield.to_a
  p v
end
w3 { [3, 1, 2] }
w3 { ["b", "a"] }
w3 { { a: 1 } }

def w4
  v = yield.max(2)
  p v
end
w4 { [3, 1, 2] }
w4 { ["b", "a"] }
w4 { { a: 1 } }

def w5
  v = yield.next
  p v
end
w5 { 7 }
w5 { "abc" }
w5 { :ab }
