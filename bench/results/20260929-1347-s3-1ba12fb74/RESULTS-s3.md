# Hasil benchmark Kilau vs Rails

- Sesi: 2026-09-29 13:47 WIB, commit Kilau `03fedb4`
- Mesin: MacBookAir10,1 Apple M1 cores=8 mem=8GB, macOS 26.6.2
- Versi: spinel 2026.09.12+2124 (1ba12fb74) [apple clang 21.0.0 (cc)]; ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin23]; Rails 8.1.4; puma version 8.0.2; oha 1.16.0
- Prosedur: pemanasan 10 dtk, lalu 3 × 30 dtk per sel; angka = median. Pool DB 5. Setiap sel memakai salinan baru DB seed (100 post) dan proses app baru.
- Urutan: scenario, concurrency, app (apps interleaved); jeda sebelum tiap sel 20 dtk.
- `kilau` = route table dengan proc (Rencana 2); `kilau-routes` = `kilau gen routes`; `rails` = Rails + Puma (workers = core, 5 thread), YJIT.
- Data mentah: `bench/results/20260929-1347-s3-1ba12fb74/`

## S1 `GET /_ping`

(tidak diukur di sesi ini)

## S2 `GET /posts/:id`

(tidak diukur di sesi ini)

## S3 `GET /posts` (100 baris)

| App | Konkurensi | req/s | p50 (ms) | p99 (ms) | Status tak terduga | Error lain |
|---|---|---|---|---|---|---|
| kilau | 1 | 1744 | 0.58 | 0.65 | 0 | 0 |
| kilau | 16 | 2502 | 5.04 | 57.32 | 0 | 0 |
| kilau | 64 | 2914 | 20.24 | 78.04 | 0 | 0 |
| kilau-routes | 1 | 1960 | 0.50 | 0.66 | 0 | 0 |
| kilau-routes | 16 | 3085 | 4.78 | 12.51 | 0 | 0 |
| kilau-routes | 64 | 3320 | 18.34 | 63.33 | 0 | 0 |

## S4 `POST /posts`

(tidak diukur di sesi ini)

## Start, memori, artefak

| App | Start → 200 pertama, median (ms) | RSS puncak, maks semua sel (MB) | Artefak deploy | Waktu build (dtk) |
|---|---|---|---|---|
| kilau | 56 | 33.6 | 0.8 MB (satu binary) | — |
| kilau-routes | 60 | 31.9 | 0.8 MB (satu binary) | — |
