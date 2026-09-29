# Keputusan desain

Satu baris per keputusan: fitur, in-language atau codegen, alasan, dan rujukan
katalog. Penyimpangan dari spec atau rencana juga dicatat di sini.

| ID | Fitur | Keputusan | Alasan | Rujukan |
|---|---|---|---|---|
| D-001 | Timestamp | INTEGER epoch, in-language | `Time.parse` tidak ada | K-001 |
| D-002 | Driver DB | Dua backend dengan API sama: FFI (spinel), gem sqlite3 (CRuby) | Tes CRuby sebagai oracle untuk lapisan di atas driver | K-003 |
| D-003 | Out-param `sqlite3**` / `sqlite3_stmt**` | Wrapper C di `ffi_source` | `ffi_buffer` statis tidak aman antar thread | — |
| D-004 | Binds | Array eksplisit `execute(sql, [a, b])`, bukan argumen variadic (penyimpangan dari contoh spec §5.4) | Satu bentuk untuk kedua backend | K-005 |
| D-005 | Baca kolom | `text`/`int`/`float` (NULL → nilai kosong) vs `*_or_nil` | Kolom NOT NULL tetap bertipe sempit (R3) | — |
| D-006 | DSL migrasi | Blok `create_table("posts") { \|t\| t.string("title") }`, bukan array pasangan (penyimpangan dari spec §5.1) | Array `[String, Symbol]` bernilai campuran → jalur boxed; blok bertipe | — |
| D-007 | Versi migrasi | Method `version` eksplisit | Nama class tidak dibaca lewat reflection | — |
| D-008 | Lokasi DB untuk `blog_schema` | Flag `--db PATH` (default `db/development.sqlite3`) sampai config ada di Rencana 2 | YAML tidak tersedia | K-002 |
| D-009 | Entity | Codegen (`kilau gen entities`), di-commit ke `src/models/_entities/` | Pola Loco sendiri (SeaORM entity dari skema) | — |
| D-010 | Helper tes | `Kilau::Testing.check` / `T.check` sebagai method modul, bukan `include` di top level (penyimpangan dari Rencana 1) | Method bertipe blok lewat `include` di top level gagal link | K-004 |
| D-011 | Snapshot tes | `.expected` berisi stdout+stderr gabungan; `make test-cruby` juga menggabungkan (penyimpangan dari Rencana 1) | `spin test` menggabungkan kedua stream (spinel #3405); docs/spin.md yang menyebut "stdout" sudah usang | — |
| D-012 | Config | `Kilau::Config`, parser subset YAML + getter bertipe + override `KILAU_*`; `logger.requests` (bool) menggantikan `logger.level` di contoh spec | YAML tidak ada; hanya log request yang diimplementasikan | K-002 |
| D-013 | Router | Handler = blok yang disimpan di `Endpoint`, dengan `get/post/patch/delete` sebagai method class `Kilau::Controller` | Tanpa `const_get`/`send` saat runtime; biaya tipenya tercatat di K-012 | R1, K-012 |
| D-014 | Request | `request.request_method`, bukan `request.method` (penyimpangan dari spec §3.2) | `method` akan menutupi `Object#method` | — |
| D-015 | Tes request | `Kilau::Testing::Client.new(hooks, app_context)`, bukan `Kilau::Testing.request(App)` (penyimpangan dari spec §3) | Tes menyiapkan DB + migrasi sendiri; client tidak perlu tahu migrasi app | — |
| D-016 | Error handler | `Kilau::Error` menyimpan status di ivar lewat `initialize`; subclass hanya `super(status, msg)` | Override method pada subclass exception gagal compile | K-010 |
| D-019 | Binds SQL | `Kilau::DB::Binds` (builder bertipe: `.int/.float/.text/.null/*_or_nil`) menggantikan Array binds campuran di seluruh API `execute/query/query_all/query_first/insert` (penyimpangan dari D-004 dan Rencana 1); entity hasil generate membangun `insert_binds`/`update_binds` dengan reader kolomnya | Array campuran membuat spinel crash (K-015) dan melebar (K-005) | K-015, K-005 |
| D-020 | Subset sintaks template | Seperti tabel "Subset sintaks template" di Rencana 3: delimiter satu baris; baris tag tunggal dibuang; `{# #}` komentar; `for k, v`; `elif` = `elsif`; block layout menjadi parameter `block_<nama>` (String atau nil) dan child memanggil `Templates.<layout>(...)`; cek variabel hanya pada identifier akar ekspresi (blok Ruby di ekspresi tidak didukung); `buf`/`block_*` dicadangkan | Terjemahan streaming token ke Ruby tanpa AST polimorfik (menghindari pola K-015/K-016); cek akar menangkap salah ketik tanpa parser Ruby | K-015, K-016 |
| D-021 | Lokasi hasil template | `build/gen/templates.rb` tidak di-commit; `make test`/`make test-cruby` di akar dan `make`/`make e2e` di blog selalu membangunnya dulu. `make test-cruby` menjalankan tes dari direktori paket seperti `spin test`. Golden generator di-commit sebagai `tool/test/fixtures/templates.rb` dan dijalankan oleh `template_runtime_test.rb` | Spec §1: template di-compile saat build; golden yang dijalankan membuktikan kode hasil generate valid di kedua engine | — |
| D-017 | View blog (sementara) | Fungsi `Views::Posts.*` menyusun HTML langsung + `Kilau::Html.escape`; Rencana 3 mengganti isinya dengan `Templates.*` — selesai di Rencana 3 (D-020) | Controller final sejak Rencana 2 tanpa menunggu template | — |
| D-018 | Root `/` | 303 ke `/posts` lewat route di `App#routes` | Loco tak punya `root`; route biasa cukup | — |
