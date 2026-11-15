# K-051: a program NoMethodError#initialize is run by the conditional-def dispatcher arm (CRuby never runs it). Run with an argument. CRuby: [NoMethodError, "undefined method ..."]; Spinel: message prefixed "own: "
class NoMethodError
  def initialize(m = nil) = super("own: " + m.to_s)
end
class Foo; end
if ARGV.empty?
  class Foo
    def tag = 1
  end
end
p((Foo.new.tag rescue [$!.class, $!.message]))
