# K-003: a require in a branch RUBY_ENGINE rules out is still resolved at
# parse time, so a CRuby-only gem fails the build. Kernel.require is not.
if RUBY_ENGINE == "spinel"
  puts "spinel"
else
  require "sqlite3"
  puts "cruby"
end
