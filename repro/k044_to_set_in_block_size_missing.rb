# K-044 (2026-11-13, found while fixing K-042): a Set built by `.to_set` INSIDE
# a block answers `class` and `include?` but not `size`/`length`. CRuby 4.0.6
# prints `1`. Spinel: "undefined method 'size' for an instance of Set
# (NoMethodError)", with `require "set"` present, so it is not the K-042 scan.
# The same program with `Set.new(a)` in place of `a.to_set` is identical to CRuby.
require "set"
s = [[1, 1], [2]].map { |a| a.to_set }
p s[0].size
