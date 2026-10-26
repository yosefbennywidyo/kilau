# Rencana: K-030b, K-031, K-032

Dibuat: 2026-10-20 ~20:15 WIB. Sumber temuan: sapuan builtin pada receiver `yield`
(`kilau/docs/CATALOG.md`, entri K-030 s.d. K-032; repro di `kilau/repro/`).

Status umum (2026-10-20 ~21:50 WIB):
- K-030: merged sebagai matz/spinel#9779 (13:46Z, merge commit `4ab5183b5`).
- K-032: bukan bug, perilaku sengaja (lihat T1).
- K-031: merged matz/spinel#9794 (15:46Z, merge commit `9e6678d2e`).
- K-030b: merged matz/spinel#9795 (15:46Z, merge commit `9923101bd`).

## Aturan kerja

- Satu PR per fix. Repro dan test CRuby di `test/` (`.expected` dari CRuby).
- Perubahan bertipe juga menambah assertion di `test/infer/`.
- Jangan jalankan `make test` atau `make gate` di Mac ini. Verifikasi lokal:
  repro merah/hijau, test baru, dan perbandingan C yang dihasilkan.
  Gate penuh lewat `gate-shards-17job.yml` di fork (`gate/<branch>`).
- Sebelum buka PR upstream: tunggu clang fork hijau, lalu konfirmasi ke user.
- Setelah fix masuk master, `kilau`: `sudo make install` dijalankan user sendiri.

## Tugas

### T1. K-032: `"abc".frozen?` bernilai `true` (di luar yield)

- Kriteria selesai: `p "abc".frozen?` dan `x = "abc"; p x.frozen?` identik dengan
  CRuby 4.0 (`false`, `false`), dan ada test baru.
- Langkah:
  1. Cari apakah literal dibekukan sengaja: `grep -rn frozen docs/limitations.md src/`.
  2. Jika sengaja, dokumentasikan di `docs/limitations.md` dan tutup K-032 sebagai
     "bukan bug". Jika tidak, perbaiki.
- Status: **selesai, bukan bug (2026-10-20 ~20:40 WIB).** `docs/limitations.md`
  (bagian "String literals are frozen by default") mendokumentasikan
  `frozen_string_literal: true` sebagai baseline yang disengaja, tanpa opt-out.
  Tidak ada perubahan compiler. Katalog K-032 sudah diperbarui.

### T2. K-031: `yield.<=>(2)` dengan site Integer lalu site String → TypeError

- Kriteria selesai: `kilau/repro/k031_*.rb` identik dengan CRuby (`1`, `nil`).
- Langkah:
  1. Verifikasi dugaan dengan `spinel --emit-types`: jawaban call node `<=>`
     dan tipe yield. Dugaan awal: sama keluarga K-030, tetapi `<=>` belum lewat
     jalur per site untuk site non-numerik.
  2. Perbaikan mengikuti pola #9779 hanya jika bukti (langkah 1) mendukung.
     Widening ke site String/Hash sebelumnya merusak `yield.inspect`
     (lihat #9779, "Known limits"), jadi hati-hati.
  3. Test: `test/` (CRuby) dan `test/infer/`.
- Status: **upstream matz/spinel#9794 (2026-10-20 ~21:50 WIB).** Commit `d847a1d6c` di
  branch `k031-yield-spaceship-site-answer`, di atas head #9779 (`fe86b5f93`).
  Test: `test/yield_receiver_spaceship_site_kinds.rb` + `test/infer/`. Repro
  K-031 identik dengan CRuby (`1 nil`). Dibutuhkan pembangunan ulang
  `lib/libspinel_rt.a` (arsip runtime tertinggal dari sumber; `make bin/spinel`
  tidak membangunnya). Tidak ada regresi di 67 test `yield.`.

### T3. K-030b: `yield.sort` / `yield.reverse` gagal compile C saat ada site Hash atau String

- Kriteria selesai: `kilau/repro/k030b_*.rb` compile dan identik dengan CRuby.
- Langkah:
  1. Opsi (a): perluas allowlist `yield_site_listed` di `src/types.c` agar Hash dan
     String menjawab dari row bawaan mereka sendiri. Opsi ini lebih kecil dan
     tidak menyentuh emitter. Opsi (b), jalur per site, butuh emitter yang bisa
     membox jawaban per site, jadi ditunda.
  2. Sapuan ulang `kilau/tools/yield-sweep/` untuk memastikan tidak ada regresi.
  3. Test CRuby dan `test/infer/`.
- Status: **upstream matz/spinel#9795 (2026-10-20 ~21:50 WIB), bergantung pada #9794.** Commit `898cac013` di
  branch `k030b-yield-sort-reverse-nonarray-site`, di atas commit K-031. Helper
  `yield_site_per_kind_name` menampung nama `<=>`, `sort`, `reverse`. Repro
  K-030b identik dengan CRuby. Sapuan: `sort` dan `reverse` dari CC_FAIL ke OK,
  `<=>` dari MISMATCH ke OK. Tidak ada regresi di 67 test `yield.`.

## T4. Enumerable tanpa blok pada Hash di site yield yang bercampur (baru, 2026-10-20 ~23:30 WIB)

- Gejala: `def w; p yield.cycle.first(3); end; w { [1, 2] }; w { {a: 1} }` →
  spinel `NoMethodError: undefined method 'cycle' for an instance of Hash`, CRuby
  menjawab `[[:a, 1], [:a, 1], [:a, 1]]`. Dengan satu site Hash saja, benar.
- Di luar yield, `{a: 1}.cycle`, `each_cons`, `each_slice`, dan `find_index`
  semuanya benar.
- Penyebab (dilihat dengan print sementara, sudah dibersihkan):
  - YieldNode diberi tipe `int_array` (site pertama), bukan poly. Jadi widening
    `YU_RECEIVER` tidak terjadi.
  - Jawaban per site untuk site Array = enumerator (benar).
  - Jawaban per site untuk site Hash = `TY_UNKNOWN`, karena inferensi face-pinned
    tidak menghasilkan enumerator untuk `cycle` pada Hash.
  - Codegen lalu jatuh ke `sp_stage_recv_args_msg("undefined method ...")`.
- Coba: menambah `cycle`, `each_cons`, `each_slice`, `find_index` ke
  `yield_site_per_kind_name`. Tidak cukup: `cycle` masih gagal, dan probe
  campuran `each_slice`/`find_index` gagal compile (PolyArray vs IntArray).
- Kriteria selesai: `w { [1, 2] }` + `w { {a: 1} }` untuk keempat nama identik
  dengan CRuby, dan `yield.each_slice` / `each_cons` / `find_index` tidak gagal
  compile saat bercampur.
- Langkah yang disarankan:
  1. Perbaiki inferensi face-pinned agar Hash `cycle` (tanpa blok) menjawab
     enumerator, dan periksa apakah `each_slice`/`each_cons` juga perlu.
  2. Untuk `find_index`, tentukan tipe hasil per site (Integer atau nil), bukan
     tipe elemen.
  3. Test CRuby dan `test/infer/`.
- Status: **selesai** (2026-10-26, branch spinel `t4-yield-hash-enum`, 3 commit,
  belum di-push upstream):
  - `8d3ac09bc`: cycle, each_slice, each_cons pada receiver yield ikut redispatch
    pair-array; codegen tidak lagi menimpa view receiver yang diredispatch dengan
    tipe per-site block (`view_type_top`). Test `yield_hash_enum_mixed_sites`.
  - `6d693983c`: find_index dijawab per-site (`yield_site_per_kind_name`). Test
    `yield_hash_find_index_mixed_sites`.
  - `49743dfc6`: `yield.cycle.first(n)` / `take(n)` dijawab poly array per-site;
    fold `emit_cycle_bounded_expr` membungkus elemen ke PolyArray bila tipe
    pemanggil poly. Test `yield_cycle_first_mixed_sites`. Repro headline di atas
    sekarang keluaran benar `[1, 2, 1]` / `[[:a, 1], [:a, 1], [:a, 1]]`.
  - Verifikasi: 1591 tes corpus yang memuat yield/cycle/find_index/each_slice/
    each_cons, semua lolos (2 tes gagal karena cwd runner, lolos dari root).

## Di luar cakupan (belum dijadwalkan)

- Hash tidak punya `cycle`, `each_cons`, `each_slice`, `find_index` di spinel,
  sedangkan CRuby punya. Periksa apakah ini gap umum atau hanya di jalur yield.
- `public_methods` dan `private_methods` berbeda dari CRuby. Kemungkinan tidak
  relevan untuk program AOT, prioritas rendah.

## Urutan

T1 → T2 → T3. T3 bisa dimulai lebih awal jika #9779 selesai dan T1/T2 sedang
menunggu gate.

## Ringkasan posisi (2026-10-21 ~01:35 WIB)

Sudah selesai:
- K-030 (`yield` + builtin numerik per site): merged matz/spinel#9779 (2026-10-20 13:46Z).
- K-031 (`yield.<=>`): merged matz/spinel#9794 (15:46Z, merge commit `9e6678d2e`).
- K-030b (`yield.sort` / `yield.reverse`): merged matz/spinel#9795 (15:46Z, merge commit `9923101bd`).
- K-032 (`frozen?` pada literal): ditutup sebagai perilaku yang disengaja (`docs/limitations.md`).
- Pembersihan branch lokal dan fork dari pekerjaan ini. Di fork hanya tersisa branch non-pekerjaan ini.

Belum selesai:
- T4 (Hash Enumerable tanpa blok pada site yield campuran). Selesai, lihat bagian T4.
- Catatan K-032 di katalog masih memakai kata "nilai salah diam-diam". Seharusnya "perbedaan yang disengaja dengan default CRuby".
- Kilau: 17 commit sebelumnya belum dipush ke origin (bukan dari pekerjaan ini). Keputusan push ada di user.
- Kilau: `sudo make install` perlu dijalankan user agar compiler memuat perbaikan.

Langkah berikutnya yang disarankan: T4, mulai dari `cycle` pada Hash. Lihat catatan "Langkah yang disarankan" di T4.

## Log status
- 2026-10-21 ~01:35 WIB: ringkasan posisi dan HANDOFF ditulis.
- 2026-10-20 ~23:30 WIB: T4 ditemukan dan didiagnosis. Eksperimen perubahan
  dibatalkan, tidak ada perubahan kode yang tersisa.

- 2026-10-20 ~20:15 WIB: rencana dibuat. T1, T2, T3 belum dimulai.
- 2026-10-20 ~21:30 WIB: T2 dan T3 fix lokal selesai.
- 2026-10-20 ~22:46 WIB: #9794 dan #9795 merged (15:46Z). Ketiga tugas selesai.
- 2026-10-20 ~21:50 WIB: gate fork hijau untuk K-031 dan K-030b, clang fork hijau. Dibuka upstream sebagai #9794 dan #9795. Fork PR #37 dan #38 ditutup. #9779 sudah merged (13:46Z).
- 2026-10-20 ~20:40 WIB: T1 selesai, bukan bug (perilaku sengaja, lihat docs/limitations.md). Catalog K-032 diperbarui. Catatan status K-030 yang sebelumnya salah masuk ke K-032 dipindah ke K-030.
- 2026-10-26: T4 selesai (3 commit di spinel branch `t4-yield-hash-enum`). Doc diperbarui.
