# five chained gsubs on a 43-byte String, 2M times
s = "Post number 17 <with> a title & \"quotes\""
total = 0
n = 0
while n < 2_000_000
  t = s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;").gsub("'", "&#39;")
  total += t.bytesize
  n += 1
end
puts total
