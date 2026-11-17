# K-058: an error the runtime raises itself, and Errno::*, skip a reopened StandardError#initialize. CRuby: "S[index 9 outside of array bounds: -1...1]" then "S[No such file or directory - x]"; Spinel: no S[...] on either
class StandardError
  def initialize(msg = nil) = super("S[#{msg}]")
end
begin; [1].fetch(9); rescue => e; p e.message; end
p Errno::ENOENT.new("x").message
