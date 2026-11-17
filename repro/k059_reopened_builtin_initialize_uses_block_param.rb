# K-059: a reopened builtin exception's initialize that uses its own block parameter fails in the C compiler (call to undeclared function sp_IndexError_initialize). CRuby: "I:k"
class IndexError
  def initialize(m = nil, &blk)
    x = blk.nil?
    super("I:" + m.to_s)
  end
end
p IndexError.new("k").message
