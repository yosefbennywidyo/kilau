# K-016: a local assigned inside a block nested two deep comes back nil when
# the method is reached through a proc stored in an ivar. CRuby prints 200,
# Spinel (38dc57dd and 1ba12fb74) prints 404.
#
# Each condition below was checked by removing it; without it the program
# prints 200 under Spinel too:
# - the assignment `found = yield(row)` sits two block levels deep
#   (with { query { ... } }); one level works;
# - the outer block's argument comes out of a collection (`@idle.pop`, an
#   Array or a Thread::Queue); an object held in an ivar works;
# - query_first is called on a proc parameter (so its receiver is untyped),
#   and the proc is stored in an ivar and called from a method
#   (Endpoint#call); calling the proc from a local works.
class Row
  def initialize(v) = @v = v
  def int(i) = @v
end

class Conn
  def query(sql, binds)
    yield Row.new(1)
    nil
  end
end

class Pool
  def initialize
    @idle = []
    @idle << Conn.new
  end

  def with
    conn = @idle.pop
    yield conn
  end

  def query_first(sql, binds)
    found = nil
    with { |conn| conn.query(sql, binds) { |row| found = yield(row) } }
    found
  end
end

class Endpoint
  def initialize(handler) = @handler = handler
  def call(a, b) = @handler.call(a, b)
end

ep = Endpoint.new(proc { |c, r| c.query_first("q", 1) { |row| row.int(0) }.nil? ? 404 : 200 })
puts ep.call(Pool.new, 0)
