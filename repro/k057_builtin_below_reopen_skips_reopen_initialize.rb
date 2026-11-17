# K-057: a builtin exception with no reopening of its own, below a reopened one that defines initialize, skips that initialize. CRuby: "S[a]", "S[f]"; Spinel: "a", "f"
class StandardError
  def initialize(msg = nil) = super("S[#{msg}]")
end
p ArgumentError.new("a").message
p FrozenError.new("f").message
