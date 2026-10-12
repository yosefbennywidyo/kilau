# K-017b: initial (INCORRECT) diagnosis of the 2026-10-12 K-017 regression,
# kept for the record. The two-argument `elsif` shape below (a string
# literal plus a method call) looked like the trigger -- the single-
# argument form (`elsif update_binds`, no Pool#execute wrapping it) was
# evaluated correctly -- but that was a coincidence of this repro's own
# shape, not the real condition. The actual root cause (see K-017's entry
# in docs/CATALOG.md): a BARE self-call to an attr_reader (`id.nil?`, no
# `self.`) doesn't re-derive its nilability from the backing ivar the way
# `self.id.nil?` does, once a sibling write in the same branch settles the
# ivar's type to a concrete Integer/Float -- nothing to do with `elsif` or
# argument count. Fixed and merged upstream as matz/spinel#8679
# (2026-10-12 ~21:37 WIB); the minimal, correct repro for that is
# test/bare_self_call_reader_nil_check_sibling_write.rb in the spinel repo
# itself, not kept here since it's a pure compiler bug with no kilau-
# specific context. This file is left in place only because the two-
# argument elsif shape it exercises is itself a valid (now-passing)
# regression check, not because the diagnosis in its name was right.
#
# CRuby: "insert_binds called" then "true".
# Spinel (46a9efb16): "update_binds called", then "insert_binds called",
# then raises "nil given to int (RuntimeError)".
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
    if id.nil?
      self.id = db.insert("insert", insert_binds)
    elsif db.execute("update", update_binds)
    end
    true
  end
  attr_accessor :id
  def insert_binds
    puts "insert_binds called"
    Binds.new.int(1)
  end
  def update_binds
    puts "update_binds called"
    insert_binds.int(@id)
  end
end
puts Widget.new.save(Pool.new)
