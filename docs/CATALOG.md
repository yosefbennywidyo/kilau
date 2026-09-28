# Katalog batas AOT

Compiler: spinel 2026.09.12+1379 (38dc57dd). Format entri: spec §6.3.
Repro dijalankan dengan `spinel --require-gate` (seperti `spin build`), dan CRuby
4.0.6 sebagai pembanding.

## Jawaban riset

| ID | Pertanyaan | Status | Bukti |
|---|---|---|---|
| R1 | Tabel closure route tetap bertipe? | belum (Rencana 2) | |
| R2 | `Hash[String, String]` params/form tetap sempit? | belum (Rencana 2) | |
| R3 | Kolom nullable di entity tetap bertipe? | belum (Task 9) | |
| R4 | `buf << ...` di template tetap di jalur string buffer? | belum (Rencana 3) | |
| R5 | FFI menangani `SQLITE_TRANSIENT` dan salinan `column_text`? | **terjawab: ya** (2026-09-28 ~16:20 WIB) | `bind_text(stmt, i, s, -1, -1)` = SQLITE_TRANSIENT lewat integer literal sebagai `:ptr`; teks yang dibaca di blok `query` selamat setelah `finalize` + `GC.start` (tes `text read in a block outlives the statement`, teks Unicode dan 10 KB); out-param `sqlite3**`/`sqlite3_stmt**` lewat wrapper C `ffi_source`. Biaya: handle/statement berjalan di jalur boxed (K-006). |
| R6 | Green thread + FFI `blocking: true` + pool tahan konkurensi? | belum (Task 3 sebagian; Rencana 4) | |

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
