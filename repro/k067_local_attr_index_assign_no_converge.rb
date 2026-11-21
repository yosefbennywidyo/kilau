# K-067: a local bound to an object's attribute, passed to a function that does []= on it, then written with []= again: "type inference did not converge in 128 rounds"
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
  jar = r.session
  tok(jar)
  jar["user"] = "7"
  1
end
x = Req.new
x.session = Sess.new
p handle(x)
