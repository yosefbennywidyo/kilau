# K-067b: the same program as k067 with `r.session` used directly instead of through a local: this converges (the ablation)
class Sess
  def initialize = @d = {}
  def []=(k, v)
    @d[k] = v
  end
end
class Req
  attr_accessor :session
  def initialize = @session = nil
end
def tok(s) = (s["csrf"] = "abc")
def handle(r)
  tok(r.session)
  r.session["user"] = "7"
  1
end
x = Req.new
x.session = Sess.new
p handle(x)
