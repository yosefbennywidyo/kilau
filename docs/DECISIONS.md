# Keputusan desain

Satu baris per keputusan: fitur, in-language atau codegen, alasan, dan rujukan
katalog. Penyimpangan dari spec atau rencana juga dicatat di sini.

| ID | Fitur | Keputusan | Alasan | Rujukan |
|---|---|---|---|---|
| D-001 | Timestamp | INTEGER epoch, in-language | `Time.parse` tidak ada | K-001 |
| D-010 | Helper tes | `Kilau::Testing.check` / `T.check` sebagai method modul, bukan `include` di top level (penyimpangan dari Rencana 1) | Method bertipe blok lewat `include` di top level gagal link | K-004 |
