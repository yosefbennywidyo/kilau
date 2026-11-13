- date=2026-11-13 12:42 WIB
- kilau_sha=e08137f
- machine=MacBookAir10,1 Apple M1 cores=8
- power=Battery Power lowpowermode=1
- spinel=spinel 2026.10.25+4639 (d1878a068) [apple clang 21.0.0 (cc)]
- ruby=ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23] (CRuby apps run with --yjit)
-  * falcon (0.57.0); * pitchfork (0.18.2); * puma (8.0.2); * rack (3.2.8); * sqlite3 (2.9.6);
- reps=3 warmup=5 duration=15 cooldown=5 pool=5 workers=8
- proxy=nginx (nginx version: nginx/1.31.8, worker_processes auto, upstream keepalive 64; pitchfork over a Unix socket without keep-alive)

## S1 `GET /_ping`, 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 3770 | 0.25 | 0.49 | 0 | 0 | 56 | 16 | same |
| kilau-spinel-direct | 6504 | 0.15 | 0.26 | 0 | 0 | 70 | 15 | same |
| kilau-cruby | 4018 | 0.24 | 0.35 | 0 | 0 | 420 | 32 | same |
| kilau-puma | 3362 | 0.28 | 0.56 | 0 | 0 | 545 | 271 | same |
| kilau-puma-direct | 5426 | 0.17 | 0.31 | 0 | 0 | 572 | 262 | same |
| kilau-pitchfork | 4352 | 0.21 | 0.40 | 0 | 0 | 555 | 334 | same |
| kilau-falcon | 2936 | 0.31 | 0.70 | 0 | 0 | 753 | 319 | same |
| rails-puma | 2044 | 0.42 | 1.32 | 0 | 0 | 1870 | 448 | same |

## S1 `GET /_ping`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 7237 | 2.07 | 4.32 | 0 | 0 | 66 | 20 | same |
| kilau-spinel-direct | 15546 | 1.01 | 1.63 | 0 | 0 | 57 | 20 | same |
| kilau-cruby | 8067 | 1.95 | 3.50 | 0 | 0 | 487 | 33 | same |
| kilau-puma | 6995 | 2.10 | 4.43 | 0 | 0 | 555 | 321 | same |
| kilau-puma-direct | 14420 | 1.06 | 1.78 | 0 | 0 | 533 | 321 | same |
| kilau-pitchfork | 11955 | 1.21 | 3.53 | 0 | 0 | 546 | 357 | same |
| kilau-falcon | 7316 | 2.08 | 3.81 | 0 | 0 | 850 | 412 | same |
| rails-puma | 3622 | 3.36 | 20.84 | 0 | 0 | 4130 | 531 | same |

## S1 `GET /_ping`, 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 7326 | 8.20 | 16.70 | 0 | 0 | 76 | 22 | same |
| kilau-spinel-direct | 15684 | 4.02 | 5.16 | 0 | 0 | 60 | 23 | same |
| kilau-cruby | 7044 | 8.23 | 23.20 | 0 | 0 | 446 | 37 | same |
| kilau-puma | 5469 | 10.23 | 43.49 | 0 | 0 | 541 | 311 | same |
| kilau-puma-direct | 10129 | 5.09 | 36.37 | 0 | 0 | 626 | 310 | same |
| kilau-pitchfork | 9301 | 5.07 | 71.42 | 0 | 0 | 569 | 346 | same |
| kilau-falcon | 6049 | 10.11 | 24.47 | 0 | 0 | 799 | 418 | same |
| rails-puma | 4416 | 10.03 | 132.87 | 0 | 0 | 2025 | 667 | same |

## S2 `GET /posts/:id`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 6748 | 2.33 | 4.14 | 0 | 0 | 70 | 21 | same |
| kilau-spinel-direct | 14049 | 1.13 | 1.95 | 0 | 0 | 56 | 21 | same |
| kilau-cruby | 7540 | 2.01 | 3.34 | 0 | 0 | 450 | 34 | same |
| kilau-puma | 6917 | 2.29 | 3.88 | 0 | 0 | 542 | 317 | same |
| kilau-puma-direct | 9025 | 1.33 | 8.83 | 0 | 0 | 640 | 326 | same |
| kilau-pitchfork | 8396 | 1.34 | 15.96 | 0 | 0 | 607 | 324 | same |
| kilau-falcon | 6219 | 2.40 | 5.58 | 0 | 0 | 754 | 387 | same |
| rails-puma | 3859 | 3.52 | 14.00 | 0 | 0 | 1792 | 828 | same |

## S3 `GET /posts` (100 rows), 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 980 | 0.92 | 2.01 | 0 | 0 | 61 | 18 | same |
| kilau-spinel-direct | 1429 | 0.66 | 1.10 | 0 | 0 | 55 | 16 | same |
| kilau-cruby | 959 | 1.01 | 1.38 | 0 | 0 | 433 | 33 | same |
| kilau-puma | 898 | 1.06 | 1.57 | 0 | 0 | 549 | 308 | same |
| kilau-puma-direct | 1216 | 0.75 | 1.32 | 0 | 0 | 594 | 275 | same |
| kilau-pitchfork | 1190 | 0.76 | 1.43 | 0 | 0 | 568 | 291 | same |
| kilau-falcon | 880 | 1.06 | 1.82 | 0 | 0 | 733 | 354 | same |
| rails-puma | 909 | 1.03 | 2.03 | 0 | 0 | 1793 | 488 | same |

## S3 `GET /posts` (100 rows), 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 1782 | 8.63 | 20.20 | 0 | 0 | 64 | 24 | same |
| kilau-spinel-direct | 1852 | 8.31 | 18.00 | 0 | 0 | 60 | 25 | same |
| kilau-cruby | 1962 | 8.14 | 10.06 | 0 | 0 | 430 | 46 | same |
| kilau-puma | 3424 | 4.31 | 11.15 | 0 | 0 | 531 | 334 | same |
| kilau-puma-direct | 4063 | 2.99 | 16.66 | 0 | 0 | 514 | 317 | same |
| kilau-pitchfork | 3768 | 3.92 | 11.09 | 0 | 0 | 522 | 310 | same |
| kilau-falcon | 3175 | 3.95 | 24.54 | 0 | 0 | 702 | 407 | same |
| rails-puma | 2688 | 5.23 | 16.91 | 0 | 0 | 1728 | 683 | same |

## S3 `GET /posts` (100 rows), 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 1754 | 35.43 | 107.40 | 0 | 0 | 64 | 25 | same |
| kilau-spinel-direct | 1777 | 34.91 | 86.69 | 0 | 0 | 61 | 28 | same |
| kilau-cruby | 1712 | 36.47 | 50.28 | 0 | 0 | 436 | 56 | same |
| kilau-puma | 3019 | 11.19 | 158.05 | 0 | 0 | 535 | 339 | same |
| kilau-puma-direct | 4066 | 13.68 | 61.11 | 0 | 0 | 487 | 360 | same |
| kilau-pitchfork | 3866 | 15.75 | 27.71 | 0 | 0 | 548 | 319 | same |
| kilau-falcon | 2750 | 18.76 | 83.56 | 0 | 0 | 695 | 428 | same |
| rails-puma | 2685 | 10.81 | 205.43 | 0 | 0 | 1747 | 704 | same |

## S4 `POST /posts`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 6216 | 1.16 | 23.66 | 0 | 0 | 63 | 23 | — |
| kilau-spinel-direct | 10718 | 0.49 | 20.44 | 0 | 0 | 53 | 23 | — |
| kilau-cruby | 7454 | 2.13 | 5.02 | 0 | 0 | 432 | 36 | — |
| kilau-puma | 6159 | 1.04 | 23.35 | 0 | 0 | 539 | 339 | — |
| kilau-puma-direct | 6884 | 0.69 | 23.75 | 0 | 0 | 513 | 339 | — |
| kilau-pitchfork | 6291 | 1.53 | 21.04 | 0 | 0 | 524 | 348 | — |
| kilau-falcon | 5684 | 1.44 | 22.41 | 0 | 0 | 778 | 424 | — |
| rails-puma | 2656 | 4.40 | 25.55 | 0 | 0 | 1721 | 675 | — |
