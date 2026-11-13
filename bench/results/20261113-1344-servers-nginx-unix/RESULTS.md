- date=2026-11-13 13:44 WIB
- kilau_sha=e08137f
- machine=MacBookAir10,1 Apple M1 cores=8
- power=Battery Power lowpowermode=1
- spinel=spinel 2026.10.25+4639 (d1878a068) [apple clang 21.0.0 (cc)]
- ruby=ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23] (CRuby apps run with --yjit)
-  * falcon (0.57.0); * pitchfork (0.18.2); * puma (8.0.2); * rack (3.2.8); * sqlite3 (2.9.6);
- reps=3 warmup=5 duration=15 cooldown=5 pool=5 workers=8
- proxy=nginx (nginx version: nginx/1.31.8, worker_processes auto, upstream keepalive 64; pitchfork over a Unix socket without keep-alive)

## S1 `GET /_ping`, 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-puma | 7474 | 2.02 | 3.66 | 0 | 0 | 489 | 328 | same |
| kilau-puma-unix | 11569 | 1.24 | 4.29 | 0 | 0 | 567 | 313 | same |
| kilau-pitchfork | 12020 | 1.21 | 3.59 | 0 | 0 | 578 | 347 | same |

## S3 `GET /posts` (100 rows), 16 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-puma | 2670 | 3.29 | 88.37 | 0 | 0 | 559 | 313 | same |
| kilau-puma-unix | 3682 | 3.27 | 19.62 | 0 | 0 | 925 | 325 | same |
| kilau-pitchfork | 3679 | 3.78 | 13.06 | 0 | 0 | 522 | 316 | same |

## S3 `GET /posts` (100 rows), 64 connections

| App | req/s | p50 (ms) | p99 (ms) | Unexpected status | Other errors | Start (ms) | Peak RSS (MB) | Body |
|---|---|---|---|---|---|---|---|---|
| kilau-puma | 3736 | 12.58 | 96.37 | 0 | 0 | 506 | 338 | same |
| kilau-puma-unix | 3295 | 13.26 | 111.09 | 0 | 0 | 561 | 325 | same |
| kilau-pitchfork | 3756 | 16.05 | 33.46 | 0 | 0 | 561 | 324 | same |
