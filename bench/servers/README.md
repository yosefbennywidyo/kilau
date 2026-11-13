# The Kilau blog behind other HTTP servers

Kilau's own HTTP server (`framework/kilau/http/server.rb`) is 95 lines of
Ruby. This directory answers what the blog gains or loses when something
else does that job. A Spinel binary cannot be hosted by a Rack server, but
Kilau is plain Ruby and also runs under CRuby, so the comparison has two
steps:

| App | Runtime | HTTP server | Processes |
|---|---|---|---|
| `kilau-spinel` | Spinel binary (`blog_routes`) | Kilau's own | 1, M:N threads on 8 workers |
| `kilau-cruby` | CRuby + YJIT | Kilau's own | 1, threads under the GVL |
| `kilau-puma` | CRuby + YJIT | Puma, 8 workers × 5 threads | 8 |
| `kilau-pitchfork` | CRuby + YJIT | Pitchfork, 8 workers | 8 |
| `kilau-falcon` | CRuby + YJIT | Falcon, 8 forked instances | 8 |
| `rails-puma` | CRuby + YJIT | Puma, 8 × 5 (`bench/rails_blog`) | 8 |

`kilau-spinel` against `kilau-cruby` changes only the runtime.
`kilau-cruby` against the three Rack servers changes only the server.
`kilau-puma` against `rails-puma` changes only the framework.

## Files

- `config.ru`: loads the blog's own `examples/blog/config.ru`, which runs
  `Kilau::RackApp` (`framework/kilau/rack_app.rb`, the framework's Rack
  front; decision D-032).
- `puma.rb`, `pitchfork.rb`: server configuration. Falcon takes its
  settings on the command line (`run.sh`).
- `run.sh`: one session over every app; `summarize.rb` turns its results
  directory into tables.
- `Gemfile`: Puma and sqlite3 at the versions `bench/rails_blog` uses.

## Running

```sh
make -C examples/blog all
(cd bench/servers && bundle config set --local path vendor/bundle && bundle install)
bench/servers/run.sh                    # about 50 minutes
ruby bench/servers/summarize.rb bench/results/<stamp>-servers
```

Keep the laptop on AC with Low Power Mode off, and compare only within one
session (`docs/FINDINGS.md` §6 says why).

## Behind nginx

`PROXY=nginx bench/servers/run.sh` starts nginx (Homebrew, `nginx` on PATH or
`NGINX=`) for every cell: keep-alive to the client and to the app over TCP.
Pitchfork closes every connection, so it gets a Unix socket and no upstream
keep-alive; without a proxy the load generator runs out of local ports and its
numbers mean nothing. Two extra app names exist for controls in the same
session: a `-direct` suffix skips the proxy (`kilau-puma-direct`), and
`kilau-puma-unix` puts Puma on the same kind of socket as Pitchfork.

Check a session before trusting it: the `-direct` rows should repeat an earlier
session on the same power state. One session here ran 2-3× slow because the
laptop was busy with something else.

## What this does not show

- Pitchfork's reforking, its main memory feature, is Linux-only and is off.
- The Rack front adds its own small cost that Kilau's server does not pay.
- nginx runs on the same laptop as the app and `oha`, so its cost here is a cost
  of sharing eight cores, not what a proxy costs on its own machine.
- `oha` runs on the same machine.
