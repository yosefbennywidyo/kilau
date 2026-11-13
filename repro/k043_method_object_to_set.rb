# K-043 (2026-11-13, found while fixing K-042): `method(:to_set)` on an Array.
# CRuby 4.0.6 prints `1`. Spinel compiles and dies at run time with
# "undefined method 'to_set' for class 'Array' (NameError)", even with
# `require "set"`. The Range form, `p (1..3).method(:to_set).call.size`, fails at
# C compile time instead ("operand of type 'sp_Range' where arithmetic or pointer
# type is required"); it is kept out of this file so each failure shows alone.
require "set"
p [1, 1].method(:to_set).call.size
