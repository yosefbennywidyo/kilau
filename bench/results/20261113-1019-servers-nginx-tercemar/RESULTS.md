- date=2026-11-13 10:19 WIB
- kilau_sha=e08137f
- machine=MacBookAir10,1 Apple M1 cores=8
- power=AC Power lowpowermode=0
- spinel=spinel 2026.10.25+4639 (d1878a068) [apple clang 21.0.0 (cc)]
- ruby=ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23] (CRuby apps run with --yjit)
-  * falcon (0.57.0); * pitchfork (0.18.2); * puma (8.0.2); * rack (3.2.8); * sqlite3 (2.9.6);
- reps=3 warmup=5 duration=15 cooldown=5 pool=5 workers=8
- proxy=nginx (nginx version: nginx/1.31.8, worker_processes auto, upstream keepalive 64; pitchfork over a Unix socket without keep-alive)

## S1 `GET /_ping`, 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 5593 | 0.17 | 0.24 | 0 | 0 | 49 | 21 | same |
| kilau-spinel-direct | 9771 | 0.10 | 0.13 | 0 | 0 | 46 | 15 | same |
| kilau-cruby | 5538 | 0.17 | 0.24 | 0 | 0 | 325 | 32 | same |
| kilau-puma | 4710 | 0.21 | 0.29 | 0 | 0 | 365 | 327 | same |
| kilau-puma-direct | 7115 | 0.13 | 0.21 | 0 | 0 | 367 | 328 | same |
| kilau-pitchfork | 4255 | 0.21 | 0.56 | 0 | 0 | 361 | 355 | same |
| kilau-falcon | 3659 | 0.26 | 0.48 | 0 | 0 | 511 | 396 | same |
| rails-puma | 2728 | 0.35 | 0.90 | 0 | 0 | 1184 | 705 | same |

## S1 `GET /_ping`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 5556 | 2.99 | 4.13 | 0 | 0 | 54 | 21 | same |
| kilau-spinel-direct | 10471 | 1.53 | 2.26 | 0 | 0 | 48 | 20 | same |
| kilau-cruby | 4290 | 3.04 | 12.01 | 0 | 0 | 298 | 34 | same |
| kilau-puma | 5720 | 2.92 | 3.92 | 0 | 0 | 389 | 320 | same |
| kilau-puma-direct | 10478 | 1.54 | 2.32 | 0 | 0 | 342 | 332 | same |
| kilau-pitchfork | 9214 | 1.60 | 4.54 | 0 | 0 | 334 | 360 | same |
| kilau-falcon | 3951 | 3.05 | 24.87 | 0 | 0 | 496 | 412 | same |
| rails-puma | 2118 | 6.24 | 28.93 | 0 | 0 | 1496 | 688 | same |

## S1 `GET /_ping`, 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 4969 | 12.79 | 16.90 | 0 | 0 | 51 | 23 | same |
| kilau-spinel-direct | 11299 | 5.97 | 6.58 | 0 | 0 | 45 | 24 | same |
| kilau-cruby | 6206 | 9.90 | 12.73 | 0 | 0 | 294 | 38 | same |
| kilau-puma | 4473 | 12.00 | 71.88 | 0 | 0 | 566 | 314 | same |
| kilau-puma-direct | 7890 | 1.39 | 108.29 | 0 | 0 | 353 | 326 | same |
| kilau-pitchfork | 7265 | 6.61 | 112.99 | 0 | 0 | 362 | 352 | same |
| kilau-falcon | 4952 | 12.97 | 15.25 | 0 | 0 | 482 | 447 | same |
| rails-puma | 2167 | 17.41 | 148.98 | 0 | 0 | 1204 | 752 | same |

## S2 `GET /posts/:id`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 4203 | 3.26 | 10.77 | 0 | 0 | 48 | 23 | same |
| kilau-spinel-direct | 7055 | 1.26 | 20.28 | 0 | 0 | 50 | 22 | same |
| kilau-cruby | 4458 | 3.16 | 10.05 | 0 | 0 | 309 | 36 | same |
| kilau-puma | 3232 | 3.84 | 15.32 | 0 | 0 | 501 | 334 | same |
| kilau-puma-direct | 4772 | 1.03 | 38.78 | 0 | 0 | 395 | 329 | same |
| kilau-pitchfork | 6471 | 1.36 | 24.54 | 0 | 0 | 510 | 341 | same |
| kilau-falcon | 6051 | 2.49 | 4.61 | 0 | 0 | 671 | 448 | same |
| rails-puma | 3540 | 3.98 | 13.67 | 0 | 0 | 1741 | 822 | same |

## S3 `GET /posts` (100 rows), 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 861 | 1.11 | 1.87 | 0 | 0 | 62 | 17 | same |
| kilau-spinel-direct | 1335 | 0.72 | 1.16 | 0 | 0 | 47 | 16 | same |
| kilau-cruby | 965 | 0.99 | 1.43 | 0 | 0 | 304 | 33 | same |
| kilau-puma | 585 | 1.65 | 3.10 | 0 | 0 | 1723 | 230 | same |
| kilau-puma-direct | 1142 | 0.81 | 1.38 | 0 | 0 | 365 | 278 | same |
| kilau-pitchfork | 1177 | 0.77 | 1.77 | 0 | 0 | 393 | 308 | same |
| kilau-falcon | 950 | 1.00 | 1.55 | 0 | 0 | 562 | 400 | same |
| rails-puma | 700 | 1.00 | 2.93 | 0 | 0 | 1298 | 582 | same |

## S3 `GET /posts` (100 rows), 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 1087 | 12.51 | 49.92 | 0 | 0 | 59 | 24 | same |
| kilau-spinel-direct | 1208 | 11.63 | 41.02 | 0 | 0 | 53 | 25 | same |
| kilau-cruby | 1136 | 13.17 | 21.49 | 0 | 0 | 309 | 46 | same |
| kilau-puma | 1623 | 7.08 | 104.43 | 0 | 0 | 381 | 333 | same |
| kilau-puma-direct | 1590 | 5.81 | 122.22 | 0 | 0 | 387 | 333 | same |
| kilau-pitchfork | 1355 | 9.28 | 107.66 | 0 | 0 | 383 | 315 | same |
| kilau-falcon | 1268 | 8.83 | 131.05 | 0 | 0 | 544 | 414 | same |
| rails-puma | 1020 | 13.70 | 55.32 | 0 | 0 | 2337 | 683 | same |

## S3 `GET /posts` (100 rows), 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 1115 | 45.68 | 225.42 | 0 | 0 | 96 | 31 | same |
| kilau-spinel-direct | 1013 | 50.96 | 249.68 | 0 | 0 | 52 | 29 | same |
| kilau-cruby | 671 | 97.39 | 149.56 | 0 | 0 | 936 | 58 | same |
| kilau-puma | 1344 | 33.72 | 211.99 | 0 | 0 | 400 | 340 | same |
| kilau-puma-direct | 1621 | 23.19 | 214.60 | 0 | 0 | 376 | 339 | same |
| kilau-pitchfork | 1408 | 39.81 | 163.54 | 0 | 0 | 370 | 311 | same |
| kilau-falcon | 1239 | 40.97 | 182.34 | 0 | 0 | 588 | 423 | same |
| rails-puma | 1083 | 46.50 | 260.09 | 0 | 0 | 1576 | 692 | same |

## S4 `POST /posts`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 4911 | 1.47 | 37.45 | 0 | 0 | 62 | 23 | — |
| kilau-spinel-direct | 7865 | 0.55 | 22.51 | 0 | 0 | 54 | 23 | — |
| kilau-cruby | 6229 | 2.55 | 5.58 | 0 | 0 | 430 | 36 | — |
| kilau-puma | 5259 | 1.24 | 29.20 | 0 | 0 | 542 | 339 | — |
| kilau-puma-direct | 6685 | 0.60 | 26.48 | 0 | 0 | 494 | 340 | — |
| kilau-pitchfork | 6226 | 1.56 | 21.87 | 0 | 0 | 502 | 349 | — |
| kilau-falcon | 5003 | 1.76 | 24.46 | 0 | 0 | 693 | 429 | — |
| rails-puma | 2605 | 4.33 | 25.75 | 0 | 0 | 1680 | 704 | — |
