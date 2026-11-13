- date=2026-11-13 08:34 WIB
- kilau_sha=ae36e39
- machine=MacBookAir10,1 Apple M1 cores=8
- power=Battery Power lowpowermode=1
- spinel=spinel 2026.10.25+4639 (d1878a068) [apple clang 21.0.0 (cc)]
- ruby=ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23] (CRuby apps run with --yjit)
-  * falcon (0.57.0); * pitchfork (0.18.2); * puma (8.0.2); * rack (3.2.8); * sqlite3 (2.9.6);
- reps=3 warmup=5 duration=15 cooldown=5 pool=5 workers=8

## S1 `GET /_ping`, 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 6737 | 0.14 | 0.18 | 0 | 0 | 55 | 15 | same |
| kilau-cruby | 7473 | 0.13 | 0.19 | 0 | 0 | 444 | 32 | same |
| kilau-puma | 5561 | 0.17 | 0.27 | 0 | 0 | 533 | 310 | same |
| kilau-pitchfork | 792 | 1.15 | 2.37 | 0 | 0 | 531 | 329 | same |
| kilau-falcon | 4437 | 0.21 | 0.56 | 0 | 0 | 733 | 315 | same |
| rails-puma | 2910 | 0.30 | 0.97 | 0 | 0 | 1725 | 605 | same |

## S1 `GET /_ping`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 16149 | 0.97 | 1.56 | 0 | 0 | 51 | 20 | same |
| kilau-cruby | 15898 | 0.98 | 1.43 | 0 | 0 | 442 | 34 | same |
| kilau-puma | 14682 | 1.04 | 1.66 | 0 | 0 | 558 | 325 | same |
| kilau-pitchfork | 2055 | 6.60 | 14.18 | 0 | 15343 | 518 | 324 | same |
| kilau-falcon | 12076 | 1.16 | 4.13 | 0 | 0 | 832 | 395 | same |
| rails-puma | 8163 | 1.52 | 8.18 | 0 | 0 | 1748 | 631 | same |

## S1 `GET /_ping`, 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 11868 | 4.97 | 29.46 | 0 | 0 | 48 | 23 | same |
| kilau-cruby | 14086 | 4.56 | 8.09 | 0 | 0 | 543 | 38 | same |
| kilau-puma | 12709 | 4.81 | 10.45 | 0 | 0 | 489 | 327 | same |
| kilau-pitchfork | 2159 | 28.20 | 69.60 | 0 | 10588 | 503 | 332 | same |
| kilau-falcon | 13254 | 4.74 | 10.24 | 0 | 0 | 748 | 426 | same |
| rails-puma | 8861 | 5.60 | 38.69 | 0 | 0 | 1770 | 628 | same |

## S2 `GET /posts/:id`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 12053 | 1.26 | 1.98 | 0 | 0 | 54 | 22 | same |
| kilau-cruby | 10440 | 1.56 | 2.50 | 0 | 0 | 475 | 35 | same |
| kilau-puma | 10640 | 1.50 | 2.92 | 0 | 0 | 514 | 335 | same |
| kilau-pitchfork | 1863 | 8.29 | 13.67 | 0 | 8352 | 533 | 304 | same |
| kilau-falcon | 9476 | 1.51 | 5.04 | 0 | 0 | 689 | 394 | same |
| rails-puma | 4377 | 2.82 | 14.49 | 0 | 0 | 1723 | 780 | same |

## S3 `GET /posts` (100 rows), 1 connection

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 1449 | 0.67 | 1.05 | 0 | 0 | 48 | 16 | same |
| kilau-cruby | 1330 | 0.71 | 1.05 | 0 | 0 | 444 | 33 | same |
| kilau-puma | 1260 | 0.74 | 1.22 | 0 | 0 | 572 | 263 | same |
| kilau-pitchfork | 497 | 1.94 | 3.51 | 0 | 0 | 497 | 306 | same |
| kilau-falcon | 1082 | 0.82 | 1.54 | 0 | 0 | 693 | 308 | same |
| rails-puma | 1209 | 0.76 | 1.63 | 0 | 0 | 1839 | 546 | same |

## S3 `GET /posts` (100 rows), 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 1599 | 9.57 | 21.30 | 0 | 0 | 50 | 26 | same |
| kilau-cruby | 1974 | 8.05 | 9.72 | 0 | 0 | 442 | 48 | same |
| kilau-puma | 3831 | 3.27 | 16.58 | 0 | 0 | 545 | 314 | same |
| kilau-pitchfork | 1464 | 10.67 | 23.36 | 0 | 0 | 524 | 313 | same |
| kilau-falcon | 3356 | 2.94 | 28.62 | 0 | 0 | 702 | 414 | same |
| rails-puma | 3043 | 3.47 | 36.05 | 0 | 0 | 1736 | 688 | same |

## S3 `GET /posts` (100 rows), 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 1656 | 37.94 | 92.75 | 0 | 0 | 51 | 28 | same |
| kilau-cruby | 1862 | 33.72 | 41.48 | 0 | 0 | 446 | 60 | same |
| kilau-puma | 3750 | 13.78 | 77.82 | 0 | 0 | 538 | 344 | same |
| kilau-pitchfork | 1415 | 44.58 | 64.40 | 0 | 0 | 503 | 312 | same |
| kilau-falcon | 3436 | 17.36 | 40.03 | 0 | 0 | 751 | 414 | same |
| rails-puma | 3086 | 17.05 | 86.75 | 0 | 0 | 1722 | 699 | same |

## S4 `POST /posts`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-spinel | 8958 | 0.58 | 22.26 | 0 | 0 | 58 | 23 | — |
| kilau-cruby | 8363 | 1.82 | 4.60 | 0 | 0 | 445 | 36 | — |
| kilau-puma | 6628 | 0.61 | 28.85 | 0 | 0 | 538 | 336 | — |
| kilau-pitchfork | 1829 | 8.27 | 18.48 | 0 | 2786 | 518 | 345 | — |
| kilau-falcon | 6002 | 0.89 | 36.13 | 0 | 0 | 743 | 414 | — |
| rails-puma | 2696 | 4.11 | 27.78 | 0 | 0 | 1684 | 702 | — |
