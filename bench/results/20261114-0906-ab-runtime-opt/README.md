# A/B 2026-11-14 ~09:06 WIB: installed spinel (-O0 build) vs a clean -O2 build

Same Kilau source (`9301664`), S3 (`GET /posts`, 100 rows), `blog_routes`, pool 5, 8 workers, interleaved
old, new; 3 s warm-up then 20 s per run. Battery, Low Power Mode on; another session was building on the laptop,
so only the pairs inside `ab_s3.log` compare.

| Label | Compiler |
|---|---|
| `old` | installed `01ef5b4b2`, built with `COPT=-O0 -g0` from the spinel checkout's `config.mk` |
| `new` | master `020275b35`, built in a clean worktree with the default `-O2` |

Script: `ab.sh <old-tree> <new-tree> <out> blog_routes 20 3`. See K-045 in `docs/CATALOG.md`.
