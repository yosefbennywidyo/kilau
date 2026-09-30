# K-024: a builtin method called on a yield, from a method whose blocks answer
# different types at different call sites (spinel df5067a63, which already
# has the K-022 fixes #6185, #6219 and, pending, #6226).
#
# Codegen lowers the method per site from that site's block type
# (sp_yield_site_type), but the method's value slot is typed from the first
# site, and the concrete per-site result goes into it unboxed.
#
# CRuby prints 3, 2.5, 1, 1. Spinel prints 3 and then 2 for -2.5.abs, a
# wrong value with no error. Uncomment the `first` pair to see the other
# shape, which does not compile ("incompatible pointer to integer conversion").
def absolute = yield.abs
p absolute { -3 }
p absolute { -2.5 }

# def head = yield.first
# p head { [1, 2] }
# p head { "ab".chars }

def sized = yield.size
p sized { [1] }
p sized { "a" }
