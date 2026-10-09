# K-025c: yield.include?(v) with a poly `v`, when Array#include? is reopened
# elsewhere in the program, loses its String site's boxing and fails to
# compile C (`assigning to 'sp_RbVal' from incompatible type 'sp_bool'`).
# CRuby: true

class Array
  def include?(v)
    "reopened-array"
  end
end

def w(arg)
  yield.include?(arg)
end

mixed = [1, "a"]
arg = mixed[1]
p w(arg) { "abcxdef" }
