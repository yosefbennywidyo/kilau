# HANDOFF — Kilau

Entri terbaru di atas.

## 2026-09-29 09:33 WIB — Rencana 3 selesai: template ter-compile, R4 terjawab

**Status repo**
- `main` = `7314530` (Rencana 2 + dokumen Rencana 3).
- Branch `plan-3-templates`: commit Rencana 3 di atas `main`, **belum di-merge** (keputusan merge di pengguna).
- Semua hijau di ujung branch:
  - `make test` (spinel): framework 13/13, tool 6/6, blog 3/3
  - `make test-cruby`: 22/22 (sekarang dijalankan per direktori paket, seperti `spin test`)
  - `cd examples/blog && make e2e`: 11/11
- Rencana: `docs/superpowers/plans/2026-09-29-kilau-rencana-3-template.md`. Keputusan baru: D-020 (subset sintaks), D-021 (lokasi hasil + golden yang dijalankan).

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
- Review akhir Rencana 2 selesai: 2 Important sudah diperbaiki (`1a71483`), 2 Minor ditunda (lihat bawah). Detailnya ada di `docs/review/rencana-review-rencana-2.md` dan `docs/review/proses-reviewer-rencana-2.md`.
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
