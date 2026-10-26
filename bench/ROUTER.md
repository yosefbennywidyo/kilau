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

## Pengukuran lanjutan: 300, 600, dan 750 route

Sama seperti di atas (spinel `9d1040375`, median 3 run, 20.000 lookup per run).
Varian gabungan: `case` pada segmen pertama, lalu rantai `if` hanya untuk route
yang berawalan segmen itu (`bench/router/gen_micro.rb`, `hybrid_source`).

| Route | Trie | Rantai `if` | Gabungan | `if` / trie | gabungan / trie |
|---|---|---|---|---|---|
| 300 | 928 | 1.102 | 907 | 1,19x | 0,98x |
| 600 | 920 | 1.538 | 1.100 | 1,67x | 1,20x |
| 750 | 913 | 1.782 | 1.203 | 1,95x | 1,32x |

Membaca hasil:
- Rantai `if` dan trie bersilangan antara 100 dan 300 route. Di bawah itu rantai
  lebih cepat, di atasnya trie lebih cepat dan selisihnya makin besar.
- Gabungan `case` + `if` hanya menyamai trie di 300 route. Di tabel ini setiap
  segmen pertama unik, jadi `case` menjadi perbandingan string berantai dan
  tumbuh dengan jumlah segmen. Di aplikasi nyata yang banyak route berbagi
  segmen pertama, bagian `if` di dalam cabang akan ikut tumbuh, dan gabungan
  bisa berbeda dari angka ini. Itu belum diukur.
- Trie tetap datar (sekitar 900 ns) di semua ukuran yang diuji.

Keputusan yang belum diambil: aturan Fase D (adopsi di mode generate bila menang
di >= 100 route dan tidak kalah di 10) berarti mode generate tetap rantai `if`.
Kalau ingin trie di mode generate untuk aplikasi besar, perlu ambang (misalnya
di atas 200 route) dan dua jalur kode, dan itu butuh keputusan terpisah.

## Pengukuran kecil: 10, 30, 60, dan 100 route

Cara sama seperti di atas (spinel `9d1040375`, median 3 run, 20.000 lookup per
run). Dijalankan dengan `ruby bench/router/gen_micro.rb <dir> 10 30 60 100`.

| Route | Trie | Rantai `if` | Gabungan | `if` / trie | gabungan / trie |
|---|---|---|---|---|---|
| 10 | 904 | 691 | 685 | 0,76x | 0,76x |
| 30 | 926 | 723 | 721 | 0,78x | 0,78x |
| 60 | 922 | 757 | 742 | 0,82x | 0,80x |
| 100 | 915 | 806 | 763 | 0,88x | 0,83x |

Rantai `if` dan gabungan lebih cepat dari trie di semua ukuran ini. Selisihnya
menyempit dari 0,76x di 10 route ke 0,88x di 100 route, lalu berbalik antara
100 dan 300 route (lihat bagian di atas). Jadi titik silang trie dan rantai
`if` berada di antara 100 dan 300 route pada mesin dan kode ini.

## Keputusan: mode generate memakai gabungan

Dipilih `case` pada segmen pertama lalu `if` (D-027). Di 10 sampai 100 route
gabungan sedikit lebih cepat dari rantai `if`, dan di 300 route ke atas
gabungan menyamai trie di 300 route. Route yang segmen pertamanya parameter
tetap diperiksa setelah `case`, dengan prioritas yang sama seperti di Fase C.
Trie tetap dipakai di mode table.

Belum diukur: trie yang disusun sebagai `case` bersarang untuk setiap segmen,
serta tabel dengan segmen statis di kedalaman 2 dan 3. Tabel sintetis di sini
hanya punya segmen kedua berupa parameter, jadi `case` kedua tidak bisa dibuat.

## Trie bersarang sebagai kode: tabel dengan dua tingkat segmen statis

Tabel: 5 segmen pertama (`s0`..`s4`), B segmen kedua di bawah masing-masing,
dan dua pola per kombinasi (`/s<i>/t<j>/:id` dan `/s<i>/t<j>/:id/edit`).
Jumlah route = 10 x B. Dijalankan dengan `ruby bench/router/nested_micro.rb <dir>`
(spinel `9d1040375`, median 3 run, 20.000 lookup per run).

- trie: struktur runtime (`Micro.find`)
- if: satu `if` per route
- case+if: `case` pada segmen pertama, `if` di dalam (D-027)
- bersarang: `case` pada segmen pertama, `case` pada segmen kedua, lalu `if` di
  daun (trie bersarang sebagai kode)

| Route | Trie | if | case+if | bersarang | if/trie | case+if/trie | bersarang/trie |
|---|---|---|---|---|---|---|---|
| 10 | 1.159 | 863 | 856 | 860 | 0,74x | 0,74x | 0,74x |
| 100 | 1.166 | 980 | 889 | 884 | 0,84x | 0,76x | 0,76x |
| 300 | 1.160 | 1.280 | 941 | 913 | 1,10x | 0,81x | 0,79x |
| 600 | 1.183 | 1.795 | 1.021 | 941 | 1,52x | 0,86x | 0,80x |
| 750 | 1.154 | 2.099 | 1.117 | 972 | 1,82x | 0,97x | 0,84x |

Membaca hasil:
- Trie bersarang tidak pernah lebih lambat dari `case`+`if` yang diukur, dan
  paling cepat dari 100 route ke atas. Di 10 route, ketiga varian kode berada
  dalam selisih kecil (4 ns antara bersarang dan case+if, dalam noise).
- Trie runtime tetap yang paling lambat di semua ukuran di tabel ini, karena
  setiap langkah berupa lookup Hash, sedangkan varian kode memakai perbandingan
  string yang langsung.
- Di tabel dengan segmen statis dalam, `case` bersarang bisa dipakai. Tabel
  satu tingkat (segmen kedua selalu parameter) tidak bisa, seperti dibahas di
  bagian sebelumnya.

Keputusan yang belum diambil: mengganti gabungan `case`+`if` di `kilau gen
routes` dengan trie bersarang. Itu menuntut generator yang menyusun pohon
dengan kedalaman sembarang dan menjaga prioritas Fase C pada grup yang berbagi
prefix. Itu pekerjaan generator yang cukup besar dan perlu persetujuan dulu.

## Ambang di kilau gen routes (D-028)

Di bawah 10 route (default ikut dihitung), generator memakai `case` pada segmen
pertama dan `if` (D-027). Dari 10 route ke atas, ia memakai trie bersarang.
Konstanta: `NESTED_MIN_ROUTES` di `tool/kilau_tool/routes_gen.rb`. Fixture
(9 route) memakai jalur pertama; blog (10 route) memakai jalur kedua, dan
keduanya diuji oleh `make test` dan `make e2e`.
