# one gsub that matches nothing, 10M times
s = "Post number 17 <with> a title & \"quotes\""
total = 0
n = 0
while n < 10_000_000
  t = s.gsub("'", "&#39;")
  total += t.bytesize
  n += 1
end
puts total
