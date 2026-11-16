# Servers, spinel `c892caf09` installed `-O2`, AC power (2026-11-16 21:46-22:24 WIB)

`APPS="kilau-spinel kilau-cruby kilau-puma kilau-falcon rails-puma" bench/servers/run.sh` (kilau `35bab64`; Pitchfork left
out, it needs nginx). AC, Low Power Mode off, 5 s warm-up, 3 x 15 s, 5 s cooldown, no proxy. `summary.md` is
`bench/servers/summarize.rb` over this directory. Compare only inside this session; see FINDINGS §6 ("Semua server, ulang
dengan runtime -O2 dan daya AC"). The control (S3 c1, kilau-spinel 3.999 req/s) matches the separate A/B in
`../20261116-2150-ab-k045-O2/`.
