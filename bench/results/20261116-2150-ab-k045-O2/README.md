# A/B 2026-11-16 ~21:50 WIB: spinel `81bac3b7e` vs `c892caf09`, both `-O2`

Same Kilau source (`cbdd209`; the `old` tree is a detached worktree of it), `blog_routes`, S3 (`GET /posts`, 100 rows,
6.773 bytes), pool 5, 8 workers, interleaved old, new; 3 s warm-up then 20 s per run, 3 reps. **AC power, Low Power Mode off**
(the 2026-11-13/14 runs were on battery with Low Power Mode on, so absolute numbers do not compare with them).

| Label | Compiler |
|---|---|
| `old` | `81bac3b7e` (`+5429`), `make COPT=-O2` in worktree `../spinel-k045-old` (the previous `-O2` install) |
| `new` | `c892caf09` (`+5532`), installed with `make clean && make install COPT=-O2` |

Means (req/s): c1 old 3.943 (3.803-4.041), new 4.002 (3.955-4.046); c16 old 4.814 (4.804-4.831), new 4.772 (4.767-4.781).
Script: `ab.sh <old-tree> <new-tree> <out> blog_routes 20 3`. Build timing/size: see K-045 in `docs/CATALOG.md`.
