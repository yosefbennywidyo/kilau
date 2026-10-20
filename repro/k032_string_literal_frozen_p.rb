# K-032 (2026-10-20, found by the K-030 sweep; NOT a yield bug): a String literal
# reports `frozen? == true` in spinel. CRuby 4.0 leaves a plain literal unfrozen
# (chilled), so `frozen?` is `false`. Reproduces without any block or yield.
p "abc".frozen?
x = "abc"
p x.frozen?
