# K-052: super with a rest/splat into an Errno class / SystemExit is refused at compile time.
# CRuby runs every line; Spinel (master 93d7883bd) refuses each initialize at its super.
class MyENOENT < Errno::ENOENT
  def initialize(*args); super; end
end
class MyEACCES < Errno::EACCES
  def initialize(*args, **kw); super(*args, **kw); end
end
class MyExit < SystemExit
  def initialize(*args); super; end
end
class MyPlainSysErr < SystemCallError
  def initialize(*args); super; end
end

def show_err(e) = puts("#{e.class} | #{e.message.inspect} | #{e.errno.inspect}")
def show_exit(e) = puts("#{e.class} | #{e.message.inspect} | #{e.status.inspect} | #{e.success?}")
def show_raise(e) = puts("raises #{e.class}: #{e.message}")

begin; raise MyENOENT.new; rescue SystemCallError => e; show_err(e); end
begin; raise MyENOENT.new("file.txt"); rescue SystemCallError => e; show_err(e); end
begin; raise MyENOENT.new("file.txt", "open"); rescue SystemCallError => e; show_err(e); end
begin; MyENOENT.new("a", "b", "c"); rescue ArgumentError => e; show_raise(e); end
begin; raise MyEACCES.new("dir"); rescue SystemCallError => e; show_err(e); end
begin; raise MyExit.new(3, "bye"); rescue SystemExit => e; show_exit(e); end
begin; raise MyExit.new(false); rescue SystemExit => e; show_exit(e); end
begin; raise MyExit.new; rescue SystemExit => e; show_exit(e); end
begin; MyExit.new(1, 2, 3); rescue ArgumentError => e; show_raise(e); end
# a direct SystemCallError subclass has no errno of its own: CRuby raises TypeError for any arguments
begin; MyPlainSysErr.new("x"); rescue TypeError => e; show_raise(e); end
