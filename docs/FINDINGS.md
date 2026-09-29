# Temuan irisan vertikal pertama Kilau

- Ditulis: 2026-09-29 ~12:40 WIB, di commit `9d81984` (branch `plan-4-routes-bench`).
- Compiler: spinel `2026.09.12+1379 (38dc57dd)`. Pembanding: CRuby 4.0.6 + YJIT,
  Rails 8.1.4, Puma 8.0.2.
- Angka diambil dari `bench/RESULTS.md` (sesi `bench/results/20260929-1108`).
  Rujukan K-/D-/R- mengacu ke `docs/CATALOG.md` dan `docs/DECISIONS.md`.

## 1. Ringkasan

Blog CRUD yang ditulis sebagai Ruby biasa berjalan sebagai **satu binary native 0,8 MB**
hasil spinel. Binary itu lulus suite yang sama di spinel dan CRuby, serta e2e lewat
browser dan curl. Terhadap Rails 8.1 dengan markup yang identik byte per byte:
- Kilau melayani **1,9–2,9× lebih banyak request** per detik di `_ping`, halaman
  tunggal, dan POST.
- p99 Kilau **~8× lebih rendah** di S1/S2 c64, dan 1,6× di S4.
- Kilau siap dalam **~54 ms** (Rails ~1,4 dtk), dengan **~33 MB** RSS (Rails ~910 MB
  untuk 8 worker).

Di halaman list 100 baris yang berat template (S3), route table Kilau **kalah** dari
Rails di c16. Hanya varian dispatch hasil generate yang menyamai Rails. Biayanya ada
di DX: subset Ruby, beberapa langkah build, dan bug compiler yang muncul tergantung
isi seluruh program.

## 2. Yang jalan in-language (Ruby biasa, tanpa codegen)

- **HTTP/1.1 server** dengan green thread per koneksi dan keep-alive, **parser**,
  **Request/Response**, **Format**, **Error**, dan **Config** (parser subset YAML,
  karena YAML tidak tersedia: K-002).
- **Router gaya Loco** (`Routes`/`AppRoutes`/`Dispatcher`) dengan override `_method`,
  error → status, dan 404.
- **Model + migrasi + pool SQLite** lewat FFI langsung ke C.
  - R3 (kolom nullable tetap bertipe): **ya**.
  - R5 (`SQLITE_TRANSIENT`, salinan `column_text`): **ya**.
  - R6 (konkurensi 64 tanpa `SQLITE_BUSY`): **ya**. S4 c64 memproses ~8.800
    INSERT/dtk dari 64 koneksi lewat 5 koneksi SQLite, dengan 0 status tak terduga
    di semua 24 sel Kilau. Rails sempat menjawab dua 500 `database is locked` di
    pemanasan.
- **Tes**: `Kilau::Testing` + snapshot. CRuby menjadi oracle, dengan stdout + stderr
  digabung seperti `spin test`.
- R2 (params `Hash[String, String]` tetap sempit): **sebagian**. Di dalam framework
  sempit, tapi di handler boxed karena K-012.

## 3. Yang butuh codegen saat build

| Fitur | Alat | Alasan |
|---|---|---|
| Entity model | `kilau gen entities` (D-009) | Pola Loco sendiri (entity dari skema), dan tipe kolom tetap sempit (R3) |
| Template | `kilau gen templates` (D-020, D-021) | Interpreter template runtime butuh data bernilai campuran dan akses atribut by-name, yang keduanya jalur boxed. Template yang di-compile menjadi method Ruby memakai append in-place (R4 = ya untuk buffer). |
| Dispatch route | `kilau gen routes` (D-022), eksperimen | Proc yang disimpan adalah penghalang tipe (K-012, R1 = tidak). Salinan body blok yang dipanggil langsung menurunkan titik pelebaran di kode app dari **30 → 11**. Sisanya berawal dari K-008 (`Post.all`/`find_by_id`). **Diadopsi** sebagai jalur utama setelah diukur ulang di spinel `1ba12fb74` (D-023). |

Tanpa `send`, `method_missing`, `define_method` bernama dinamis, atau `eval`, semua
"magic" Rails harus pindah ke codegen yang dijalankan sebelum build. Setiap generator
ditulis dalam subset Ruby yang di-compile spinel sendiri, dan golden-nya dijalankan
di kedua engine.

## 4. Yang mentok di compiler (spinel `38dc57dd`)

| K | Masalah | Dampak | Status |
|---|---|---|---|
| K-004 | method yang menerima blok, lewat `include` top level, tidak di-emit (link error) | DX | kandidat laporan |
| K-007 | pemanggilan method tak terdefinisi di `unless yield` menghasilkan error tak jelas | DX | kandidat laporan |
| K-008 | method yang mengembalikan hasil blok melebar ke untyped | performa: sisa pelebaran R4/D-022 | batas inferensi |
| K-010 | override method di subclass exception, dipanggil setelah `rescue Base => e`, gagal compile | DX | kandidat laporan |
| K-011 | `%zz` didekode menjadi NUL diam-diam | **keamanan** | di-workaround di `Form.unescape`; kandidat laporan |
| K-012 | proc tersimpan memutus inferensi tipe | performa (terasa di S3) | batas inferensi |
| K-013 | nama method bawaan pada receiver untyped menghasilkan C tidak valid | DX | kandidat laporan |
| K-014 | kode mati dengan receiver untyped ditolak, tergantung program lain | DX | butuh isolasi |
| K-015 | Integer di array campuran terbaca sebagai String, lalu **segfault** | **crash** | di-workaround (D-019); butuh repro minimal |
| K-016 | penugasan dari blok bersarang hilang, sehingga **nilai salah diam-diam** | **nilai salah** | di-workaround; butuh repro minimal |
| K-017 | `elsif` + `raise` merusak jalur lain | nilai salah | di-workaround; **diperbaiki upstream** (matz/spinel#5789, merged 2026-09-29; terverifikasi di `6626c0f05`) |
| K-018 | `spin test` via PATH mengabaikan mtime compiler → tes lama `(cached)` | hasil tes palsu | di-workaround di `Makefile`; kandidat PR |

**Pola yang paling mahal:** K-012 dan K-014 s.d. K-017 bergantung pada inferensi
**seluruh program**. Menambah satu pemanggilan bertipe di tempat lain bisa
memunculkan atau menyembunyikan bug, dan repro mandiri biasanya tidak memicunya.
Upstream spinel sudah 740 commit di depan, dan beberapa commit-nya tampak menyentuh
K-010, K-011, K-015, dan K-016. Hasil pemeriksaan ulang (Rencana 6 Fase 0, spinel `1ba12fb74`): hanya **K-010 dan K-011** yang diperbaiki. K-004, K-007, dan K-013 s.d. K-017 masih ada (tabel status di `docs/CATALOG.md`).

## 5. Biaya DX

- **Subset Ruby.** Tidak ada metaprogramming runtime, YAML, `Time.parse`, maupun
  `StringIO` (karena izin instalasi, K-009). Setiap gotcha tercatat di skill
  `spinel-notes`.
- **Langkah build.** `make gen` (template + routes), `make entities` setelah migrasi,
  lalu `spin build`. Kilau build dalam ~2,3 dtk per binary. Rails tidak punya langkah
  build.
- **Grammar sempit.** Template: delimiter wajib satu baris, dan cek variabel hanya
  identifier akar. `gen routes`: route satu baris dengan blok `{ }`. Pelanggaran
  menjadi error `file:baris`, bukan tebakan.
- **Debug bug compiler butuh delta-debug di program asli** (K-015/K-016). Beberapa
  jam habis untuk isolasi yang tidak selesai. Ini biaya terbesar selama irisan ini.
- **Perilaku bisa berubah antar-engine** kalau tidak dijaga. Setiap tes dijalankan di
  spinel dan CRuby terhadap snapshot yang sama, dan itulah jaring pengamannya.

## 6. Performa (c64, median 3 × 30 dtk)

| Skenario | kilau req/s (p99) | kilau-routes req/s (p99) | rails req/s (p99) | Kilau / Rails |
|---|---|---|---|---|
| S1 `GET /_ping` | 17.128 (4,65 ms) | 17.156 (4,64 ms) | 9.122 (36,18 ms) | 1,9× |
| S2 `GET /posts/:id` | 16.339 (6,08 ms) | 16.389 (5,98 ms) | 5.815 (47,08 ms) | 2,8× |
| S3 `GET /posts` (100 baris) | 2.530 (85,72 ms) | 3.304 (65,19 ms) | 3.256 (75,45 ms) | 0,8× / 1,0× |
| S4 `POST /posts` | 8.815 (51,66 ms) | 8.818 (52,34 ms) | 2.990 (82,44 ms) | 2,9× |

| | Start → 200 pertama | RSS puncak | Artefak | Build |
|---|---|---|---|---|
| kilau | 54 ms | 33 MB | 0,8 MB binary | 2,4 dtk |
| kilau-routes | 53 ms | 32 MB | 0,7 MB binary | 2,2 dtk |
| rails | 1.423 ms | 910 MB (8 worker) | 86,5 MB + CRuby | — (`bundle install --local` 0,2 dtk) |

- **S1/S2/S4:** kedua varian Kilau setara (selisih < 5%). Penghalang proc murah di
  jalur ini.
- **S3:** di c16, `kilau` 2.367 req/s (p99 57 ms), `kilau-routes` 3.180 (p99 12 ms),
  dan `rails` 3.848. Halaman yang banyak mengolah nilai di template adalah tempat
  boxing (K-012 + K-008) dan heap lock global runtime M:N paling terasa.
- **Tingkat jenuh:** semua app mentok sekitar c16. c64 hanya menambah antrean. Rails
  menunjukkan ekor latensi yang jauh lebih panjang (p99 ≈ 7× p50 di S1 c64; Kilau
  ≈ 1,2×).

## 7. Batasan pengukuran

- **Satu laptop:** MacBook Air M1, 8 core, 8 GB. oha berjalan di mesin yang sama dan
  ikut memakai CPU.
- **Model konkurensi berbeda:** Kilau adalah 1 proses dengan runtime M:N 8 worker,
  tanpa GVL. Rails adalah 8 proses Puma × 5 thread dengan YJIT. RSS Rails adalah
  total 8 proses.
- **Termal.** Mesin tanpa kipas. Sesi pertama dengan urutan per blok dibatalkan:
  `kilau-routes` S1 c16 terukur 14,3 ribu vs `kilau` 31,8 ribu, padahal cara dispatch
  `_ping`-nya sama. Setelah diselang-seling di mesin yang sudah panas, keduanya
  ≈ 16 ribu. Angka absolut di sini dibatasi panas (smoke test saat mesin dingin
  mencapai ~34 ribu req/s untuk S1). Perbandingan antar-app adil karena urutannya
  selang-seling dengan jeda 20 dtk per sel.
- **Model tertutup oha.** Jumlah koneksi tetap dan `--latency-correction` tidak
  dipakai. p99 c64 adalah latensi yang dialami 64 klien itu, bukan latensi pada
  laju tetap (*coordinated omission*).
- **Beban mikro.** Satu endpoint per sel dan DB seed 100 baris. Tidak ada alur
  pengguna nyata.

## 8. Langkah berikutnya

1. ~~Rencana 6 Fase 0~~ selesai (2026-09-29 14:00 WIB): K-010 dan K-011 diperbaiki upstream, dan K-004, K-007, K-013 s.d. K-017 masih ada. Kilau sekarang memakai spinel `1ba12fb74`. D-023: `gen routes` diadopsi.
2. **K-008** di `Pool#query_all`/`query_first`. Ini sumber sisa pelebaran di template
   dan handler, dan kemungkinan kunci performa S3.
3. **Rencana 5** (kualitas route): introspeksi, 405 + HEAD, deteksi konflik, trie
   segmen yang diukur dulu, dan parameter bertipe.
4. **Laporan upstream** ke spinel dengan repro minimal, dengan izin pengguna per item.
5. **Benchmark tahap berikutnya dengan k6** (v2.2.0, sudah terpasang via mise),
   sebagai pelengkap oha:
   - (a) alur pengguna multi-langkah (buat → lihat → edit → hapus) dengan data
     dinamis;
   - (b) model terbuka `constant-arrival-rate`/`ramping-arrival-rate`, untuk latensi
     pada laju tetap tanpa coordinated omission;
   - (c) `thresholds` p99/error sebagai gerbang regresi di CI.

   k6 harus dijalankan dari **mesin terpisah**. Overhead VM JS per VU jauh di atas
   oha dan akan lebih dulu menjadi hambatan dibanding Kilau.
