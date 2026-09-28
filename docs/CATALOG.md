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
| R5 | FFI menangani `SQLITE_TRANSIENT` dan salinan `column_text`? | belum (Task 2) | |
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
- Solusi yang dipakai: `Kernel.require "sqlite3"` di cabang CRuby, karena tidak di-resolve saat parse (diverifikasi 2026-09-28 dengan probe)
- Biaya: nol; satu baris
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
