# K-030b (sweep, 2026-10-20): a builtin the allowlist answers only for a plain
# Array receiver (sort, reverse, ...) fails to compile when one `yield` site
# receives a non-Array (Hash or String). CRuby runs cleanly.
# Compiler: `assigning to 'sp_IntArray *' from 'sp_PolyArray *'` (sort, Hash site)
# and `assigning to 'const char *' from 'sp_IntArray *'` (reverse, String site).
def t_sort = yield.sort
def t_reverse = yield.reverse
p t_sort { [3, 1, 2] }
p t_sort { {a: 1} }
p t_reverse { "abc" }
p t_reverse { [3, 1, 2] }
