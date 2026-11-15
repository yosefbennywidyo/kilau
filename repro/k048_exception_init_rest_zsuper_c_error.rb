# K-048 (matz/spinel#11889): a bare super in an exception initialize with a rest parameter -> C compile error. CRuby: "x"
class AppError < StandardError
  def initialize(*a)
    super
  end
end
p AppError.new("x").message
