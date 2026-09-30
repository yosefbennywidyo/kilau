# K-022: a yielding method called with blocks that answer different types
# (String at one site, Float at another) compiles to invalid C (spinel
# 8fec82476): "assigning to 'const char *' from incompatible type 'sp_float'"
# at `yield + yield`. CRuby prints "aa" and 3.0. It happens the same way with
# a top-level def, a module_function method called through the module, and a
# bare call after a top-level include. Found 2026-09-30 while fixing K-021.
def twice
  yield + yield
end
p twice { "a" }
p twice { 1.5 }
