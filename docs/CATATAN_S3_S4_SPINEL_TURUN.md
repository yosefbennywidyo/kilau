# Catatan investigasi: kenapa `kilau-spinel` turun tajam di S3 c1/c16/c64 dan S4 c16?

Dibuat 2026-11-16 ~22:36 WIB, saat sesi nginx (`bench/results/20261116-2245-servers-nginx-O2-ac`) masih berjalan.
Status: **belum diselidiki, belum ada eksperimen**. Dokumen ini hanya menyiapkan pertanyaan, pembanding, dan urutan
percobaan. Perbarui bagian "Log" di bawah tiap kali ada hasil (sertakan jam).

## 0. Pertanyaan yang harus dipastikan lebih dulu

"Turun tajam" dibandingkan dengan apa? Dokumen ini mencakup tiga bacaan; **pastikan mana yang dimaksud** sebelum
menghabiskan waktu pada satu hipotesis (aturan ablasi: jangan bangun teori mekanisme sebelum pembanding jelas).

| Bacaan | Sel yang ikut | Angka (sesi `...-servers-O2-ac`, tanpa proxy) |
|---|---|---|
| A. Dibanding endpoint ringan di app yang sama | S3 c1, S3 c16, S3 c64, S4 c16 (S2 hanya -16%) | S3 c1 3.999 vs S1 c1 10.253 (-61%); S3 c16 4.809 vs S1 c16 31.108 (-85%); S3 c64 4.349 vs S1 c64 28.466 (-85%); S4 c16 15.874 vs 31.108 (-49%) |
| B. Dibanding varian 8 proses | S3 c16, S3 c64 | `kilau-puma` 7.221 / 6.691 vs `kilau-spinel` 4.809 / 4.349 (-33% / -35%); S3 c1 dan S4 justru spinel lebih tinggi |
| C. Di belakang nginx dibanding `-direct` (sesi 2026-11-13 `-O0`/baterai di kolom ini; sesi hari ini di paragraf bawah tabel) | S1, S2, S3 c1, S4 | spinel-direct 15.546 / 14.049 / 1.429 / 10.718 vs di belakang nginx 7.237 / 6.748 / 980 / 6.216; S3 c16/c64 hampir tak turun (1.852 -> 1.782, 1.777 -> 1.754) |

Sesi nginx hari ini (`-O2`, AC, selesai 23:20 WIB, `bench/results/20261116-2245-servers-nginx-O2-ac`): `kilau-spinel` di belakang
nginx / `-direct` = S1 0,44x, S2 0,51x, S3 c1 0,74x, S3 c16 0,81x, S3 c64 0,87x, S4 0,64x. Penurunan itu terjadi juga pada
`kilau-puma` (S3 0,67x / 0,81x / 0,78x; S4 0,88x), jadi sebagian besar adalah biaya nginx berebut CPU di laptop yang sama,
bukan masalah khas Spinel; kecuali S4 (spinel 0,64x vs puma 0,88x) yang patut diperiksa. Peringkat spinel di S3 c16 dan c64
sesi ini 5 dan 6 dari 7, sama dengan bacaan B. Bacaan A sebagian besar wajar (S3 mengolah ~100x lebih banyak baris dan ~6,8 KB HTML); yang perlu
dijelaskan hanya bila angkanya lebih rendah dari kerja ekstra itu.

## 1. Fakta yang sudah terukur (jangan diukur ulang tanpa alasan)

- Skala di satu proses: S3 `kilau-spinel` c1 3.999 -> c16 4.809 (**hanya 1,2x** dengan 8 worker). `kilau-cruby`
  (1 proses, GVL) naik 1.857 -> 3.094 (1,7x). `kilau-puma` (8 proses) 1.692 -> 7.221 (4,3x). Jadi worker M:N Spinel
  tidak memakai core lain untuk beban ini, bahkan lebih buruk dari GVL CRuby secara relatif.
- Pada c1 binary Spinel 2,15x CRuby (3.999 vs 1.857): kerja per request-nya cepat; yang bermasalah adalah **paralelisme**.
- S4 c16: `kilau-spinel` 15.874 req/s tetapi p99 10,9 ms (`kilau-cruby` 12.450 / 3,4 ms). Throughput bagus, ekor buruk.
- Profil lama (`sample` 5 dtk, c1, `-O0`, 2026-11-13) menunjuk `_tlv_get_addr`, `madvise`, `__psynch_mutexwait`,
  `sp_bytestr`: alokator/kunci. Itu pada build `-O0`; **belum diulang pada `-O2`**.
- Kontrol sah: S3 c1 `kilau-spinel` 3.999 (sesi server) = 3.943/4.002 (A/B K-045), jadi bukan artefak sesi.
- Konfigurasi sesi: `KILAU_DATABASE_POOL=5`, `SPINEL_WORKERS=8` (`bench/lib.sh`). **Pool 5 < 8 worker.**

## 2. Hipotesis, urut dari ablasi termurah (satu perubahan per percobaan, semua yang lain tetap)

Per aturan ablasi: lepas SATU detail paling mencurigakan dulu; baru bangun teori mekanisme kalau ablasi gagal.

1. **Pool koneksi SQLite (5) lebih kecil dari worker (8).** Murah: ulangi S3 c16 dan S4 c16 dengan
   `KILAU_DATABASE_POOL=8` dan `16`, sisanya sama. Kalau S3 c16 naik jauh, pool adalah akarnya (dan S4 p99 ikut
   diperiksa: pool kecil = antre di pool).
2. **Jumlah worker.** Kurva `SPINEL_WORKERS=1,2,4,8` pada S3 c16 (pool dilebarkan sesuai). Skala tidak ada di 1->8 = kunci
   global; skala ada tapi datar di atas N = batas lain (jumlah core fisik efektif 4 performance + 4 efficiency di M1).
3. **Kunci global alokator/heap runtime M:N** (dugaan lama, belum dibuktikan). Uji: `sample` 5 dtk pada c16 `-O2`,
   cari `__psynch_mutexwait`/spinlock di puncak stack; bandingkan share-nya c1 vs c16. Hanya kalau 1-2 tidak
   menjelaskan.
4. **SQLite itu sendiri** (read lock/WAL pada satu berkas, `busy_timeout`, `sqlite3_step` di dalam kunci). Pembanding:
   `kilau-puma` memakai 8 proses dengan koneksi masing-masing dan skala 4,3x di berkas yang sama, jadi SQLite sendiri
   BUKAN penghalang mutlak; yang diuji: apakah semua worker berbagi satu koneksi/mutex di sisi binary.
5. **GC presisi (`sp_gc.c`)**: stop-the-world saat alokasi HTML besar (6,8 KB x banyak). Uji: variasi ukuran heap
   awal / `SPINEL_GC_*` bila ada; atau S3 dengan 10 baris vs 100 baris (kalau selisih skala hilang di 10 baris, kerja
   alokasi per request yang menjadi masalah).

Teori yang SUDAH gugur (jangan diulang): regresi upstream compiler (K-045: penyebab kecepatan `-O0`, bukan kode);
`gsub` di `sp_str_cold.c`; salinan lokal `sp_bytestr`.

## 3. Cara mengukur (supaya hasilnya sah)

- **Jangan jalankan apa pun selama sesi nginx berjalan** (CPU dipakai bersama; satu sesi pernah 2-3x lambat karena
  beban lain). Tunggu `bench/results/20261116-2245-servers-nginx-O2-ac/.finished`.
- AC + Low Power Mode mati (`pmset -g batt`, `pmset -g | grep lowpowermode`), catat sebelum dan sesudah.
- Gunakan `bench/results/20261114-0906-ab-runtime-opt/ab.sh` sebagai pola: berselang-seling, 3 s pemanasan,
  20 s per run, 3 ulangan; binary `blog_routes` dari compiler terpasang (`c892caf09`, `-O2`).
- Satu perubahan per percobaan; simpan tiap seri di `bench/results/<stamp>-s3-<variabel>/` dengan `meta.txt`.
- Kriteria "ditemukan": perubahan SATU variabel menggerakkan S3 c16 minimal ~30% (bukan derau antar-ulangan ~1-5%) dan
  hasilnya terulang 3 kali; ablasi kebalikan (kembalikan) mengembalikan angka lama.
- Skala: laporkan rasio c16/c1, bukan hanya req/s (rasio lebih tahan terhadap kondisi mesin).

## 4. Hasil yang diharapkan dan tindak lanjut

- Bila akarnya konfigurasi (pool/worker): perbaiki default di Kilau (`bench/lib.sh`, `framework/kilau/`), tulis di
  FINDINGS, dan ukur ulang tabel server.
- Bila akarnya runtime Spinel (kunci/alokator/GC): buat repro mikro tanpa HTTP/SQLite (loop alokasi string di N thread
  M:N), isi entri baru di `docs/CATALOG.md` (nomor berikutnya), lalu fix + PR sesuai alur biasa (fix dulu, PR; issue
  hanya bila tidak akan dikerjakan).
- Apa pun hasilnya: perbarui FINDINGS §6 ("Halaman list kini menang di c1, kalah tipis di c16/c64") dan §8 butir 3.

## 5. Log

[2026-11-16 23:25 WIB] Sesi nginx `-O2`/AC selesai dan dicatat di FINDINGS §6; bacaan C diisi (lihat §0). Belum ada ablasi.

(format entri berikutnya: `[YYYY-MM-DD HH:MM WIB] percobaan -> angka -> kesimpulan`)
