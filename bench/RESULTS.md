# Hasil benchmark Kilau vs Rails

- Sesi: 2026-09-29 11:08 WIB, commit Kilau `efb629c`
- Mesin: MacBookAir10,1 Apple M1 cores=8 mem=8GB, macOS 26.6.2
- Versi: spinel 2026.09.12+1379 (38dc57dd) [apple clang 21.0.0 (cc)]; ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23]; Rails 8.1.4; puma version 8.0.2; oha 1.16.0
- Prosedur: pemanasan 10 dtk, lalu 3 × 30 dtk per sel; angka = median. Pool DB 5. Setiap sel memakai salinan baru DB seed (100 post) dan proses app baru.
- Urutan: scenario, concurrency, app (apps interleaved); jeda sebelum tiap sel 20 dtk.
- `kilau` = route table dengan proc (Rencana 2); `kilau-routes` = `kilau gen routes`; `rails` = Rails + Puma (workers = core, 5 thread), YJIT.
- Data mentah: `bench/results/20260929-1108`

## S1 `GET /_ping`

| App | Konkurensi | req/s | p50 (ms) | p99 (ms) | Status tak terduga | Error lain |
|---|---|---|---|---|---|---|
| kilau | 1 | 6411 | 0.15 | 0.19 | 0 | 0 |
| kilau | 16 | 17253 | 0.93 | 1.20 | 0 | 0 |
| kilau | 64 | 17128 | 3.80 | 4.65 | 0 | 0 |
| kilau-routes | 1 | 6435 | 0.15 | 0.18 | 0 | 0 |
| kilau-routes | 16 | 16538 | 0.95 | 1.28 | 0 | 0 |
| kilau-routes | 64 | 17156 | 3.80 | 4.64 | 0 | 0 |
| rails | 1 | 3180 | 0.29 | 0.73 | 0 | 0 |
| rails | 16 | 8997 | 1.45 | 6.60 | 0 | 0 |
| rails | 64 | 9122 | 5.40 | 36.18 | 0 | 0 |

## S2 `GET /posts/:id`

| App | Konkurensi | req/s | p50 (ms) | p99 (ms) | Status tak terduga | Error lain |
|---|---|---|---|---|---|---|
| kilau | 1 | 5519 | 0.17 | 0.29 | 0 | 0 |
| kilau | 16 | 16055 | 0.97 | 1.86 | 0 | 0 |
| kilau | 64 | 16339 | 3.87 | 6.08 | 0 | 0 |
| kilau-routes | 1 | 5544 | 0.17 | 0.25 | 0 | 0 |
| kilau-routes | 16 | 15816 | 0.98 | 1.85 | 0 | 0 |
| kilau-routes | 64 | 16389 | 3.87 | 5.98 | 0 | 0 |
| rails | 1 | 1750 | 0.53 | 1.49 | 0 | 0 |
| rails | 16 | 5649 | 2.27 | 11.13 | 0 | 0 |
| rails | 64 | 5815 | 8.63 | 47.08 | 0 | 0 |

## S3 `GET /posts` (100 baris)

| App | Konkurensi | req/s | p50 (ms) | p99 (ms) | Status tak terduga | Error lain |
|---|---|---|---|---|---|---|
| kilau | 1 | 1803 | 0.55 | 0.64 | 0 | 0 |
| kilau | 16 | 2367 | 5.24 | 57.35 | 0 | 0 |
| kilau | 64 | 2530 | 23.98 | 85.72 | 0 | 0 |
| kilau-routes | 1 | 1991 | 0.49 | 0.66 | 0 | 0 |
| kilau-routes | 16 | 3180 | 4.66 | 11.78 | 0 | 0 |
| kilau-routes | 64 | 3304 | 18.35 | 65.19 | 0 | 0 |
| rails | 1 | 1231 | 0.75 | 1.53 | 0 | 0 |
| rails | 16 | 3848 | 3.56 | 12.80 | 0 | 0 |
| rails | 64 | 3256 | 15.92 | 75.45 | 0 | 0 |

## S4 `POST /posts`

| App | Konkurensi | req/s | p50 (ms) | p99 (ms) | Status tak terduga | Error lain |
|---|---|---|---|---|---|---|
| kilau | 1 | 4848 | 0.19 | 0.38 | 0 | 0 |
| kilau | 16 | 8604 | 0.88 | 12.36 | 0 | 0 |
| kilau | 64 | 8815 | 3.67 | 51.66 | 0 | 0 |
| kilau-routes | 1 | 4855 | 0.19 | 0.39 | 0 | 0 |
| kilau-routes | 16 | 8591 | 0.87 | 12.50 | 0 | 0 |
| kilau-routes | 64 | 8818 | 3.65 | 52.34 | 0 | 0 |
| rails | 1 | 1565 | 0.60 | 1.33 | 0 | 0 |
| rails | 16 | 2892 | 3.73 | 24.25 | 0 | 0 |
| rails | 64 | 2990 | 17.08 | 82.44 | 0 | 0 |

## Start, memori, artefak

| App | Start → 200 pertama, median (ms) | RSS puncak, maks semua sel (MB) | Artefak deploy | Waktu build (dtk) |
|---|---|---|---|---|
| kilau | 54.0 | 33.3 | 0.8 MB (satu binary) | 2.4 |
| kilau-routes | 53.0 | 31.6 | 0.7 MB (satu binary) | 2.2 |
| rails | 1423.0 | 909.9 | 86.5 MB app + vendor/bundle (+ CRuby) | 0.2 |

## Catatan

- **Run pemanasan** tidak masuk tabel. Satu pemeriksaan terhadap ke-36
  `*.warmup.json` menemukan dua anomali, keduanya di Rails:
  - `rails-s4-c16`: satu `500`
  - `rails-s4-c64`: satu `500`

  Log Rails (`rails-s4-c*.log.rails`) mencatat penyebabnya:
  `ActiveRecord::StatementTimeout (SQLite3::BusyException: database is locked)`.

  Kilau dan kilau-routes tidak punya anomali di run mana pun. Log app di c64 tidak
  berisi `busy`/`locked`.
- **Termal:** sesi pertama (urutan per blok) dihentikan karena bias panas mesin.
  Sesi ini memakai urutan selang-seling dan jeda 20 dtk per sel. Detailnya di
  `docs/FINDINGS.md`.
