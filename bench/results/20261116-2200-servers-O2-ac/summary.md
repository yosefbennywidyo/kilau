- date=2026-11-16 21:46 WIB
- kilau_sha=35bab64
- machine=MacBookAir10,1 Apple M1 cores=8
- power=AC Power lowpowermode=0
- spinel=spinel 2026.10.25+5532 (c892caf09) [apple clang 21.0.0 (cc)]
- ruby=ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23] (CRuby apps run with --yjit)
-  * falcon (0.57.0); * pitchfork (0.18.2); * puma (8.0.2); * rack (3.2.8); * sqlite3 (2.9.6);
- reps=3 warmup=5 duration=15 cooldown=5 pool=5 workers=8
- proxy=none

## S1 `GET /_ping`, 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 10253 | 0.09 | 0.12 | 0 | 0 | 44 | 15 | same |
| kilau-cruby | 10550 | 0.09 | 0.13 | 0 | 0 | 280 | 32 | same |
| kilau-puma | 7935 | 0.12 | 0.22 | 0 | 0 | 346 | 330 | same |
| kilau-falcon | 5961 | 0.16 | 0.40 | 0 | 0 | 549 | 326 | same |
| rails-puma | 4565 | 0.20 | 0.52 | 0 | 0 | 1285 | 652 | same |

## S1 `GET /_ping`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 31108 | 0.50 | 0.69 | 0 | 0 | 49 | 20 | same |
| kilau-cruby | 28673 | 0.55 | 0.85 | 0 | 0 | 268 | 34 | same |
| kilau-puma | 26679 | 0.57 | 1.26 | 0 | 0 | 327 | 344 | same |
| kilau-falcon | 22783 | 0.54 | 2.00 | 0 | 0 | 386 | 424 | same |
| rails-puma | 13465 | 0.95 | 4.51 | 0 | 0 | 922 | 674 | same |

## S1 `GET /_ping`, 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 28466 | 2.26 | 2.53 | 0 | 0 | 50 | 24 | same |
| kilau-cruby | 28174 | 2.26 | 3.10 | 0 | 0 | 260 | 39 | same |
| kilau-puma | 26212 | 2.42 | 3.63 | 0 | 0 | 324 | 354 | same |
| kilau-falcon | 23962 | 2.36 | 7.74 | 0 | 0 | 491 | 457 | same |
| rails-puma | 13351 | 3.90 | 17.16 | 0 | 0 | 1164 | 678 | same |

## S2 `GET /posts/:id`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 26263 | 0.59 | 0.88 | 0 | 0 | 47 | 22 | same |
| kilau-cruby | 18103 | 0.87 | 1.75 | 0 | 0 | 283 | 35 | same |
| kilau-puma | 21703 | 0.63 | 2.46 | 0 | 0 | 378 | 344 | same |
| kilau-falcon | 15825 | 0.92 | 2.68 | 0 | 0 | 517 | 432 | same |
| rails-puma | 6728 | 1.84 | 9.45 | 0 | 0 | 1167 | 849 | same |

## S3 `GET /posts` (100 rows), 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 3999 | 0.23 | 0.37 | 0 | 0 | 48 | 16 | same |
| kilau-cruby | 1857 | 0.51 | 0.74 | 0 | 0 | 308 | 33 | same |
| kilau-puma | 1692 | 0.56 | 0.86 | 0 | 0 | 400 | 334 | same |
| kilau-falcon | 1568 | 0.57 | 1.03 | 0 | 0 | 500 | 364 | same |
| rails-puma | 1625 | 0.57 | 1.19 | 0 | 0 | 1194 | 672 | same |

## S3 `GET /posts` (100 rows), 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 4809 | 3.18 | 7.80 | 0 | 0 | 51 | 24 | same |
| kilau-cruby | 3094 | 5.11 | 9.04 | 0 | 0 | 297 | 48 | same |
| kilau-puma | 7221 | 1.67 | 7.74 | 0 | 0 | 358 | 341 | same |
| kilau-falcon | 5860 | 1.95 | 8.79 | 0 | 0 | 489 | 427 | same |
| rails-puma | 5077 | 2.33 | 12.28 | 0 | 0 | 1214 | 728 | same |

## S3 `GET /posts` (100 rows), 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 4349 | 14.82 | 38.73 | 0 | 0 | 52 | 28 | same |
| kilau-cruby | 2539 | 25.42 | 36.15 | 0 | 0 | 306 | 47 | same |
| kilau-puma | 6691 | 8.41 | 32.34 | 0 | 0 | 365 | 372 | same |
| kilau-falcon | 6131 | 9.15 | 30.08 | 0 | 0 | 501 | 428 | same |
| rails-puma | 6121 | 9.22 | 34.97 | 0 | 0 | 1169 | 745 | same |

## S4 `POST /posts`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 15874 | 0.34 | 10.90 | 0 | 0 | 47 | 23 | — |
| kilau-cruby | 12450 | 1.22 | 3.43 | 0 | 0 | 280 | 35 | — |
| kilau-puma | 9433 | 0.34 | 22.63 | 0 | 0 | 336 | 342 | — |
| kilau-falcon | 8135 | 0.57 | 21.35 | 0 | 0 | 506 | 435 | — |
| rails-puma | 3964 | 2.56 | 19.38 | 0 | 0 | 1214 | 745 | — |
