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
  1,9 MB (dulu 0,8 MB). Diukur tepat setelah sesi benchmark di mesin yang sama, jadi
  angka absolutnya bisa terpengaruh panas; arah dan besarnya (sekitar 7×) tidak.
  Penyebabnya belum diselidiki.
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

### Pengukuran ulang S3, 2026-11-12 (spinel `d1878a068`)

Sesi `bench/results/20261112-2236-s3-d1878a068`: hanya S3, prosedur sama (pemanasan
10 dtk, 3 × 30 dtk, median), commit Kilau `cb4df20`. Rails, Puma, dan CRuby tidak
berubah versinya.

| App | c1 req/s (p99) | c16 req/s (p99) | c64 req/s (p99) |
|---|---|---|---|
| kilau | 1.970 (0,83 ms) | 3.059 (11,82 ms) | 2.966 (53,52 ms) |
| kilau-routes | 1.962 (0,80 ms) | 2.795 (12,65 ms) | 2.959 (53,66 ms) |
| rails | 1.615 (1,28 ms) | 5.228 (12,08 ms) | 3.660 (64,33 ms) |

- **Dua varian Kilau sekarang setara di S3.** Route table naik dari 2.367 ke 3.059
  req/s di c16 dan p99-nya turun dari 57 ms ke 12 ms. Biaya penghalang proc (K-012)
  tidak lagi terlihat di skenario ini, jadi alasan performa untuk `gen routes`
  (D-023) hilang; alasan tipenya tetap.
- **Plafon Kilau tetap sekitar 3.000 req/s** di c16 dan c64, sama seperti September
  (`kilau-routes` 3.180 dan 3.304). Ribuan commit compiler tidak menggesernya.
  `--warn-widen` blog juga nyaris sama: 465 baris, dulu 463.
- **Rails terukur jauh lebih cepat di sesi ini**: 5.228 di c16, dulu 3.848, tanpa
  perubahan versi. Penjelasan yang paling mungkin adalah panas: di sesi September S3
  dijalankan setelah sekitar satu jam S1/S2, sedangkan sesi ini hanya S3. Itu belum
  dibuktikan. Akibatnya rasio lintas-sesi tidak bisa dibandingkan.
- **Di dalam sesi ini** Kilau unggul di c1 (1,2×) dan kalah di c16 (0,59×) dan c64
  (0,81×). Kesimpulan September ("varian generate menyamai Rails di S3") tidak
  bertahan: di mesin yang dingin Rails lebih cepat di halaman berat template begitu
  ada konkurensi.
- Karena plafon Kilau tidak ikut naik saat mesin dingin, plafon itu bukan dibatasi
  panas. Dugaan lama (boxing K-008 plus heap lock global runtime M:N) tetap dugaan;
  belum ada profil yang membuktikannya.

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

1. **Profil S3.** Plafon ~3.000 req/s adalah satu-satunya tempat Kilau kalah dari
   Rails, dan penyebabnya belum diukur. Langkah pertama adalah profil (`sample` pada
   binary di bawah beban c16), baru memutuskan apakah yang dikejar K-008, alokasi
   template, atau kunci runtime.
2. **Waktu build.** Cari tahu mengapa satu binary blog sekarang butuh ~17 dtk dan
   1,9 MB; ukur di mesin dingin, lalu bisect kasar antar-versi compiler bila
   angkanya bertahan.
3. **Irisan vertikal kedua**, bila proyek dilanjutkan: fitur dari non-goal spec §6.5
   (kandidat: session/cookie, CSRF, autentikasi) untuk menguji batas AOT yang belum
   tersentuh blog CRUD. Butuh spec baru dan keputusan pengguna.
4. **Benchmark k6 dari mesin terpisah** (alur multi-langkah, model terbuka dengan
   laju tetap, `thresholds` sebagai gerbang regresi). Tetap berlaku dari versi
   September; sesi ini menunjukkan lagi bahwa satu laptop tanpa kipas membuat angka
   lintas-sesi tidak bisa dibandingkan.
5. **K-042** ke upstream bila dianggap layak (prioritas rendah).
