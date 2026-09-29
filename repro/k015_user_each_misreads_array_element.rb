# K-015: an Integer element of a mixed Array is read as a String in Spinel
# (38dc57dd and 1ba12fb74), and String#include? on it segfaults. CRuby
# prints "bind: Integer", "bind: NilClass", then 303. Spinel prints
# "bind: String" and dies with SIGSEGV (exit 139).
#
# Each condition below was checked by removing it; without it Spinel prints
# 303 too:
# - a user class defines a method named `each` that yields (Errors#each,
#   never called; `yield 1` is enough). Renamed, or without the yield, there
#   is no crash;
# - a dead method passes an Array of Strings to the same `execute` the live
#   path uses (Migrator#migrate, never called, on an untyped @conn);
# - the live call runs inside a block captured by `&handler`, stored in an
#   ivar and called through a method (Endpoint#call); a proc literal, or
#   calling save directly, does not crash.
def check_binds(binds)
  binds.each do |value|
    $stderr.puts "bind: #{value.class}"
    case value
    when String
      puts "NUL" if value.include?("\0")
    end
  end
end

class Connection
  def execute(sql, binds) = check_binds(binds)
end

class Pool
  def insert(sql, binds) = Connection.new.execute(sql, binds)
end

class Post
  attr_accessor :id, :created_at

  def insert_binds = [@created_at, nil]

  def save(db)
    @created_at = 1790589111
    self.id = db.insert("INSERT", insert_binds)
  end
end

# Never run: a migrator whose connection is never typed.
class Migrator
  def migrate
    @migrations.each { |migration| @conn.execute("INSERT", [migration.version]) }
  end
end

class Migration
  def version = "20260928000001"
end

# Never run either: a user-defined each that yields.
class Errors
  def each
    yield 1
  end
end

class Endpoint
  def initialize(handler) = @handler = handler
  def call(a, b) = @handler.call(a, b)
end

def post_endpoint(&handler) = Endpoint.new(handler)

ep = post_endpoint { |c, r| Post.new.save(c) ? 303 : 422 }
puts ep.call(Pool.new, 0)
