# buf << literal and buf << String, no gsub: 100 rows x 20k
s = "Post number 17 with a title and quotes"
total = 0
n = 0
while n < 20_000
  buf = +""
  i = 0
  while i < 100
    buf << "<li><a href=\"/posts/"
    buf << "17"
    buf << "\">"
    buf << s
    buf << "</a></li>\n"
    i += 1
  end
  total += buf.bytesize
  n += 1
end
puts total
