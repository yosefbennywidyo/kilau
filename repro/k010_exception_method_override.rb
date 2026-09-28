# K-010: a method a subclass of an exception overrides, called on the
# exception rescued as its base class, fails to compile in Spinel
# (no member named 'cls_id' in 'struct sp_Exception_s'). Storing the value
# in an ivar through initialize(status, message) + super works.
class AppErr < StandardError
  def status = 500
end
class NotFoundErr < AppErr
  def status = 404
end
begin
  raise NotFoundErr, "x"
rescue AppErr => e
  puts e.status
end
