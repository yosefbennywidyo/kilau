class Array
  private :first
end
begin
  p [1, 2, 3].first
rescue NoMethodError => e
  p e.message
end
p [1, 2, 3].respond_to?(:first)
