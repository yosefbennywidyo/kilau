# K-017: Spinel evaluates the argument of a call in an `elsif` condition
# before the `if` branch runs, even when the `if` branch is taken.
# CRuby prints only "insert_binds called ..." and then true. Spinel
# (38dc57dd and 1ba12fb74) first prints "update_binds called", then raises
# "nil given to int" from update_binds' .int(@id), because @id is still nil.
#
# Checked by removing each part; without it Spinel answers true too:
# - the second branch is `elsif <recv>.<call>(<arg>)`; the same code written
#   as `else; x = <recv>.<call>(<arg>); end` is correct, and so is no second
#   branch;
# - the argument (update_binds) calls the method the `if` branch uses
#   (insert_binds); an argument built on its own is correct.
# Not needed: a superclass or module, `== 0`, a raise in the branch.
# A plain `elsif check(arg)` in a top-level method is evaluated correctly.
class Binds
  def int(value)
    raise "nil given to int" if value.nil?
    self
  end

end

class Pool
  def insert(sql, binds) = 1
  def execute(sql, binds) = 1
end

class Widget
  def save(db)
    touch(123)
    if id.nil?
      self.id = db.insert("insert", insert_binds)
    elsif db.execute("update", update_binds)
    end
    true
  end

  attr_accessor :id, :created_at

  def insert_binds
    puts "insert_binds called, @created_at=#{@created_at.inspect} @id=#{@id.inspect}"
    Binds.new.int(@created_at)
  end
  def update_binds
    puts "update_binds called"
    insert_binds.int(@id)
  end

  def touch(now)
    @created_at = now
  end
end

widget = Widget.new
puts widget.save(Pool.new)
