# K-019: an alias of a yielding method whose yield sits inside nested blocks
# (with { conn.query { yield } }) fails to compile under Spinel (a82686caf,
# c5898078e): the emitted C has "operand of type 'sp_Row' where arithmetic or
# pointer type is required" at the alias line and at the inner `yield`.
# CRuby prints 7. Calling the method by its own name compiles and prints 7.
# Simple aliases work: a bare `yield`, a yield inside one `each` block, and an
# alias called beside the original all print what CRuby prints.
# Found 2026-09-30 while answering CodeRabbit on matz/spinel#6008. Not reduced
# further yet.
class Row
  def initialize(v) = @v = v
  def val = @v
end
class Conn
  def query
    yield Row.new(7)
    nil
  end
end
class Pool
  def initialize = @idle = [Conn.new]
  def with
    conn = @idle.pop
    yield conn
  end
  def first_match
    found = nil
    with { |conn| conn.query { |row| found = yield(row) } }
    found
  end
  alias find first_match
end
p Pool.new.find { |row| row.val }
