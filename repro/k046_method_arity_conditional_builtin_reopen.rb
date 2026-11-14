if ARGV.empty?
  class Array
    def inject(a, b) = 1
  end
end
p [1].method(:inject).arity
m = [1].method(:inject)
p m.arity
