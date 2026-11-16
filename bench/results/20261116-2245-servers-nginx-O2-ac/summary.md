- date=2026-11-16 22:29 WIB
- kilau_sha=eed86df
- machine=MacBookAir10,1 Apple M1 cores=8
- power=AC Power lowpowermode=0
- spinel=spinel 2026.10.25+5532 (c892caf09) [apple clang 21.0.0 (cc)]
- ruby=ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23] (CRuby apps run with --yjit)
-  * falcon (0.57.0); * pitchfork (0.18.2); * puma (8.0.2); * rack (3.2.8); * sqlite3 (2.9.6);
- reps=3 warmup=5 duration=15 cooldown=5 pool=5 workers=8
- proxy=nginx (nginx version: nginx/1.31.8, worker_processes auto, upstream keepalive 64; pitchfork over a Unix socket without keep-alive)

## S1 `GET /_ping`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 15086 | 1.05 | 1.31 | 0 | 0 | 54 | 21 | same |
| kilau-spinel-direct | 34598 | 0.45 | 0.63 | 0 | 0 | 37 | 20 | same |
| kilau-cruby | 14782 | 1.06 | 1.39 | 0 | 0 | 277 | 35 | same |
| kilau-puma | 13390 | 1.18 | 1.77 | 0 | 0 | 321 | 336 | same |
| kilau-puma-unix | 24598 | 0.62 | 1.34 | 0 | 0 | 312 | 336 | same |
| kilau-puma-direct | 26024 | 0.58 | 1.41 | 0 | 0 | 326 | 339 | same |
| kilau-pitchfork | 21388 | 0.56 | 2.85 | 0 | 0 | 334 | 361 | same |
| kilau-falcon | 12749 | 1.22 | 2.10 | 0 | 0 | 461 | 464 | same |
| rails-puma | 10529 | 1.38 | 3.94 | 0 | 0 | 1167 | 805 | same |

## S2 `GET /posts/:id`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 13416 | 1.17 | 1.52 | 0 | 0 | 54 | 22 | same |
| kilau-spinel-direct | 26418 | 0.59 | 0.89 | 0 | 0 | 47 | 22 | same |
| kilau-cruby | 13529 | 1.17 | 1.55 | 0 | 0 | 295 | 38 | same |
| kilau-puma | 11802 | 1.31 | 2.11 | 0 | 0 | 296 | 336 | same |
| kilau-puma-unix | 19274 | 0.70 | 2.93 | 0 | 0 | 333 | 341 | same |
| kilau-puma-direct | 23745 | 0.59 | 2.13 | 0 | 0 | 346 | 344 | same |
| kilau-pitchfork | 16151 | 0.76 | 3.69 | 0 | 0 | 377 | 338 | same |
| kilau-falcon | 12250 | 1.26 | 2.53 | 0 | 0 | 465 | 471 | same |
| rails-puma | 7506 | 1.75 | 7.69 | 0 | 0 | 1149 | 888 | same |

## S3 `GET /posts` (100 rows), 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 2972 | 0.31 | 0.49 | 0 | 0 | 52 | 19 | same |
| kilau-spinel-direct | 3992 | 0.23 | 0.37 | 0 | 0 | 47 | 16 | same |
| kilau-cruby | 1199 | 0.81 | 1.04 | 0 | 0 | 294 | 33 | same |
| kilau-puma | 1169 | 0.83 | 1.14 | 0 | 0 | 365 | 335 | same |
| kilau-puma-unix | 1648 | 0.57 | 0.91 | 0 | 0 | 326 | 332 | same |
| kilau-puma-direct | 1744 | 0.54 | 0.87 | 0 | 0 | 338 | 333 | same |
| kilau-pitchfork | 1745 | 0.55 | 0.87 | 0 | 0 | 366 | 311 | same |
| kilau-falcon | 1105 | 0.85 | 1.34 | 0 | 0 | 497 | 420 | same |
| rails-puma | 1096 | 0.87 | 1.52 | 0 | 0 | 1208 | 716 | same |

## S3 `GET /posts` (100 rows), 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 3875 | 3.76 | 9.99 | 0 | 0 | 55 | 25 | same |
| kilau-spinel-direct | 4757 | 3.20 | 7.76 | 0 | 0 | 50 | 25 | same |
| kilau-cruby | 2907 | 5.44 | 9.64 | 0 | 0 | 291 | 48 | same |
| kilau-puma | 5794 | 2.47 | 7.95 | 0 | 0 | 340 | 343 | same |
| kilau-puma-unix | 5569 | 2.41 | 10.14 | 0 | 0 | 342 | 343 | same |
| kilau-puma-direct | 7140 | 1.84 | 7.71 | 0 | 0 | 346 | 338 | same |
| kilau-pitchfork | 5251 | 2.83 | 6.56 | 0 | 0 | 344 | 320 | same |
| kilau-falcon | 4379 | 3.07 | 12.10 | 0 | 0 | 488 | 451 | same |
| rails-puma | 3793 | 3.61 | 13.17 | 0 | 0 | 1175 | 756 | same |

## S3 `GET /posts` (100 rows), 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 3412 | 18.60 | 51.96 | 0 | 0 | 47 | 27 | same |
| kilau-spinel-direct | 3911 | 16.44 | 43.47 | 0 | 0 | 50 | 27 | same |
| kilau-cruby | 2525 | 26.30 | 36.62 | 0 | 0 | 277 | 62 | same |
| kilau-puma | 4462 | 6.51 | 179.08 | 0 | 0 | 321 | 373 | same |
| kilau-puma-unix | 5705 | 5.08 | 138.54 | 0 | 0 | 336 | 372 | same |
| kilau-puma-direct | 5688 | 9.47 | 34.64 | 0 | 0 | 338 | 373 | same |
| kilau-pitchfork | 5885 | 10.44 | 15.65 | 0 | 0 | 303 | 319 | same |
| kilau-falcon | 4448 | 12.20 | 42.18 | 0 | 0 | 478 | 448 | same |
| rails-puma | 3789 | 7.45 | 191.01 | 0 | 0 | 1177 | 859 | same |

## S4 `POST /posts`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 9813 | 0.76 | 14.01 | 0 | 0 | 55 | 23 | — |
| kilau-spinel-direct | 15384 | 0.34 | 10.79 | 0 | 0 | 49 | 23 | — |
| kilau-cruby | 9472 | 1.67 | 4.11 | 0 | 0 | 286 | 36 | — |
| kilau-puma | 8480 | 0.62 | 21.05 | 0 | 0 | 453 | 343 | — |
| kilau-puma-unix | 10062 | 0.30 | 21.26 | 0 | 0 | 368 | 341 | — |
| kilau-puma-direct | 9637 | 0.34 | 22.17 | 0 | 0 | 333 | 342 | — |
| kilau-pitchfork | 9031 | 1.03 | 10.51 | 0 | 0 | 305 | 348 | — |
| kilau-falcon | 7336 | 0.92 | 20.35 | 0 | 0 | 479 | 458 | — |
| rails-puma | 3714 | 2.91 | 18.71 | 0 | 0 | 1176 | 745 | — |
