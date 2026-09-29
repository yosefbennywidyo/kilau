# Katalog batas AOT

Compiler: spinel 2026.09.12+2124 (1ba12fb74) sejak 2026-09-29 13:45 WIB. Entri K-001 s.d. K-017 ditemukan dengan 2026.09.12+1379 (38dc57dd); lihat tabel status di bawah. Format entri: spec §6.3.
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
| K-004 | link gagal (`Undefined symbols`) | link gagal | **masih ada** |
| K-007 | `unsupported condition (non-bool)` | sama | **masih ada** |
| K-009 | link gagal (izin `root 0640`) | lulus dari worktree | soal instalasi; akar masalah ditemukan 2026-09-29 13:45 WIB, lihat entri K-009 |
| K-010 | C gagal (`no member named 'cls_id'`) | sama dengan CRuby | **diperbaiki upstream** |
| K-011 | `%zz` → NUL | sama dengan CRuby (`ArgumentError`) | **diperbaiki upstream** |
| K-012 | pelebaran app 30 (`blog`) / 11 (`blog_routes`) | 30 / 11 | tidak berubah |
| K-013 | C gagal (`sp_MatchData *`) | sama | **masih ada** |
| K-014 | `unsupported equality` / `interpolation` (http_server_test, migrator tanpa `to_s`) | penolakan sama | **masih ada** |
| K-015 | segfault (exit 139), CRuby 303 | segfault (exit 139) | **masih ada** |
| K-016 | `query_first` bentuk lama → tes blog `show escapes the title` FAIL | FAIL sama | **masih ada**; repro minimal 37 baris |
| K-017 | `elsif … == 0` + raise → `nil given to int` | sama | **masih ada** |

Kilau `main` dengan spinel baru: `make test` 14/14, 8/8, 4/4; `make test-cruby` 26/26;
`make e2e` 11/11 untuk kedua binary. Tidak ada regresi.

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
- Upstream: kandidat laporan (sebaiknya menyebut method yang tak ada); belum dilaporkan

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
- Solusi yang dipakai: `Route#match` → `Route#match_path`. **Aturan umum:** hindari nama method yang sama dengan method bawaan String/Array/Hash (`match`, `size`, `each`, `call`, ...) pada kelas framework yang bisa tidak terpakai di sebagian program.
- Biaya: nol (ganti nama)
- Upstream: kandidat laporan; belum dilaporkan

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
- Program minimal per file: 724 baris setelah di-flatten (framework DB/model/controller + migrasi + Request + model Post). Replika sintetis dengan unsur-unsur di atas **belum** crash, jadi ada detail lain yang belum teridentifikasi. Reduksi otomatis (`spinel-reduce`, oracle: CRuby 303 + spinel exit 139) berjalan dari 724 baris itu. Batas 6–8 giliran untuk K-015 sudah tercapai.
- Klasifikasi: bug-compiler/runtime (pembacaan elemen array poly salah tag), serius (crash)
- Solusi yang dipakai: binder bertipe `Kilau::DB::Binds` menggantikan array binds campuran (D-019). Tidak ada lagi `PolyArray` di jalur SQL.
- Biaya: perubahan API `execute/query/insert(sql, binds)` di Rencana 1 (binds kini `Binds`, bukan Array). Sekaligus menghapus pelebaran K-005.
- Upstream: kandidat laporan setelah repro minimal; belum dilaporkan

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
- Klasifikasi: bug-compiler (dugaan: variabel lokal yang ditangkap blok bersarang, ditulis dari dalam, tidak terlihat oleh method saat method itu di-dispatch poly)
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
- Repro: framework/kilau/model/model.rb dengan bentuk `elsif` di atas + framework/test/model_test.rb. Belum minimal.
- Klasifikasi: bug-compiler (sensitivitas inferensi seluruh program; sekeluarga dengan K-015/K-016)
- Solusi yang dipakai: bentuk `else` + variabel + `to_i`
- Biaya: nol
- Upstream: perlu isolasi
