# K-049 (matz/spinel#11890): an ivar in a method added to a builtin exception -> C compile error (iv_own). CRuby: "boom"
class RuntimeError
  def initialize(m = nil)
    super(m)
    @own = 1
  end
end
begin; raise "boom"; rescue => e; p e.message; end
