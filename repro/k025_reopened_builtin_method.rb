# K-025: a method a program reopens on Array (or Hash) under a builtin's name
# is ignored: the builtin answers (spinel master 7ba5b1e10). CRuby prints
# "arr-first", "hash-size", then "int-abs" and 2.5. Spinel printed 1 and 1,
# and the yield part (Integer#abs reopened to a String, Integer and Float
# blocks) did not compile.
class Array
  def first = "arr-first"
end
class Hash
  def size = "hash-size"
end
p [1, 2].first
p({a: 1}.size)

class Integer
  def abs = "int-abs"
end
def absolute = yield.abs
p absolute { -3 }
p absolute { -2.5 }
