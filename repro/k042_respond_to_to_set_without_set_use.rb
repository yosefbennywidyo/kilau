# K-042: respond_to?(:to_set) on a concrete Array or Hash answers false when
# the program neither requires "set" nor uses a Set anywhere else. CRuby 4.0
# (Set is core) answers true. Adding `require "set"`, or any `[1].to_set` /
# `Set.new` elsewhere in the program, makes spinel answer true too.
p [1, 2].respond_to?(:to_set)
h = { "a" => 1 }
p h.respond_to?(:to_set)
p (1..3).respond_to?(:to_set)
