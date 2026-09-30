# Kilau

A [Loco](https://loco.rs)-style web framework written in plain Ruby and compiled
ahead of time by [Spinel](https://github.com/matz/spinel) into a single native
binary.

Kilau is a **research project**. It exists to find out how far an AOT-compiled
subset of Ruby can go as a web framework, and what that costs. The first vertical
slice is a CRUD blog: an HTTP/1.1 server, a router, controllers, compiled
templates, and SQLite models. The blog runs as one 0.8 MB executable, and the
same test suite passes under Spinel and under CRuby.

> **Language note:** the catalog, decisions, findings and handoff notes in
> `docs/` are written in Indonesian. Code, comments, commit messages and this
> README are in English. References to "spec §N" and "Rencana N" (plan N) in
> comments and docs point to the design spec and implementation plans, which are
> kept outside this repository.

## Results at a glance

These numbers come from the blog against a Rails 8.1.4 app whose pages match it
byte for byte, measured with [oha](https://github.com/hatoo/oha) at 64
connections on an 8-core, 8 GB MacBook Air M1. Each figure is the median of
3 × 30 s runs. `kilau-routes` is the same blog behind the dispatcher that
`kilau gen routes` generates. Full tables are in [`bench/RESULTS.md`](bench/RESULTS.md),
and the analysis is in [`docs/FINDINGS.md`](docs/FINDINGS.md) (Indonesian).

| Scenario | kilau | kilau-routes | Rails (Puma, 8 × 5, YJIT) |
|---|---|---|---|
| `GET /_ping` | 17,128 req/s (p99 4.7 ms) | 17,156 | 9,122 (p99 36.2 ms) |
| `GET /posts/:id` | 16,339 (p99 6.1 ms) | 16,389 | 5,815 (p99 47.1 ms) |
| `GET /posts`, 100 rows | 2,530 (p99 85.7 ms) | 3,304 | 3,256 (p99 75.5 ms) |
| `POST /posts` | 8,815 (p99 51.7 ms) | 8,818 | 2,990 (p99 82.4 ms) |
| Startup to first 200 | 54 ms | 53 ms | 1.4 s |
| Peak RSS | 33 MB | 32 MB | 910 MB (8 workers) |

Read these as one laptop's numbers. The machine has no fan, oha runs on the same
host, and the two stacks use different concurrency models: Kilau is one process
with Spinel's M:N threads and no GVL, and Rails is eight Puma processes.
`docs/FINDINGS.md` §7 lists all the caveats.

## What is in the box

| Path | What it is |
|---|---|
| `framework/` | The `kilau` package: HTTP server, parser, `Request`/`Response`, Loco-style `Routes`/`AppRoutes`/`Dispatcher`, a YAML-subset `Config`, SQLite over FFI with a connection pool, models and migrations, and `Kilau::Testing` |
| `tool/` | The `kilau` build tool: `kilau gen entities`, `kilau gen templates`, `kilau gen routes` |
| `examples/blog/` | The example app: migrations, controllers, models, Tera-style templates in `assets/views/`, and two entry points: `blog_routes` (generated dispatcher, the one to deploy; decision D-023) and `blog` (route table, kept for development and as a fallback) |
| `bench/` | The Rails comparison app, the benchmark harness, raw results and `RESULTS.md` |
| `repro/` | Minimal reproductions of the Spinel limits and bugs catalogued in `docs/CATALOG.md` |
| `docs/` | `CATALOG.md` (AOT limits, K-001 to K-017), `DECISIONS.md`, `FINDINGS.md`, `HANDOFF.md` |

Spinel supports no `eval`, `method_missing`, runtime `define_method` or
reflection. Everything Rails does with runtime metaprogramming, Kilau does either
as plain explicit Ruby or with a generator that runs before the build. The
generators are themselves compiled by Spinel.

## Requirements

- **Spinel**, built from [matz/spinel](https://github.com/matz/spinel). Kilau was
  developed against `38dc57dd` and now runs on `ea9feecfe` (`2026.09.12+2826`).
  It needs at least `c6cff7c76` (matz/spinel#6151): Kilau's own tests call a
  yielding helper bare after `include Kilau::Testing`, which older compilers
  reject. Newer commits may change behaviour; see `docs/CATALOG.md` and
  `docs/HANDOFF.md`.
  If sccache is installed, Spinel's build writes package objects as `0640`;
  after `sudo make install`, run `sudo chmod a+r /usr/local/lib/spinel/packages/*/*.o`
  (see K-009 in `docs/CATALOG.md`).
  Install it so that `spinel` and `spin` are on `PATH`
  (`make deps && make && sudo make install` in the Spinel checkout).
- A C toolchain and SQLite 3 (the system library on macOS).
- Network access on the first build: the database layer is the
  [spinel-sqlite](https://github.com/yosefbennywidyo/spinel-sqlite) spin package,
  which spin fetches into its cache at the commit pinned in each `spin.lock`.
  Later builds, and `SPIN_OFFLINE=1`, use the cache.
- For the CRuby test oracle: CRuby 4.0 and the `sqlite3` gem.
- For the end-to-end test: `curl`.
- For the benchmark: `oha`, `sqlite3` (CLI), `perl`, and Bundler. The Rails app
  installs its own gems into `bench/rails_blog/vendor/bundle`.

Only macOS (Apple silicon) has been tested. The benchmark scripts use macOS
commands (`sysctl`, `sw_vers`, `stat -f`).

## Quick start

```sh
make test          # every package's snapshot tests, compiled by Spinel
make test-cruby    # the same tests under CRuby, against the same snapshots

cd examples/blog
make               # kilau gen templates + routes, then build blog and blog_routes
./build/bin/blog_routes db migrate
./build/bin/blog_routes start   # http://127.0.0.1:5150
make e2e           # drive both binaries with curl
```

`make entities` regenerates `src/models/_entities/` after a migration changes.
Configuration lives in `config/<KILAU_ENV>.yaml`, and any key can be overridden
with a `KILAU_*` environment variable (for example `KILAU_SERVER_PORT=8080`).

## Benchmark

```sh
make -C examples/blog all
bench/check_bodies.sh          # refuses to go on unless all three apps answer alike
bench/run.sh                   # the full session, about 95 minutes; QUICK=1 for a smoke run
ruby bench/summarize.rb bench/results/<stamp> > bench/RESULTS.md
```

Close other heavy applications first. On a fanless laptop, heat changes the
numbers, so the harness interleaves the apps and rests between cells.

## Status

Research code. It is not production-ready: there is no TLS, CSRF protection,
sessions or authentication, and several Spinel limits are worked around rather
than fixed (see `docs/CATALOG.md`). The next steps are in `docs/HANDOFF.md`: re-test
on the latest Spinel, route-quality work (plan 5), compiler fixes (plan 6), and a
k6-based benchmark stage.

## License

[MIT](LICENSE)
