# K-047: a Method of a String Range answers a wrong value, silently.
# CRuby 4.0.9: ["a", "b", "c"] / nil / ["a", "b", "c"]
# spinel 548d2b672: [] / nil / ["a", "b", "c"]   (the first line is wrong)
r = ("a".."c")
p r.method(:to_a).call
p r.method(:size).call
p r.to_a
