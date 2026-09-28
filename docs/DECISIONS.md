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
| D-010 | Helper tes | `Kilau::Testing.check` / `T.check` sebagai method modul, bukan `include` di top level (penyimpangan dari Rencana 1) | Method bertipe blok lewat `include` di top level gagal link | K-004 |
