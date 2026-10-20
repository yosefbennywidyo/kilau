# Rencana: K-030b, K-031, K-032

Dibuat: 2026-10-20 ~20:15 WIB. Sumber temuan: sapuan builtin pada receiver `yield`
(`kilau/docs/CATALOG.md`, entri K-030 s.d. K-032; repro di `kilau/repro/`).

Status umum: K-030 sudah diperbaiki secara lokal dan dibuka sebagai matz/spinel#9779
(menunggu clang). Item di bawah belum dikerjakan.

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
- Status: belum dimulai.

### T3. K-030b: `yield.sort` / `yield.reverse` gagal compile C saat ada site Hash atau String

- Kriteria selesai: `kilau/repro/k030b_*.rb` compile dan identik dengan CRuby.
- Langkah:
  1. Opsi (a): perluas allowlist `yield_site_listed` di `src/types.c` agar Hash dan
     String menjawab dari row bawaan mereka sendiri. Opsi ini lebih kecil dan
     tidak menyentuh emitter. Opsi (b), jalur per site, butuh emitter yang bisa
     membox jawaban per site, jadi ditunda.
  2. Sapuan ulang `kilau/tools/yield-sweep/` untuk memastikan tidak ada regresi.
  3. Test CRuby dan `test/infer/`.
- Status: belum dimulai. Tunggu #9779 selesai dulu.

## Di luar cakupan (belum dijadwalkan)

- Hash tidak punya `cycle`, `each_cons`, `each_slice`, `find_index` di spinel,
  sedangkan CRuby punya. Periksa apakah ini gap umum atau hanya di jalur yield.
- `public_methods` dan `private_methods` berbeda dari CRuby. Kemungkinan tidak
  relevan untuk program AOT, prioritas rendah.

## Urutan

T1 → T2 → T3. T3 bisa dimulai lebih awal jika #9779 selesai dan T1/T2 sedang
menunggu gate.

## Log status

- 2026-10-20 ~20:15 WIB: rencana dibuat. T1, T2, T3 belum dimulai.
- 2026-10-20 ~20:40 WIB: T1 selesai, bukan bug (perilaku sengaja, lihat docs/limitations.md). Catalog K-032 diperbarui. Catatan status K-030 yang sebelumnya salah masuk ke K-032 dipindah ke K-030.
