# HANDOFF — Kilau

Entri terbaru di atas.

## 2026-09-29 23:10 WIB — Compiler naik ke `6626c0f05`; K-017 terverifikasi; K-018 ditemukan

**Status**
- Kilau memakai spinel **`2026.09.12+2237 (6626c0f05)`** (`/usr/local`), yang berisi perbaikan K-017 (`dca09ca13`, matz/spinel#5789).
- Repro K-017 sekarang sama dengan CRuby (dengan `1ba12fb74` masih `nil given to int`).
- Suite dengan kompilasi segar: 14/14, 8/8, 4/4, CRuby 26/26.
- **K-018 (baru):** `spin test` yang dipanggil lewat PATH tidak melihat mtime compiler, sehingga setelah upgrade compiler semua tes tetap `(cached)` dan hasil hijaunya palsu. `Makefile` sekarang memakai `SPIN ?= $(shell command -v spin)`. Detail di `docs/CATALOG.md` K-018.

**Langkah berikutnya**
1. ~~Kembalikan `Model#save` ke bentuk `elsif`~~ selesai 2026-09-29 23:20 WIB; suite hijau.
2. K-018: kandidat PR upstream kecil di `tools/spin.rb` (`spinel_bin` me-resolve `"spinel"` lewat `which`). Perlu izin pengguna.
3. Lanjutkan dari entri sebelumnya: Fase 2 K-016 → K-015 → K-004/K-013/K-007 → K-014.

## 2026-09-29 17:44 WIB — Rencana 6: Fase 0 selesai, Fase 1 hampir, Fase 2 dimulai (PR K-017)

**Status**
- Kilau memakai spinel **`1ba12fb74`** (`/usr/local`). Suite 14/14, 8/8, 4/4, CRuby 26/26, e2e hijau. D-023: `gen routes` diadopsi.
- Rencana 6 **Fase 0** (uji ulang di spinel terbaru) selesai: K-010 dan K-011 diperbaiki upstream, sisanya masih ada. Tabel lengkap di `docs/CATALOG.md`.
- Rencana 6 **Fase 1** (repro minimal):

| K | Repro | Status |
|---|---|---|
| K-016 | `repro/k016_nested_block_assignment.rb` (37 baris) | ✅ minimal + 3 syarat terbukti |
| K-017 | `repro/k017_elsif_argument_evaluated_early.rb` | ✅ minimal + mekanisme (argumen `elsif` dievaluasi terlalu dini) |
| K-015 | `repro/k015_user_each_misreads_array_element.rb` | ✅ minimal + 3 syarat (`each` buatan pengguna yang `yield` membuat elemen Integer terbaca String) |
| K-014 | belum ada | 🟡 butuh rantai migrasi mati **dan** bagian program hidup (tes HTTP); reduksi dihentikan di sekitar 344 baris, tidak tersimpan |
| K-004, K-007, K-013 | repro minimal sudah ada sejak awal | — |

- Rencana 6 **Fase 2** (perbaikan di spinel):
  - **K-017 diperbaiki.** Di `emit_if` (`src/codegen_stmt.c`), prelude predikat `elsif` sekarang di-emit di dalam cabangnya. Tes `test/elsif_condition_args_wait_for_their_branch.rb`, `make check` hijau (4.597 pass).
  - Commit `05a5ebef6` di branch `elsif-condition-args-in-branch` (fork `yosefbennywidyo/spinel`).
  - **PR https://github.com/matz/spinel/pull/5789 di-merge oleh matz** (2026-09-29 17:49 WIB, merge commit `dca09ca13`). CI hijau.

**Lingkungan**
- Worktree spinel terbaru: `~/apps/me/gems/spinel-latest`, sedang di branch `elsif-condition-args-in-branch`. Remote `fork` = `git@github.com:yosefbennywidyo/spinel.git`. Untuk perbaikan berikutnya, buat branch baru dari `origin/master`.
- Setelah **setiap** `sudo make install` spinel, jalankan `sudo chmod a+r /usr/local/lib/spinel/packages/*/*.o` (K-009: sccache menulis mode 0640).
- Alat dan input reduksi Fase 1 disimpan di `~/apps/me/gems/kilau-private-20260929/phase1/` (di luar repo; `/tmp` sudah tidak bisa diandalkan). Isinya:
  - `repros.sh`, `old_shapes.sh`, `try.sh`,
  - `k014/` (input flatten + `oracle_run.sh`),
  - `k015/` (skrip greedy + tahapan),
  - `pr-k017.md` (deskripsi PR).
- Pelajaran reduksi sudah di skill `spinel-notes`:
  - `spinel-reduce` tidak punya checkpoint, dan file sementaranya bentrok kalau dua input bernama sama.
  - oracle harus mewajibkan program berjalan di CRuby.
  - bisection per file atau per method jauh lebih cepat daripada ddmin per baris.

**Langkah berikutnya (urutan disarankan)**
1. ~~Pantau PR #5789~~ di-merge 2026-09-29 17:49 WIB. Sisa: naikkan compiler Kilau ke spinel yang berisi `dca09ca13`, jalankan ulang `repro/k017_elsif_argument_evaluated_early.rb`, dan pertimbangkan kembali ke bentuk `elsif` di `Model#save`.
2. **Fase 2 K-016** (nilai salah diam-diam): mulai dari repro 37 baris. Ini bug inferensi/penangkapan variabel di blok bersarang yang diakses lewat proc tersimpan; periksa C yang di-emit untuk `found` (sel yang ditangkap).
3. **Fase 2 K-015** (segfault): mulai dari repro. Tebakan awal: dispatch poly `each` yang ikut mempertimbangkan `each` buatan pengguna salah membaca tag elemen. Periksa C untuk `binds.each` di `check_binds`.
4. **Fase 2 K-004 / K-013 / K-007**: repro minimalnya sudah ada.
5. **K-014**: lanjutkan reduksi dengan reducer rakus yang punya checkpoint (pola `greedy2.py`), memakai `k014/k014_run_flat.rb` + `oracle_run.sh`. Target: repro yang tetap berjalan di CRuby.
6. Setiap perbaikan: tes spinel + `make check` hijau → commit (email Gmail, tanpa atribusi Claude) → push ke `fork` → PR **hanya dengan izin pengguna per item**. Gaya PR: judul = subjek commit, body prosa + `Test: … (output taken from CRuby 4.0.6)`.
7. **Rencana 5** Fase A–C (daftar route, 405/HEAD, deteksi konflik), sekarang dengan `gen routes` sebagai jalur utama.
8. Minor yang ditunda: lihat entri 2026-09-29 12:xx di bawah.

## 2026-09-29 14:00 WIB — Spinel 1ba12fb74, K-009 dipahami, D-023: gen routes diadopsi

**Status repo**
- `main` dipublikasikan di https://github.com/yosefbennywidyo/kilau (MIT).
- Kilau memakai spinel **`2026.09.12+2124 (1ba12fb74)`**, terpasang di `/usr/local`. Suite 14/14, 8/8, 4/4, CRuby 26/26, e2e 11/11 × 2.

**Hasil Rencana 6 Fase 0** (tabel lengkap di `docs/CATALOG.md`)
- Diperbaiki upstream: K-010, K-011.
- Masih ada: K-004, K-007, K-013, K-014, K-015 (segfault), K-016 (nilai salah), K-017.
- K-012 tidak berubah (pelebaran 30 / 11).
- K-009 adalah masalah instalasi: sccache menulis `.o` dengan mode 0640, lalu `cp -r` saat install mempertahankannya. Setelah **setiap** `sudo make install` spinel, jalankan `sudo chmod a+r /usr/local/lib/spinel/packages/*/*.o`.

**D-023: `gen routes` diadopsi.** `blog_routes` adalah binary deploy dan benchmark utama. `blog` (route table) tetap sebagai mode dev/tes dan fallback. Dasarnya adalah S3 di dua compiler (+12–34% req/s, p99 c16 57 → 12–13 ms), sementara S1/S2/S4 setara.

**Langkah berikutnya**
1. Rencana 6 Fase 1: repro minimal K-016 → K-015 → K-017 → K-014, lalu Fase 2 perbaikan (K-004/K-007/K-013 sudah punya repro minimal). Batas waktu per bug belum diputuskan pengguna.
2. Rencana 5 Fase A–C (route listing, 405/HEAD, konflik), sekarang dengan `gen routes` sebagai jalur utama.
3. Kandidat upstream baru: installer spinel + sccache (K-009).

## 2026-09-29 12:39 WIB — Rencana 4 selesai: gen routes, benchmark vs Rails, FINDINGS

**Status repo**
- `main` = `f17d41f` (Rencana 3). Branch `plan-4-routes-bench` berisi Rencana 4 + dokumen Rencana 5/6, **belum di-merge**.
- Suite di ujung branch: `make test` framework 14/14, tool 8/8, blog 4/4. `make test-cruby` 26/26. `make e2e` 11/11 untuk `blog` dan `blog_routes`.
- Hasil: `bench/RESULTS.md` (sesi `bench/results/20260929-1108`) dan `docs/FINDINGS.md`. D-022 (`gen routes`) dan D-023 (adopsi ditunda) tercatat.

**Menjalankan**
```
make gen                               # templates + routes untuk blog (akar repo)
cd examples/blog && make               # build/bin/blog (route table) dan build/bin/blog_routes (gen routes)
bench/check_bodies.sh                  # gerbang: ketiga app menjawab identik
bench/run.sh                           # sesi penuh ~95 menit; QUICK=1 untuk smoke
ruby bench/summarize.rb bench/results/<stamp> > bench/RESULTS.md
```
Sebelum `bench/run.sh`: tutup app berat. Mesin tanpa kipas: urutan selang-seling dan jeda 20 dtk sudah bawaan.

**Hasil singkat (c64)**
- S1 `_ping`: kilau 17.128 / kilau-routes 17.156 / rails 9.122 req/s.
- S2: 16.339 / 16.389 / 5.815.
- S3 (100 baris): 2.530 / 3.304 / 3.256.
- S4 (POST): 8.815 / 8.818 / 2.990.
- Start 54 ms vs 1,4 dtk. RSS 33 MB vs 910 MB.

**Langkah berikutnya**
1. Pengguna memutuskan merge `plan-4-routes-bench`.
2. **Rencana 6 Fase 0** (dokumen rencana lokal, tidak dipublikasikan): build spinel `origin/master` (740 commit di depan) di worktree terpisah, uji ulang semua repro K dan suite. Lalu ukur ulang S3 untuk D-023.
3. **Rencana 5** Fase A–C .
4. Benchmark tahap berikutnya dengan k6, dari mesin terpisah (FINDINGS §8).
5. Minor yang ditunda:
   - dari Rencana 1–2: `Migrator#migrate` `.to_s`, cabang `Binds::NULL`, `ROLLBACK` yang menutupi error;
   - dari Rencana 3: CRLF di template, `{{ a | b }}` bitwise, `{{{ x }}}`.

**Pertanyaan riset: semua terjawab**

| ID | Status |
|---|---|
| R1 | tidak (K-012); eksperimen `gen routes`: 30 → 11 pelebaran, S3 +34% |
| R2 | sebagian |
| R3 | ya |
| R4 | ya (buffer); nilai boxed dari handler |
| R5 | ya |
| R6 | ya (0 `SQLITE_BUSY` di semua sel Kilau) |

**Kandidat upstream** (belum dilaporkan; cek dulu di spinel terbaru): K-004, K-007, K-010, K-011, K-013, K-015, K-016, K-017.

## 2026-09-29 09:33 WIB — Rencana 3 selesai: template ter-compile, R4 terjawab

**Status repo**
- `main` = `7314530` (Rencana 2 + dokumen Rencana 3).
- Branch `plan-3-templates`: commit Rencana 3 di atas `main`, **belum di-merge** (keputusan merge di pengguna).
- Semua hijau di ujung branch:
  - `make test` (spinel): framework 13/13, tool 6/6, blog 3/3
  - `make test-cruby`: 22/22 (sekarang dijalankan per direktori paket, seperti `spin test`)
  - `cd examples/blog && make e2e`: 11/11
- Keputusan baru: D-020 (subset sintaks), D-021 (lokasi hasil + golden yang dijalankan).

**Menjalankan blog**
```
cd examples/blog
make                        # kilau gen templates . lalu spin build blog
./build/bin/blog db migrate
./build/bin/blog start      # http://127.0.0.1:5150
```
Setelah mengubah `assets/views/**`, jalankan `make` lagi (atau `make templates`). `build/gen/templates.rb` tidak di-commit.
Kalau generator sengaja diubah, perbarui golden `tool/test/fixtures/templates.rb` (caranya ada di Rencana 3, Task 3).

**Langkah berikutnya**
1. Pengguna memutuskan merge `plan-3-templates` ke `main`, lalu hapus branch-nya.
2. **Rencana 4**: benchmark vs Rails 8 (spec §6.1–6.2, `oha`) dan `FINDINGS.md`, menjawab sisa **R6**. Keputusan `kilau gen routes` (dispatch tanpa proc) sekarang punya manfaat tambahan: parameter `Templates.posts_list/show/edit` ikut boxed karena K-012 (lihat R4), dan akan menyempit bersama handler.
3. Minor yang ditunda (tetap dari entri sebelumnya):
   - `Migrator#migrate` memakai `done.include?(migration.version)` tanpa `.to_s`.
   - `connection_cruby.rb` `values(binds)` tidak punya cabang `Binds::NULL` eksplisit.
   - Dari Rencana 1: `ROLLBACK` yang gagal menutupi error asli.

**Pertanyaan riset**

| ID | Status |
|---|---|
| R1 | tidak (K-012) |
| R2 | sebagian |
| R3 | ya |
| R4 | ya, buffernya; nilai ikut boxed dari handler (K-012) |
| R5 | ya |
| R6 | sebagian (Rencana 4) |

Kandidat laporan upstream dan bacaan wajib: sama seperti entri di bawah.

## 2026-09-28 17:12 WIB — akhir sesi: Rencana 2 selesai, menunggu keputusan merge

**Status repo**
- `main` = `d778e3c` (Rencana 1 + dokumen Rencana 2).
- Branch `plan-2-http-controller` = `1a71483`: 12 commit di atas `main`, **belum di-merge**. Keputusan merge ada di pengguna (opsi: merge lokal / PR / biarkan). Repo belum punya remote.
- Semua hijau di `1a71483`:
  - `make test` (spinel): framework 13/13, tool 2/2, blog 2/2
  - `make test-cruby`: 17/17
  - `cd examples/blog && make e2e`: 11/11 (termasuk 200 request dengan 32 koneksi paralel)
- Review akhir Rencana 2 selesai: 2 Important sudah diperbaiki (`1a71483`), 2 Minor ditunda (lihat bawah). Detailnya ada di catatan review lokal (tidak dipublikasikan).
- `.DS_Store` untracked. Abaikan saja, atau tambahkan ke `.gitignore`.

**Menjalankan blog**
```
cd examples/blog
make entities
./build/bin/blog db migrate
./build/bin/blog start      # http://127.0.0.1:5150
```
`make entities` hanya perlu dijalankan kalau migrasi berubah. Config ada di `config/<KILAU_ENV>.yaml`, dan setiap kunci bisa ditimpa dengan env `KILAU_*`.

**Langkah berikutnya**
1. Pengguna memutuskan cara merge `plan-2-http-controller` ke `main`, lalu hapus branch-nya.
2. Tulis **Rencana 3**: `kilau gen templates` (spec §4). Template gaya Tera di `assets/views/**` di-compile menjadi `build/gen/templates.rb`, lalu isi `examples/blog/src/views/posts.rb` diganti panggilan `Templates.*` dengan signature yang sama. Menjawab **R4**.
3. **Rencana 4**: benchmark vs Rails 8 (spec §6.1–6.2, alat `oha`) dan `FINDINGS.md`. Menjawab sisa **R6** (konkurensi 64). Di sini juga diputuskan apakah fallback dispatch hasil generate (`kilau gen routes`, tanpa proc) layak dibuat, karena **R1 = tidak** (K-012).
4. Minor yang ditunda:
   - `Migrator#migrate` memakai `done.include?(migration.version)` tanpa `.to_s`.
   - `connection_cruby.rb` `values(binds)` tidak punya cabang `Binds::NULL` eksplisit.
   - Dari Rencana 1: `ROLLBACK` yang gagal menutupi error asli.

**Wajib dibaca sebelum menulis kode**
- Skill global `spinel-notes`: gotcha Spinel dan teknik debug.
- `docs/CATALOG.md` K-001 s.d. K-017. Yang paling mahal adalah K-012 dan K-015 s.d. K-017: perilaku yang bergantung pada inferensi **seluruh program**. Menambah satu pemanggilan bertipe bisa menyembunyikan atau memunculkan bug. Reduksi selalu dilakukan dengan delta-debug pada program asli, karena repro mandiri biasanya tidak memicunya.
- `docs/DECISIONS.md` D-001 s.d. D-019. Penyimpangan penting dari spec:
  - D-004 → D-019: binds memakai builder bertipe `Kilau::DB::Binds`, bukan Array.
  - D-006: migrasi memakai DSL blok.
  - D-014: `request.request_method`.
  - D-015: tes request memakai `Testing::Client.new(hooks, app_context)`.
- Konvensi tes:
  - Mulai dengan `T = Kilau::Testing`, lalu `T.check(...)` (bukan `include`, lihat K-004).
  - Snapshot berisi stdout+stderr gabungan, dengan stderr muncul lebih dulu.
  - Tidak memakai StringIO (K-009).

**Pertanyaan riset**

| ID | Status |
|---|---|
| R1 | tidak (K-012) |
| R2 | sebagian |
| R3 | ya |
| R4 | belum (Rencana 3) |
| R5 | ya |
| R6 | sebagian (Rencana 4) |

**Kandidat laporan upstream ke spinel** (belum ada yang dilaporkan; perlu izin pengguna)

| ID | Masalah |
|---|---|
| K-004 | method yang menerima blok, lewat include di top level, tidak di-emit |
| K-010 | override method pada subclass exception gagal compile |
| K-011 | `%zz` didekode menjadi NUL |
| K-013 | method bernama bawaan pada receiver untyped |
| K-015 | crash pada array campuran (repro masih di atas app) |
| K-016 | penugasan dari blok bersarang hilang (repro masih di atas app) |
| K-017 | `elsif` + `raise` merusak cabang lain (repro masih di atas app) |
