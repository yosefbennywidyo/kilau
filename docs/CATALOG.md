# Katalog batas AOT

Compiler: spinel 2026.09.12+2606 (35ddccadb) sejak 2026-09-30 06:43 WIB (sebelumnya `6626c0f05` sejak 2026-09-29 23:08, `1ba12fb74` sejak 13:45). Entri K-001 s.d. K-017 ditemukan dengan 2026.09.12+1379 (38dc57dd); lihat tabel status di bawah. Format entri: spec §6.3.
Repro dijalankan dengan `spinel --require-gate` (seperti `spin build`), dan CRuby
4.0.6 sebagai pembanding.

## Status di spinel terbaru (Rencana 6 Fase 0, 2026-09-29 13:29 WIB)

Diuji dengan spinel `2026.09.12+2124 (1ba12fb74)`, yang 745 commit di depan `38dc57dd`.
Spinel baru dibuat di worktree terpisah, sedangkan instalasi `/usr/local/bin/spinel`
tetap `38dc57dd` saat tabel ini dibuat (lalu dinaikkan, lihat baris compiler di atas). Repro mandiri di-compile dengan `--require-gate` dan output-nya
dibandingkan dengan CRuby. Untuk K-014 s.d. K-017, bentuk kode lama dipasang ulang
dari riwayat pra-publik, dan tes yang dulu memicunya dijalankan dengan kedua versi.
Semua kasus "masih ada" juga gagal dengan `38dc57dd`, jadi rekonstruksinya valid.

| K | `38dc57dd` | `1ba12fb74` | Status |
|---|---|---|---|
| K-004 | link gagal (`Undefined symbols`) | link gagal | **diperbaiki upstream** (matz/spinel#6029, di-merge 2026-09-30 05:41 WIB, `eb340a6ab`) |
| K-007 | `unsupported condition (non-bool)` | sama | **masih ada**; perbaikan diajukan: matz/spinel#6093 |
| K-009 | link gagal (izin `root 0640`) | lulus dari worktree | soal instalasi; akar masalah ditemukan 2026-09-29 13:45 WIB, lihat entri K-009 |
| K-010 | C gagal (`no member named 'cls_id'`) | sama dengan CRuby | **diperbaiki upstream** |
| K-011 | `%zz` → NUL | sama dengan CRuby (`ArgumentError`) | **diperbaiki upstream** |
| K-012 | pelebaran app 30 (`blog`) / 11 (`blog_routes`) | 30 / 11 | tidak berubah |
| K-013 | C gagal (`sp_MatchData *`) | sama | **diperbaiki upstream** (matz/spinel#6063, di-merge 2026-09-30 06:32 WIB, `35ddccadb`); workaround `match_path` dicabut |
| K-014 | `unsupported equality` / `interpolation` (http_server_test, migrator tanpa `to_s`) | penolakan sama | **masih ada** |
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
- Upstream: layak diusulkan agar compile menolak `Time.parse` alih-alih mengembalikan `unknown`; belum dilaporkan

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
- Upstream: bisa diusulkan agar cabang `RUBY_ENGINE` yang mati tidak me-resolve `require`; belum dilaporkan

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
- Upstream: kandidat laporan ke spinel dengan repro di atas; belum dilaporkan (menunggu persetujuan pengguna)
- **Perbaikan (Rencana 6 Fase 2, 2026-09-30):** method yang `yield` hanya ada dalam bentuk inline, jadi fungsinya tidak pernah di-emit. `emit_inline_call_x` (`src/codegen_iter.c`) mencari panggilan tanpa receiver di kelas pembungkus dan fungsi top level, tapi tidak di modul yang di-`include` di top level. Panggilan jatuh ke jalur top-level-include di `emit_call`, yang memanggil `sp_<Modul>_<method>(NULL, …)`, fungsi yang tidak ada, sehingga link gagal. Kini inliner juga mencari lewat `comp_included_method_index`; method yang memakai ivar tetap ke jalur lama (ditolak dengan diagnostik #3775). Tes `test/toplevel_include_yielding_method.rb` (yield, `&blk`, modul bersarang, dipanggil dari method top level) merah sebelum, hijau sesudah, GC stress lulus; C benchmark identik; CI penuh hijau di PR fork. Commit `471ed6171` → direvisi tiga kali atas temuan CodeRabbit menjadi `602e30b52`: (1) `comp_included_method_index` kini mencari method **instance** dulu, karena modul dengan `def self.pick` + `def pick` diam-diam menjawab singleton; (2) inliner juga mengambil method kelas (`module_function`) dengan modul sebagai self, karena `module_function` + `yield` masih gagal link; (3) pemeriksaan ivar di kedua jalur kini lewat satu helper `scope_uses_ivars` (`codegen_util.c`) yang juga menangkap target multi-assign (`@a, @b = …`) dan `&&=`, dipatok reject test `test/reject/toplevel_include_yield_ivar_target.rb`. Temuan ke-4 (ivar di blok bersarang) tidak bisa direproduksi dengan lima bentuk; dibalas. **PR https://github.com/matz/spinel/pull/6029**, **di-merge oleh matz 2026-09-30 05:41 WIB** (`eb340a6ab`). Riwayat terkait: #5117 (gejala sama lewat clone proc form saat modul di-include dua kali).

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
- Upstream: PR matz/spinel#6093
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
- Upstream: kandidat (installer sebaiknya memaksa mode 0644); belum dilaporkan
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
- Upstream: kandidat laporan; belum dilaporkan

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
- Upstream: kandidat laporan (prioritas: decode ke NUL); belum dilaporkan

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
- Upstream: kandidat laporan; belum dilaporkan
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
- Upstream: perlu isolasi lebih dulu sebelum layak dilaporkan

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
- Upstream: kandidat laporan setelah repro minimal; belum dilaporkan

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
- Upstream: **diperbaiki** (matz/spinel#5789)

## K-018: `spin test` memakai ulang binary tes lama setelah compiler di-upgrade
- Lapisan: tooling (`spin`)
- Yang terjadi: setelah `sudo make install` spinel `6626c0f05` (2026-09-29 23:08 WIB), `make test` melaporkan 26/26 lulus, tetapi **semua** tes bertanda `(cached)`. Binary tesnya dari 13:43, lebih tua dari compiler, jadi hasil hijau itu masih milik compiler lama.
- Mekanisme (`tools/spin.rb`, `spinel_bin`, di spinel `6626c0f05`): `spin` mencari compiler di `<dir dari $0>/spinel`. Kalau dipanggil lewat PATH (`spin test`), `$0` hanya `spin`, sehingga `File.expand_path` menunjuk ke direktori kerja. Kandidat itu tidak ada, dan fungsi mengembalikan nama polos `"spinel"`. `File.exist?("spinel")` false, sehingga mtime compiler dianggap 0 dan tidak pernah membuat cache basi (batas kesegaran #3202).
- Bukti: `cd framework && /usr/local/bin/spin test` → 0 `(cached)`, 14 tes dikompilasi ulang.
- Solusi yang dipakai: `Makefile` Kilau memakai `SPIN ?= $(shell command -v spin)` (path absolut).
- Klasifikasi: bug-tooling
- Upstream: **PR https://github.com/matz/spinel/pull/5983 di-merge oleh matz 2026-09-30 00:23 WIB** (merge commit `c5898078e`; dibuka ~00:20 WIB, commit `265ed2fea`, branch `spin-compiler-mtime-through-path`). `spinel_bin` sekarang mencari `$0` polos lewat PATH (fungsi `which` di `spin.rb`) sebelum `expand_path`. Tes baru di `tools/spin_e2e.sh` gagal sebelum dan lulus sesudah perbaikan. `make check`: semua leg lulus; corpus 4.647 pass, 1 fail (`hash_store_operand_gc_root`, timeout 10 dtk saat run paralel, lulus 5/5 bila dijalankan sendiri).
- Tindak lanjut: CodeRabbit menemukan bahwa `which` melewati komponen PATH kosong (`:` di awal/akhir, `::`), padahal shell membacanya sebagai direktori kerja. Sejak #5983, `spinel_bin` bisa memakai compiler di sebelah `spin` lain yang lebih belakang di PATH. Perbaikan (`split(":", -1)`, komponen kosong → `.`) + tes e2e dengan `spin` decoy yang compiler-nya selalu gagal (merah sebelum, hijau sesudah): **PR https://github.com/matz/spinel/pull/5997 di-merge oleh matz 2026-09-30 01:24 WIB** (commit `4fafd9ba4`; CI hijau, CodeRabbit tanpa temuan). Hanya `spin-check` yang dijalankan (tidak ada perubahan di `src/`/`lib/`).

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
- Upstream: PR matz/spinel#6092

