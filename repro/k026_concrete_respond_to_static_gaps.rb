a = [1, 2, 3]
p a.respond_to?(:tally)
p a.respond_to?(:to_set)
h = { "a" => 1 }
p h.respond_to?(:transform_keys!)
s = "abc"
p s.respond_to?(:unicode_normalize)
