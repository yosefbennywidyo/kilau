# K-004: a method that takes a block, reached through a top-level
# include, is never emitted: the link fails on an undefined symbol.
# The same method called as a module method, or included in a class, works.
module Helper
  def check(label)
    raise "FAIL: #{label}" unless yield
    puts "ok #{label}"
  end
end
include Helper
check("flat yield") { 1 + 1 == 2 }
