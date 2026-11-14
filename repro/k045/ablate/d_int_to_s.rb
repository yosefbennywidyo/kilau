# Integer#to_s, 10M times
total = 0
n = 0
while n < 10_000_000
  total += (n % 100).to_s.bytesize
  n += 1
end
puts total
