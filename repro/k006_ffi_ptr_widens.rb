# K-006: a :ptr returned by ffi_func widens to untyped once it is passed to
# a method or stored in an ivar. Run: spinel --warn-widen repro/k006_ffi_ptr_widens.rb
module LibC
  ffi_func :malloc, [:size_t], :ptr
  ffi_func :free, [:ptr], :void
end
class Holder
  def initialize(p)
    @p = p
  end
  def release = LibC.free(@p)
end
h = Holder.new(LibC.malloc(16))
h.release
puts "done"
