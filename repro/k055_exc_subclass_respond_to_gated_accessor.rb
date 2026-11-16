# K-055: a program class below a builtin exception answers false for its parent's class-gated accessor. CRuby: true false
class MyKE < KeyError; end
p MyKE.new("m").respond_to?(:key), MyKE.new("m").respond_to?(:args)
