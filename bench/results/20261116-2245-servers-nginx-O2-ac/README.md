# All servers behind nginx, spinel `c892caf09` installed `-O2`, AC power (2026-11-16 22:29-23:20 WIB)

`PROXY=nginx APPS="kilau-spinel-direct kilau-spinel kilau-cruby kilau-puma-direct kilau-puma kilau-puma-unix kilau-pitchfork
kilau-falcon rails-puma" CELLS="s1:16 s2:16 s3:1 s3:16 s3:64 s4:16" bench/servers/run.sh` (kilau `eed86df`). AC, Low Power Mode off,
5 s warm-up, 3 x 15 s, 5 s cooldown, nginx 1.31.8 (worker_processes auto, upstream keepalive 64; Pitchfork and `-unix` over a
Unix socket without keep-alive). 54 cells, 0 unexpected statuses, 0 errors, bodies identical (S4 has no body to compare).
`summary.md` is `bench/servers/summarize.rb` over this directory. Compare only inside this session; the `-direct` rows repeat
`../20261116-2200-servers-O2-ac/` within 0-15% (S3 c64 is 10-15% lower here for both `-direct` rows). See FINDINGS §6.
