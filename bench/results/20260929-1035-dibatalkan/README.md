# Sesi yang dibatalkan (2026-09-29 10:35–11:02 WIB)

Sesi ini tidak dipakai di `bench/RESULTS.md`. Urutannya per blok (app →
skenario → konkurensi). Di MacBook Air tanpa kipas, app yang jalan belakangan
mendapat mesin yang lebih panas:
- `kilau-routes-s1-c16`: 14.258 req/s, padahal `kilau-s1-c16` 31.771 req/s,
  meskipun kedua binary men-dispatch `_ping` dengan cara yang sama.
- Setelah diselang-seling di mesin yang sudah panas: 16,3 ribu vs 15,9 ribu.

Sesi dihentikan pada sel ke-15 dari 36. Sesi pengganti ada di `../20260929-1108`
(urutan selang-seling + jeda 20 dtk). Lihat `docs/FINDINGS.md` §7.
