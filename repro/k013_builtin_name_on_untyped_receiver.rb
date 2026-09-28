# K-013: a user method named like a builtin (`match`) on a receiver the
# analyzer never types (the calling method is dead in this program) is
# resolved to the builtin String#match, and the C does not compile.
class Route
  def match(path) = path == "/" ? {} : nil
end

class Dispatcher
  def initialize(routes) = @routes = routes
  def call(path)
    @routes.each do |route|
      params = route.match(path)
      return params unless params.nil?
    end
    nil
  end
end

puts "Dispatcher is never used here"
