# Temuan irisan vertikal pertama Kilau

- Ditulis: 2026-09-29 ~12:40 WIB, di commit `9d81984` (branch `plan-4-routes-bench`).
- Compiler: spinel `2026.09.12+1379 (38dc57dd)`. Pembanding: CRuby 4.0.6 + YJIT,
  Rails 8.1.4, Puma 8.0.2.
- Angka diambil dari `bench/RESULTS.md` (sesi `bench/results/20260929-1108`).
- **Diperbarui 2026-11-12 ~23:00 WIB** di compiler `2026.10.25+4639 (d1878a068)`: tabel §4
  diperluas sampai K-042, §5 dan §6 mendapat pengukuran ulang, §8 ditulis ulang. Bagian
  lain tetap seperti ditulis pada 2026-09-29.
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

## 4. Yang mentok di compiler (dari spinel `38dc57dd` sampai `d1878a068`)

| K | Masalah | Dampak | Status |
|---|---|---|---|
| K-004 | method yang menerima blok, lewat `include` top level, tidak di-emit (link error) | DX | **diperbaiki upstream** (matz/spinel#6029); workaround dicabut (helper `module_function`) |
| K-007 | pemanggilan method tak terdefinisi di `unless yield` menghasilkan error tak jelas | DX | **diperbaiki upstream** (matz/spinel#6093) |
| K-008 | method yang mengembalikan hasil blok melebar ke untyped | performa: sisa pelebaran R4/D-022 | batas inferensi |
| K-010 | override method di subclass exception, dipanggil setelah `rescue Base => e`, gagal compile | DX | **diperbaiki upstream** (terverifikasi di `1ba12fb74`) |
| K-011 | `%zz` didekode menjadi NUL diam-diam | **keamanan** | **diperbaiki upstream** (terverifikasi di `1ba12fb74`); validasi di `Form.unescape` dipertahankan |
| K-012 | proc tersimpan memutus inferensi tipe | performa (terasa di S3) | batas inferensi |
| K-013 | nama method bawaan pada receiver untyped menghasilkan C tidak valid | DX | **diperbaiki upstream** (matz/spinel#6063); workaround dicabut |
| K-014 | method yang selalu `raise` (bukan kode mati, terisolasi 2026-10-02) ditolak saat dibandingkan/diinterpolasi/dioperasikan, tergantung program lain | DX | **diperbaiki upstream** (matz/spinel#7064, perluasan #7095); workaround `.to_s` dicabut setelah compiler dinaikkan |
| K-015 | Integer di array campuran terbaca sebagai String, lalu **segfault** | **crash** | **diperbaiki upstream** (matz/spinel#6027); `Binds` dipertahankan sebagai desain |
| K-016 | penugasan dari blok bersarang hilang, sehingga **nilai salah diam-diam** | **nilai salah** | **diperbaiki upstream** (matz/spinel#6008); workaround dicabut |
| K-017 | `elsif` + `raise` merusak jalur lain | nilai salah | di-workaround; **diperbaiki upstream** (matz/spinel#5789, merged 2026-09-29; terverifikasi di `6626c0f05`) |
| K-018 | `spin test` via PATH mengabaikan mtime compiler → tes lama `(cached)` | hasil tes palsu | di-workaround di `Makefile`; **diperbaiki upstream** (matz/spinel#5983, merged 2026-09-30); tindak lanjut #5997 (merged 2026-09-30) |
| K-019 | value object yang di-`yield` ke blok berbentuk proc menghasilkan C tidak valid (bukan soal alias) | DX (gagal compile) | **diperbaiki upstream** (matz/spinel#6028) |
| K-020 | nilai `next` diabaikan saat mengetik panggilan `yield`: **nilai salah diam-diam** / C gagal | **nilai salah** | **diperbaiki upstream** (matz/spinel#6092) |
| K-021 | `module_function` yield+rescue via top-level include, blok selalu raise → C tidak valid | DX (gagal compile) | **diperbaiki upstream** (matz/spinel#6151); workaround dicabut (compiler `ea9feecfe`) |
| K-022 | method `yield` dengan blok bertipe berbeda di call site berbeda → C tidak valid | DX (gagal compile) / nilai salah (argumen: `TypeError` saat runtime) | **diperbaiki upstream**: argumen (#6185), operator aritmetika (#6219); String `+`/`*` dengan argumen dikonversi (#6226, merged 2026-09-30) |
| K-023 | subclass `BasicObject` menjangkau method modul yang di-`include` di top level | nilai salah (program yang di CRuby raise malah berjalan) | **diperbaiki upstream** (matz/spinel#6162) |
| K-024 | method builtin pada receiver `yield` (`yield.abs`, `yield.first`) dengan blok bertipe berbeda | **nilai salah diam-diam** (`-2.5.abs` → `2`) / C gagal | **diperbaiki upstream** (#7024 `abs`/`-@`; #7063 tabel per site); di luar cakupan: `sum`, `succ`, `dig` tanpa reopen |
| K-025 | method builtin yang dibuka ulang di Array/Hash diabaikan; reopen lewat `yield` gagal compile / nilai salah | **nilai salah diam-diam** | **diperbaiki upstream** (#7078; K-025b #7096); bagian 2 (#7158) ditutup tanpa merge |
| K-026 | `respond_to?` pada receiver konkret menjawab `false` untuk method builtin yang baru ditambahkan | nilai salah | **diperbaiki upstream** (#8153, #8821, #9344) |
| K-027 | method bernama seperti nama "opaque" compiler (`bind`, `send`, ...) kehilangan fakta kelas parameternya: `NoMethodError` untuk method yang ada | **crash runtime** (pool SQLite Kilau) | **diperbaiki upstream** (#8720, lalu perbaikan sempit matz `a58cbba58`) |
| K-028 | `private`/`protected` pada reopening kelas builtin diabaikan | nilai salah (enkapsulasi) | **diperbaiki upstream** (#9386, #9404) |
| K-029 s.d. K-031, K-033 s.d. K-036 | puluhan method builtin pada receiver `yield` dengan blok bertipe berbeda antar-site | C tidak valid / **nilai salah diam-diam** / `TypeError` | **diperbaiki upstream** (#9419, #9779, #9794, #9795, #10272, #10476, #10481, #10974, dan lainnya di katalog) |
| K-032 | `"abc".frozen?` bernilai `true` | beda perilaku dari CRuby | **by design** (literal String beku, `docs/limitations.md` spinel) |
| K-037 | `push` dkk. berargumen pada receiver `yield` yang arraynya bertipe tunggal ditolak | DX (penolakan bernama) | **by design** (aturan typed-array) |
| K-038 | `yield` sebagai argumen konstruktor yang `initialize`-nya memakai `yield`/`block_given?` | **nilai salah diam-diam** / `LocalJumpError` palsu | **diperbaiki upstream** (#11451) |
| K-039 | `Array#rfind` pada receiver yang tipenya baru diketahui saat run | `NoMethodError` / C tidak valid | **diperbaiki upstream** (#11670 + 7 PR tindak lanjut s.d. #11691) |
| K-040, K-041 | tes `scale-test` upstream buta; kerja kompilasi kuadratik untuk banyak konstanta | bukan bug kebenaran | **diperbaiki upstream oleh pihak lain** (#11481 s.d. #11483) |
| K-042 s.d. K-044 | `respond_to?(:to_set)`, `method(:to_set)`, dan `size` pada Set dari `to_set` di dalam blok | nilai salah / error | terbuka; perbaikan K-042 sedang disiapkan (lihat katalog) |
| K-045 | halaman list 26-37% lebih lambat, build 4× lebih lama, binary 2,3× lebih besar dibanding compiler September | **performa dan DX** | terbuka; terbukti di compiler, belum dibisect |

**Pola yang paling mahal:** K-012 dan K-014 s.d. K-017 bergantung pada inferensi
**seluruh program**. Menambah satu pemanggilan bertipe di tempat lain bisa
memunculkan atau menyembunyikan bug, dan repro mandiri biasanya tidak memicunya.
Upstream spinel sudah 740 commit di depan, dan beberapa commit-nya tampak menyentuh
K-010, K-011, K-015, dan K-016. Hasil pemeriksaan ulang (Rencana 6 Fase 0, spinel `1ba12fb74`): hanya **K-010 dan K-011** yang diperbaiki. K-004, K-007, dan K-013 s.d. K-017 masih ada (tabel status di `docs/CATALOG.md`).

**Keadaan 2026-11-12 (spinel `d1878a068`).** Dari entri K-001 s.d. K-042, satu-satunya
bug yang masih terbuka adalah K-042 (baru, kecil). Yang tersisa selain itu adalah batas
inferensi yang diterima (K-005, K-006, K-008, K-012) dan dua perilaku yang disengaja
(K-032, K-037). Sisanya diperbaiki upstream, sebagian besar lewat PR dari proyek ini.
Bukti pada compiler terpasang:

- Semua 35 berkas `repro/*.rb` dijalankan ulang terhadap CRuby 4.0.6: 27 identik,
  termasuk `Time.parse` (K-001) dan YAML (K-002) yang dulu tidak tersedia (repro
  di-compile tanpa `--require-gate`; di bawah gate `spin build` belum diuji). Dari 8
  sisanya, 5 berbeda karena repronya sendiri (mencetak nama engine, hanya-FFI, butuh
  `-I`, format pesan error, penolakan yang disengaja di K-023), 1 adalah K-032
  (desain), dan 2 adalah K-042 (`k026_*` dan `k042_*`).
- Sapuan `tools/yield-sweep` (258 probe builtin pada receiver `yield`): 178 OK,
  66 MISMATCH, 14 CC_FAIL. Semua 80 yang bukan OK masuk kategori yang sudah dikenal
  (`inspect` Enumerator, refleksi, bentuk tanpa blok yang tidak didukung, literal beku,
  aturan typed-array). Ke-14 CC_FAIL adalah penolakan bernama, bukan C tidak valid.
  66 MISMATCH dikelompokkan dari pola keluarannya, tidak dibedah ulang per site.
- Suite Kilau 28/28 dan e2e blog 35/35 pada kedua binary.

**Yang berubah dari kesimpulan September:** bug yang bergantung pada seluruh program
masih kelas yang paling mahal, tetapi sudah jarang. Sapuan terakhir tidak menemukan
satu pun. Pergeseran yang perlu dicatat: beberapa bentuk yang dulu ditolak saat
compile (misalnya `map!` tanpa blok) sekarang lolos compile dan baru gagal saat
dijalankan dengan `NotImplementedError` bernama. Program yang tidak pernah mencapai
baris itu jadi bisa dibangun, tetapi kesalahannya pindah dari waktu build ke waktu
jalan.

## 5. Biaya DX

- **Subset Ruby.** Tidak ada metaprogramming runtime, YAML, `Time.parse`, maupun
  `StringIO` (karena izin instalasi, K-009). Setiap gotcha tercatat di skill
  `spinel-notes`. Per 2026-11-12 repro `Time.parse` dan YAML sudah identik dengan
  CRuby, dan K-009 (`StringIO`) diperbaiki upstream; Kilau belum memanfaatkannya
  (parser config dan waktu epoch tetap dipakai).
- **Langkah build.** `make gen` (template + routes), `make entities` setelah migrasi,
  lalu `spin build`. Kilau build dalam ~2,3 dtk per binary. Rails tidak punya langkah
  build. **Diukur ulang 2026-11-12 di `d1878a068`: ~16,8 dtk per binary** (dua kali
  berturut 16,77 dan 16,76 dtk; ~7,9 dtk di antaranya menghasilkan C), dan binary
  1,9 MB (dulu 0,8 MB). Diulang setelah mesin beristirahat 15 menit: `spin build blog`
  16,30 / 16,36 / 16,31 dtk, jadi bukan efek panas. Pengukuran itu di baterai dengan
  Low Power Mode, yang di benchmark memperlambat semuanya 25–35%; dengan AC belum
  diukur. Sumber Kilau yang sama dibangun compiler September dalam 3,95 dtk dan
  0,82 MB pada kondisi daya yang sama, jadi kenaikan 4× waktu dan 2,3× ukuran berasal
  dari compiler (K-045). Commit penyebabnya belum dicari.
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

### Pengukuran ulang S3, 2026-11-12/13 (spinel `d1878a068`)

Empat sesi, hanya S3, prosedur sama (pemanasan 10 dtk, 3 × 30 dtk, median), Rails,
Puma, dan CRuby tidak berubah versinya. Angka = req/s.

| Sesi | Daya | kilau c1 / c16 / c64 | kilau-routes c1 / c16 / c64 | rails c1 / c16 / c64 |
|---|---|---|---|---|
| `20261112-2236` | AC | 1.970 / 3.059 / 2.966 | 1.962 / 2.795 / 2.959 | 1.615 / 5.228 / 3.660 |
| `20261112-2331` (ulang 1) | baterai, Low Power Mode | 1.451 / 1.998 / 2.016 | 1.444 / 1.924 / 1.920 | 1.209 / 3.831 / 3.730 |
| `20261112-2349` (ulang 2) | baterai, Low Power Mode | 1.466 / 1.999 / 1.743 | 1.445 / 1.976 / 2.045 | 1.192 / 3.102 / 4.066 |
| `20261113-0008` (ulang 3) | baterai, Low Power Mode | 1.449 / 1.680 / 1.978 | 1.446 / 1.975 / 1.973 | 1.204 / 3.830 / 3.609 |

Sesi pertama berjalan dengan charger terpasang; `pmset -g log` mencatat pindah ke
baterai pada 22:52:59, saat sel terakhirnya (rails c64) masih berjalan. Profil baterai
mesin ini menyalakan Low Power Mode, dan tiga sesi ulang berjalan di situ. Itu yang
menurunkan semua app sekitar 25–35%, bukan panas seperti dugaan pertama. Keadaan daya
sesi September tidak tercatat.

Rasio `kilau-routes` / `rails` di dalam tiap sesi:

| Sesi | c1 | c16 | c64 |
|---|---|---|---|
| September (`20260929-1108`, spinel `38dc57dd`) | 1,62 | 0,83 | 1,01 |
| `20261112-2236` | 1,21 | 0,53 | 0,81 |
| ulang 1 | 1,19 | 0,50 | 0,51 |
| ulang 2 | 1,21 | 0,64 | 0,50 |
| ulang 3 | 1,20 | 0,52 | 0,55 |

Yang bisa disimpulkan:

- **Angka absolut bergantung pada keadaan daya; rasio di c1 tidak.** Rasio c1 berada
  di 1,19–1,21 pada keempat sesi, dengan AC maupun baterai. Rasio c16 dan c64 lebih
  berisik (0,50–0,64 dan 0,50–0,81).
- **Kilau unggul di c1 (1,2×) dan kalah di c16 dan c64** pada keempat sesi. Kesimpulan
  September ("varian generate menyamai Rails di S3") tidak bertahan.
- **Relatif terhadap Rails, S3 Kilau turun sejak September**: c1 dari 1,62 ke 1,20, c16
  dari 0,83 ke sekitar 0,5. Rails tidak berubah, jadi yang berubah ada di sisi Kilau:
  compiler dan runtime spinel (`38dc57dd` ke `d1878a068`), atau kode Kilau sendiri
  (Rencana 5 mengubah router dan jalur HEAD). Mana yang menyebabkannya **belum
  dipisahkan** saat bagian ini ditulis. **Dipisahkan 2026-11-13 ~08:05 WIB (K-045):**
  penyebabnya compiler/runtime, bukan kode Kilau. Kode September dan kode sekarang
  setara bila dibangun compiler yang sama (S3 c1 ~1.440 vs ~1.450 req/s). Sumber yang
  sama dibangun `38dc57dde` 26-37% lebih cepat di c1 dan 50-87% di c16 daripada yang
  dibangun `d1878a068`. Hanya halaman list yang kena: di `_ping` dan `/posts/42`
  compiler baru justru 3-7% lebih cepat. Bukti di
  `bench/results/20261113-0805-ab-compiler/`.
- **Dua varian Kilau setara** di c1 pada keempat sesi (rasio 1,00–1,01). Di c16 dan
  c64 selisihnya berbalik arah antar-sesi (0,85–1,09), jadi tidak ada yang konsisten
  lebih cepat. Biaya penghalang proc (K-012) tidak lagi terlihat di S3; di September
  route table 25% lebih lambat di c16.
- `--warn-widen` blog nyaris sama dengan September: 465 baris, dulu 463.
- Penyebab Kilau kalah di bawah konkurensi tetap dugaan (boxing K-008, heap lock
  global runtime M:N); belum ada profil.

### Server Kilau diganti: Puma, Pitchfork, Falcon (2026-11-13)

Sesi `bench/results/20261113-0834-servers` (baterai, Low Power Mode; 5 dtk pemanasan,
3 × 15 dtk, median). Kode Kilau adalah Ruby biasa, jadi blog yang sama dijalankan di
CRuby + YJIT lewat front Rack tipis (`bench/servers/`). Tiap pasangan hanya mengubah
satu hal: runtime (`kilau-spinel` vs `kilau-cruby`), server (`kilau-cruby` vs tiga
server Rack), atau framework (`kilau-puma` vs `rails-puma`). Semua varian menjawab
dengan body yang identik. Angka = req/s.

| App | S1 c1 | S1 c16 | S1 c64 | S2 c16 | S3 c1 | S3 c16 | S3 c64 | S4 c16 | RSS puncak |
|---|---|---|---|---|---|---|---|---|---|
| kilau-spinel (binary, server Kilau) | 6.737 | 16.149 | 11.868 | 12.053 | 1.449 | 1.599 | 1.656 | 8.958 | 15-28 MB |
| kilau-cruby (CRuby, server Kilau) | 7.473 | 15.898 | 14.086 | 10.440 | 1.330 | 1.974 | 1.862 | 8.363 | 32-60 MB |
| kilau-puma (8 × 5) | 5.561 | 14.682 | 12.709 | 10.640 | 1.260 | 3.831 | 3.750 | 6.628 | 263-344 MB |
| kilau-falcon (8 instance) | 4.437 | 12.076 | 13.254 | 9.476 | 1.082 | 3.356 | 3.436 | 6.002 | 308-426 MB |
| rails-puma (8 × 5) | 2.910 | 8.163 | 8.861 | 4.377 | 1.209 | 3.043 | 3.086 | 2.696 | 546-780 MB |

- **Halaman list tidak menskala di satu proses.** `kilau-spinel` naik hanya dari
  1.449 (c1) ke 1.599 (c16), padahal punya 8 worker tanpa GVL. `kilau-cruby`, yang
  terikat GVL, berperilaku sama (1.330 ke 1.974). Kode yang sama di 8 proses Puma
  mencapai 3.831. Jadi kekalahan Kilau dari Rails di S3 berasal dari satu proses
  yang tidak memakai core lain untuk beban ini, bukan dari framework-nya. Ini cocok
  dengan dugaan kunci global di runtime Spinel (alokasi), tetapi kuncinya sendiri
  belum ditunjukkan dengan profil.
- **Framework Kilau lebih cepat dari Rails di server yang sama.** `kilau-puma` /
  `rails-puma`: 1,8× (S1 c16), 2,4× (S2), 1,26× (S3 c16), 2,5× (S4), dengan sekitar
  separuh memori.
- **AOT tidak memberi keunggulan throughput atas CRuby + YJIT** pada compiler sekarang:
  `kilau-spinel` dan `kilau-cruby` setara di c1 (S1 6.737 vs 7.473; S3 1.449 vs
  1.330). Yang diberikan binary Spinel adalah start ~50 ms (CRuby ~450 ms) dan memori
  separuh `kilau-cruby` atau sepersepuluh server multi-proses. Dengan compiler
  September halaman list 26-37% lebih cepat (K-045), jadi di sana selisihnya dulu ada.
- **Server Kilau cukup untuk beban ringan.** Di S1, S2, dan S4 satu proses Kilau
  (binary maupun CRuby) setara atau di atas Puma dan Falcon 8 proses. Mengganti server
  hanya menolong S3.
- **Puma sedikit di atas Falcon** di hampir semua sel; Falcon punya p99 lebih rendah
  di c64 (S3: 40 ms vs 78 ms). Bebannya CPU dan SQLite, bukan I/O lambat, jadi
  keunggulan fiber tidak terpakai.
- **Pitchfork tidak terukur dengan sah.** Ia menutup koneksi setelah tiap request,
  dan tanpa reverse proxy `oha` kehabisan port lokal (`Can't assign requested
  address`, sampai 60% request gagal) dengan throughput ~2.000 req/s di semua
  skenario. Angkanya tidak dimuat di tabel; ada di data mentah. Pengukuran yang
  adil butuh nginx di depannya, dan Linux untuk reforking.
- S2 dan S4 hanya diukur di c16. Satu sesi, belum diulang.

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

Ditulis ulang 2026-11-12. Daftar September (Rencana 5, Rencana 6, laporan upstream)
sudah selesai; riwayatnya ada di `docs/HANDOFF.md`.

1. **K-045: persempit regresi S3 di compiler.** Sudah terbukti compiler, bukan kode
   Kilau. Berikutnya: repro mikro tanpa HTTP dan SQLite (loop `buf << escape(str)`
   untuk 100 baris), lalu bisect antara `38dc57dde` dan `d1878a068` dengan repro itu.
   Petunjuk dari `sample`: jalur String/byte dan alokator.
2. **K-045: waktu build dan ukuran binary** (4× dan 2,3× untuk sumber yang sama).
   Bisect yang sama bisa mengukur keduanya sekaligus.
3. **Skala halaman list di satu proses.** Profil `kilau-spinel` di bawah c16 untuk
   menunjukkan kunci mana yang menahan 8 worker (lihat §6, bagian server). Sementara
   itu, pilihan yang sudah terukur untuk beban semacam ini adalah beberapa proses:
   kode Kilau di CRuby di belakang Puma mengalahkan Rails di semua skenario.
4. **Irisan vertikal kedua**, bila proyek dilanjutkan: fitur dari non-goal spec §6.5
   (kandidat: session/cookie, CSRF, autentikasi) untuk menguji batas AOT yang belum
   tersentuh blog CRUD. Butuh spec baru dan keputusan pengguna.
5. **Benchmark k6 dari mesin terpisah** (alur multi-langkah, model terbuka dengan
   laju tetap, `thresholds` sebagai gerbang regresi). Tetap berlaku dari versi
   September; sesi ini menunjukkan lagi bahwa angka lintas-sesi di satu laptop tidak
   bisa dibandingkan. `bench/run.sh` sebaiknya mencatat sumber daya dan Low Power
   Mode ke `meta.txt`.
6. **K-042** ke upstream bila dianggap layak (prioritas rendah).
