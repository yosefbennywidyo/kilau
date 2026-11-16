# K-054: super from a reopened NoMethodError#initialize skips a reopened NameError#initialize. CRuby: "N: M: x"; Spinel: "M: x"
class NameError
  def initialize(msg = nil, *rest, **kw) = super("N: #{msg}", *rest, **kw)
end
class NoMethodError
  def initialize(m = nil) = super("M: " + m.to_s)
end
p NoMethodError.new("x").message
