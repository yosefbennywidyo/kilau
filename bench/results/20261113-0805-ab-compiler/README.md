# A/B 2026-11-13 ~08:05 WIB: which side lost S3 speed since September

Battery, Low Power Mode on (see each log's last line), so only the pairs inside
one log compare. Runs are interleaved old, new, old, new; 3 s warm-up then
20 s (S3) or 15 s (S1, S2) per run; `blog_routes`, pool 5, 8 workers, fresh
seed database per run. Script: `ab.sh <old-tree> <new-tree> <out> blog_routes`.

| Log | old | new |
|---|---|---|
| `ab_kilau_code_same_compiler.log` | Kilau `2ee4980` (September benchmark commit) | Kilau `27ba1a6`; both built by spinel `d1878a068` |
| `ab_compiler_s3.log` | Kilau `2ee4980` built by spinel `38dc57dde` | the same source built by `d1878a068` |
| `ab_compiler_s1_s2.log` | as above, `GET /_ping` and `GET /posts/42` | as above |

`sample-oldc-top.txt` / `sample-newc-top.txt`: `sample <pid> 5` of each binary
under `oha -c 1` on `/posts`, "Sort by top of stack" only.
