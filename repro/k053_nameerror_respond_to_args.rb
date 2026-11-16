# K-053: NameError (not NoMethodError) answers respond_to?(:args) true in Spinel. CRuby: false, true.
p NameError.new("m", :x).respond_to?(:args)
p NoMethodError.new("m", :x).respond_to?(:args)
