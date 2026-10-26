# Fase D: mesin pencocokan route (trie segmen)

Pengukuran sebelum adopsi, sesuai Rencana 5 Fase D: benchmark mikro, bukan
keputusan dari perkiraan.

- Mesin: MacBookAir10,1 Apple M1, 8 core, RAM 8 GB, macOS.
- Versi: spinel `9d1040375` (upstream master, dikompilasi dengan `spinel`).
- Skrip: `bench/router/micro.rb` (linear vs trie, CRuby dan spinel) dan
  `bench/router/gen_micro.rb` (menghasilkan file untuk mode generate: satu
  `if` per route, route pertama yang cocok dikembalikan).
- Tabel sintetis: 10, 100, dan 1.000 route. Setiap indeks `i` punya `/r<i>/:id`
  dan `/r<i>/:id/edit`, dan lookup berputar di setiap indeks.
- Angka: ns per lookup, median dari 3 run (masing-masing 20.000 lookup).

| Route | Mode table: linear (Route#match semua route) | Mode table: trie | Mode generate: rantai `if` | Trie vs linear table | Trie vs rantai `if` |
|---|---|---|---|---|---|
| 10 | 9.389 | 896 | 688 | 10,5x lebih cepat | 0,77x (trie lebih lambat) |
| 100 | 87.833 | 916 | 809 | 95,9x lebih cepat | 0,88x (trie lebih lambat) |
| 1.000 | 835.686 | 928 | 2.180 | 900,5x lebih cepat | 2,35x (trie lebih cepat) |

Catatan:
- Mode table memindai semua route di setiap request (karena pemilihan pemenang
  butuh semua yang cocok, untuk Allow dan 405). Itu sebabnya linear table naik
  linear dengan jumlah route.
- Mode generate sudah berhenti di route pertama yang cocok, dan tiap `if`
  murah. Itu sebabnya rantai `if` lebih cepat dari trie sampai sekitar 100 route.
- Trie yang diukur adalah prototipe yang sama dengan `Kilau::RouteTrie` yang
  diadopsi. Pengecekan kesetaraannya (trie vs `Route#match`) dijalankan sebelum
  setiap pengukuran.

## Keputusan

Aturan dari rencana: trie diadopsi hanya bila menang berarti di 100 route atau
lebih **dan** tidak kalah di 10 route.

- **Mode table: diadopsi.** Trie menang di ketiga ukuran, termasuk 10 route.
- **Mode generate: tidak diadopsi sekarang.** Trie kalah di 10 dan 100 route,
  sehingga aturan tidak terpenuhi. Rantai `if` yang dihasilkan `kilau gen routes`
  tetap dipakai. Trie baru menang di 1.000 route; itu bisa ditinjau lagi bila
  aplikasi nyata mencapai ukuran itu.

Dicatat sebagai D-026 di `docs/DECISIONS.md`.

## Batasan

- Hanya pencocokan yang diukur, tanpa biaya request HTTP atau pemanggilan
  handler. Angka HTTP end-to-end tetap perlu `bench/run.sh` bila dibutuhkan.
- `--warn-widen` menunjukkan pelebaran tipe di `route_trie.rb` (poly), seperti
  yang sudah ada di `routes.rb`. Tidak ada koleksi yang mencampur jenis yang
  berbeda. Angka di atas sudah mencakup biaya itu.
