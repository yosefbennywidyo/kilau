# K-031 (2026-10-20, found by the K-030 sweep): `yield.<=>(2)` with an Integer
# site and a non-numeric site. CRuby answers `1` for the Integer site and `nil`
# for the String site. Spinel fixes the answer type from the Integer site and
# raises TypeError on the String site's nil, so the program dies at runtime.
# Order matters: `w { "abc" }` before `w { 7 }` does not reproduce.
def w
  v = yield.<=>(2)
  p v
end
w { 7 }
w { "abc" }
