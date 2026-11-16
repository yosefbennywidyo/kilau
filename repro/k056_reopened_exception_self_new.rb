# K-056: a reopened NoMethodError that defines self.new fails to compile (unknown type name sp_NoMethodError). CRuby: "x"
class NoMethodError
  def self.new(*a, **k) = super
end
p NoMethodError.new("x").message
