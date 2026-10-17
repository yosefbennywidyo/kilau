# Same bug family as K-024 (yield.abs/-@) and its dig/succ/sum followup
# (matz/spinel#9419): `ty_recv_builtin_result` (src/types.c) only knows a
# hand-picked list of builtin names. Any OTHER builtin called on a `yield`
# receiver without its own block, across call sites with different
# concrete receiver/element kinds, emits invalid C instead of compiling --
# confirmed for at least these 11 names (there are certainly more; this is
# not exhaustive). Spinel refuses to compile a valid, unambiguous Ruby
# program -- a loud failure, not a silently wrong value, but a real gap.
def t_sort_bang = yield.sort!
p t_sort_bang { [3, 1, 2] }
p t_sort_bang { ["b", "a"] }

def t_reverse_bang = yield.reverse!
p t_reverse_bang { [1, 2, 3] }
p t_reverse_bang { ["x", "y"] }

def t_rotate = yield.rotate
p t_rotate { [1, 2, 3] }
p t_rotate { ["a", "b", "c"] }

def t_shuffle = yield.shuffle
p t_shuffle { [1] }
p t_shuffle { ["a"] }

def t_sample = yield.sample
p t_sample { [1] }
p t_sample { ["a"] }

def t_take = yield.take(1)
p t_take { [1, 2, 3] }
p t_take { ["a", "b", "c"] }

def t_drop = yield.drop(1)
p t_drop { [1, 2, 3] }
p t_drop { ["a", "b", "c"] }

def t_first_n = yield.first(2)
p t_first_n { [1, 2, 3] }
p t_first_n { ["a", "b", "c"] }

def t_last_n = yield.last(2)
p t_last_n { [1, 2, 3] }
p t_last_n { ["a", "b", "c"] }

def t_fetch = yield.fetch(0)
p t_fetch { [1, 2, 3] }
p t_fetch { ["a", "b", "c"] }

def t_clamp = yield.clamp(0, 5)
p t_clamp { 3 }
p t_clamp { 7.5 }
