# Katalog batas AOT

Compiler: **spinel terpasang** (`/usr/local/bin/spinel`) `2026.09.12+10352 (d20573c47)`
sejak 2026-10-17 (`sudo make install`, berisi fix K-026 cause A #9344 dan semua PR
yang merge setelahnya, 1.474 commit di depan `e24b53a35`). `make test` diuji ulang
bersih (`spin clean` + `make test`): 25/25 lulus (13/13 framework, 8/8 tool, 4/4
examples/blog), tanpa regresi. Repro suite (`repro/*.rb`, dibandingkan manual dengan
CRuby karena tak ada `.expected` sidecar) juga diuji ulang: semua diff yang muncul
sudah terdokumentasi dan sesuai harapan (K-003 by design, K-006/K-015 butuh `-I`
kilau, K-007 beda prefix backtrace saja, K-023 ditolak compile memang desainnya,
K-026 sekarang MATCH untuk `tally`/`transform_keys!`). Sebelumnya `2026.09.12+8878
(e24b53a35)` sejak 2026-10-13 ~11:31 WIB (berisi juga fix lanjutan Matz
`a58cbba58`/`45d534608` — lihat catatan K-027 di bawah, 143 commit di depannya — jadi
ongkos boxing 32 slot/~21 program yang K-027 sempat timbulkan sekarang hilang juga).
Sebelumnya `2026.09.12+8734
(35aea8ccc)` sejak 2026-10-13 ~11:30 WIB (berisi fix K-027 #8720 dan K-017 #8679, BELUM
fix lanjutan Matz). Sebelumnya master `46a9efb16` sejak 2026-10-12 ~17:30 WIB, dibangun bersih di worktree
terpisah (bukan `/usr/local/bin/spinel` terpasang saat itu, lihat uji ulang di bawah
untuk detail). Sebelumnya `f3da0151f` sejak 2026-10-07 ~16:27 WIB (sebelumnya `ae2c38c71` sejak 11:10,
`ea9feecfe` sejak 2026-09-30 14:29 WIB, `35ddccadb` sejak 06:43, `6626c0f05` sejak 2026-09-29
23:08, `1ba12fb74` sejak 13:45). Entri K-001 s.d. K-017 ditemukan dengan 2026.09.12+1379
(38dc57dd); lihat tabel status di bawah. Format entri: spec §6.3.
Repro dijalankan dengan `spinel --require-gate` (seperti `spin build`), dan CRuby
4.0.6 sebagai pembanding.

## Status di spinel terbaru (Rencana 6 Fase 0, 2026-09-29 13:29 WIB)
**Uji ulang 2026-10-07 ~11:12 WIB** dengan spinel `ae2c38c71` (terpasang lewat `sudo make install`; repro di-compile tanpa `--require-gate` karena regresi di bawah):

| K | Hasil | Status |
|---|---|---|
| K-014 | `migrator.rb` tanpa `.to_s` dikompilasi; compiler lama menolak (`unsupported equality`) | diperbaiki, workaround dicabut |
| K-018 | `spin test` dengan path absolut dan lewat PATH: run kedua `(cached)`, setelah `touch bin/spinel` dibangun ulang | diperbaiki |
| K-020 | repro `next` di blok yield: `true`, `true`, `5`, sama dengan CRuby | diperbaiki |
| K-005 | `--warn-widen` pada `sqlite/binds.rb` dan `connection_spinel.rb` masih melebar. File repro lama `db_connection_test.rb` sudah tidak ada | tidak berubah, diterima |
| K-008 | `--warn-widen` masih melebar di `Pool#with`, `query_all`, `query_first`, dan `Model#destroy` | tidak berubah, diterima |

**Regresi K-003b (lihat entri K-003 di bawah untuk detail):** ditemukan 2026-10-07, fix terkirim
sebagai **matz/spinel#7807** hari yang sama (gate ter-shard hijau penuh, CodeRabbit bersih) dan
**di-merge Matz pukul 08:45:32Z** (`b4d30a1d3`, master `f3da0151f`). Compiler kilau belum
dinaikkan ke versi yang berisi fix ini — langkah berikutnya.


Diuji dengan spinel `2026.09.12+2124 (1ba12fb74)`, yang 745 commit di depan `38dc57dd`.
Spinel baru dibuat di worktree terpisah, sedangkan instalasi `/usr/local/bin/spinel`
tetap `38dc57dd` saat tabel ini dibuat (lalu dinaikkan, lihat baris compiler di atas). Repro mandiri di-compile dengan `--require-gate` dan output-nya
dibandingkan dengan CRuby. Untuk K-014 s.d. K-017, bentuk kode lama dipasang ulang
dari riwayat pra-publik, dan tes yang dulu memicunya dijalankan dengan kedua versi.
Semua kasus "masih ada" juga gagal dengan `38dc57dd`, jadi rekonstruksinya valid.

| K | `38dc57dd` | `1ba12fb74` | Status |
|---|---|---|---|
| K-004 | link gagal (`Undefined symbols`) | link gagal | **diperbaiki upstream** (matz/spinel#6029, di-merge 2026-09-30 05:41 WIB, `eb340a6ab`) |
| K-007 | `unsupported condition (non-bool)` | sama | **diperbaiki upstream** (matz/spinel#6093, di-merge 2026-09-30 06:53 WIB, `c9b672e05`) |
| K-009 | link gagal (izin `root 0640`) | lulus dari worktree | **diperbaiki upstream** (matz/spinel#7062, di-merge 2026-10-02 09:33 WIB, `7339b7c43`); instalasi spinel lama tetap butuh `chmod` |
| K-010 | C gagal (`no member named 'cls_id'`) | sama dengan CRuby | **diperbaiki upstream** |
| K-011 | `%zz` → NUL | sama dengan CRuby (`ArgumentError`) | **diperbaiki upstream** |
| K-012 | pelebaran app 30 (`blog`) / 11 (`blog_routes`) | 30 / 11 | tidak berubah |
| K-013 | C gagal (`sp_MatchData *`) | sama | **diperbaiki upstream** (matz/spinel#6063, di-merge 2026-09-30 06:32 WIB, `35ddccadb`); workaround `match_path` dicabut |
| K-014 | `unsupported equality` / `interpolation` (http_server_test, migrator tanpa `to_s`) | penolakan sama | **diperbaiki upstream** (matz/spinel#7064, di-merge 2026-10-02 09:33 WIB, `417abb662`; perluasan operator/call #7095, di-merge 12:22 WIB, `09e78f57a`); workaround `.to_s` **dicabut 2026-10-07** setelah uji ulang (lihat blok di bawah) |
| K-015 | segfault (exit 139), CRuby 303 | segfault (exit 139) | **diperbaiki upstream** (matz/spinel#6027, di-merge 2026-09-30 03:26 WIB) |
| K-016 | `query_first` bentuk lama → tes blog `show escapes the title` FAIL | FAIL sama | **diperbaiki upstream** (matz/spinel#6008, di-merge 2026-09-30 02:21 WIB, `fe642d488`); compiler Kilau `6626c0f05` belum berisi perbaikan ini |
| K-017 | `elsif … == 0` + raise → `nil given to int` | sama | **diperbaiki upstream** (matz/spinel#5789, di-merge 2026-09-29 17:49 WIB, `dca09ca13`); diverifikasi di `6626c0f05`: repro sama dengan CRuby |

Kilau `main` dengan spinel baru: `make test` 14/14, 8/8, 4/4; `make test-cruby` 26/26;
`make e2e` 11/11 untuk kedua binary. Tidak ada regresi.

**Uji ulang 2026-09-30 ~01:10 WIB** (`repros.sh`) dengan spinel `6626c0f05` (terpasang)
dan `c5898078e` (`master` upstream saat itu): hasilnya sama di kedua compiler.
K-009, K-010, K-011, dan K-017 sama dengan CRuby. K-004 (link), K-007 (`unsupported
condition`), dan K-013 (C tidak valid) masih gagal compile. K-015 masih segfault
(`bind: String`, rc 139) dan K-016 masih mencetak `404`, bukan `200`. Batas
K-001/002/003/006 tidak berubah. K-014 tidak diuji ulang karena `old_shapes.sh`
butuh `kilau-old` (riwayat sebelum publik), yang sudah tidak ada di `phase1/`.

**Uji ulang 2026-10-02 ~06:30 WIB** dengan spinel master `cd9cc4146` ditambah fix K-024b
(`--require-gate`, semua `repro/*.rb`): K-004, K-009 (repro), K-010, K-011, K-013,
K-015 (`user_each`), K-016, K-017, K-019, K-021, K-022 dan K-024 sama dengan CRuby.
K-023 ditolak saat compile, dan itu memang perilaku #6162 (lihat entrinya). K-001
masih raise saat runtime, dengan pesan yang lebih jelas. K-002 dan K-003 tetap batasan.
`k015_endpoint_save_crash` butuh `-I` ke lib kilau, jadi tidak diuji mandiri.

**Status upstream 2026-10-02 ~13:15 WIB** (master `16cc41285`): di-merge pukul 09:33 WIB
K-009 (#7062), K-014 (#7064), K-024b (#7063) dan K-025 (#7078); pukul 12:22 WIB K-014b
(#7095) dan K-025b bagian 1 (#7096). Masih terbuka: K-025b bagian 2 (#7158). Compiler
Kilau belum dinaikkan ke versi yang berisi perbaikan-perbaikan ini.

**Uji ulang 2026-10-02 ~13:17 WIB** dengan spinel master `16cc41285` (build bersih di
worktree terpisah, `--require-gate`, semua `repro/*.rb`, pembanding CRuby 4.0.6):

| Hasil | K |
|---|---|
| sama dengan CRuby | K-004, K-009 (setelah paket di-build), K-010, K-011, K-013, K-015 (`user_each`), K-016, K-017, K-019, K-021, K-022, K-024, **K-025** |
| sama secara makna | K-007: pesan `undefined method 'save' for an instance of Gadget (NoMethodError)` sama; hanya awalan backtrace CRuby yang berbeda |
| batasan, sesuai harapan | K-001 (raise saat runtime: `undefined method 'parse' for class Time`), K-002 (`yaml` ditolak), K-003 (repro sengaja mencetak nama engine), K-006 (FFI hanya ada di spinel) |
| ditolak saat compile, memang desainnya | K-023 (#6162) |
| tidak diuji mandiri | `k015_endpoint_save_crash` (butuh `-I` ke lib kilau) |

K-014 tidak punya file repro di `repro/`. Buktinya diambil dari test spinel di master
yang sama: `raise_only_method_value`, `raise_only_method_value_overridden` (#7064) dan
`raise_only_method_more_positions` (#7095) semuanya PASS.

**Uji ulang 2026-10-12 ~17:42 WIB** dengan spinel master `46a9efb16` (build bersih di
worktree terpisah -- `rm -rf build lib/libspinel_rt.a bin/spinel`, lalu `make -j8
bin/spinel lib/libspinel_rt.a` --, `--require-gate`, semua `repro/*.rb`, pembanding
CRuby 4.0.6). Dipicu permintaan user "cek apakah ada regresi di kilau" setelah
matz/spinel#8650 (generate `respond_to?` tables + self-check Range/Symbol/Proc/
Exception) merge ke master:

| Hasil | K |
|---|---|
| sama dengan CRuby | K-004, K-009, K-010, K-011, K-013, K-015 (`user_each`), K-016, K-019, K-021, K-022, K-024, K-025, K-025c |
| sama secara makna | K-007 (pesan sama, backtrace beda) |
| batasan, sesuai harapan | K-001, K-002, K-003, K-006 |
| ditolak saat compile, memang desainnya | K-023 (#6162) |
| tidak diuji mandiri | `k015_endpoint_save_crash` |
| **REGRESI, lalu diperbaiki ulang** | **K-017** -- ditemukan 2026-10-12 ~17:50, diperbaiki dan merge sebagai matz/spinel#8679 pada hari yang sama (~21:37 WIB); lihat entrinya untuk akar masalah sesungguhnya (bukan "elsif dua argumen" seperti diagnosis awal) |
| batasan tak berubah (bukan regresi baru) | K-026 -- masih `false/false/false/false`, persis seperti terakhir didokumentasikan |

Tidak ada regresi baru di luar K-017.

## Jawaban riset

| ID | Pertanyaan | Status | Bukti |
|---|---|---|---|
| R1 | Tabel closure route tetap bertipe? | **terjawab: tidak** (2026-09-28 ~16:45 WIB) | Proc handler yang disimpan di `Endpoint` lalu dipanggil lewat `@handler.call` adalah penghalang tipe. Return `Endpoint#call` dan `Dispatcher#call` "born here" untyped, dan parameter `app_context`/`request` setiap handler "never bound", jadi seluruh kode handler berjalan boxed (K-012). Fallback spec §2.2 (`kilau gen routes`, dispatch `case` yang memanggil handler langsung) diputuskan di Rencana 4 berdasarkan benchmark S1/S2. Eksperimen Rencana 4 (2026-09-29): `kilau gen routes` (D-022) menghapus penghalang proc. Pelebaran di kode app turun 30 → 11. S1/S2 c64 17.128 vs 17.156 dan 16.339 vs 16.389 req/s (setara). S3 c16 2.367 vs 3.180 req/s dengan p99 57 → 12 ms (bench/RESULTS.md). Diukur ulang di spinel `1ba12fb74` (2026-09-29 14:00 WIB): S3 c16 2.502 vs 3.085 req/s dengan p99 57 → 13 ms (bench/results/20260929-1347-s3-1ba12fb74). `gen routes` **diadopsi** sebagai jalur utama: D-023. |
| R2 | `Hash[String, String]` params/form tetap sempit? | **terjawab: sebagian** (2026-09-28 ~17:03 WIB) | Di dalam `Kilau::Request`/`Kilau::Form`, hash tetap sempit: `Form.decode`, `#form_values`, dan `#query` tidak muncul di `--warn-widen` (examples/blog/test/posts_request_test.rb). Di kode app, nilainya boxed: `PostParams.from_form` parameter `fields` melebar, begitu juga `Request#form` param `prefix` dan return `header`. Penyebabnya bukan hash, melainkan `request` di handler yang sudah untyped (K-012), sehingga setiap pemanggilan `request.*` di-dispatch poly. Perbaikannya sama dengan R1 (dispatch tanpa proc). |
| R3 | Kolom nullable di entity tetap bertipe? | **terjawab: ya** (2026-09-28 ~16:19 WIB) | `--warn-widen` pada framework/test/model_test.rb (Widget, kolom `note` nullable lewat `text_or_nil`) dan examples/blog/test/post_model_test.rb: tidak ada peringatan untuk atribut entity, `from_row`, atau `Row#text_or_nil` yang dipanggil. Kemunculan `text_or_nil`/`float` di log Post hanya karena method itu tak pernah dipanggil di sana ("never bound"). Pelebaran yang tersisa di lapisan data berasal dari K-005, K-006, dan K-008, bukan dari nullability. |
| R4 | `buf << ...` di template tetap di jalur string buffer? | **terjawab: ya, buffernya** (2026-09-29 ~09:32 WIB) | Setiap `buf << ...` hasil `kilau gen templates` di-compile menjadi `sp_String_append_bin` ke satu `sp_String` yang bisa diubah (append in-place, satu salinan saat return); tak ada `templates.rb` di `--warn-widen` untuk tool/test/template_runtime_test.rb, dan `Templates.items_list` bertanda `(sp_StrArray *, const char *)`. Di blog, *nilai* yang masuk ke template ikut boxed bila pemanggilnya handler: parameter `posts_list`/`posts_show`/`posts_edit` = `sp_RbVal` ("never bound"), sedangkan `posts_new`/`posts__form` tetap `sp_Post *`. Penyebabnya K-012 (dan K-008 untuk `Post.all`), bukan template; fallback dispatch tanpa proc di Rencana 4 akan ikut menyempitkan template. |
| R5 | FFI menangani `SQLITE_TRANSIENT` dan salinan `column_text`? | **terjawab: ya** (2026-09-28, sebelum 16:19 WIB) | `bind_text(stmt, i, s, -1, -1)` = SQLITE_TRANSIENT lewat integer literal sebagai `:ptr`; teks yang dibaca di blok `query` selamat setelah `finalize` + `GC.start` (tes `text read in a block outlives the statement`, teks Unicode dan 10 KB); out-param `sqlite3**`/`sqlite3_stmt**` lewat wrapper C `ffi_source`. Biaya: handle/statement berjalan di jalur boxed (K-006). |
| R6 | Green thread + FFI `blocking: true` + pool tahan konkurensi? | **terjawab: ya** (2026-09-29 12:36 WIB) | Sesi benchmark `bench/results/20260929-1108` (urutan selang-seling, `SPINEL_WORKERS=8`, pool 5, WAL): di c64, `kilau` melayani S1 17.128, S2 16.339, S3 2.530, dan S4 8.815 req/s (p99 4,65 / 6,08 / 85,72 / 51,66 ms), dan `kilau-routes` 17.156 / 16.389 / 3.304 / 8.818 req/s. Di semua 24 sel Kilau (72 run terukur + 24 pemanasan): 0 status selain 200/303, 0 error selain batas waktu oha, dan 0 `busy`/`locked` di log app. S4 c64 berarti ~8.800 INSERT/dtk dari 64 koneksi lewat 5 koneksi SQLite. Sebagai pembanding, Rails (8 worker × 5 thread) menjawab satu `500` `SQLite3::BusyException` di pemanasan S4 c16 dan c64. Sebelumnya: 50 thread × insert di framework/test/db_pool_test.rb dan 200 request/32 koneksi di `make e2e`. Lihat `bench/RESULTS.md`. |

## K-001: `Time.parse` tidak tersedia, dan gagal diam-diam saat compile
- Lapisan: model
- Pola Loco yang dicoba: timestamp sebagai TEXT ISO-8601
- Yang terjadi:
  - Compile **lolos tanpa peringatan**, walaupun memakai `--require-gate`.
  - Saat dijalankan: `undefined method 'to_i' for unknown (NoMethodError)`, exit 1.
  - CRuby mencetak `1790582400`.
- Repro: repro/k001_time_parse.rb
- Klasifikasi: batasan-terdokumentasi (spinel docs/limitations.md: tambahan parsing `require "time"`)
- Solusi yang dipakai: kolom INTEGER berisi epoch detik; dibaca dengan `Time.at`
- Biaya: timestamp di CLI `sqlite3` perlu `datetime(col, 'unixepoch')` agar terbaca
- Upstream: **diperbaiki** (matz/spinel#8029, di-merge 2026-10-08 10:13 WIB). `Time.parse`/`Time.strptime` sekarang ditolak saat compile, bukan `NoMethodError` saat runtime; penolakan dikunci ke rantai method `Time` sendiri (bukan sembarang kelas bernama `Time`). Follow-up **matz/spinel#8115** (di-merge 2026-10-08 21:50 WIB) membuat penolakan ini bisa dideferred lewat `--defer-refusals` seperti penolakan lain.
- **Uji ulang 2026-10-09** dengan spinel master `961718cc9`: `repro/k001_time_parse.rb` kini ditolak saat compile (bukan lagi lolos tanpa peringatan). **K-001: Fixed.**

## K-002: `YAML` tidak tersedia
- Lapisan: config
- Pola Loco yang dicoba: `config/<env>.yaml` (spec §3.1)
- Yang terjadi: `spinel: cannot load such file -- yaml (require "yaml")`, exit compile 1 (dengan require gate). Tanpa gate: peringatan `'yaml' is not available in Spinel`, lalu `NameError` saat dijalankan.
- Repro: repro/k002_yaml.rb
- Klasifikasi: batasan-terdokumentasi (stdlib C-extension)
- Solusi yang dipakai: `Kilau::Config`, parser subset YAML milik framework dengan getter bertipe dan override `KILAU_*` (spec §3.1a, diimplementasikan di Rencana 2). Selama Rencana 1, `blog_schema` menerima `--db PATH`.
- Biaya: belum terukur
- Upstream: tidak perlu

## K-003: `require` di cabang `RUBY_ENGINE` yang mati tetap di-resolve
- Lapisan: db
- Pola Loco yang dicoba: backend spinel (FFI) dan CRuby (gem `sqlite3`) dipisah dengan `if RUBY_ENGINE == "spinel"`
- Yang terjadi: `spinel: cannot load such file -- sqlite3 (require "sqlite3")`, exit compile 1
- Repro: repro/k003_require_in_dead_branch.rb
- Klasifikasi: batasan-terdokumentasi (require di-resolve saat parse, sebelum cabang dibuang)
- Solusi yang dipakai: `gem "sqlite3"` lalu `Kernel.require "sqlite3"` di cabang CRuby. `Kernel.require` tidak di-resolve spinel saat parse. Tetapi `Kernel.require` adalah require inti yang melewati override RubyGems, jadi `gem` harus mengaktifkan load path gem lebih dulu. Tanpa itu, CRuby gagal dengan `cannot load such file -- sqlite3 (LoadError)`. Diverifikasi 2026-09-28 di kedua engine.
- Biaya: nol; dua baris
- Upstream: diusulkan sebagian — lihat **K-003b** di bawah untuk workaround `Kernel.require` sendiri

**K-003b — regresi pada workaround `Kernel.require` (ditemukan 2026-10-07, FIXED)**
- Yang terjadi: dengan spinel master `ae2c38c71`, workaround `Kernel.require "sqlite3"` di atas
  (dipakai persis begini oleh paket `spinel-sqlite` v0.1.0 yang dipakai kilau) sendiri mulai
  ditolak di bawah `--require-gate` (yang selalu dipakai `spin build`/`spin test`):
  `cannot load such file -- sqlite3`, walau cabangnya tidak pernah jalan. `make test` kilau
  gagal di tahap `tool`.
- Akar penyebab (dibuktikan lewat bisect): commit spinel `0c0f61fff` ("`Kernel.require "x"` is
  the bare require", 2026-09-30) membuat `Kernel.require` diresolve sebagai require polos
  secara tekstual, tapi skip cabang mati saat itu hanya menangkap bentuk `require` polos.
  Perbaikan lain (`5fbdf2411`, 2026-10-01) menutup lubang untuk `require` polos tapi tidak
  untuk `Kernel.require`, jadi tetap rusak sejak 2026-09-30.
- Repro dan analisis lengkap: spinel `DRAFT_REQUIRE_GATE_REGRESSION.md` (repo root, status
  RESOLVED).
- Upstream: **matz/spinel#7807** (dibuka 2026-10-07, langsung sebagai PR tanpa issue terpisah —
  CONTRIBUTING.md: "a pull request needs no issue"), branch fork `kernel-require-dead-branch`.
  Gate ter-shard di fork hijau penuh (run 37585630372: korpus 6.251 test, infer-test,
  scale-test, optcarrot, bench, rubyspec). **Di-merge Matz pukul 08:45:32Z** (`b4d30a1d3`,
  master `f3da0151f`).
- **Diuji ulang 2026-10-07 ~16:30 WIB** dengan compiler terpasang `f3da0151f`: `make test`
  (13/13 framework, 8/8 tool, 4/4 blog), `make test-cruby` (semua `ok`), `make e2e` di
  `examples/blog` (`blog` dan `blog_routes`, semua `ok` termasuk 200 request konkuren) —
  semuanya lolos penuh tanpa workaround, dari build bersih. **K-003b: Fixed.**

## K-004: method yang menerima blok, lewat `include` di top level, tidak di-emit
- Lapisan: testing (menimpa semua lapisan yang memakai helper modul)
- Pola yang dicoba: `module Kilau::Testing; def check(label) ... yield ... end; end`, lalu `include Kilau::Testing` di top level tes
- Yang terjadi:
  ```
  Undefined symbols for architecture arm64:
    "_sp_Helper_check", referenced from:
  ld: symbol(s) not found for architecture arm64
  ```
  - Terjadi pada modul bersarang maupun tidak, dengan `yield` maupun `&blk`.
  - Method yang sama tanpa blok bekerja.
  - `include` di dalam class bekerja.
  - Pemanggilan sebagai method modul (`def self.check`, juga lewat alias `T = Mod`) bekerja.
- Repro: repro/k004_include_block_method.rb (CRuby: `ok flat yield`)
- Klasifikasi: bug-compiler
- Solusi yang dipakai: `Kilau::Testing` memakai method modul, dan tes memanggil `T.check(...)` dengan `T = Kilau::Testing`
- Biaya: nol untuk runtime; tes sedikit lebih verbose
- Upstream: **diperbaiki** (matz/spinel#6029, di-merge 2026-09-30 05:41 WIB). Repro sama dengan CRuby di `cd9cc4146` (2026-10-02).
- **Perbaikan (Rencana 6 Fase 2, 2026-09-30):** method yang `yield` hanya ada dalam bentuk inline, jadi fungsinya tidak pernah di-emit. `emit_inline_call_x` (`src/codegen_iter.c`) mencari panggilan tanpa receiver di kelas pembungkus dan fungsi top level, tapi tidak di modul yang di-`include` di top level. Panggilan jatuh ke jalur top-level-include di `emit_call`, yang memanggil `sp_<Modul>_<method>(NULL, …)`, fungsi yang tidak ada, sehingga link gagal. Kini inliner juga mencari lewat `comp_included_method_index`; method yang memakai ivar tetap ke jalur lama (ditolak dengan diagnostik #3775). Tes `test/toplevel_include_yielding_method.rb` (yield, `&blk`, modul bersarang, dipanggil dari method top level) merah sebelum, hijau sesudah, GC stress lulus; C benchmark identik; CI penuh hijau di PR fork. Commit `471ed6171` → direvisi tiga kali atas temuan CodeRabbit menjadi `602e30b52`: (1) `comp_included_method_index` kini mencari method **instance** dulu, karena modul dengan `def self.pick` + `def pick` diam-diam menjawab singleton; (2) inliner juga mengambil method kelas (`module_function`) dengan modul sebagai self, karena `module_function` + `yield` masih gagal link; (3) pemeriksaan ivar di kedua jalur kini lewat satu helper `scope_uses_ivars` (`codegen_util.c`) yang juga menangkap target multi-assign (`@a, @b = …`) dan `&&=`, dipatok reject test `test/reject/toplevel_include_yield_ivar_target.rb`. Temuan ke-4 (ivar di blok bersarang) tidak bisa direproduksi dengan lima bentuk; dibalas. **PR https://github.com/matz/spinel/pull/6029**, **di-merge oleh matz 2026-09-30 05:41 WIB** (`eb340a6ab`). Riwayat terkait: #5117 (gejala sama lewat clone proc form saat modul di-include dua kali).
- **Workaround dicabut (2026-09-30, compiler `35ddccadb`):** `Kilau::Testing` kini `module_function`; tes bisa `include Kilau::Testing` lalu `check` tanpa receiver (tes baru `framework/test/testing_include_test.rb`), tes lama `T.check` tetap. Satu bentuk tersisa gagal: K-021.

## K-005: array binds campuran melebar ke untyped
- Lapisan: db
- Pola yang dicoba: `conn.execute(sql, [title, nil, 3, 1.5])` (D-004)
- Yang terjadi (`--warn-widen`, test/db_connection_test.rb):
  ```
  kilau/db/connection_spinel.rb:48:26: warning: parameter `binds` of `execute` widened to untyped (boxed poly slow path)
  test/db_connection_test.rb:12:90: note: passed `` is Array[untyped] -- born here: no untyped input
  kilau/db/connection_spinel.rb:101:31: warning: parameter `value` of `bind` widened to untyped (boxed poly slow path)
  kilau/db/base.rb:15:26: warning: parameter `binds` of `check_binds` widened to untyped (boxed poly slow path)
  ```
- Repro: framework/test/db_connection_test.rb (`spinel $(spin flags) --warn-widen ...`)
- Klasifikasi: pelebaran-tipe (sudah diduga: array bernilai campuran)
- Solusi yang dipakai: diterima. `bind` men-dispatch per nilai lewat `case`, sekali per parameter SQL.
- Biaya: belum terukur. Diukur di benchmark S4 (Rencana 4). Kalau signifikan, alternatifnya binder bertipe (`bind_text(i, s)`) per kolom di entity hasil generate.
- Upstream: tidak perlu
- **Uji ulang 2026-10-07 ~11:12 WIB** (spinel `ae2c38c71`): `--warn-widen` pada paket sqlite `binds.rb` masih melebar (`int`, `text`, `int_or_nil`, dst.), jadi pelebaran tetap seperti dicatat di atas. File `framework/test/db_connection_test.rb` tidak ada lagi; pelebarannya sekarang terlihat di paket sqlite. Tidak berubah, diterima.


## K-006: `:ptr` dari `ffi_func` melebar ke untyped begitu dioper atau disimpan
- Lapisan: db
- Pola yang dicoba: `Row.new(stmt)` / `Connection.new(handle)` menyimpan pointer SQLite di ivar
- Yang terjadi:
  - Setiap pointer lahir sebagai untyped. Terjadi juga di modul datar paling sederhana (`malloc` → ivar), jadi bukan akibat struktur Kilau.
  - Output `--warn-widen` untuk repro:
    ```
    ptrw.rb:6:18: warning: parameter `p` of `initialize` widened to untyped (boxed poly slow path)
    ptrw.rb:11:16: note: passed `LibC.malloc(16)` is untyped -- born here: no untyped input
    ```
- Repro: repro/k006_ffi_ptr_widens.rb
- Klasifikasi: pelebaran-tipe (perilaku FFI spinel; docs/FFI.md hanya menyebut pointer tidak boleh masuk nilai polimorfik)
- Solusi yang dipakai: diterima untuk sekarang. Semua pemanggilan `Native.*` tetap benar.
- Biaya: setiap akses kolom lewat `Row` mem-unbox pointer statement. Diukur di benchmark S3 (100 baris) di Rencana 4.
- Upstream: kandidat pertanyaan ke spinel (apakah `:ptr` dalam ivar bisa tetap bertipe); belum dilaporkan

## K-007: pemanggilan method yang tak terdefinisi di blok `unless yield` menjadi error tak jelas
- Lapisan: testing (diagnostik compiler)
- Pola yang dicoba: fase RED TDD. `T.check("...") { widget.save(db) }` sebelum `Kilau::Model` ada.
- Yang terjadi:
  - Dalam isolasi: `spinel: unresolved.rb:3: unsupported condition (non-bool): node 10 (YieldNode)` / `1 refusal, nothing written`.
  - Di framework/test/model_test.rb: C yang tidak valid, `kilau/testing/check.rb:9: error: invalid argument type 'sp_RbVal' to unary expression`, lalu `C compilation failed`.
  - CRuby melaporkan `undefined method 'save' for an instance of Gadget (NoMethodError)`.
  - Hilang begitu method-nya didefinisikan. Nilai poly biasa sebagai hasil `yield` bekerja normal.
- Repro: repro/k007_unresolved_call_in_yield_condition.rb
- Klasifikasi: bug-compiler (kualitas diagnostik; bukan perilaku runtime)
- Solusi yang dipakai: tidak perlu. Di fase RED, baca error ini sebagai "method belum ada".
- Biaya: kebingungan saat TDD
- Upstream: **matz/spinel#6093 merged** (2026-09-30 06:53 WIB)
- **Perbaikan (Rencana 6 Fase 2, 2026-09-30):** node `yield` dipakai bersama semua call site, jadi tipenya diambil dari blok call site lain. Hanya satu call site → tak bertipe → ditolak "non-bool"; di samping call site berblok bool → tipe bool, lalu blok yang melempar (`({ sp_raise_nomethod(...); })`, `sp_RbVal`) di-negasi `!` → C gagal (gejala "program besar"). Di samping blok poly sudah benar (`sp_poly_truthy`). `emit_cond` (`codegen_stmt.c`) kini, sebelum dispatch tipe, melihat blok yang di-inline di call site ini: bila tail-nya tak bertipe, `block_tail_is_unresolved` (dipindah dari `codegen_fold.c` jadi helper bersama), dan tidak ada `next v` → kondisi `((yield), 0)` (bentuk sama dengan #5096). Versi pertama lupa syarat tail tak bertipe (blok `1 + 1 == 2` ikut dianggap falsy); temuan CodeRabbit di fork menambah syarat `next`. Tes `test/yield_condition_block_calls_missing_method.rb` merah sebelum, hijau sesudah, GC stress lulus, CI fork hijau, C benchmark identik. Commit `9198a689d`, **PR https://github.com/matz/spinel/pull/6093**.

## K-008: method yang mengembalikan hasil blok melebar ke untyped, termasuk `Post.all`
- Lapisan: db / model
- Pola yang dicoba: helper generik ala Loco (`Pool#with { |conn| ... }`, `query_all(sql, binds) { |row| from_row(row) }`) yang mengembalikan nilai dari blok pemanggil
- Yang terjadi (`--warn-widen`, examples/blog/test/post_model_test.rb):
  ```
  framework/kilau/db/pool.rb:18:7: warning: the return of `with` widened to untyped (boxed poly slow path)
  framework/kilau/db/pool.rb:38:7: warning: the return of `query_all` widened to untyped (boxed poly slow path)
  src/models/posts.rb:11:3: warning: the return of `all` widened to untyped (boxed poly slow path)
  framework/kilau/model/errors.rb:15:5: warning: the return of `[]` widened to untyped (boxed poly slow path)
  src/models/_entities/posts.rb:29:5: warning: the return of `insert_binds` widened to untyped (boxed poly slow path)
  ```
  - Satu method dipakai dengan blok yang mengembalikan tipe berbeda (Integer, String, Post), sehingga return-nya melebar dan hasil `Post.all` ikut boxed.
  - `Errors#[]` (lookup `Hash[String, String]` → `String | nil`) juga melebar. Ini relevan untuk R2.
- Repro: examples/blog/test/post_model_test.rb (`spinel $(spin flags) --warn-widen ...`)
- Klasifikasi: pelebaran-tipe
- Solusi yang dipakai: diterima di Rencana 1, karena perilakunya benar di kedua engine.
- Biaya: belum terukur. Kandidat perbaikan di Rencana 2/4 kalau benchmark S3 menunjukkan biaya: entity hasil generate menyediakan finder bertipe sendiri (`all`, `find_by_id`) yang memanggil `Connection#query` langsung, bukan lewat blok generik pool.
- Upstream: tidak perlu (sifat inferensi return per method, bukan per pemanggilan)
- **Uji ulang 2026-10-07 ~11:12 WIB** (spinel `ae2c38c71`): `--warn-widen` pada `examples/blog/test/post_model_test.rb` masih melaporkan `Pool#with`, `query_all`, `query_first` (paket sqlite) dan `Model#destroy`. Tidak berubah, diterima.


## K-009: `StringIO` gagal link karena izin file instalasi
- Lapisan: testing (lingkungan)
- Pola yang dicoba: tes parser HTTP dengan `StringIO` sebagai IO palsu
- Yang terjadi:
  ```
  ld: file cannot be open()ed, errno=13 (Permission denied) path=/usr/local/lib/spinel/packages/stringio/sp_stringio.o in '/usr/local/lib/spinel/packages/stringio/sp_stringio.o'
  clang: error: linker command failed with exit code 1 (use -v to see invocation)
  ```
  CRuby mencetak `a`.
- Repro: repro/k009_stringio_install_perms.rb
- Klasifikasi: lingkungan / instalasi. File `sp_stringio*.o` dimiliki `root:wheel` dengan mode `0640` setelah `sudo make install`.
- Solusi yang dipakai: tes memakai `FakeIO` sendiri (framework/test/support/fake_io.rb). Perbaikan permanen yang butuh izin pengguna: `sudo chmod a+r /usr/local/lib/spinel/packages/*/*.o`, atau install ulang dengan umask 022.
- Biaya: nol untuk Kilau
- Upstream: **diperbaiki**, matz/spinel#7062 di-merge 2026-10-02 09:33 WIB (`7339b7c43`). Sebelumnya masih ada di master `cd9cc4146`. Akar masalahnya terverifikasi: sccache 0.17.0 menulis object `0640` apa pun umask-nya, termasuk saat cache hit (`cc` biasa menghasilkan `0644`), lalu `make install` menyalinnya dengan `cp -r`. Fix: `chmod -R a+rX` atas `packages/` dan `builtins/` yang terpasang. Commit `4ad0e9709`, branch spinel `k009-install-readable-packages`, PR upstream **matz/spinel#7062** (dibuka 2026-10-02 ~06:45 WIB; CI fork 5.478 lolos; fork #14 ditutup). Uji: install ke PREFIX scratch, resep lama menyisakan 16 object `0640`, resep baru 0. `chmod` manual hanya perlu untuk instalasi spinel yang lebih lama dari `7339b7c43`.
- **Akar masalah (2026-09-29 13:45 WIB):**
  - `common.mk` spinel otomatis membungkus `cc` dengan **sccache** kalau sccache
    terpasang.
  - sccache menulis `.o` dengan mode `0640`, meskipun umask-nya `022`. Contohnya
    `build/regexp/*.o` dan `packages/*/*.o` di worktree.
  - `make install` menyalin `packages` dengan `cp -r`, sehingga mode itu ikut
    terbawa, dengan pemilik root.
  - Akibatnya 14 `.o` di 7 paket (json, openssl, strscan, stringio, zlib, tmpdir,
    base64) tidak bisa dibaca user biasa. `umask 022` saat install **tidak**
    menolong.
  - Perbaikan lokal: `sudo chmod a+r /usr/local/lib/spinel/packages/*/*.o`, sudah
    dijalankan pengguna. Setelahnya repro k009 ter-link dan sama dengan CRuby.
  - Kandidat upstream: installer sebaiknya memakai `install -m 0644` atau `chmod`
    setelah `cp`, atau build tanpa sccache (`NO_CCACHE=1`) untuk install.

## K-010: method yang di-override subclass exception, dipanggil setelah `rescue Base => e`, gagal compile
- Lapisan: controller
- Pola yang dicoba: `class Kilau::Error; def status = 500; end` dengan `NotFound#status = 404`, lalu `rescue Kilau::Error => e; e.status` di dispatcher
- Yang terjadi:
  - `repro/k010_exception_method_override.rb:14: error: no member named 'cls_id' in 'struct sp_Exception_s'` (exit compile 1). CRuby mencetak `404`.
  - Pada varian yang sama (probe 2026-09-28), `e.is_a?(NotFoundErr)` mengembalikan `false`, padahal CRuby `true`. Tanpa override method, `is_a?` benar.
- Repro: repro/k010_exception_method_override.rb
- Klasifikasi: bug-compiler
- Solusi yang dipakai: status disimpan sebagai ivar lewat `initialize(status, message)`, dan subclass memanggil `super(404, message)`. Tidak ada override method pada subclass exception.
- Biaya: nol
- Upstream: **diperbaiki upstream** (lulus sejak `1ba12fb74`; sama dengan CRuby di `cd9cc4146`, 2026-10-02).

## K-011: `URI.decode_www_form_component` mendekode input rusak diam-diam, termasuk menjadi byte NUL
- Lapisan: http
- Pola yang dicoba: `Kilau::Form.unescape` = `URI.decode_www_form_component` + `rescue ArgumentError` → 400 (seperti di CRuby)
- Yang terjadi (repro, spinel vs CRuby):
  ```
  "%zz" -> "\u0000"          | CRuby: ArgumentError invalid %-encoding (%zz)
  "post%5Bt%zz" -> "post[t\u0000" | CRuby: ArgumentError
  "%4" -> "%4"                | CRuby: ArgumentError
  "a%2" -> "a%2"              | CRuby: ArgumentError
  "%C3%A9" -> "é"             | sama
  ```
  Input form berisi `%zz` akan sampai ke aplikasi sebagai byte NUL tanpa error.
- Repro: repro/k011_uri_decode_malformed.rb
- Klasifikasi: bug-compiler / stdlib (perilaku berbeda dari CRuby, diam-diam; relevan keamanan)
- Solusi yang dipakai: `Kilau::Form.unescape` memvalidasi sendiri bahwa setiap `%` diikuti dua digit hex (kalau tidak, `BadRequest` 400), baru memanggil decoder stdlib. Tes `broken percent-encoding in a form/query is BadRequest` lulus di kedua engine.
- Biaya: satu pemindaian string per nilai form
- Upstream: **diperbaiki upstream** (lulus sejak `1ba12fb74`; sama dengan CRuby di `cd9cc4146`, 2026-10-02).

## K-012: proc yang disimpan lalu dipanggil lewat `.call` memutus inferensi tipe (menjawab R1)
- Lapisan: routing
- Pola Loco yang dicoba: `get { |app_context, request| list(app_context, request) }` → `Endpoint` menyimpan blok → `Dispatcher` memanggil `route.endpoint.call(app_context, request)`
- Yang terjadi (`--warn-widen`, framework/test/dispatcher_test.rb, 2026-09-28 ~16:45 WIB):
  ```
  kilau/controller/controller.rb:11:5: warning: the return of `call` widened to untyped (boxed poly slow path)
  kilau/controller/controller.rb:11:38: note: returned `@handler.call(app_context, request)` is untyped -- born here: no untyped input
  kilau/routing/dispatcher.rb:12:5: warning: the return of `call` widened to untyped (boxed poly slow path)
  test/dispatcher_test.rb:16:30: warning: parameter `request` of `list` widened to untyped (boxed poly slow path)
  note: never bound: no call site gives it a type
  ```
  Hal yang sama terjadi untuk `app_context`/`request` di `add`, `show`, `update`, dan `remove`.
- Repro: framework/test/dispatcher_test.rb (`spinel $(spin flags) --warn-widen ...`)
- Klasifikasi: pelebaran-tipe (batas inferensi: argumen dan return proc yang disimpan tidak dilacak)
- Solusi yang dipakai: diterima di Rencana 2, karena perilakunya benar di kedua engine.
- Biaya: belum terukur. Setiap request melewati dispatch boxed, dan setiap akses `request.*`/`app_context.*` di handler berjalan boxed.
- Alternatif (spec §2.2 fallback): `kilau gen routes` menghasilkan `case` yang memanggil `PostsController.list(app_context, request)` langsung, tanpa proc. Diputuskan di Rencana 4 dengan angka S1/S2.
- Upstream: kandidat pertanyaan (apakah tipe argumen/return proc yang disimpan bisa dilacak bila semua pemanggil konsisten); belum dilaporkan

## K-013: method buatan bernama sama dengan bawaan (`match`) pada receiver untyped di-resolve ke bawaan, dan C gagal compile
- Lapisan: routing
- Pola yang dicoba: `Route#match(path)` dipanggil dari `Dispatcher#call`. Di program yang tidak memakai router (misalnya framework/test/smoke_test.rb, yang tetap meng-compile seluruh framework), `route` tidak pernah bertipe.
- Yang terjadi:
  - Di test suite: `kilau/routing/dispatcher.rb:16: error: assigning to 'volatile sp_RbVal' from incompatible type 'sp_MatchData *'`. `smoke_test` dan `http_parser_test` gagal build, sedangkan `dispatcher_test` (yang memakai router) lulus.
  - Repro minimal: `k013.rb:12: error: assigning to 'sp_RbVal' from incompatible type 'sp_MatchData *'`. CRuby jalan normal.
- Repro: repro/k013_builtin_name_on_untyped_receiver.rb
- Klasifikasi: bug-compiler
- Solusi yang dipakai: `Route#match` → `Route#match_path` (sampai 2026-09-30; **dicabut** setelah matz/spinel#6063 di-merge dan compiler Kilau naik ke `35ddccadb`: nama kembali `match`, suite hijau dari build bersih, sedangkan compiler lama `6626c0f05` gagal 11/14 dengan error K-013). **Aturan umum:** hindari nama method yang sama dengan method bawaan String/Array/Hash (`match`, `size`, `each`, `call`, ...) pada kelas framework yang bisa tidak terpakai di sebagian program.
- Biaya: nol (ganti nama)
- Upstream: **diperbaiki** (matz/spinel#6063, di-merge 2026-09-30 06:32 WIB).
- **Perbaikan (Rencana 6 Fase 2, 2026-09-30):** analyzer (`an_user_defines_or_reads`) menghitung setiap kelas yang mendefinisikan `match`, sedangkan codegen (`user_defines_or_reads`) hanya kelas yang bisa dijangkau. Karena `Route` tak pernah dibuat, codegen memakai `match` bawaan (`sp_MatchData *`) ke slot yang analyzer beri tipe poly, dan C gagal. Arm `match` di `codegen_call_recv.c` kini mem-box hasil bawaan bila analyzer mengetik panggilan itu poly (`match?`/`=~` sudah aman; `size` dicek aman). Tes `test/untyped_receiver_builtin_match_beside_user_match.rb` merah sebelum, hijau sesudah, GC stress lulus, C benchmark identik. Commit `705e36969`, CI hijau + CodeRabbit bersih di PR fork #4, lalu **PR https://github.com/matz/spinel/pull/6063** (dibuka 2026-09-30 05:44 WIB; CodeRabbit upstream: tanpa temuan), **di-merge oleh matz 2026-09-30 06:32 WIB** (`35ddccadb`).

## K-014: kode mati dengan receiver untyped bisa ditolak, bergantung pada isi program lain
- Lapisan: model (terpicu dari tes HTTP server)
- Pola yang dicoba: `Migrator#rollback` / `#status_lines` membandingkan dan meng-interpolasi `m.version`. Di framework/test/http_server_test.rb, Migrator tidak dipakai sama sekali, tapi tetap ikut di-compile sebagai bagian dari framework.
- Yang terjadi:
  ```
  spinel: .../framework/kilau/model/migrator.rb:41: unsupported equality: node 3625 (CallNode `==`) recv=CallNode/ty1 argc=1 arg0ty6
  spinel: .../framework/kilau/model/migrator.rb:52: unsupported interpolation value: node 3684 (EmbeddedStatementsNode)
  spinel: 2 refusals, nothing written
  ```
  - Tes lain yang juga meng-compile Migrator tanpa memakainya (dispatcher_test, smoke_test) tidak kena.
  - Repro kecil (class + Migrator mati, dengan atau tanpa `require "socket"` / Thread) **tidak** memicunya.
  - Pemicu pastinya **belum terisolasi**. Pencarian dihentikan sesuai batas 6–8 giliran per masalah.
- Repro: belum ada yang minimal. Kondisi pemicunya adalah framework/test/http_server_test.rb di commit sebelum perbaikan (lihat git log Task 5 Rencana 2).
- **Isolasi lanjutan (Rencana 6 Fase 1, 2026-09-29 16:26 WIB, spinel `1ba12fb74`)**: penolakan yang sama masih muncul (bentuk lama: `migrator.rb` tanpa `to_s` + `http_server_test.rb`). Temuan:
  1. reduksi per file (oracle: CRuby berjalan sukses + spinel menolak dengan `unsupported equality`): wajib ada rantai **kode mati** `cli/schema_cli` → `model/migrator` → `model/migration`, plus `db/connection_spinel`. File lain tidak bisa dilepas karena dipakai tes HTTP yang hidup;
  2. rantai kode mati itu **saja** (15 file framework, badan program `puts "ok"`) ter-compile normal. Jadi penolakan juga butuh **bagian hidup** program (server HTTP, Dispatcher, Config, dan seterusnya). Itu menjelaskan kenapa repro kecil dulu tidak pernah memicunya;
  3. pesan penolakan: `recv=CallNode/ty1 argc=1 arg0ty0`. `m.version` bertipe nil, karena `Migration#version` di kelas dasar hanya `raise` dan tes ini tidak punya subclass migrasi, sedangkan argumennya tidak diketahui tipenya. Repro tulisan tangan dengan bentuk itu (kode mati saja) ter-compile normal;
  4. temuan terkait: kalau `Migrator` **dipakai** dan `version` hanya `raise`, spinel menolak `"#{m.version}"` saat compile (`unsupported interpolation value`), padahal CRuby baru gagal saat runtime.
- ddmin per baris dengan oracle ketat (CRuby harus berjalan sukses) masih berjalan (1.428 → 853 baris saat dicatat). Batas 6–8 giliran untuk K-014 sudah tercapai.
- Klasifikasi: bug-compiler (dugaan: receiver untyped di kode mati di-resolve ke tipe lain; sekeluarga dengan K-013)
- Solusi yang dipakai: `m.version.to_s` sebelum `==` dan interpolasi, sehingga operand selalu `String`. **Aturan umum:** di kode framework yang bisa mati di sebagian program, paksa tipe primitif (`to_s`, `to_i`) sebelum `==` dan interpolasi pada nilai dari receiver generik.
- Biaya: nol
- Upstream: **diperbaiki** (lihat Fix di bawah). Catatan lama: "perlu isolasi lebih dulu", sudah terisolasi 2026-10-02.
- **Workaround dicabut 2026-10-07 ~11:12 WIB** (`framework/kilau/model/migrator.rb`, baris 30, 41, 53). Dengan `spinel` `ae2c38c71` (terpasang), `migrator_test`, `http_server_test`, `schema_cli_test` dan 13 tes framework lainnya lolos sama dengan `.expected`. Compiler lama `ea9feecfe` tidak lagi dipakai, jadi tidak ada uji silang.
- **Terisolasi 2026-10-02** (spinel master `2be1b3c59`): pemicunya adalah method yang **selalu raise** (`Migration#version` di kelas dasar), bukan kode mati. Analyzer mengetiknya `TY_VOID` ("ty1" di pesan penolakan). Codegen menolak `==`/`!=` dan interpolasi atas call VOID. Repro minimal (19 baris, receiver poly lewat `@ms.map { |m| ... }`) gagal compile di master, sedangkan CRuby mencetak `raised subclass` dua kali. Penolakan bergantung pada isi program lain karena subclass yang meng-override `version` (dengan String) membuat dispatch poly bertipe String, dan tes HTTP tidak punya migrasi.
- **Fix**: `call_never_returns` (`src/codegen_util.c`), dipakai emitter interpolasi (diperlakukan seperti arm `sp_raise_*`, #4092) dan emitter `==`. VOID saja tidak cukup: `puts`/`print`/`p`/`warn` tanpa receiver juga VOID tapi mengembalikan nil (`puts(...) == nil` tetap `true`). Commit `62f363590`, branch spinel `k014-raise-only-method-value`, PR upstream **matz/spinel#7064**, **di-merge 2026-10-02 09:33 WIB** (`417abb662`). **Perluasan** ke operator, call method dan rantai (`m.version + "x"`, `< 3`, `.size`, `m.version - 1 > 2`): branch `k014b-raise-only-method-more-positions`, **matz/spinel#7095 di-merge 2026-10-02 12:22 WIB** (`09e78f57a`; fork #16 ditutup). Local assignment `x = m.version` sudah berfungsi sejak awal. Workaround `.to_s` di `migrator.rb` (baris 30, 41, 53) bisa dicabut **setelah** compiler Kilau dinaikkan ke spinel yang berisi `417abb662`.

## K-015: Integer di array binds campuran terbaca sebagai String, lalu segfault (jalur handler lewat `Endpoint#call`)
- Lapisan: db / routing
- Pola yang dicoba: blog `POST /posts` → `Endpoint#call` (proc tersimpan) → `PostsController.add` (parameter untyped, K-012) → `Post#save(db)` (dispatch poly `db.insert`) → `Pool#insert` → `Connection#execute` → `DB.check_binds(binds)` dengan `binds = [@title, @content, @created_at, @updated_at]`
- Yang terjadi:
  - Binary tes: `Segmentation fault: 11` (exit 139), di spinel saja. CRuby cocok dengan snapshot.
  - lldb (build `--debug`): crash di `sp_str_include + 36`, `lr` = `_proc_1 + 692 at base.rb:21:293` (`value.include?("\0")`), `x0 = 0x6aba38b7` = 1790589111 = epoch `created_at`.
  - Mencetak `value.class` per elemen: `bind 2: String` untuk `created_at`, padahal C `insert_binds` mem-push `sp_box_int_or_nil(self->iv_created_at)`.
  - Mengganti `binds.each` dengan loop indeks tidak mengubah apa pun.
- Reduksi (delta-debug di atas app blog):
  | Varian | Hasil |
  |---|---|
  | `Testing::Client#post` | crash |
  | `Dispatcher#call` | crash |
  | `routes[1].endpoint.call` | crash |
  | `PostsController.add(...)` langsung | lulus |
  | `save` di proc biasa dengan ctx untyped | lulus |
  | salinan rantai yang sama tanpa framework (/tmp) | lulus |
- Repro: repro/k015_endpoint_save_crash.rb (butuh app blog; cara pakai di header file). **Belum minimal**; isolasi dihentikan pada batas waktu yang disepakati pengguna.
- **Isolasi lanjutan (Rencana 6 Fase 1, 2026-09-29 14:48 WIB, spinel `1ba12fb74`)**: masih crash (exit 139) di bentuk kode lama (`d8de580` + file app dari `4f4d93b`). Syarat yang terbukti:
  1. endpoint dibuat dari **blok yang ditangkap lewat `&handler`** (`Kilau::Controller.post { |c, r| … }`). Literal `proc { … }` yang dioper ke `Endpoint.new` tidak crash, dan panggilan `PostsController.add` langsung juga tidak;
  2. di dalam blok, `Post.new` + `post.save(c)`, dengan `c` = pool (argumen proc untyped). `Testing::Client`, `Dispatcher`, `AppContext`, dan route table **tidak** dibutuhkan;
  3. **kode mati** harus ikut di-compile: `model/migration` + `model/migrator` + `migration/migrator.rb` app (Migrator tidak pernah dibuat, dan `@conn` di dalamnya untyped; ia memanggil `@conn.execute(sql, [migration.version])` dan `@conn.query(...)`) serta `http/request` (yang punya `Request#query(name)`, bernama sama dengan `Connection#query`). Tanpa salah satunya, crash hilang;
  4. lapisan lain framework (server, parser, Config, Format, Routes, Dispatcher, Testing, CLI) dan kode app lain tidak dibutuhkan.
- **Repro minimal (2026-09-29 17:44 WIB)**: **repro/k015_user_each_misreads_array_element.rb** (Ruby murni, tanpa SQLite atau Kilau, dengan trace). CRuby mencetak `bind: Integer`, `bind: NilClass`, lalu 303. Spinel `38dc57dd`/`1ba12fb74` mencetak **`bind: String`** untuk elemen Integer, lalu `String#include?` segfault (exit 139).
- **Syarat** (masing-masing dibuktikan dengan menghapusnya di versi rapi):
  1. ada kelas buatan pengguna dengan method **`each` yang `yield`** (`Errors#each`, tidak pernah dipanggil; `yield 1` sudah cukup). Kalau di-rename atau tanpa `yield`, tidak crash. Dugaan: `binds.each { … }` pada receiver untyped di-dispatch poly dan ikut mempertimbangkan `each` buatan pengguna (sekeluarga dengan K-013);
  2. method mati mengoper Array berisi String ke `execute` yang sama (`Migrator#migrate` pada `@conn` untyped), plus kelas `Migration#version` yang mengembalikan String;
  3. jalur hidup berjalan di dalam blok yang ditangkap lewat `&handler`, disimpan di ivar, dan dipanggil lewat method (`Endpoint#call`). Literal `proc`, atau `save` langsung, tidak crash.
- Tidak dibutuhkan: SQLite/FFI, `Thread::Queue`, `Pool#with`, loop bind, dan String di binds (cukup `[Integer, nil]`).
- Jalan reduksi (Rencana 6 Fase 1): per file (724 baris) → per method dengan checkpoint (496) → SQLite diganti stub Ruby murni (411) → per baris (172) → pemangkasan kumulatif dan repro bersih.
- Klasifikasi: bug-compiler/runtime (pembacaan elemen array poly salah tag), serius (crash)
- Solusi yang dipakai: binder bertipe `Kilau::DB::Binds` menggantikan array binds campuran (D-019). Tidak ada lagi `PolyArray` di jalur SQL.
- Biaya: perubahan API `execute/query/insert(sql, binds)` di Rencana 1 (binds kini `Binds`, bukan Array). Sekaligus menghapus pelebaran K-005.
- Upstream: **diperbaiki** (matz/spinel#6008)
- **Perbaikan (Rencana 6 Fase 2, 2026-09-30):** `Pool#insert` hanya dijangkau lewat receiver yang tidak diikat call site bertipe, jadi parameternya `UNKNOWN` selama fixpoint dan baru dilebarkan ke `POLY` oleh backstop "never bound" (`src/analyze.c`) sesudahnya; pengikatan parameter tidak dijalankan ulang, sehingga `Connection#execute`'s `binds` hanya diberi tipe oleh call site mati `[migration.version]` → `StrArray`. Saat jalan, `sp_poly_as_str_array` membaca tiap elemen sebagai `v.s` tanpa cek tag → Integer jadi pointer string → segfault. (`Errors#each` hanya menentukan apakah literal mati bertipe `StrArray` atau `PolyArray`.) Backstop kini dua tahap: (1) lebarkan parameter method yang bisa dijangkau panggilan (self implisit, receiver kelasnya/turunannya, atau receiver poly/belum ditentukan) lalu ikat ulang parameter sampai stabil; (2) baru lebarkan parameter method yang tak dipanggil siapa pun. Versi pertama (ikat ulang setelah melebarkan semua) gagal `infer-test` #4889 di CI fork dan diperbaiki. Tes `test/widened_param_reaches_its_callee.rb` segfault sebelum, hijau sesudah; CI penuh hijau di PR fork; C benchmark identik. Commit `592036080`, **PR https://github.com/matz/spinel/pull/6027**, **di-merge oleh matz 2026-09-30 03:26 WIB** (`5fb976da3`). CodeRabbit: satu temuan (`is_descendant` untuk kelas yang sama) tidak valid, dibalas.
- **Workaround tidak lagi wajib (2026-09-30, compiler `35ddccadb`):** repro sama dengan CRuby. `Kilau::DB::Binds` **dipertahankan** karena desain (D-019): builder bertipe menjaga bind tetap sempit, sedangkan array campuran selalu `Array[untyped]` (K-005) dan lewat jalur boxed.

## K-016: `Pool#query_first` mengembalikan `nil` saat dipanggil dari handler; penugasan dari blok bersarang hilang
- Lapisan: db
- Pola yang dicoba: `found = nil; with { |conn| conn.query(sql, binds) { |row| found = yield(row) unless taken ... } }; found`, dipanggil dari `PostsController.load_item` (parameter untyped, K-012) lewat dispatch poly
- Yang terjadi (2026-09-28 ~17:03 WIB, framework dengan `Binds`):
  - Tes blog `GET /posts/1` setelah create → 404 di spinel. CRuby 200.
  - Instrumentasi di `load_item` (program tes yang sama):
    ```
    id=1 class=Integer kind=1 int_at=1
    sql=SELECT id, title, content, created_at, updated_at FROM posts WHERE id = ? LIMIT 1
    post=nil
    ```
  - Pada konfigurasi yang sama: `query_all(...)` → `size=1`, `query_first(...)` → `nil`.
  - **Sensitif terhadap seluruh program:** menambahkan satu pemanggilan bertipe `Post.find_by_id(db, 1)` di mana pun dalam program membuat `query_first` benar lagi.
  - Repro mandiri dengan pola yang sama (/tmp, blok bersarang + `yield` + receiver untyped) lulus.
- Repro: **repro/k016_nested_block_assignment.rb** (37 baris Ruby murni, tanpa SQLite atau Kilau; 2026-09-29 14:42 WIB). CRuby mencetak 200, spinel `38dc57dd` dan `1ba12fb74` mencetak 404.
- **Syarat minimal** (masing-masing dibuktikan dengan menghapusnya; tanpa syarat itu spinel juga mencetak 200):
  1. penugasan `found = yield(row)` berada **dua tingkat blok** di dalam (`with { query { … } }`); satu tingkat benar;
  2. argumen blok luar **berasal dari koleksi** (`@idle.pop`, Array atau `Thread::Queue`); objek dari ivar benar; `begin/ensure` tidak berpengaruh;
  3. `query_first` dipanggil pada **parameter proc** (receiver untyped), dan proc itu **disimpan di ivar lalu dipanggil dari method** (`Endpoint#call`); proc yang dipanggil dari variabel lokal benar.
- Jalan reduksi (Rencana 6 Fase 1): program blog (1.661 baris setelah di-flatten) → tanpa server/CLI/migrasi/POST (1.241) → bisection per lapisan (Client, Dispatcher, dan controller tidak dibutuhkan; proc tersimpan wajib) → framework DB + `Endpoint` saja → sintetis tanpa SQLite → 37 baris.
- Temuan sampingan: di program blog, proc `{ |c, r| c.db.query_first(…) { |row| row.int(0) }.nil? ? 404 : 200 }` membuat spinel menolak `src/controllers/posts.rb:53` dengan `unsupported condition (non-bool)`. Ini sekeluarga dengan K-007/K-014, dan belum diisolasi.
- **Mekanisme (Rencana 6 Fase 2, 2026-09-30 ~01:00 WIB, dibuktikan dengan instrumentasi):** tipe nilai `yield` dihitung `yield_value_type` (`src/analyze_util.c`) dari blok di tiap call site yang di-resolve `yvt_callee_index`, yang hanya me-resolve receiver bertipe objek. Satu-satunya pemanggil `query_first` adalah parameter proc (receiver `poly`, efek K-012), jadi call site dilewati dan nilai yield tetap `UNKNOWN`. `found` lalu bertipe dari penulisan lainnya saja (`nil`), return method `nil`, dan fungsi C di-emit `void` sehingga nilai `found` dibuang. Codegen tetap mengirim panggilan ke `sp_Pool_query_first` lewat `switch (cls_id)` dan membaca nilai yield sebagai poly.
- **Koreksi syarat:** blok bersarang dua level **tidak** diperlukan. Yang menentukan: receiver poly, dan tidak ada jalur lain yang memberi tipe ke lokal itu. `conn = @idle.last` menyembunyikan bug (panggilan bertipe `conn.query` memberi `found` tipe poly lewat jalur lain); `@idle.pop` memunculkannya.
- **Perbaikan:** `yield_value_type` mencatat call site yang dilewati bila receiver-nya poly dan namanya sama dengan method instance itu; bila tidak ada call site ter-resolve yang memberi tipe, nilai yield = poly. Tes `test/yield_value_through_poly_receiver.rb` merah sebelum (`nil`/`true`/`nil`), hijau sesudah, lulus di bawah `SPINEL_GC_STRESS=1`. `make check` RC=0 (4.741 pass; 25 timeout dalam satu jendela 90 dtk, lulus saat diulang). C yang di-emit untuk 62 benchmark + optcarrot identik (optcarrot 1128 fps). Commit `76c9df044`, **PR https://github.com/matz/spinel/pull/6008** (dibuka 2026-09-30), **di-merge oleh matz 2026-09-30 02:21 WIB** (`fe642d488`). CodeRabbit memberi 2 temuan: (1) mode `g_yvt_unify_all` mengabaikan call site poly bila ada call site bertipe; tidak bisa direproduksi dengan tiga bentuk (yield biasa, akumulator `out << yield`, `blk.call`), dibalas tanpa perubahan kode; (2) alias yang dipanggil lewat receiver poly; ternyata bug terpisah yang sudah ada sebelumnya, dicatat sebagai K-019.
- Klasifikasi: bug-compiler (tipe nilai `yield` saat semua pemanggil lewat receiver poly)
- Solusi yang dipakai: `query_first` mengumpulkan ke array (`found << yield(row) if found.empty?`, lalu `found.first`), pola yang sama dengan `query_all` yang terbukti benar
- Biaya: nol
- Upstream: **diperbaiki** (matz/spinel#6008, di-merge 2026-09-30 02:21 WIB).
- **Workaround dicabut (2026-09-30, compiler `35ddccadb`):** `Pool#query_first` kembali `found = yield(row)` di blok bersarang; suite hijau termasuk tes blog `show escapes the title` yang dulu memicu K-016.

## K-017: satu `elsif <panggilan> == 0` + `raise` di `Model#save` merusak jalur insert di cabang lain
- Lapisan: model
- Pola yang dicoba (perbaikan temuan review Rencana 2 #1): `elsif db.execute(update_sql, update_binds) == 0; raise Kilau::Error::NotFound, "row #{id} no longer exists"; end`
- Yang terjadi:
  - framework/test/model_test.rb di spinel gagal pada save valid **pertama** (cabang insert, bukan update) dengan `nil given to int; use int_or_nil for a nullable column (Kilau::DB::Error)`. Timestamp yang baru diisi `touch` terbaca nil oleh `Binds#int`.
  - CRuby lulus.
  - Ditulis ulang sebagai `else; changed = db.execute(...); raise ... if changed.to_i == 0; end` → lulus di kedua engine.
- Repro: **repro/k017_elsif_argument_evaluated_early.rb** (Ruby murni, dengan trace; 2026-09-29 14:55 WIB).
- **Mekanisme, terbukti dengan trace** (spinel `38dc57dd` dan `1ba12fb74`): argumen pemanggilan di kondisi `elsif` (`db.execute("update", update_binds)`) **dievaluasi sebelum cabang `if` dijalankan**, meskipun cabang `if` yang diambil. `update_binds` → `.int(@id)` dengan `@id` masih nil → `nil given to int`. CRuby tidak pernah memanggil `update_binds` di jalur insert. Jadi yang dulu dibaca sebagai "timestamp nil" sebenarnya `@id` yang nil.
- **Syarat** (masing-masing dibuktikan dengan menghapusnya):
  1. cabang kedua berbentuk `elsif <recv>.<call>(<arg>)`. Bentuk `else; x = <recv>.<call>(<arg>); end` benar, dan tanpa cabang kedua juga benar;
  2. argumennya (`update_binds`) memanggil method yang dipakai cabang `if` (`insert_binds`). Argumen yang dibangun sendiri benar.
- Tidak dibutuhkan: superclass atau modul, `== 0`, `raise` di cabang, dan kode lain di framework. `elsif check(arg)` polos di method top level dievaluasi benar, jadi bentuk pastinya masih lebih sempit dari "setiap argumen `elsif`".
- **Perbaikan (Rencana 6 Fase 2, 2026-09-29 17:11 WIB)**: di spinel, `emit_if` (`src/codegen_stmt.c`) kini menangkap prelude predikat `elsif` dan meng-emit-nya di dalam blok `else` milik `elsif` itu, sama seperti yang sudah dilakukan emitter lengan `case`/ternary. Tes baru `test/elsif_condition_args_wait_for_their_branch.rb` (+ snapshot CRuby) gagal sebelum dan lulus sesudah perbaikan. `make check`: 4.597 pass, 0 fail, `alloc-report-test`, `infer-test`, dan `spin-e2e` hijau. Commit `05a5ebef6` di branch `elsif-condition-args-in-branch` (fork `yosefbennywidyo/spinel`). **PR upstream: https://github.com/matz/spinel/pull/5789** (dibuka 2026-09-29), **di-merge oleh matz 2026-09-29 17:49 WIB** (merge commit `dca09ca13`). CI hijau (gcc, clang, macOS, wasm32-wasi); CodeRabbit tanpa temuan (cek Docstring Coverage "inconclusive" diabaikan, repo tidak memakai docstring).
- Reduksi (Rencana 6 Fase 1): program tes (framework penuh) → reduksi per file (cukup DB + model + entity) → repro sintetis 50 baris → pemangkasan kumulatif (37) → tanpa superclass (33) + trace.
- Klasifikasi: bug-compiler (sensitivitas inferensi seluruh program; sekeluarga dengan K-015/K-016)
- **Verifikasi (2026-09-29 23:10 WIB)**: dengan spinel `6626c0f05` (berisi `dca09ca13`), `repro/k017_elsif_argument_evaluated_early.rb` keluar 0 dengan output sama persis dengan CRuby; `1ba12fb74` masih `nil given to int`. Suite Kilau hijau (14/14, 8/8, 4/4, CRuby 26/26).
- Solusi yang dipakai: dulu bentuk `else` + variabel + `to_i`. Sejak 2026-09-29 23:20 WIB `Model#save` kembali ke bentuk `elsif … == 0` (butuh spinel ≥ `dca09ca13`); suite 14/14, 8/8, 4/4, CRuby 26/26.
- Biaya: nol
- Upstream: **diperbaiki** (matz/spinel#5789) -- **REGRESI ditemukan ulang 2026-10-12
  ~17:50 WIB, lalu diperbaiki ulang dan di-merge 2026-10-12 ~21:37 WIB
  (matz/spinel#8679)**. Lihat blok di bawah untuk kronologi lengkap, termasuk
  koreksi diagnosis awal yang salah arah.

**Regresi, 2026-10-12 ~17:50 WIB** (spinel master `46a9efb16`, 73 commit di depan `9c2582011`,
jauh setelah `dca09ca13`): `repro/k017_elsif_argument_evaluated_early.rb` kembali gagal
dengan persis bug ASLI yang dijelaskan di komentar file itu sendiri (`update_binds
called` lalu `nil given to int`), bukan output CRuby. Test resmi `#5789`
(`test/elsif_condition_args_wait_for_their_branch.rb`) tetap LULUS tanpa perubahan di
spinel master yang sama, jadi fix `05a5ebef6` sendiri tidak di-revert.

**Diagnosis awal (salah arah, dikoreksi di bawah)**: dikira bentuk `elsif` DUA ARGUMEN
(`db.execute("update", update_binds)`, literal string + panggilan method) adalah
pemicunya, karena reduksi argumen tunggal (`elsif update_binds`) sempat lolos benar.
Repro minimal pertama disimpan sebagai **repro/k017b_elsif_two_arg_call_evaluated_early.rb**.

**Akar masalah sesungguhnya (ditemukan 2026-10-12 ~19:00-20:30 WIB, lewat instrumentasi
debug sementara di `nullable_int_value`/`src/analyze.c`)**: bukan soal jumlah argumen
`elsif` sama sekali -- bentuk dua-argumen itu cuma kebetulan cocok dengan bentuk repro
asli. Bug sesungguhnya: **bare self-call ke method `attr_reader`** (`id.nil?` tanpa
`self.`) tidak mewarisi fakta nullability ivar-nya dengan benar, saat ivar yang
sama di-assign nilai konkret non-nil di CABANG YANG SAMA (`self.id = db.insert(...)`).
`if self.id.nil?` (receiver eksplisit, method sama) selalu menjawab benar --
`nullable_int_value`'s cabang `CallNode` punya dua jalur: untuk receiver eksplisit,
re-derive langsung dari `ivar_nullable_int[iv]`; untuk bare self-call, hanya percaya
`scope.ret_nullable_int` milik method `id` yang di-resolve -- dan method getter
sintetis (`def id = @id`) TIDAK PERNAH ditandai `ret_nullable_int` oleh fixpoint umum
begitu ada sibling-write yang menetapkan tipe ivar jadi Integer/Float konkret.
Direduksi ke 12 baris murni (tanpa kaitan sama sekali dengan `elsif`, cukup `if
id.nil? ... self.id = 99 ... end`), lalu diverifikasi 2 repro kilau cocok CRuby.
- **Bug kedua, ditemukan sendiri lewat gate run fork sebelum sampai PR**: fix pertama
  (menyamakan jalur re-derivasi untuk bare self-call) salah memukul rata ke member
  `Struct.new`/`Data.define` juga -- heuristik `ivar_assigned_in_initialize`
  (dipakai bersyarat untuk tipe Float) menjawab `false` untuk SETIAP member struct
  (karena constructor-nya sintetis, bukan `def initialize` literal), salah
  menandai method reader Float milik struct sebagai nullable (`sp_ofloat`) padahal
  codegen struct-nya sendiri mengembalikan `sp_float` biasa -- C type mismatch,
  ketahuan dari dua test korpus spinel (`issue_2872`, `struct_block_overrides_bracket`)
  gagal compile di gate run fork pertama. Diperbaiki dengan menambah pengecualian
  `is_struct`, lalu diverifikasi ulang: 58 file test (ivar/nullable/attr_reader +
  struct/Data) cocok CRuby, gate fork hijau 18/18.
- Repro minimal final: **test/bare_self_call_reader_nil_check_sibling_write.rb**
  (ditambahkan ke suite resmi spinel sendiri, bukan `repro/` kilau, karena ini
  murni bug compiler tanpa kaitan konteks kilau).
- **Upstream: diperbaiki, di-merge** -- **matz/spinel#8679** (judul: "A bare
  attr_reader self-call's nil check answers per call, not per method"), di-merge
  oleh matz 2026-10-12 ~21:37 WIB (merge commit `e07cb990e`), diverifikasi masuk
  `master` persis sesuai PR (`git diff <parent> <merge-commit>` = 3 file, 68 baris,
  cocok diff PR). Gate fork hijau 18/18 sebelum PR dibuka (`Gate: green tree
  5aeefa3cc744 master 31ccc270711c (linux-x86_64 gcc-13.3.0) tests 7113/0`).
  CI upstream (clang) pass 27m13s, CodeRabbit tanpa temuan. **Compiler Kilau belum
  dinaikkan ke versi yang berisi fix ini** -- langkah berikutnya.

## K-018: `spin test` memakai ulang binary tes lama setelah compiler di-upgrade
- Lapisan: tooling (`spin`)
- Yang terjadi: setelah `sudo make install` spinel `6626c0f05` (2026-09-29 23:08 WIB), `make test` melaporkan 26/26 lulus, tetapi **semua** tes bertanda `(cached)`. Binary tesnya dari 13:43, lebih tua dari compiler, jadi hasil hijau itu masih milik compiler lama.
- Mekanisme (`tools/spin.rb`, `spinel_bin`, di spinel `6626c0f05`): `spin` mencari compiler di `<dir dari $0>/spinel`. Kalau dipanggil lewat PATH (`spin test`), `$0` hanya `spin`, sehingga `File.expand_path` menunjuk ke direktori kerja. Kandidat itu tidak ada, dan fungsi mengembalikan nama polos `"spinel"`. `File.exist?("spinel")` false, sehingga mtime compiler dianggap 0 dan tidak pernah membuat cache basi (batas kesegaran #3202).
- Bukti: `cd framework && /usr/local/bin/spin test` → 0 `(cached)`, 14 tes dikompilasi ulang.
- Solusi yang dipakai: `Makefile` Kilau memakai `SPIN ?= $(shell command -v spin)` (path absolut).
- Klasifikasi: bug-tooling
- Upstream: **PR https://github.com/matz/spinel/pull/5983 di-merge oleh matz 2026-09-30 00:23 WIB** (merge commit `c5898078e`; dibuka ~00:20 WIB, commit `265ed2fea`, branch `spin-compiler-mtime-through-path`). `spinel_bin` sekarang mencari `$0` polos lewat PATH (fungsi `which` di `spin.rb`) sebelum `expand_path`. Tes baru di `tools/spin_e2e.sh` gagal sebelum dan lulus sesudah perbaikan. `make check`: semua leg lulus; corpus 4.647 pass, 1 fail (`hash_store_operand_gc_root`, timeout 10 dtk saat run paralel, lulus 5/5 bila dijalankan sendiri).
- Tindak lanjut: CodeRabbit menemukan bahwa `which` melewati komponen PATH kosong (`:` di awal/akhir, `::`), padahal shell membacanya sebagai direktori kerja. Sejak #5983, `spinel_bin` bisa memakai compiler di sebelah `spin` lain yang lebih belakang di PATH. Perbaikan (`split(":", -1)`, komponen kosong → `.`) + tes e2e dengan `spin` decoy yang compiler-nya selalu gagal (merah sebelum, hijau sesudah): **PR https://github.com/matz/spinel/pull/5997 di-merge oleh matz 2026-09-30 01:24 WIB** (commit `4fafd9ba4`; CI hijau, CodeRabbit tanpa temuan). Hanya `spin-check` yang dijalankan (tidak ada perubahan di `src/`/`lib/`).
- **Uji ulang 2026-10-07 ~11:12 WIB** (spinel `ae2c38c71`): `spin test` dengan path absolut dan dengan nama polos lewat PATH sama-sama membangun ulang setelah `bin/spinel` disentuh. Diuji dengan proyek spin kecil di scratch. Diperbaiki.


## K-019: value object yang di-`yield` ke blok berbentuk proc gagal dikompilasi (awalnya dikira soal alias)
- Lapisan: compiler (codegen alias + yield)
- Yang terjadi: `alias find first_match`, dengan `first_match` yang `yield` di dalam `with { |conn| conn.query { |row| found = yield(row) } }`, menghasilkan C tidak valid: `non-pointer operand type 'sp_Row' incompatible with NULL` / `operand of type 'sp_Row' where arithmetic or pointer type is required` di baris alias dan di `yield` terdalam. CRuby mencetak 7.
- Repro: **repro/k019_alias_of_nested_yield_method.rb** (2026-09-30).
- Diuji di spinel `6626c0f05` (terpasang) dan `76c9df044` (`master` + #6008): gagal di keduanya. Memanggil lewat nama asli (`first_match`) benar. Receiver bertipe maupun poly sama-sama gagal.
- Tidak memicu (alias benar): `yield` langsung, `yield` di dalam satu blok `each`, alias dipanggil berdampingan dengan nama aslinya. Jadi syaratnya lebih sempit; belum direduksi lebih jauh.
- Ditemukan saat menanggapi CodeRabbit di matz/spinel#6008.
- Klasifikasi: bug-compiler
- Solusi yang dipakai: tidak ada (Kilau tidak memakai alias seperti ini)
- Upstream: **diperbaiki** (matz/spinel#6028)
- **Koreksi & perbaikan (Rencana 6 Fase 2, 2026-09-30):** alias tidak berperan; memanggil `first_match` langsung gagal sama. Pemicu minimal: kelas kecil read-only (`Row`) dikompilasi sebagai *value object* (struct), lalu di-`yield` ke blok yang harus jadi proc sungguhan (blok menulis lokal luar dan receiver berasal dari Array). Tiga tempat memperlakukan struct sebagai pointer: (1) `emit_proc_call_args` mengecek `proc_slot_is_ptr` (benar untuk semua objek) sebelum cek by-value → cast `(sp_int)(uintptr_t)` struct, dan temp di-root sebagai pointer; (2) parameter blok tanpa argumen default `NULL`; (3) temp hasil `emit_poly_method_dispatch` diinisialisasi `NULL`. Helper baru `default_value_from_compiler` (nama usulan pengguna) memberi `(sp_X){0}` untuk value object, dipakai hanya di tiga tempat itu. Emitter (3) ditemukan dengan instrumentasi backtrace sementara di `buf_putn` setelah pencarian teks gagal. Tes `test/value_object_yielded_through_a_proc_block.rb` merah sebelum, hijau sesudah, GC stress lulus; CI penuh hijau di PR fork; C benchmark identik. Commit `58fc6b8e4`, **PR https://github.com/matz/spinel/pull/6028**, **di-merge oleh matz 2026-09-30 03:26 WIB** (`7304a08a2`). CodeRabbit: `SP_GC_ROOT` vs `SP_GC_ROOT_STR` untuk field String; tidak valid (`_SP_GC_SLOT_TAG` memilih tag dari tipe C slot), dibalas.

## K-020: nilai `next` di blok diabaikan saat mengetik panggilan method yang `yield`
- Lapisan: compiler (inferensi tipe + codegen blok inline)
- Ditemukan: 2026-09-30, saat menanggapi temuan CodeRabbit di PR K-007 (`next true` sebelum tail yang tak ter-resolve).
- Yang terjadi (`def run = yield`):
  - `p run { next true if 1 == 1; nil }` → Spinel mencetak **`nil`**, CRuby `true` (**nilai salah diam-diam**: `p` di-fold ke "nil").
  - `run { next true if c; "str" }` / `run { next 5 if c; "tail" }` → C gagal (`const char *` ← `sp_RbVal`).
  - `run { next 5 if c; obj.missing }` → C gagal (`sp_int` ← `sp_RbVal`).
- Mekanisme: `method_call_ret` (`analyze_util.c`) mengetik panggilan method yield-tailed dari **tail blok saja**, sedangkan `yield_value_type` sudah menggabungkan `block_next_value_ty`. Setelah diperbaiki, tail berupa panggilan tak bertipe masih ditugaskan ke slot bertipe nilai `next`.
- Perbaikan: `method_call_ret` menggabungkan tipe `next` dengan tail (void → nil); inliner blok (`codegen_iter.c`) menjalankan tail panggilan tak bertipe sebagai `(void)(...)` (ia melempar, atau placeholder nil, dan slot sudah nil). Tes `test/next_value_types_a_yield_call.rb` merah sebelum, hijau sesudah, GC stress lulus, CI fork hijau, C benchmark identik. Review CodeRabbit di fork terlewat karena kuota. Commit `f3d38f439`, **PR https://github.com/matz/spinel/pull/6092**.
- Klasifikasi: bug-compiler (nilai salah diam-diam + C gagal)
- Solusi yang dipakai: tidak perlu di Kilau (pola ini tidak dipakai)
- Upstream: **matz/spinel#6092 merged** (2026-09-30 06:53 WIB)
- **Uji ulang 2026-10-07 ~11:12 WIB** (spinel `ae2c38c71`): repro tiga kasus (`next true`, `next 5`) sama dengan CRuby (`true`, `true`, `5`). Diperbaiki.


## K-021: method `module_function` yang `yield` + `rescue`, dipanggil tanpa receiver setelah `include` top level dengan blok yang selalu raise, menghasilkan C tidak valid
- Lapisan: compiler (inline method modul via top-level include, jalur baru dari matz/spinel#6029)
- Ditemukan: 2026-09-30 saat mencabut workaround K-004.
- Yang terjadi: `include T; check("x") { raises? { raise DbErr, "boom" } }` dengan `raises?` = `yield; false; rescue DbErr; true` → `invalid argument type 'void' to unary expression` di `unless yield` milik `check`. CRuby: `ok x`.
- Tidak memicu: lewat modul (`T.check { T.raises? { raise … } }`), `raises?` tanpa receiver dengan blok yang tidak raise, `check` tanpa receiver dengan blok biasa.
- Repro: **repro/k021_include_rescue_yield_raising_block.rb**
- Klasifikasi: bug-compiler
- Solusi yang dipakai: tes Kilau memanggil `Kilau::Testing.raises_db_error?` lewat modul untuk bentuk ini; **dicabut** 2026-09-30 14:29 WIB (compiler `ea9feecfe`). Compiler terpasang lama `35ddccadb` gagal dengan error K-021 yang sama pada tes tanpa workaround, dan compiler baru lulus.
- Mekanisme (2026-09-30): dua tempat di spinel tidak me-resolve pemanggilan tanpa receiver ke modul yang di-`include` di top level, padahal inliner (#6029) melakukannya. (1) Codegen `call_targets_yielding_method` menganggap ekor blok bukan pemanggilan yang di-inline → bentuk statement → blok bernilai `void`. (2) Analyzer `yvt_callee_index` tidak mencocokkan blok call site ke `yield` method itu → nilai yang dipakai (`n = twice { 2 }`) bertipe nil; sebelumnya gagal link, sesudah perbaikan (1) saja jadi `nil` diam-diam. Keduanya kini jatuh ke `comp_included_method_index`.
- Upstream: **matz/spinel#6151 merged** (2026-09-30), commit `c6cff7c76`; tes `test/toplevel_include_yield_value_tail.rb`. C benchmark + optcarrot identik.

## K-022: method yang `yield` dengan blok bertipe berbeda di call site berbeda menghasilkan C tidak valid
- Lapisan: compiler (tipe nilai yield / inline per call site)
- Ditemukan: 2026-09-30 09:25 WIB saat memperbaiki K-021.
- Yang terjadi: `def twice = yield + yield`; `twice { "a" }` lalu `twice { 1.5 }` → `assigning to 'const char *' from incompatible type 'sp_float'` di `yield + yield`. CRuby: `"aa"`, `3.0`. Sama untuk fungsi top level, `T.twice` lewat modul, dan pemanggilan tanpa receiver setelah `include`; sudah ada sebelum perbaikan K-021.
- Repro: **repro/k022_yield_blocks_of_different_types.rb**
- Klasifikasi: bug-compiler
- Solusi yang dipakai: tidak dibutuhkan Kilau saat ini
- Mekanisme (2026-09-30): `infer_uncached` sudah mengetik `yield` sebagai poly bila nilai blok berbeda antar call site dan nilainya mengalir ke local/ivar/gvar/cvar, elemen array, atau frame rescue/ensure. Posisi argumen dan receiver pemanggilan tidak tercakup, sehingga `yield` mengambil tipe site pertama. Varian lain yang juga kena: `show(yield)` (argumen ke method pengguna) terkompilasi tapi `TypeError` saat runtime.
- Upstream: **matz/spinel#6185** (dibuka 2026-09-30) memperbaiki posisi argumen ke method pengguna (**merged**, commit `98c36b87a` setelah saran CodeRabbit: aturan argumen sadar-receiver; CI korpus penuh 2.453 + 2.453 / 4.906, 0 fail). **Sisa:** `yield + yield` / `yield * 2` (operator builtin) masih gagal compile; analyzer bisa dibuat poly, tapi codegen menurunkan operator per site ke bentuk konkret lalu memasukkannya ke slot poly tanpa box. Kandidat PR terpisah. **Perbaikan penuh 2026-09-30:** **matz/spinel#6219 merged** (2026-09-30 17:22 WIB, di `fff8bdd49`, termasuk perbaikan String `%` dan promote `/ %` dari review CodeRabbit; CI 2.463 + 2.463 / 4.926, 0 fail). Temuan ketiga CodeRabbit (String `+`/`*` dengan argumen yang dikonversi atau ditolak, mis. `yield * 2.0`, `yield + 1`) masuk setelah merge, jadi dibawa oleh **matz/spinel#6226** (commit `74e458ca7`, terbuka): analyzer mengetik `yield` poly bila menjadi receiver operator aritmetika builtin (`+ - * / %`, satu argumen), dan `sp_yield_site_type` menjawab tipe per site operator itu (String+String, String*Integer → String; Float/Integer campuran → Float; Integer+Integer → Integer kecuali mode promote), sehingga nilainya di-box ke slot poly. C benchmark + optcarrot identik; 675 tes korpus terkait lulus.


## K-023: pemanggilan tanpa receiver di subclass `BasicObject` ter-resolve ke method modul yang di-`include` di top level
- Lapisan: compiler (resolusi pemanggilan tanpa receiver)
- Ditemukan: 2026-09-30 09:36 WIB, diangkat CodeRabbit di yosefbennywidyo/spinel#7 (perbaikan K-021), diverifikasi di spinel `8fec82476` tanpa perbaikan K-021.
- Yang terjadi: `include T` di top level menambahkan T ke `Object`, yang tidak diwarisi subclass `BasicObject`. CRuby: `hello()` dan `twice { … }` di dalam `B < BasicObject` → `NoMethodError`. Spinel: `hello()` → `"hi"`, `twice` di-inline dan berjalan.
- Mekanisme: semua resolver pemanggilan tanpa receiver (`infer_uncached`, cabang top-level-include `emit_call`, `emit_inline_call_x`, dan sejak perbaikan K-021 juga `yvt_callee_index` serta `call_targets_yielding_method`) memakai `comp_included_method_index` tanpa scope pemanggil.
- Arah perbaikan: beri `comp_included_method_index` scope pemanggil dan tolak bila kelas pemanggil turunan `BasicObject` tanpa `Object` di rantainya, supaya semua resolver berubah bersama; tes `BasicObject`.
- Repro: **repro/k023_basicobject_resolves_toplevel_include.rb**
- Catatan 2026-10-02: sejak #6162, spinel **menolak saat compile** `hello()` dan `twice { }` ("unsupported call" di baris 21/26), sesuai pesan commit-nya ("a call with parentheses, arguments or a block is refused at its line"). Jadi repro ini tidak lagi menghasilkan output CRuby (`NoMethodError` dua kali); penolakan itu perilaku yang dimaksud, bukan regresi.
- Klasifikasi: bug-compiler (program yang di CRuby raise malah berjalan)
- Solusi yang dipakai: tidak dibutuhkan Kilau (tidak memakai `BasicObject`)
- Perbaikan (2026-09-30): `comp_included_method_index` kini menerima node pemanggil dan tidak menjawab apa pun dari method instance (atau blok di dalamnya) milik kelas turunan `BasicObject`; semua 10 caller berubah bersama. Method kelas tetap menjangkau modul (self-nya `Class`). Hasil: `hello` tanpa kurung → `NameError` saat runtime (sama dengan CRuby); `hello()` / `twice { }` → ditolak di barisnya (perilaku Spinel untuk pemanggilan ke method yang tidak ada). `class_is_blank_slate` pindah ke `compiler.c`. C benchmark + optcarrot identik.
- Tindak lanjut: `def` top level juga masuk ke `Object`, dan subclass `BasicObject` masih menjangkaunya (`comp_method_index`, 69 caller); di luar cakupan PR ini.
- Upstream: **matz/spinel#6162 merged** (2026-09-30), commit `c07b5c8c4` (ikut mengubah pemanggil baru `an_call_targets_nonunique`). CI dengan korpus penuh: gcc 2.439 + 2.438, clang 4.877, 0 fail.

## K-024: method builtin pada receiver `yield` dengan blok bertipe berbeda: nilai salah diam-diam atau C tidak valid
- Lapisan: compiler (codegen per site untuk nilai `yield`)
- Ditemukan: 2026-09-30 saat memperbaiki sisa K-022 (operator).
- Yang terjadi (spinel `2f2f59763`): `def w = yield.abs` dengan blok `-3` lalu `-2.5` mencetak `3` dan **`2`** (CRuby: `2.5`), jadi nilai salah tanpa error. `def w = yield.first` dengan blok Array lalu String-chars gagal compile (`incompatible pointer to integer conversion`).
- Mekanisme: sama dengan K-022. Codegen menurunkan method per site dari tipe blok site itu (`sp_yield_site_type`), tapi slot nilai method bertipe dari site pertama. Perbaikan K-022 hanya mencakup operator aritmetika; method lain butuh tipe hasil per site yang lebih umum.
- Repro: **repro/k024_yield_receiver_builtin_method.rb** (diverifikasi di spinel `df5067a63`: CRuby `3 2.5 1 1`, Spinel `3 2 1 1`; bentuk `.first` di komentar file).
- Penunjuk kode (dari perbaikan K-022, #6219/#6226):
  - `src/compiler.h` `comp_ntype` memanggil hook `sp_yield_site_type_hook`: selama codegen, node `yield` bertipe blok site yang sedang disisipkan.
  - `src/codegen_util.c` `sp_yield_site_type` + `yield_operator_site_type`: hook itu kini juga menjawab tipe per site untuk operator `+ - * / %` dengan receiver `yield`.
  - `src/analyze_infer.c`, cabang `NK_YieldNode` di `infer_uncached` (di bawah `yield_value_diverges`): daftar posisi yang membuat `yield` poly (local/ivar/gvar/cvar, array, rescue/ensure, argumen method pengguna lewat `call_may_reach_user_method`, receiver operator aritmetika).
- Arah perbaikan: perluas pasangan analyzer + hook ke method builtin pada receiver `yield`. **Analyzer dan hook harus mencakup himpunan yang sama.** Melebarkan analyzer untuk semua method tanpa hook membuat `yield.abs` berubah dari nilai salah menjadi C gagal (sudah dicoba saat K-022). Hook perlu tahu tipe hasil per site untuk method builtin; dengan tabel kecil untuk method skalar yang umum (`abs`, `size`, `length`, `to_s`, `first`, `last`), atau dengan sumber tipe return builtin yang sudah dipakai analyzer. Aturan tipe harus mengikuti apa yang dikeluarkan emitter, bukan pasangan tipe yang sah di Ruby (pelajaran #6219, lihat skill spinel-notes). Uji di mode default **dan** promote lewat `make`, termasuk semua `promote_*`.
- Klasifikasi: bug-compiler (**nilai salah** untuk `abs`)
- Solusi yang dipakai: tidak dibutuhkan Kilau saat ini
- Upstream (diperbarui 2026-10-02 ~07:05 WIB):
  - **Bagian 1** (`abs`, `-@`): **matz/spinel#7024 merged** (2026-10-01 23:49Z, merge commit `5360dc76c`). Menyusul `d3cd772e0` setelah temuan CodeRabbit: `-@` dengan site String (Int+String sebelumnya C gagal).
  - **Bagian 2** (K-024b, branch spinel `k024b-yield-receiver-element-self`, commit `1b697faaa` + `a4fef1b72` setelah rebase ke merge #7024, PR upstream **matz/spinel#7063**, **di-merge 2026-10-02 09:33 WIB** (`8d17c7db6`; fork #13 ditutup)): tabel bersama `ty_recv_builtin_result` di `src/types.c`, dibaca analyzer (`yield_recv_builtin_every_site`, arm YU_RECEIVER + `infer_call`) dan hook codegen (`yield_builtin_method_site_type`). Dua kelas aturan: pembaca elemen (`first last min max pop shift [i]`) → elemen array; salinan/urutan ulang (`itself dup clone freeze sort reverse uniq compact to_a`, plus `abs magnitude -@` untuk Int/Float) → jenis receiver. Mengikuti rantai (`yield.sort.reverse.last`). Analyzer hanya melebarkan bila **semua** site terjawab tabel. Pelajaran: hook per site hanya boleh menjawab bila analyzer mengetik call itu poly. Kalau tidak, nilai site lain dibuang jadi nil oleh arm raise-tail.
  - Matriks probe sebelum fix: ~20 method rusak (C gagal compile, atau nilai salah diam-diam untuk Int vs Float: `first`, `min`, `max`, `pop`, `shift`, `[0]`, `itself`, `magnitude`).
- **Di luar cakupan bagian 2, dan alasannya** (ground truth `--emit-types`, 2026-10-02):
  - `sum`: `IntArray#sum` = `int` di mode raise tapi `poly` di promote (bisa jadi Bignum). Jadi tipenya ditentukan mode, bukan receiver. `StrArray#sum` di CRuby raise `TypeError` (`String can't be coerced into Integer`), dan emitter lewat jalur boxed `sp_RbVal`. Butuh aturan bergerbang mode plus arm raise, jebakan yang sama dengan #6219.
  - `succ`: `Integer#succ` = `int` di raise, `poly` di promote (overflow ke Bignum, setara `+ 1`). `String#succ` = `string`. Bisa ditambah dengan gerbang `g_promote_mode` seperti `yield_operator_site_type`, tapi belum diverifikasi. (Hanya bila ada reopen pada rantai, `succ` dan nama lain di luar tabel kini terjawab per site oleh #7158; lihat K-025.)
  - `dig`: hasilnya bergantung jumlah indeks (kedalaman), dan di promote bahkan `IntArray#dig(0)` = `poly`. Bukan aturan "ikut receiver".
  - Issue terkait tapi berbeda posisi: matz/spinel#7010 (yield divergen di ABI proc, `next []`, nilai blok ke method user, inline `super`). Programnya tetap gagal dengan 4 error yang sama dengan K-024b; tidak diperbaiki dan tidak diperburuk.
- **Catatan untuk refactor umum** (diputuskan user 2026-10-02: belum dikerjakan): tabel ini tetap daftar tangan. Solusi menyeluruh adalah memisahkan logika "tipe hasil builtin untuk receiver bertipe `rt`" dari `infer_call` (`src/analyze_infer.c`, kira-kira baris 1650 sampai 6400, tersebar di `infer_array_call`, `infer_numeric_call`, `infer_hash_call`, `infer_poly_call` dan arm inline) menjadi fungsi murni tanpa tulis cache. Dengan begitu hook codegen bisa memanggilnya dengan `rt` per site dan semua method tertutup sekaligus. Hambatannya: fungsi-fungsi itu menerima `Compiler *` non-const, membaca `infer_type` (yang mengisi cache), dan menghitung `rt` dari node receiver di dalam fungsi. Risiko regresinya besar, jadi layak didiskusikan dulu dengan Matz (issue), bukan langsung PR. Perkembangan 2026-10-02: #7158 memakai *face re-inference* (`an_set_face_node` + `infer_call`, mekanisme dispatch receiver poly) sebagai sumber tipe per site, tapi hanya bila ada reopen pada rantai; arah upstream yang lebih luas ada di matz/spinel#7033 (tabel builtin) dan #7100 (`CallPlan`).

## K-025: method builtin yang dibuka ulang di Array/Hash diabaikan; reopen scalar lewat `yield` gagal compile
- Lapisan: compiler (dispatch reopen kelas builtin)
- Ditemukan: 2026-10-02 saat memverifikasi temuan CodeRabbit di matz/spinel#7063.
- Yang terjadi (master `7ba5b1e10`): `class Array; def first = "arr-first"; end` lalu `[1, 2].first` mencetak `1` (CRuby `"arr-first"`). Hal yang sama berlaku untuk `sort`/`last` Array dan `size` Hash. `def w = yield.abs` dengan `Integer#abs` dibuka ulang menjadi String, dengan blok Integer dan Float, gagal compile.
- Mekanisme: reopen scalar (Integer/String/Float/...) sudah memiliki nama builtin sejak `ce2d5c1c2`. Reopen Array/Hash hanya dicapai oleh dispatch di akhir `emit_call_body`, padahal nama builtin sudah lebih dulu diambil arm builtin. Analyzer juga mengetik call itu sebagai builtin. Hook `yield_builtin_method_site_type` (#7024) menjawab tipe builtin untuk site yang kelasnya dibuka ulang.
- Repro: **repro/k025_reopened_builtin_method.rb**
- Verifikasi asal-usul (build bersih): bug Array/Hash sudah ada sebelum #7024 (`28e34cee3`). Untuk reopen scalar lewat `yield`, #7024 mengubah nilai salah menjadi C gagal pada dua bentuk, dan tidak membuat kasus yang benar menjadi salah.
- Klasifikasi: bug-compiler (nilai salah diam-diam untuk Array/Hash)
- Solusi yang dipakai: tidak dibutuhkan Kilau saat ini
- Upstream: fix di branch spinel `k025-reopened-builtin-method` (`71895e74c`), PR upstream **matz/spinel#7078**, **di-merge 2026-10-02 09:33 WIB** (`b778f39e7`; fork #17 ditutup). Matz menyusulkan `f018966dc`: arm #7078 menambah 17 baris ke `emit_call_body` (melanggar aturan ukuran fungsi #7033) dan memanggil fungsi yang tidak dimiliki method yang yield, sehingga reopen yang yield tanpa blok gagal compile; arm dipindah ke helper.
- **K-025b** (ditemukan 2026-10-02 ~09:50 WIB, setelah #7063 dan #7078 sama-sama masuk master): aturan "tolak site Array/Hash" #7063 tersisa, sehingga `yield.first` dengan reopen `Hash#first` dan site Array gagal compile; site yang kind-nya tidak ada di tabel per site (`size` di semua kind, `first` di Hash) di samping site reopen juga gagal compile, dan `yield.succ` pada blok String menjalankan reopen `Integer#succ` (nilai salah).
  - Bagian 1 (hapus aturan tolak Array/Hash): **matz/spinel#7096 di-merge 2026-10-02 12:22 WIB** (`9d889fd26`).
  - Bagian 2 (site lain dijawab builtin-nya sendiri lewat `an_yield_site_builtin_answer`, face re-inference, hanya bila ada reopen pada rantai): **matz/spinel#7158** (dibuka 2026-10-02 13:10 WIB, terbuka). Gate sharded di fork: https://github.com/yosefbennywidyo/spinel/actions/runs/36971021776 (corpus 5.583, rubyspec 2.446, bench 64, optcarrot 59662; C optcarrot dan 64 benchmark identik).
  - Batas yang diketahui: `yield.include?(v)` dengan `v` argumen poly masih menjalankan reopen Array di site String (sama seperti master).

## K-025c: `yield.include?(poly_arg)` dengan `Array#include?` dibuka ulang gagal compile C (lanjutan batas K-025b)
- Lapisan: compiler (codegen per site untuk nilai `yield`, sama keluarga dengan K-024/K-025b)
- Ditemukan: 2026-10-09, saat memeriksa batas "diketahui" yang dicatat K-025b.
- Yang terjadi (spinel master `961718cc9`): `class Array; def include?(v) = "reopened-array"; end`, lalu method `w(arg) = yield.include?(arg)` dengan satu call site `w(arg) { "abcxdef" }` (site `yield` selalu `String`) dan `arg` poly (dibaca dari array campuran) → **gagal compile C**: `assigning to 'sp_RbVal' from incompatible type 'sp_bool' (aka 'bool')`. CRuby: `true`.
- Mekanisme (dibuktikan dengan debug trace di `an_yield_site_builtin_answer`/`infer_poly_operand_call`, `src/analyze_infer.c`): akar masalahnya BUKAN mesin per-site K-024/K-025b (itu tak pernah terpanggil untuk node ini -- hanya ada satu call site, jadi `yield_recv_builtin_every_site` tak relevan). `infer_poly_operand_call` punya arm `is_membership_alias(name) && an_user_ret_disagrees(c, name, TY_BOOL)` yang mengecek SELURUH program untuk kelas mana pun yang mendefinisikan `include?`/`member?` dengan return bukan bool, lalu melebarkan ke poly -- gerbangnya `rt == TY_POLY || a0 == TY_POLY`, jadi argumen poly SAJA (bukan receiver) sudah memicunya, walau receiver-nya String konkret yang tak pernah dibuka ulang. Codegen tak punya jawaban per-site untuk jalur ini (jalur itu cuma melayani keluarga `yield_recv_builtin_every_site`), jadi `bool` native site String tertulis mentah ke slot `sp_RbVal` tanpa `sp_box_bool`.
- Repro: **repro/k025c_yield_include_poly_arg_reopen.rb**
- Klasifikasi: bug-compiler (C tidak valid, bukan sekadar nilai salah)
- Solusi yang dipakai: tidak dibutuhkan Kilau saat ini
- Upstream: **diperbaiki** (matz/spinel#8140, **di-merge 2026-10-09 05:19:45Z**, `fa03e2468`). Fix: gerbang arm `is_membership_alias` di `infer_poly_operand_call` ditambah `rt == TY_POLY` (reasoning ambiguitas receiver, sama seperti arm `is_cmp_op`/`==` di sebelahnya), jadi argumen poly saja pada receiver konkret tidak lagi memicu pelebaran. Test baru `test/yield_membership_single_site_poly_arg.rb`. Gate ter-shard di fork: https://github.com/yosefbennywidyo/spinel/actions/runs/37882294485 (`Gate: green tree 2b664e7dd264 master 9c57b440b908 tests 6560/0`).

## K-026: `respond_to?` pada receiver KONKRET (bukan boxed) masih punya gap untuk method yang baru-baru ini ditambahkan builtin-nya
- Lapisan: compiler (dispatch `respond_to?` statis, mekanisme terpisah dari matz/spinel#8153)
- Ditemukan: 2026-10-09, sebagai efek samping saat membangun `tools/respond_to_audit.rb` untuk PR `poly-respond-to-builtin-surface-completion` (matz/spinel#8153, lihat PR itu untuk konteks lengkap "mengapa boxed dan konkret adalah dua mekanisme berbeda").
- Yang terjadi (spinel master, commit sama dengan #8153 — `961718cc9` bergerak maju ke tree `03fff570a1c3`): receiver KONKRET (bukan dipaksa boxed lewat `force_poly`) salah menjawab `respond_to?` untuk sedikitnya 4 method: `Array#tally`, `Array#to_set`, `Hash#transform_keys!`, `String#unicode_normalize` — semuanya `false`, CRuby `true`. Repro terverifikasi langsung (lihat di bawah).
- Mekanisme: ini BUKAN `sp_poly_responds_builtin` (`lib/spinel_rt.h`, yang #8153 perbaiki untuk receiver BOXED/poly). Receiver konkret lewat jalur sepenuhnya berbeda: `respond_to_static_answer`/`rt_probe_answer` (`src/codegen_call.c`, ~baris 24595), yang menjawab `respond_to?` saat COMPILE TIME dengan mensintesis sebuah probe call dan mengecek apakah inferensi tipe berhasil meresolusinya (`rt_probe_answer`), bukan lewat tabel nama statis. Fungsi ini juga punya tabel Symbol/Proc/Time duplikat sendiri secara inline, independen dari `uni`/`symm`/`procm` di `sp_poly_responds_builtin`. Root cause presisi BELUM ditelusuri lebih jauh (kemungkinan: probe untuk method-method ini gagal diresolusi inferensi walau implementasinya ada, atau nama-nama ini memang belum terdaftar ke jalur probe `rt_probe_answer` sama sekali) — catatan ini mendokumentasikan gejala yang terverifikasi, bukan akar penyebab final.
- Repro: **repro/k026_concrete_respond_to_static_gaps.rb**
- Klasifikasi: bug-compiler (nilai salah diam-diam untuk `respond_to?`)
- Solusi yang dipakai: tidak dibutuhkan Kilau saat ini
- Upstream: **belum diajukan**. Sengaja TIDAK ditambal di #8153 (file/mekanisme berbeda, akan memperluas scope PR itu di luar yang diminta — lihat bagian "Scope notes" di PR tersebut). Next step: telusuri akar penyebab di `rt_probe_answer`/`respond_to_static_answer`, lalu buka PR terpisah dengan repro ini sebagai test.
- **Diverifikasi ulang 2026-10-12 ~17:48 WIB** dengan spinel master `46a9efb16` (setelah
  matz/spinel#8650, generator `respond_to?` untuk receiver BOXED): gap tidak berubah,
  masih `false/false/false/false` — #8650 memang tidak menyentuh `respond_to_static_answer`/
  `rt_probe_answer`, sesuai yang didokumentasikan. Bukan regresi baru.
- **Akar masalah ditelusuri 2026-10-13 — DUA mekanisme berbeda, bukan satu.** Dibuktikan
  dengan build spinel dari worktree (checkout `fix/inline-rbs-grep-pipe`, 1 commit di depan
  `fork/master`) dan pemanggilan LANGSUNG (bukan lewat `respond_to?`): `a.tally`, `a.to_set`,
  `h.transform_keys! { … }` ketiganya berjalan BENAR dan identik dengan CRuby — jadi method-nya
  sendiri tidak rusak, hanya probe `respond_to?`-nya yang salah menjawab. `String#unicode_normalize`
  terpisah: spinel SENGAJA menolaknya (`not supported: Unicode normalization requires shipping
  the Unicode decomposition/composition tables …`), jadi `false` di sana adalah desain, bukan
  bug dari keluarga yang sama — tidak dibahas lebih lanjut di sini.
  - **Cacat A — soal waktu (timing), kena `tally` dan `transform_keys!`/`transform_values!`:**
    `desugar_respond_to_probe` (`src/analyze_desugar.c:4710`) mensintesis 3 bentuk probe
    (`recv.m`, `recv.m { }`, `recv.m(recv)`) di DALAM fixpoint analyzer (ia butuh `infer_type`,
    yang butuh scope sudah terbangun). Tapi rewrite yang membuat `tally` benar-benar jalan
    (`desugar_builtins`, `src/analyze.c:40980`, lewat flag per-call-site `enum_copy` yang
    dikonsumsi `desugar_builtin_enum_calls`) dan rewrite untuk `transform_keys!`/
    `transform_values!` (`desugar_enum_chain_shapes`, dipanggil 2x di `src/analyze.c:41000-41001`)
    KEDUANYA jalan SEKALI SAJA, di daftar pre-pass "one-shot" sebelum scope dibangun sama sekali
    (komentar di `src/analyze_desugar.c:8937`: "before the scopes are built"). Probe yang baru
    ada belakangan (saat fixpoint) tidak pernah ada di node table waktu pre-pass itu jalan, jadi
    tidak pernah mendapat `enum_copy`/rewrite bang-nya — `desugar_builtin_enum_calls` membaca
    `enum_copy < 0` lalu `continue` (`src/analyze_desugar.c:9861`), dan probe-nya tetap jadi
    CallNode polos bernama `tally`/`transform_keys!` yang jatuh ke baris `bop_rows` yang memang
    sengaja menjawab `TY_UNKNOWN` sebagai placeholder (`src/builtin_ops.c:2369`,
    `BOP_ANY_ARRAY, "tally", …, TY_UNKNOWN, BOPE_NONE`) — `rt_probe_answer` membaca tipe itu
    sebagai "untyped" dan `respond_to?` menjawab `false`. **Dibuktikan bukan soal
    keterjangkauan (reachability)**: menambah panggilan `.tally` NYATA dan terjangkau tepat di
    sebelah `respond_to?(:tally)` di program yang sama TIDAK mengubah jawabannya — menyingkirkan
    teori "method dianggap dead code" dan mengarah tepat ke urutan pre-pass vs fixpoint.
  - **Cacat B — ketidakcocokan bentuk node, kena `to_set`:** rewrite `to_set` (`Set.new(recv.to_a)`,
    `src/analyze.c:9374`) memang jalan DI DALAM fixpoint (ia memanggil `infer_type`), tapi
    gerbangnya `nt_ref(nt, id, "arguments") < 0` — artinya "tidak ada node `ArgumentsNode` sama
    sekali", yang hanya benar untuk panggilan tanpa tanda kurung yang ditulis tangan (`recv.to_set`).
    Ketiga bentuk probe `desugar_respond_to_probe` SELALU membuat sebuah `ArgumentsNode` (bahkan
    yang 0 elemen, untuk bentuk 0 dan 1), jadi tidak satu pun pernah memenuhi gerbang itu, dan
    rewrite Set-nya tidak pernah jalan untuk probe — jatuh ke baris `bop_rows` yang sama
    (`TY_UNKNOWN`), gejala akhirnya identik dengan Cacat A walau mekanismenya beda sama sekali.
    **Dibuktikan bukan soal splice Set yang hilang**: menambah panggilan `.to_set` NYATA (dengan
    titik literal, memicu `sp_splice_builtin_extras`/kelas `Set` ikut teregistrasi) di program
    yang sama JUGA tidak mengubah jawaban `respond_to?(:to_set)`-nya.
  - Repro verifikasi (scratchpad sesi, tidak disimpan di `repro/`): `direct_tally.rb`,
    `direct_to_set.rb`, `direct_tk.rb` (panggilan langsung, semua cocok CRuby),
    `probe_plus_real.rb` (tally nyata + `respond_to?` berdampingan, jawaban tetap `false`),
    `to_set_with_mention.rb`/`tk_real.rb` (idem untuk to_set/transform_keys!).
  - Arah perbaikan (belum dikerjakan, belum diajukan upstream): kedua cacat sama-sama berakar
    dari bentuk node yang disintesis `desugar_respond_to_probe` tidak cocok dengan asumsi yang
    dipegang rewrite lain (lewat timing ATAU lewat bentuk persis node argumen). Perbaikan
    kemungkinan bukan di `rt_probe_answer` sendiri, tapi di titik probe disintesis atau di titik
    gerbang masing-masing rewrite (`enum_copy`, `desugar_enum_chain_shapes`, gerbang
    `arguments < 0` di `to_set`) supaya keduanya mengenali sebuah probe node sebagai permintaan
    tipe yang sah, bukan panggilan nyata yang perlu bentuk AST persis seperti tulisan tangan
    pengguna.
- **Cacat B (`to_set`) FIXED 2026-10-13**: `matz/spinel#8821` (commit `13b6d2333`, merge
  `11ca54e23`) **merged** — ganti gerbang `to_set`'s rewrite dari "tidak ada `ArgumentsNode` sama
  sekali" menjadi hitungan argumen sesungguhnya, jadi probe (yang selalu membawa sebuah
  `ArgumentsNode` kosong) kini cocok juga. PR yang sama juga menambah `to_set` ke `rngm[]`
  (Range lewat `sp_poly_responds_builtin`, bukan jalur probe ini — gap terpisah yang dicatat
  di PR sebagai "Range: a concrete Range does not go through that rewrite or the probe at
  all"). **Diverifikasi ulang 2026-10-16** dengan spinel master `5ab6ba17c` (lokal, `make`
  biasa bukan `make test`): `a.respond_to?(:to_set)` kini `true` SETELAH `require "set"` di
  program yang sama (perilaku benar — tanpa `require "set"`, Spinel menjawab `false` sedangkan
  CRuby pada mesin ini menjawab `true` tanpa `require` eksplisit; itu bukan regresi Spinel,
  CRuby di sini punya `set` sudah ter-load dari tempat lain sebelum skrip jalan — bukan
  dicek lebih lanjut, di luar cakupan K-026).
  `tally`/`transform_keys!` (Cacat A) masih `false`, tidak berubah oleh #8821 (mekanisme
  berbeda, PR itu tidak menyentuhnya) — **ini kandidat berikutnya yang tersisa di K-026**.
  `unicode_normalize` tetap sengaja ditolak (desain, bukan bug), tidak dibahas lebih lanjut.
- **Cacat A (`tally`/`transform_keys!`) FIXED 2026-10-16, PR dibuka upstream**: `rt_probe_answer`
  (`src/codegen_call.c`) sekarang bertanya pertanyaan kedua saat sebuah probe terbaca
  untyped: `enum_builtin_responds` (baru, `src/analyze_desugar.c`, diekspor lewat `analyze.h`)
  menjawab pertanyaan tipe-receiver yang sama dengan gerbang `ok` milik
  `desugar_builtin_enum_calls`, tanpa perlu rewrite-nya benar-benar jalan — menghindari
  kebutuhan merestrukturisasi timing pre-pass/fixpoint (opsi yang lebih berisiko, lihat
  "Arah perbaikan" di atas). Dibatasi ke dua mekanisme cacat A saja (`builtin_enum_name_index`'s
  daftar generik, dan `transform_keys!`/`transform_values!` pada receiver bertipe Hash), bukan
  digeneralisasi ke semua nama Enumerable, karena pemanggil `respond_to_static_answer` sudah
  merutekan receiver `TY_POLY`/`TY_UNKNOWN` ke jalur lain (boxed runtime, #8153) SEBELUM
  mencapai `rt_probe_answer` — hanya tipe yang benar-benar konkret yang sampai ke cek baru ini.
  Test `test/respond_to_static_enum_methods.rb` (spinel): RED sebelum fix (3 dari 6 jawaban
  salah), GREEN sesudah (cocok CRuby persis). 40 test `test/respond_to*.rb` yang sudah ada +
  test panggilan nyata `tally`/`transform_keys!`/`transform_values!` diverifikasi ulang tak
  terpengaruh. Temuan CodeRabbit di fork PR (soal method yang di-private/undef lewat reopening)
  diperiksa dan ditolak dengan bukti: `undef_method`/`remove_method` ditolak total saat compile
  (`docs/limitations.md`), dan gap `private :name` yang sama sudah ada SEBELUM fix ini untuk
  method builtin lain mana pun (`Array#first` direprodisi sebagai bukti, tak tersentuh PR ini)
  — bukan regresi, di luar cakupan PR ini. Gate ter-shard di fork: 17 job + trailer, hijau,
  `Gate: green tree 6bc5720a205b master 5ab6ba17cd43 (linux-x86_64 gcc-13.3.0) tests 7658/0`
  (https://github.com/yosefbennywidyo/spinel/actions/runs/38906207673). **PR dibuka langsung ke
  matz/spinel: matz/spinel#9344** (fork PR #30 ditutup, menautkan ke #9344).
- **Cacat A MERGED 2026-10-16**: matz/spinel#9344 di-merge oleh matz sebagai commit `ce3b19439`
  ("after the gate and all lanes passed. Thank you."), tanpa perubahan dari versi yang diajukan.
  **K-026 kini sepenuhnya FIXED** (cacat A dan B keduanya merged): `to_set` lewat #8821
  (2026-10-13), `tally`/`transform_keys!` lewat #9344 (2026-10-16). `unicode_normalize` tetap
  sengaja ditolak (desain). Tidak ada langkah tersisa untuk K-026 kecuali Kilau ingin
  upgrade compiler terinstal untuk memakai fix ini (tidak wajib — Kilau sendiri tidak
  memanggil `respond_to?(:tally)`/`(:transform_keys!)` di source-nya).

## K-027: poly-dispatch dengan fakta-kelas KOSONG (bukan tak-ada-fakta) mengecualikan setiap kandidat, termasuk yang nyata
- Lapisan: compiler (`cls_fact_excludes`, `src/analyze_cls.c`)
- Ditemukan: 2026-10-12, setelah upgrade compiler Kilau ke `a01028b4d` (yang membawa fix K-017 #8679): `make test` gagal dengan `undefined method 'kind' for an instance of Sqlite::Binds (NoMethodError)` di `migrator_test.rb`, `model_test.rb`.
- Bisect: commit pertama yang rusak `611a23da0` ("A call on a boxed receiver binds and dispatches only to the classes the receiver can hold", matz, 2026-10-12, refs matz/spinel#8530) — tapi #8530 sendiri BUKAN akar masalah, cuma commit pertama yang membuat miskomputasi lama (sebelumnya tak berbahaya) jadi tampak sebagai NoMethodError diam-diam.
- **(Koreksi 2026-10-13, baca ini dulu)** Diagnosis mekanisme di bawah ("union-find lintas `Thread::Queue`/`query_all`") **SALAH** — itu teori yang saya bangun selama investigasi dan terbukti tidak perlu. Matz (maintainer) menemukan akar masalah yang jauh lebih sederhana dalam waktu kurang dari 1 jam setelah PR merge: `src/analyze_cls.c` punya daftar `cf_opaque_name` (nama method yang analisis TIDAK diikuti kalau dipanggil — `bind`, `send`, `owner`, `receiver`, dll., karena nama-nama itu bertabrakan dengan method metaprogramming Ruby asli seperti `Method#bind`). Panggilan ke nama seperti itu membuat NILAI dan ARGUMEN panggilannya jadi "bisa apa saja" — tapi TIDAK pernah memberi tahu PARAMETER method itu sendiri untuk juga "bisa apa saja". Jadi method privat milik Kilau yang kebetulan bernama `bind` (`Connection#bind(stmt, index, binds, i)`, sama seperti paket sqlite asli) parameternya dibiarkan KOSONG (tak pernah tersentuh), bukan karena union-find — murni karena memang tak pernah di-isi siapa pun. Saya verifikasi sendiri dengan repro 17 baris TANPA `Thread::Queue`, TANPA pool wrapper, TANPA sibling method yang tak terpanggil — cukup: method privat bernama `bind` yang memanggil `.kind` pada parameternya sendiri, kelas kedua yang juga punya `kind` (agar dispatch-nya benar-benar boxed/poly), dan caller yang memanggil method LUAR-nya dua kali dengan tipe argumen berbeda (agar parameter itu butuh representasi poly sama sekali). Itu sudah cukup memicu bug yang SAMA — mengonfirmasi `Thread::Queue`/`query_all` tidak pernah diperlukan.
- Mekanisme (SUPERSEDED, disimpan untuk catatan sejarah investigasi — jangan dipercaya sebagai penyebab sebenarnya, lihat koreksi di atas): parameter `binds` milik helper privat `Sqlite::Connection#prepare`/`#bind` di-union-find-merge lintas DUA caller — `#execute` (benar-benar dipanggil, dengan argumen `Binds` konkret) dan `#query` (hanya bisa dijangkau lewat receiver yang TAK TERSELESAIKAN — `Thread::Queue#pop` dalam pool wrapper — dan dari method sibling `query_all`/`query_first` yang TIDAK PERNAH benar-benar dipanggil saat runtime, tapi tetap reachable/dianalisis). Observasi teknisnya (node union-find tertentu memang ter-cf_all) nyata terjadi, tapi sebabnya adalah panggilan opaque ke `bind` itu sendiri, bukan `query_all`/`Thread::Queue`.
- Repro: bukan di `repro/` kilau — ini bug compiler murni tanpa kaitan konteks kilau (sama seperti K-017), ditambahkan ke suite resmi spinel sendiri sebagai `test/boxed_dispatch_shared_private_helper_sibling_widen.rb` (terjemahan tanpa FFI dari bug aslinya; repro FFI asli yang faithful dipakai cuma untuk investigasi, tidak disimpan).
- Klasifikasi: bug-compiler (dispatch total gagal diam-diam untuk method yang nyata ada — bukan sekadar optimisasi yang terlewat)
- Solusi yang dipakai: upgrade compiler Kilau begitu fix ini masuk master (lihat status instalasi di bawah)
- **Akar masalah DITEMUKAN dan DIPERBAIKI sama hari (2026-10-12)**: `cls_fact_excludes` memperlakukan fakta kelas yang kosong (`s->n == 0`) sama dengan tak ada fakta sama sekali (`cls_fact_node` sudah menjawab NULL untuk CF_ALL) — jadi tidak pernah mengecualikan apa pun berdasarkan fakta kosong itu. Fakta yang benar-benar menyempit ke satu atau lebih kelas nyata (`s->n >= 1`) tidak disentuh, jadi optimisasi #8530 tetap berlaku untuk kasus umum. Dua percobaan fix sebelumnya (melebarkan `cf_call_any`'s argument loop; fallback defensif di `comp_poly_candidates_at`) masing-masing TIDAK CUKUP karena setidaknya satu consumer lain (`emit_poly_user_arms_n`, `src/codegen_poly_plan.c`) memanggil `cls_fact_excludes` lagi secara independen, melewati ringkasan kandidat yang sudah diperbaiki — pelajaran DRY: patch primitive yang dibagi, bukan ringkasan tiap consumer.
- Diverifikasi: oracle FFI (paket sqlite kilau asli) jalan sampai selesai; suite test Kilau penuh (25/25: framework, tool, examples/blog) LULUS, termasuk `migrator_test.rb`/`model_test.rb` yang tadinya gagal.
- Upstream: **diperbaiki, di-merge** — **matz/spinel#8720** (judul: "An empty class-fact answers like no fact, not like excluding every candidate"), di-merge oleh matz 2026-10-13 (merge commit `012325e97`). Gate fork hijau sebelum PR dibuka. CI upstream (clang, verify, CodeRabbit) semuanya pass, tanpa temuan.
- **Follow-up biaya run-time dari matz**: fitur baru gate (#7501, `gate-costs`) melaporkan 32 slot jadi `boxed` di ~21-22 program setelah fix ini; matz menanyakan apakah ini biaya dari fix dan apakah menyentuh benchmark/optcarrot. Dicek lokal dengan `tools/repr_diff.sh`/`tools/c_costs.sh` terhadap merge-base: terkonfirmasi itu memang biaya fix ini (receiver yang kini benar membuka poly-dispatch butuh argumennya di-box untuk calling convention yang uniform), **0 menyentuh `benchmark/*.rb` (70 file) atau optcarrot**, tidak ada operasi O(len) baru di dalam loop — seluruhnya di program `test/`/`packages/*/test` yang namanya sendiri (`boxed_*`, `poly_*`, dll.) menunjukkan tujuannya memang menguji poly-dispatch. Dijawab di komentar PR: https://github.com/matz/spinel/pull/8720#issuecomment-6129642141
- **Fix yang lebih tepat dari Matz sendiri (2026-10-13, ~1 jam setelah merge)**: commit `a58cbba58` (di master sebagai `45d534608`) menambahkan `cf_opaque_name(s->name)` ke kondisi scope-setup yang sudah memaksa `cf_all_params` untuk protocol names — jadi method bernama opaque (`bind`, dll.) kini parameternya sendiri juga ditandai "bisa apa saja", simetris dengan bagaimana PANGGILAN ke nama itu sudah diperlakukan. Dengan ini, shortcut `s->n == 0` di fix saya (#8720) **DIHAPUS** — tidak diperlukan lagi, dan menghapusnya mengembalikan optimisasi "kosong = builtin saja" untuk 32 slot/21 program yang jadi korban fix saya. Fix Matz benar DAN gratis; fix saya benar tapi bayar ongkos yang tak perlu.
- **Compiler Kilau sudah di-upgrade** (2026-10-13): `sudo make install` dijalankan user, `spinel -v` sekarang `2026.09.12+8734 (35aea8ccc)` (berisi `012325e97`, dikonfirmasi via `git merge-base --is-ancestor`; BELUM termasuk fix lanjutan `a58cbba58`/`45d534608` — upgrade lagi kalau mau ongkos boxing di 21 program lain itu juga hilang, tidak wajib untuk Kilau sendiri). `make test` Kilau dijalankan ULANG dengan compiler yang benar-benar terinstall (bukan lagi worktree lokal): **25/25 LULUS** (13/13 framework, 8/8 tool, 4/4 examples/blog), termasuk `migrator_test.rb`/`model_test.rb`.
- **Fix lanjutan Matz sekarang juga terpasang** (2026-10-13 ~11:31 WIB, di luar sesi ini):
  `spinel -v` naik lagi ke `2026.09.12+8878 (e24b53a35)`. Diverifikasi
  `git merge-base --is-ancestor a58cbba58 e24b53a35` → ya, 143 commit di depannya — jadi
  shortcut `s->n == 0` dari fix #8720 sudah terhapus di versi yang terpasang, dan ongkos
  boxing 32 slot/~21 program yang disebut di atas sudah hilang untuk Kilau juga (tidak
  hanya untuk korpus spinel sendiri). `spin clean` + `make test` diuji ulang bersih:
  **25/25 LULUS**, tanpa regresi. Tidak ada langkah tersisa dari upgrade compiler K-027.
- **Audit kode Kilau sendiri (2026-10-13)**: dicek apakah ada method lain di source Kilau (`framework/`, `tool/`, `examples/`) yang bernama seperti salah satu entri `cf_opaque_name` (`bind`, `send`, `owner`, `receiver`, `unbind`, dll.) dan BERISIKO kena pola bug yang sama. Ditemukan satu kecocokan nama: `Kilau::HTTP::Server#bind` (`framework/kilau/http/server.rb:18`) — tapi method itu **tidak punya parameter sama sekali** (`def bind` tanpa argumen), jadi tidak relevan dengan bug ini (yang spesifik soal parameter method yang catatan kelasnya kosong). **Tidak ada kode Kilau yang perlu diubah.** Satu-satunya method `bind` yang BERPARAMETER dan berisiko (`Sqlite::Connection#bind(stmt, index, binds, i)`) ada di paket eksternal `sqlite-0.1.0`, bukan source Kilau — dan sudah otomatis aman begitu compiler yang terinstall membawa fix ini.

## K-028: `private`/`protected` lewat reopening builtin class diabaikan sepenuhnya saat panggilan LANGSUNG, bukan cuma di `respond_to?`
- Lapisan: compiler (dispatch panggilan langsung ke method builtin dengan receiver literal; `respond_to_static_answer`/`rt_probe_answer`, `src/codegen_call.c`)
- Ditemukan: 2026-10-17, sebagai efek samping saat memeriksa temuan CodeRabbit yang ditolak di PR matz/spinel#9344 (lihat entri K-026 cause A). Saat itu hanya diverifikasi untuk `respond_to?`; sesi ini diverifikasi lebih luas bahwa gap-nya jauh lebih besar dari sekadar `respond_to?`.
- Repro: **repro/k028_private_reopen_builtin_method_bypassed.rb**. Dengan spinel terpasang `2026.09.12+10352 (d20573c47)`:
  ```ruby
  class Array
    private :first
  end
  begin
    p [1, 2, 3].first
  rescue NoMethodError => e
    p e.message
  end
  p [1, 2, 3].respond_to?(:first)
  ```
  CRuby: `"private method 'first' called for an instance of Array"` lalu `false`.
  Spinel: `1` (panggilan langsung BERHASIL, tidak raise sama sekali) lalu `true`.
- Mekanisme: spinel punya daftar method privat UNIVERSAL yang hardcode untuk Object
  (`object_private_method_names()`/`object_private_method_name()`, `src/codegen_call.c:28717-28734`,
  dipakai di `respond_to_static_answer` sekitar baris 29079/29177-29240) — tapi itu HANYA menjawab
  "apakah nama ini salah satu method privat bawaan Object" (`initialize`, dll.), BUKAN "apakah
  program ini, lewat reopening (`private :nama`), baru saja membuat sebuah method builtin tertentu
  jadi privat di kelasnya sendiri". Tidak ada mekanisme analisis yang melacak reopening akses-kontrol
  semacam itu pada kelas builtin (Array, Hash, String, dll.) sama sekali — bukan cuma di jalur probe
  `respond_to?`, tapi juga di jalur panggilan langsung biasa (`recv.method_name`, resolusi statis ke
  fungsi builtin C). `docs/limitations.md` baris 301 menyebut `private :center` sebagai salah satu
  kasus yang DITANGANI, tapi HANYA untuk jalur fallback splat-call pada receiver yang BISA jadi
  builtin ATAU objek user (`o.center(*a)`) — bukan untuk panggilan langsung biasa dengan receiver
  yang diketahui pasti builtin, yang jauh lebih umum.
- Klasifikasi: bug-compiler (nilai salah diam-diam: method yang di-reopen privat tetap bisa
  dipanggil langsung dan `respond_to?` tetap menjawab `true`) — tapi **scope fix jauh lebih besar**
  dari K-026: perlu mekanisme baru yang melacak reopening akses-kontrol per kelas builtin dan
  mengonsultasikannya di SETIAP call site langsung ke method builtin, bukan cuma di satu titik
  (`rt_probe_answer`) seperti K-026 cause A.
- Solusi yang dipakai: tidak dibutuhkan Kilau saat ini (Kilau tidak me-reopen method builtin
  manapun jadi privat di source-nya sendiri — dicek cepat, tidak ada `private :` yang menyasar
  kelas builtin di `framework/`, `tool/`, `examples/`).
- Upstream: **belum diajukan, belum dikerjakan**. Diputuskan 2026-10-17 untuk didokumentasikan
  dulu tanpa fix, karena scope-nya (mekanisme baru lintas semua call site builtin, bukan satu
  titik) lebih besar dari perbaikan K-026 cause A/B dan perlu didiskusikan lagi sebelum investasi
  waktu. Kandidat untuk sesi berikutnya kalau user ingin melanjutkan.
