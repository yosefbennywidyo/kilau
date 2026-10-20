# K-030 (sweep of K-029's "other names" note, 2026-10-20): a builtin called on a
# `yield` receiver, with an Integer site and a Float site, answers the Integer
# site as a Float -- silently wrong value (`49.0` for `7 ** 2`, CRuby prints `49`).
# Verified on master 30e71a00a: each method below prints the Integer answer as
# a Float. The Float site is correct; only the Integer site is wrong.
def t_pow = yield.**(2)
def t_conj = yield.conj
def t_modulo = yield.modulo(2)
def t_ceil = yield.ceil(2)
p t_pow { 2.5 }
p t_pow { 7 }
p t_conj { 2.5 }
p t_conj { 7 }
p t_modulo { 2.5 }
p t_modulo { 7 }
p t_ceil { 2.5 }
p t_ceil { 7 }
