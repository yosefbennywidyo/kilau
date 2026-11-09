# K-038 (2026-11-09, found while triaging the K-036 MISMATCH set): `yield.to_set`
# chained directly on a bare `yield` dies at run time with
# "no block given (yield) (LocalJumpError)" although the block is given.
# CRuby prints Set[3, 1, 2]. Binding the value first (`v = yield; v.to_set`)
# and a direct `[3, 1, 2].to_set` both work. Not a `require "set"` artifact:
# it fails with the require too.
def a
  v = yield
  p v.to_set
end
a { [3, 1, 2] }
def b
  p yield.to_set
end
b { [3, 1, 2] }
