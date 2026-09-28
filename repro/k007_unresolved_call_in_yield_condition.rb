# K-007: a call no class defines, inside a block whose result feeds
# `unless yield`, is refused as a non-bool condition (or, in a larger
# program, compiles to invalid C) instead of reporting the missing method.
module Chk
  def self.check(label)
    raise "FAIL: #{label}" unless yield
    puts "ok #{label}"
  end
end
class Gadget
end
Chk.check("unresolved call in block") { Gadget.new.save(1) }
