# K-058: an error the runtime raises itself, Errno::*, and a class whose own initialize takes more than the message (NameError's name, KeyError's key:) skip a reopened StandardError#initialize. CRuby: "S[index 9 outside of array bounds: -1...1]", "S[No such file or directory - x]", "S[n]", "S[k]"; Spinel: no S[...] on any (the name and key themselves are right)
class StandardError
  def initialize(msg = nil, **kw) = super("S[#{msg}]")
end
begin; [1].fetch(9); rescue => e; p e.message; end
p Errno::ENOENT.new("x").message
n = NameError.new("n", :field)
p n.message, n.name
k = KeyError.new("k", receiver: 1, key: :kk)
p k.message, k.key, k.receiver
