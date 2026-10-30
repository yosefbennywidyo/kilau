# HANDOFF — Kilau

Entri terbaru di atas.

## 2026-10-30 — K-034 (16 lagi builtin pada `yield`) ditemukan, 14/16 diperbaiki, PR fork hijau, menunggu sharded gate

**Status**
- Ditemukan 2026-10-29 lewat sapuan ulang `tools/yield-sweep/sweep.sh` terhadap
  compiler yang baru dinaikkan ke `8ad86746d` (berisi K-033). 14/16 nama
  diperbaiki di spinel (`clear`/`compact`/`to_a`/`entries`/`fetch_values`/
  `concat`/`deconstruct`/`difference`/`intersection`/`to_ary`/`union`/`next`/
  `flatten(n)`/`max(n)`/`min(n)`/`insert(n)`). 2/16 (`clear`, `concat`) TIDAK
  dihitung sebagai bug baru -- setelah bisa compile, keduanya cuma menampakkan
  gejala K-032 (literal String dianggap frozen), dicatat sebagai addendum
  K-032, bukan sisa kerja K-034.
- Detail lengkap, breakdown per nama, dan hasil verifikasi (sapuan 258-probe
  50→34 CC_FAIL, nol regresi) ada di `docs/CATALOG.md` K-034.
- CodeRabbit menemukan satu bug nyata tambahan di fix pertama (fallback
  generik `flatten(n)` salah untuk receiver nested array, `TY_INT_ARRAY_ARRAY`/
  `TY_FLOAT_ARRAY_ARRAY` -- row `BOPR_SELF` seharusnya `ty_array_elem`).
  Diperbaiki di commit kedua; diverifikasi TIDAK reachable lewat `yield`
  biasa (forward inference tidak pernah melebar ke tipe nested itu), jadi
  fix-nya defensif/table-level, bukan memperbaiki gejala runtime yang
  terpisah (gap lama di poly dispatch, bukan dari K-034).
- Fork PR **#42** (https://github.com/yosefbennywidyo/spinel/pull/42): CI
  clang hijau, GuardRails hijau, CodeRabbit kena rate-limit di commit kedua
  (sudah ditanggapi manual). Branch `gate/k034-more-yield-receiver-builtins`
  sudah di-push, sharded gate (17 job) sedang jalan.

**Belum**
1. Tunggu verdict sharded gate, lalu buka PR upstream ke `matz/spinel`.
2. Setelah merge: `sudo make install` compiler terbaru, jalankan ulang
   `repro/k034_yield_receiver_even_more_builtins_still_bad.rb`, update
   `docs/CATALOG.md`/`docs/HANDOFF.md` dengan hasil verifikasi end-to-end
   (pola yang sama dengan K-033).

## 2026-10-29 — K-033 diverifikasi end-to-end: compiler Kilau naik ke 8ad86746d

**Status**
- Root-owned leftover dari `sudo make install` sebelumnya (`spinel`,
  `build/spin_version.rb`, `bin/spinel*`, `bin/spin`, `build/csrc/main.o`
  di repo spinel) sempat memblokir rebuild non-root — `chown` ulang oleh
  user, lalu `make -j2` bersih dan `sudo make install` sukses.
- `/usr/local/bin/spinel` sekarang `2026.10.25+1046 (8ad86746d)`, berisi
  kedua merge commit K-033 (`8b54cd405` dan `91f7d660f`).
- `repro/k033_yield_receiver_more_builtins_still_bad.rb`: output spinel
  cocok CRuby persis di semua 24 baris. `docs/CATALOG.md` K-033 diperbarui
  mencatat verifikasi ini.

**Lanjut dari sini**
- Tidak ada pekerjaan tersisa di K-033.
- Cek `docs/CATALOG.md` untuk K-item lain yang masih terbuka sebelum
  memulai pekerjaan baru (lihat daftar `## K-0xx` di file itu).

## 2026-10-29 — K-033 (23 builtin pada receiver `yield`) tertutup: kedua PR upstream MERGED

**Status**
- **matz/spinel#10476** (Tier A, 13 nama: `clear`/`flatten`/`first`/`shift`(0-arg) +
  Hash, plus 9 nama arg-1/2) merged 2026-10-28 22:51:47Z, merge commit `8b54cd405`.
- **matz/spinel#10481** (Tier B, 10 nama: `min`/`max`/`uniq`/`dig`/`fetch`/`itself`
  pada Hash, `minmax`, dan `capitalize`/`downcase`/`upcase`/`swapcase` pada Symbol)
  merged 2026-10-28 23:07:30Z, merge commit `91f7d660f`.
- Keduanya merged tanpa perubahan diminta (CI+gate+CodeRabbit+GuardRails hijau).
  `docs/CATALOG.md` K-033 entri diperbarui untuk mencatat status MERGED (sebelumnya
  tercatat "menunggu review/merge").

**Catatan**
- Compiler Kilau yang terpasang (`/usr/local/bin/spinel`) masih di commit sebelum
  kedua fix ini — belum perlu dinaikkan untuk kerja saat ini, tapi harus dinaikkan
  sebelum menutup/memverifikasi K-033 secara end-to-end di Kilau.
- Branch kerja di repo spinel (`yield-receiver-array-hash-shared-builtins`,
  worktree `k033-hash-min-max-uniq-dig-fetch`) sudah landed via PR di atas; aman
  dibersihkan (lihat memory `project_kilau_k030_yield_sweep` di sesi Claude untuk
  daftar cleanup fork branch yang masih menunggu tindakan manual).

**Lanjut dari sini**
1. `sudo make install` spinel master terbaru (berisi kedua merge commit di atas),
   lalu jalankan ulang `repro/k033_yield_receiver_more_builtins_still_bad.rb` untuk
   konfirmasi end-to-end di Kilau.
2. Tidak ada K-item lain yang diketahui terbuka saat ini — cek `docs/CATALOG.md`
   untuk kandidat baru sebelum memulai pekerjaan berikutnya.

## 2026-10-28 17:37 WIB — Verifikasi kandidat upstream: semua sudah diperbaiki

**Status**
- Kandidat "belum dilaporkan" di entri 2026-09-29 dan 2026-09-30 (K-004, K-007, K-010,
  K-011, K-013, K-015, K-016, K-017) sudah diperbaiki upstream. Tidak ada yang perlu
  dilaporkan ulang.
- Diverifikasi dengan menjalankan repro terhadap `bin/spinel` di HEAD `9d1040375`, dibandingkan
  dengan CRuby:
  - Sama dengan CRuby: K-004, K-010, K-011, K-013, K-015 (`user_each`), K-016, K-017, K-017b.
  - K-007: bukan bug lagi. Spinel mencetak `undefined method 'save' for an instance of Gadget
    (NoMethodError)`. CRuby juga mencetak cuplikan kode, jadi hanya format diagnostik yang
    berbeda.
  - K-015 (`endpoint_save_crash`): **terverifikasi di spinel** dari `examples/blog` (sesuai
    header repro). Spinel `9d1040375` mencetak `303` dan keluar 0, tanpa segfault (header
    mencatat 139 sebelum fix). Pembanding CRuby hanya dari header repro: framework memuat
    `sqlite` versi Spinel, jadi CRuby tidak bisa dijalankan langsung dari sini.
- Upstream (menurut CATALOG): K-004 matz/spinel#6029, K-007 #6093, K-013 #6063, K-015 dan K-016
  #6008, K-017 #8679. K-010 dan K-011 lulus sejak `1ba12fb74`.

**Catatan**
- Entri lama di bawah tidak diubah; daftar "kandidat upstream" di dalamnya adalah catatan
  historis pada tanggalnya.

## 2026-10-27 — Rencana 5 Fase D: trie untuk mode table

**Status**
- Benchmark di `bench/ROUTER.md` (median 3 run, spinel): mode table linear
  835 us di 1.000 route, trie 0,9 us. Di 10 dan 100 route, rantai `if` mode
  generate lebih cepat dari trie, jadi trie hanya diadopsi untuk mode table.
- `Kilau::RouteTrie` dipakai `Dispatcher` (commit `7278b34`). D-026 dicatat.
- `make test`: framework 14/14, tool 8/8, blog 4/4. `make e2e`: 35 pengecekan
  lolos, 0 gagal.

**Lanjut dari sini**
1. Fase E: parameter bertipe (`/:id<int>`), dengan `/posts/abc` tetap 400 dan
   `--warn-widen` tidak bertambah di blog.
2. Fase F (opsional), diputuskan setelah E.
3. Uji jalur shard `tools/gate.rb linux --target/--shard` di runner GitHub.

## 2026-10-27 — Status akhir sesi: Rencana 5 A–E selesai, F sebagian

**Selesai dan di `origin/main`**
- Fase A–E (route, HTTP, konflik dan prioritas, trie dan ambang, parameter `<int>`).
  Keputusan D-023 sampai D-029.
- Fase F sebagian: `Routes#nest` dan `Routes#merge` di kedua mode (D-030), commit
  `3617ee1`..`dbbd856`, dokumen di `1ceb8de`.
- `make test` (framework 16/16, tool 8/8, blog 4/4) dan `make e2e` blog (35 pengecekan)
  hijau pada commit terakhir.

**Belum dikerjakan (belum ada keputusan atau pekerjaan)**
1. `resources` ala Rails (Fase F): hanya di mode generate, sehingga paritas dua mode
   pecah. Perlu keputusan pengguna sebelum dikerjakan.
2. Nama route dan helper path (`Paths.post(id)`): non-goal spec §6.5, butuh keputusan
   pengguna.
3. File route tunggal `src/routes.rb` (Fase F): desainnya belum cukup spesifik di
   rencana. Perlu spesifikasi sebelum dikerjakan.
4. Jalur shard `tools/gate.rb linux --target/--shard` (spinel `gate-shard-option`,
   commit `b0169aea5`, belum upstream): unit test lolos, jalur Docker belum pernah
   dijalankan. Uji di runner GitHub dengan satu target dulu.
5. Trie bersarang untuk tabel dengan segmen statis lebih dalam: sudah diukur pada tabel
   dua tingkat (bench/ROUTER.md), tetapi belum pada aplikasi nyata.

**Catatan**
- Pelajaran sesi ada di memory `feedback_kilau_session_lessons_2026_10_27`.
- Angka benchmark mikro berlaku untuk tabel sintetis di mesin ini (M1, spinel
  `9d1040375`), dan ambang 10 route (D-028) mengikuti angka itu.

## 2026-10-27 — Rencana 5 Fase F sebagian: nest dan merge (D-030)

**Status**
- `Routes#nest` dan `Routes#merge` di framework, dan keduanya dibaca `kilau gen
  routes` di tempat. Commit `3617ee1`..`dbbd856` di `origin/main`.
- `make test`: framework 16/16, tool 8/8, blog 4/4. `make e2e` blog: 35 pengecekan,
  0 gagal.
- Belum dikerjakan, dengan alasan di D-030: `resources` (hanya mode generate, sehingga
  kedua mode berbeda), nama route dan helper path (non-goal, perlu keputusan
  pengguna), dan file route tunggal `src/routes.rb` (desainnya belum cukup
  spesifik di rencana).

**Lanjut dari sini**
1. Putuskan apakah `resources`, nama route, dan file route tunggal dikerjakan.
2. Uji jalur shard `tools/gate.rb linux --target/--shard` di runner GitHub.

## 2026-10-27 — Rencana 5 Fase E selesai: parameter bertipe `:id<int>`

**Status**
- `:name<int>` (D-029): route tetap cocok berdasarkan bentuk; nilai bukan bilangan
  bulat dijawab 400 sebelum handler, dengan pesan seperti `path_int`. Mode table
  di dispatcher, mode generate di cabang route.
- Blog memakai `/:id<int>` untuk post. `--warn-widen` blog: 463 sebelum dan sesudah.
- `make test`: framework 15/15, tool 8/8, blog 4/4. `make e2e` blog: 35 pengecekan,
  0 gagal. Commit: `50a1534`..`b1c5e2d`.

**Lanjut dari sini**
1. Fase F (opsional): `Routes#nest`, `Routes#merge`, satu file route opsional,
   `resources` sebagai sugar di `gen routes`. Diputuskan dulu apakah dikerjakan.
2. Uji jalur shard `tools/gate.rb linux --target/--shard` di runner GitHub
   (spinel `gate-shard-option`, belum upstream).

## 2026-10-27 — Rencana 5 Fase D selesai (trie + ambang); Fase E berikutnya

**Status**
- Pengukuran di `bench/ROUTER.md` (spinel, median 3 run): trie untuk mode table
  (D-026); mode generate memakai `case` pada segmen pertama + `if` (D-027), dan
  trie bersarang dari 10 route ke atas (D-028, `NESTED_MIN_ROUTES`).
- Commit: `c78e45f` di `origin/main`. `make test`: framework 14/14, tool 8/8,
  blog 4/4. `make e2e` blog: 35 pengecekan, 0 gagal.
- Pelajaran sesi ada di memory `feedback_kilau_session_lessons_2026_10_27`.

**Lanjut dari sini**
1. Fase E: parameter bertipe `/:id<int>`. Blog memakai sintaks itu; `/posts/abc`
   tetap 400; `--warn-widen` tidak bertambah.
2. Fase F (opsional), diputuskan setelah E.
3. Uji jalur shard `tools/gate.rb linux --target/--shard` di runner GitHub
   (spinel `gate-shard-option`, belum upstream).

## 2026-10-27 — Rencana 5 Fase C selesai; make test dan e2e hijau

**Status**
- Fase C (static menang atas :param, konflik ditolak) selesai dan di-push ke
  `origin/main` (`4217a29`..`cce3b7f`): `Route#shape_key`/`specificity`,
  `AppRoutes#add` menolak bentrok, `Dispatcher#call` memilih grup spesifisitas
  terendah, `gen routes` mengelompokkan dan menolak bentrok dengan `file:baris`.
  Keputusan: D-025.
- `make test` (spinel `9d1040375`): framework 13/13, tool 8/8, blog 4/4.
  `make e2e` blog dan blog_routes: 35 pengecekan lolos, 0 gagal.
- Memory `bug_kilau_route_segment_shadowing` ditandai FIXED.

**Lanjut dari sini**
1. Fase D (trie segmen): wajib ukur dulu dengan benchmark mikro di 10/100/1.000
   route sintetis; hasilnya di `bench/ROUTER.md`, keputusan sebagai D-0xx. Adopsi
   hanya bila menang di >= 100 route dan tidak kalah di 10 route.
2. Fase E (parameter bertipe `/:id<int>`), lalu F (opsional).
3. Uji jalur shard `tools/gate.rb linux --target/--shard` (spinel
   `gate-shard-option`, belum upstream) di runner GitHub.

## 2026-10-26 — T4 selesai dan merged upstream

**Status**
- T4 (Hash Enumerable dan cycle.first pada yield campuran): merged sebagai
  matz/spinel#10272 (11:57Z) dan fix lanjutan #10283 (15:50Z, `d8094045b`).
- K-032: tetap ditutup sebagai perilaku sengaja. Catatan di `docs/CATALOG.md`
  sudah diperbarui (commit `4f98964`, sudah di-push ke origin).
- Upstream sudah tidak punya label `gate: verified` atau trailer `Gate:` (commit
  `e9f552b9b`, 2026-10-20). Ringkasan `make gate` harus ditempel ke body PR.
- Branch lokal `gate-shard-option` (spinel, `b0169aea5`) berisi opsi
  `tools/gate.rb linux --target/--shard` dan `merge`. Jalur Docker belum diuji.

**Lanjut dari sini**
1. Uji jalur shard (`tools/gate.rb linux --target/--shard`) di runner GitHub
   sebelum matriks penuh. Branch: spinel `gate-shard-option`, belum upstream.
2. Fase C rencana route (2026-10-17) masih menunggu dieksekusi.

## 2026-10-21 ~01:35 WIB — K-030 sampai K-032 selesai; T4 (Hash Enumerable pada yield campuran) siap dikerjakan

**Status**
- **Selesai, di upstream matz/spinel:**
  - K-030 (`yield` + builtin numerik per site) → #9779, merged 2026-10-20 13:46Z.
  - K-031 (`yield.<=>`) → #9794, merged 15:46Z (`9e6678d2e`).
  - K-030b (`yield.sort` / `yield.reverse`) → #9795, merged 15:46Z (`9923101bd`).
- **K-032** (`"abc".frozen?` true) ditutup sebagai perilaku sengaja. Dasarnya di
  `spinel/docs/limitations.md`, bagian "String literals are frozen by default":
  `frozen_string_literal: true` adalah baseline, tanpa opt-out, dan mesin
  shared-string bergantung pada jaminannya.
- **Pembersihan (2026-10-20):** branch lokal dan fork dari pekerjaan K-029..K-031
  dihapus. Fork PR #36, #37, #38 ditutup setelah PR upstream dibuka. Yang tersisa
  di fork: `c-version`, `openbsd-portable-fiber`, `ruby-v1`, `self-host`
  (bukan dari pekerjaan ini, tidak disentuh).
- **Belum:** T4 (lihat di bawah). Kilau punya 17 commit lokal yang belum dipush;
  itu keputusan user.

**Temuan untuk T4 (belum diperbaiki)**
- Di luar yield, `{a: 1}.cycle`, `each_cons`, `each_slice`, `find_index` benar.
- Di yield bercampur site Array dan Hash, `yield.cycle` gagal saat runtime:
  site Hash dijawab `TY_UNKNOWN` oleh inferensi face-pinned
  (`an_yield_site_builtin_answer`, `src/analyze_infer.c`), jadi codegen memakai
  jalur "undefined method". Site Array benar (enumerator).
- Menambah nama ke `yield_site_per_kind_name` tidak cukup. `each_slice` dan
  `find_index` juga gagal compile saat bercampur (PolyArray vs IntArray).
- Detail dan kriteria selesai: `RENCANA_K030B_K031_K032.md`, T4.

**Keputusan**
- Rencana disimpan di kilau (bukan spinel), sesuai permintaan user.
- Repo spinel: `master` = `origin/master` (929186309), tanpa perubahan lokal.

**Lanjut dari sini**
1. Perbaiki inferensi face-pinned untuk `cycle` pada Hash tanpa blok, lalu
   periksa `each_slice`/`each_cons`/`find_index` (T4 langkah 1 dan 2).
2. Setiap fix: repro CRuby, `test/` dengan `.expected` dari CRuby, `test/infer/`.
   Gate di fork lewat `gate-shards-17job.yml`, bukan `make gate` lokal.
3. Catatan K-032 di `docs/CATALOG.md`: ganti "nilai salah diam-diam" dengan
   "perbedaan yang disengaja dengan default CRuby".

**Pelajaran (detail ada di memory `feedback_spinel_session_lessons_2026_10_20`)**
- `make bin/spinel` tidak membangun `lib/libspinel_rt.a`. Setelah rebase atau
  pull, jalankan juga `make lib/libspinel_rt.a`, kalau tidak link gagal dengan
  "Undefined symbols" pada fungsi `sp_re_*` yang sebenarnya ada di `lib/sp_re.c`.
- `gh pr checks --watch` dan `gh run watch` bisa keluar dengan exit 0 saat job
  masih pending. Verifikasi dengan `gh run view <id> --json status`.
- Gate fork menambah commit trailer (`Gate: ...`) ke branch PR. Setelah itu
  branch lokal harus disinkronkan (`git reset --hard fork/<branch>`). Pastikan
  rebase berikutnya memakai head yang sudah di-trailer.
- Kalau ada dua PR yang bertumpuk, cek tree dengan `git rev-parse <sha>^{tree}`.
  Tree yang sama berarti hasil gate masih berlaku setelah rebase.
- Setiap entri katalog harus disisipkan di bagian heading yang tepat. Dua kali
  status tertambah di akhir file dan masuk ke K-032 yang salah.

## 2026-10-17 ~03:24 WIB — Rencana 5 Fase C: plan siap, menunggu pilihan eksekusi

**Status**
- User menyetujui lanjut Fase C-F dari Rencana 5 (kualitas route), satu fase per
  putaran dengan cek di antaranya (bukan jalan semua C-F sekaligus tanpa henti).
- **Keputusan Fase C**: **Opsi 1** (prioritas matchit/Loco — static selalu
  menang atas `:param` pada kedalaman segmen sama, tidak bergantung urutan
  deklarasi; tumpang-tindih ambigu antar dua pola berparameter sebentuk untuk
  verb yang sama ditolak saat boot/generate) — dipilih user 2026-10-17 setelah
  dikonfrontasi dengan riset Loco (pakai matchit, persis Opsi 1) vs Rails
  (Journey, order-wins, lebih dekat Opsi 2 tapi tanpa fitur "peringatan route
  dibayangi"). Alasan: konsisten dengan D-024 (Kilau sudah pakai gaya axum
  untuk 405, bukan Rails-style 404).
- **Plan implementasi lengkap sudah ditulis dan disimpan**:
  `docs/superpowers/plans/2026-10-17-kilau-rencana-5-fase-c-conflict-priority.md`
  (7 task, TDD, commit per task). Desain intinya:
  - `Kilau::Route#shape_key` (String tunggal, bukan Array campuran — hindari
    K-015/K-016) dan `Route#specificity` (Integer bitmask, MSB = segmen paling
    kiri, bit nyala kalau segmen itu `:param` — makin kecil makin statis/makin
    tinggi prioritas; perbandingan Integer polos `<`/`==` cukup, tak perlu
    `.min`/`.sort_by` yang belum terbukti aman di spinel untuk `framework/`
    maupun `tool/`, keduanya **dikompilasi spinel** lewat `spin build`
    — lihat `Makefile:41-44`).
  - Table mode: `AppRoutes#add` menolak route baru dengan `(verb, shape_key)`
    yang sudah ada. `Dispatcher#call` dirombak jadi dua langkah: kumpulkan
    semua route yang match path, pilih grup `specificity` terkecil ("winners"),
    baru dispatch/405/OPTIONS dari grup itu saja (bukan agregat semua pattern
    yang textually match, supaya Allow header benar per "node", gaya
    matchit/axum bukan linear scan lama).
  - Generate mode (`tool/kilau_tool/routes_gen.rb`): helper `shape_key`/
    `specificity` versi teks-pattern (duplikasi sengaja dari framework, sesuai
    pola pemisahan tool/framework yang sudah ada di codebase ini — bukan DRY
    violation, lihat precedent `route_conditions`). `render` dirombak:
    kelompokkan semua deklarasi (termasuk 2 route default `_ping`/`_health`)
    per `shape_key`, tolak kalau ada verb yang sama dua kali dalam satu grup
    (dengan `file:baris` KEDUA deklarasi), urutkan grup ascending by
    `specificity` (insertion sort manual, bukan `.sort_by`), lalu emit satu
    `if <conds>` per grup berisi `case match_verb` — tiap cabang `return`,
    supaya begitu satu grup match, tak pernah jatuh ke grup kurang spesifik
    di bawahnya walau verb-nya tak cocok di grup itu.
  - Bug nyata yang jadi bukti/regression-proof: `DELETE /notes/bulk` saat ini
    *diam-diam sukses* (204) lewat `/notes/:id`'s `remove` (yang tak pernah
    memanggil `load_item`/`path_int`) — bukan sekadar 400 seperti kasus GET.
    Fase C mengubahnya jadi 405 Allow: POST yang benar. Lihat memory
    `[[kilau-route-segment-shadowing]]` untuk histori lengkap bug ini.
  - D-025 akan dicatat di `docs/DECISIONS.md` sebagai bagian plan (Task 6).

**Langkah berikutnya**
1. **Tanya user pilihan eksekusi plan** (belum dijawab sesi ini): native
   (direkomendasikan — 7 task-nya sangat sekuensial, tak ada paralelisme nyata
   untuk dimanfaatkan subagent-driven) vs subagent-driven. Lanjutkan dengan
   `superpowers:executing-plans` atau `superpowers:subagent-driven-development`
   sesuai jawabannya.
2. Eksekusi plan task 1-7 (lihat file plan di atas untuk detail lengkap per
   task: file yang disentuh, test yang ditulis dulu, langkah implementasi).
3. Setelah Fase C selesai dan `make test` + e2e blog hijau: lanjut **Fase D**
   (trie segmen) — **ingat**: Fase D baru diadopsi kalau benchmark mikro
   (gaya r10k, 10/100/1.000 route sintetis) membuktikan trie menang berarti
   di ≥100 route **dan** tidak kalah di 10 route (ukuran blog). Jangan skip
   pengukuran ini — itu syarat eksplisit dari spec Rencana 5 §3 Fase D.
4. Baru setelah D selesai/diputuskan: **Fase E** (parameter bertipe `/:id<int>`,
   atau `{id:int}` — keputusan sintaks juga ditunda ke fase itu per spec), lalu
   putuskan ke user apakah **Fase F** (DX sugar, eksplisit "opsional, diputuskan
   setelah A-E") dikerjakan sama sekali.
5. Satu fase per putaran, cek balik ke user di antaranya — ini permintaan
   eksplisit user (bukan jalan semua tanpa henti).

## 2026-10-07 ~15:50 WIB — matz/spinel#7807 MERGED

**Status**
- **Merge** pukul 08:45:32Z (`b4d30a1d3`), masuk master `f3da0151f`. Lihat entri di bawah untuk
  detail regresi dan fix.
- Branch `kernel-require-dead-branch` dan `gate/kernel-require-dead-branch` dihapus (lokal dan
  fork), sesuai alur yang sudah dipakai untuk PR-PR sebelumnya.
- Otomasi trailer `Gate:` yang ditambahkan ke `gate-shards-17job.yml` (job `trailer`: hitung
  `git merge-tree` + jumlah test, amend commit, force-push ke fork — supaya check
  `gate-trailer.yml` upstream memberi label `gate: verified`) **belum terbukti jalan sampai
  akhir**: run pertama gagal karena bug kecil (`grep -oE ... -P`, flag bertentangan; sudah
  diperbaiki jadi `-oP`), run kedua dibatalkan begitu diketahui PR sudah merge — push trailer
  ke branch PR yang sudah ditutup jadi tidak berguna. Mekanismenya tersimpan di skill
  `spinel-notes` untuk PR berikutnya, masih berstatus belum diverifikasi end-to-end.

**Langkah berikutnya — selesai 2026-10-07 ~16:30 WIB**
1. ~~`sudo make install` spinel master `f3da0151f`~~ selesai, compiler terpasang `f3da0151f`.
2. ~~Jalankan `make test`/`make test-cruby`/`make e2e` penuh~~ selesai, **semua lolos tanpa
   workaround**: `make test` 13/13 framework + 8/8 tool + 4/4 blog; `make test-cruby` semua
   `ok`; `make e2e` (`blog` + `blog_routes`) semua `ok`. Build bersih (`rm -rf */build`
   sebelum uji).
3. ~~Tandai K-003b "Fixed"~~ sudah ditandai di `docs/CATALOG.md`.

Tidak ada langkah tersisa dari upaya naikkan compiler ini. Memory soal otomasi trailer `Gate:`
(belum diverifikasi end-to-end) tercatat di `feedback_spinel_gate_trailer_automation.md` untuk
PR spinel berikutnya.

## 2026-10-07 ~14:30 WIB — Upaya naikkan compiler menemukan regresi `--require-gate`; K-014 dicabut; fix terkirim (#7807)

**Status**
- Build spinel master `ae2c38c71` berhasil dan diinstal (`sudo make install`). Tapi `make test`
  kilau gagal di tahap `tool` (`spin build`): `cannot load such file -- sqlite3`. Penyebabnya
  **bukan** kode kilau — lihat **K-003b** di `docs/CATALOG.md`: `Kernel.require "sqlite3"` di
  paket `spinel-sqlite` v0.1.0 (pola yang sama dianjurkan K-003 sendiri) ditolak di bawah
  `--require-gate`, regresi dari commit spinel `0c0f61fff`.
- Fix dikirim hari yang sama sebagai **matz/spinel#7807** (langsung PR, tanpa issue, sesuai
  CONTRIBUTING.md upstream). Gate ter-shard di fork hijau penuh (korpus 6.251 test,
  infer-test/scale-test/optcarrot/bench/rubyspec), CodeRabbit bersih. Menunggu Matz.
- **Workaround K-014 (`.to_s` di `framework/kilau/model/migrator.rb` baris 30, 41, 53) sudah
  dicabut** (commit kilau `429876e`) dan **diverifikasi lolos** — tapi lewat kompilasi langsung
  per file (`spinel $(spin flags | sed 's/--require-gate//') ...`), bukan `make test`, karena
  regresi di atas memblokir build `tool`. 13 tes framework, 16 tool, 8 blog semua cocok dengan
  `.expected`.
- K-018 dan K-020 juga diuji ulang dan dipastikan diperbaiki upstream (lihat `docs/CATALOG.md`).
  K-005 dan K-008 tetap melebar sesuai desain yang diterima.
- Compiler kilau **belum dinaikkan resmi**: compiler terpasang di `/usr/local` adalah `ae2c38c71`
  tanpa fix #7807 (belum di-install ulang setelah fix ditulis, menunggu merge). `make test`
  kilau tetap gagal sampai #7807 merge dan compiler di-install ulang.
- Dicatat juga: draf analisis regresi dipindah dari scratchpad sesi ke
  `~/apps/me/gems/spinel/DRAFT_REQUIRE_GATE_REGRESSION.md` (status RESOLVED, bukan lagi draf).

**Langkah berikutnya**
1. Tunggu #7807 merge di matz/spinel.
2. `sudo make install` ulang spinel master yang berisi `#7807`.
3. Jalankan `make test`/`make test-cruby`/`make e2e` penuh (sekarang seharusnya tidak lagi
   diblokir regresi `--require-gate`).
4. Tandai K-003b "Fixed" di `docs/CATALOG.md` setelah merge dan uji ulang.

## 2026-10-02 13:15 WIB — K-009, K-014(b), K-024b, K-025(b bag. 1) merged; K-025b bag. 2 terbuka (#7158)

**Status**
- Merged 09:33 WIB: **#7062** (K-009, `make install` membuat paket terbaca), **#7063** (K-024b, tabel per site), **#7064** (K-014, method yang selalu raise), **#7078** (K-025, reopen Array/Hash memiliki nama builtin; Matz menyusulkan `f018966dc` yang memindah arm ke helper).
- Merged 12:22 WIB: **#7095** (K-014b, operator/call/rantai pada method yang selalu raise), **#7096** (K-025b bag. 1).
- Terbuka: **#7158** (K-025b bag. 2: site lain di samping reopen dijawab builtin-nya sendiri; juga memperbaiki `yield.succ` pada blok String yang menjalankan reopen `Integer#succ`). Gate: https://github.com/yosefbennywidyo/spinel/actions/runs/36971021776.
- Aturan upstream baru (2026-10-02, matz/spinel#7082 + CONTRIBUTING.md): setiap PR menyertakan ringkasan `make gate` atas branch yang di-merge dengan master; gagal gate atau konflik dengan master = PR dikembalikan. `.expected` harus sama dengan CRuby 4.0 `--enable-frozen-string-literal`. Fungsi > 1.000 baris tidak boleh bertambah (#7033). Detail di skill `spinel-notes`.
- Kilau masih di compiler `ea9feecfe`: **belum** berisi perbaikan-perbaikan di atas.

**Langkah berikutnya**
1. Naikkan compiler Kilau ke master spinel terbaru (build + install). Dengan #7062, `chmod` K-009 tidak diperlukan lagi untuk instalasi baru.
2. Cabut workaround K-014 (`.to_s` di `framework/kilau/model/migrator.rb` baris 30, 41, 53), jalankan suite dari build bersih (`make test`, `make test-cruby`, `make e2e`).
3. Setelah #7158 merge: tandai K-025 selesai penuh di `docs/CATALOG.md` dan `docs/FINDINGS.md`.

## 2026-09-30 17:47 WIB — K-022 merged (argumen + operator); lanjutan #6226 terbuka; K-024 tercatat

**Status**
- Upstream merged: **#6172** (FFI `MemoryPointer` → `NoMemoryError`), **#6185** (K-022: `yield` sebagai argumen method pengguna; aturan sadar-receiver setelah review CodeRabbit), **#6219** (K-022: operator aritmetika `+ - * / %` pada `yield`, di-merge di `fff8bdd49`).
- Terbuka: **#6226** (lanjutan #6219: String `+`/`*` dengan argumen yang dikonversi/ditolak, mis. `yield * 2.0`, `yield + 1`). Temuan ketiga CodeRabbit masuk saat #6219 sedang di-merge; force-push perbaikannya jatuh ke PR yang sudah merge, jadi dibawa lewat PR baru. Komentar penjelasan dipasang di #6219.
- Kilau di compiler `ea9feecfe` (belum berisi #6185/#6219/#6226); workaround K-021 sudah dicabut.
- **K-024 (terbuka, nilai salah diam-diam):** `yield.abs` dengan blok Integer lalu Float mencetak `2` untuk `-2.5.abs`; `yield.first` gagal compile. Repro `repro/k024_yield_receiver_builtin_method.rb`; penunjuk kode dan arah perbaikan di entri K-024 `docs/CATALOG.md`.

**Langkah berikutnya**
1. Tunggu #6226 merge → hapus worktree `../spinel-k022op` + branch `k022-yield-operator`, `k022-yield-string-operator-args` (lokal & fork); tandai K-022 selesai di katalog/FINDINGS.
2. K-024: perluas analyzer + hook `sp_yield_site_type` ke method builtin pada receiver `yield` (lihat CATALOG). Analyzer dan hook harus mencakup himpunan yang sama; uji di mode default **dan** promote lewat `make`, termasuk semua `promote_*`.
3. Naikkan compiler Kilau setelah #6226 merge.
4. Tertunda: `spin publish` sqlite, Rencana 5, K-014; tindak lanjut K-023 (`def` top level dari `BasicObject`).

## 2026-09-30 14:19 WIB — K-021 dan K-023 merged; CI upstream ternyata kosong sejak 28 Sep (diperbaiki); PR FFI

**Status**
- Upstream merged hari ini (lanjutan): **#6151** (K-021: nilai pemanggilan method `yield` dari modul yang di-`include` di top level), **#6160** (fix CI `shard_pick`), **#6162** (K-023: subclass `BasicObject` tidak lagi menjangkau modul top-level include). Terbuka: **#6172** (FFI `MemoryPointer` yang tak bisa dialokasikan → `NoMemoryError`; temuan GuardRails, CodeRabbit bersih).
- **CI upstream kosong 2026-09-28 ~04:00Z s.d. #6160:** daftar tes > 128 KiB (`MAX_ARG_STRLEN` Linux), `shard_pick` gagal "Argument list too long", tiap lane hanya menjalankan tes paket (~174) tapi tetap hijau. Run #6160 membuktikan master saat itu lulus korpus penuh (4.873). Pelajaran: baca baris `Tests: N pass` di log CI, jangan percaya centang hijau saja.
- K-022 (method `yield` + blok bertipe berbeda → C tidak valid) tercatat, repro `repro/k022_*`. Tindak lanjut K-023: `def` top level masih terjangkau dari `BasicObject` (`comp_method_index`).
- Kilau masih di compiler `35ddccadb`: belum berisi #6092, #6093, #6151, #6162.
- GuardRails (hanya di fork): temuan `analyze_desugar.c:10383–10384` direkomendasikan *won't fix*; `sp_ffi.c:84` false positive.

**Langkah berikutnya**
1. Naikkan compiler Kilau ke master terbaru (build + install, `chmod` K-009), suite dari build bersih, cabut workaround K-021 (`raises_db_error?` lewat modul).
2. K-022: reduksi + PR spinel.
3. Setelah #6172 merge: hapus worktree `../spinel-ffi` + branch.
4. Tertunda: `spin publish` sqlite (Rencana 7 Fase 4 langkah 3), Rencana 5, K-014.

## 2026-09-30 09:12 WIB — Rencana 7 Fase 4: `spinel-sqlite` publik, Kilau memakai dependency git

**Status**
- Repo publik **github.com/yosefbennywidyo/spinel-sqlite** (MIT): README (contoh, API, alasan `Binds`), tag **`v0.1.0`** (`deea921`).
- Kilau: `framework/spin.toml` → `sqlite = { git = "…/spinel-sqlite", ref = "v0.1.0" }`; `spin.lock` di-commit di `framework`, `tool` dan `examples/blog` (pin SHA `deea921`).
- Tanpa `spin.lock`, spin meng-`git clone --branch <ref>` **setiap** perintah (jaringan tiap build + noise "detached HEAD" untuk tag annotated); dengan lock, cache dicocokkan per SHA dan `SPIN_OFFLINE=1` jalan.
- Makefile: runner CRuby mengambil `-I` dari `spin flags` (`RUBY_INCLUDES`), bukan checkout tetangga; override dengan `RUBY_INCLUDES=` untuk mencoba checkout lokal.
- Build bersih + `SPIN_OFFLINE=1`: 13/13, 8/8, 4/4, CRuby 25/25, e2e blog lulus (200 req @32 konkuren).

**Langkah berikutnya**
1. Ditunda: `spin publish` → PR ke `matz/spin-index` (Fase 4 langkah 3).
2. K-021 (PR spinel), catatan katalog merge K-007/K-020, naikkan compiler Kilau ke yang berisi #6092/#6093.
3. Mengubah package: kerjakan di `~/apps/me/gems/spinel-sqlite`, tag versi baru, lalu `spin lock` di ketiga package Kilau.

## 2026-09-30 07:01 WIB — Semua PR spinel merged; rencana 7: ekstrak Kilau::DB → `spinel-sqlite`

**Status**
- Upstream merged: **10 PR** — #5789 (K-017), #5983 + #5997 (K-018), #6008 (K-016), #6027 (K-015), #6028 (K-019), #6029 (K-004), #6063 (K-013), **#6092 (K-020)**, **#6093 (K-007)**. Tidak ada PR terbuka.
- Branch lokal & fork yang merged dihapus; worktree `spinel-latest` dihapus (buat ulang dengan `git worktree add` bila perlu).
- Kilau di spinel `35ddccadb` belum berisi #6092/#6093 (K-020/K-007) — naikkan compiler lagi bila perlu.
- Sisa bug spinel: **K-021** (repro ada, belum dikerjakan), K-014 (butuh bentuk kode lama).

**Rencana 7 (baru)**: ekstrak `Kilau::DB` (385 baris, 6 file, tanpa ketergantungan ke bagian Kilau lain; 24 file Kilau merujuknya) menjadi spin package `spinel-sqlite` (package `sqlite`), sejajar dengan `pg`/`redis` di spin-index. Detail + keputusan D1–D6 (nama, gaya API vs gem `sqlite3`, lokasi repo, migrasi, cakupan, lisensi): `docs/superpowers/plans/2026-09-30-kilau-rencana-7-spinel-sqlite.md` (lokal, gitignored).

**Langkah berikutnya**
1. Rencana 7 Fase 0: pengguna memutuskan D1–D6.
2. Fase 1–3 (lokal): scaffold → pindahkan kode + tes → Kilau memakai package via path; hijau dari build bersih.
3. Fase 4 (dengan persetujuan): repo GitHub publik, dependency git, opsional `spin publish`.
4. Paralel/berikutnya: K-021 (PR spinel), catatan katalog merge K-007/K-020.

## 2026-09-30 06:43 WIB — Compiler Kilau naik ke `35ddccadb`; workaround K-013 dicabut

**Status**
- Kilau memakai spinel **`35ddccadb`** (`/usr/local`, K-009 chmod sudah). Suite dari build bersih: 14/14, 8/8, 4/4, CRuby 26/26.
- Upstream merged: 8 PR (K-017, K-018×2, K-016, K-015, K-019, K-004, **K-013 #6063**). Terbuka: #6092 (K-020), #6093 (K-007).
- `Route#match_path` → kembali `match` (K-013). Compiler lama `6626c0f05` gagal 11/14 dengan kode ini, jadi compiler ≥ `35ddccadb` **wajib**.
- Jebakan K-018 arah sebaliknya: setelah build dengan compiler baru, tes dengan compiler lama terlihat lulus karena memakai binary cache; `spin clean` dulu sebelum membandingkan compiler.
- Pembersihan: branch lokal & fork yang sudah merged dihapus; worktree `spinel-latest` dipertahankan sampai #6092/#6093 merged.

**Langkah berikutnya**
1. Cabut workaround lain yang kini didukung compiler: K-015 (`Kilau::DB::Binds`), K-016 (pola array `query_first`), K-004 (helper tes method modul). Satu per satu, suite hijau tiap langkah.
2. Pantau #6092/#6093; setelah merge hapus worktree `spinel-latest` + branch.
3. Sisa: K-014.

## 2026-09-30 06:20 WIB — K-004 merged; PR K-013, K-007, K-020 terbuka

**Status**
- Upstream merged (7 PR, peringkat ~28/63): #5789 (K-017), #5983+#5997 (K-018), #6008 (K-016), #6027 (K-015), #6028 (K-019), **#6029 (K-004)**.
- PR terbuka: **#6063 (K-013)** (CodeRabbit bersih), **#6093 (K-007)**, **#6092 (K-020, baru)**.
- K-020: `run { next true if c; nil }` mencetak `nil` (nilai salah diam-diam); ditemukan dari review CodeRabbit di fork K-007.
- Alur baru terbukti: PR fork **non-draft** → CI + CodeRabbit di fork sebelum PR ke matz. Kuota CodeRabbit gratis di fork ≈2 review/20 mnt; K-020 terlewat review fork karena kuota.
- Kilau masih memakai spinel `6626c0f05`.

**Langkah berikutnya**
1. Pantau #6063, #6092, #6093 (tanggapi temuan CodeRabbit upstream bila ada).
2. Naikkan compiler Kilau ke `master` terbaru (sudah berisi K-004/015/016/017/018/019), jalankan ulang repro, cabut workaround: K-015 `Binds`, K-016 pola array `query_first`, K-004 helper tes; K-013 (`match_path`) setelah #6063 merged.
3. Sisa: K-014 (susun ulang bentuk lama dari riwayat git `migrator.rb`).

## 2026-09-30 04:38 WIB — K-015/K-019 merged; K-004 direvisi (CI hijau); K-013 di CI fork; survei ivar

**Status**
- Upstream merged: #5789 (K-017), #5983+#5997 (K-018), #6008 (K-016), **#6027 (K-015)**, **#6028 (K-019)**. Kamu: 6 commit, peringkat ~29/63.
- **#6029 (K-004)** terbuka, CI hijau di `602e30b52` setelah tiga revisi atas CodeRabbit (instance method dulu, `module_function`, helper `scope_uses_ivars` + reject test). Satu temuan CodeRabbit (ivar di blok bersarang) tak bisa direproduksi, sudah dibalas.
- **K-013**: perbaikan di branch `k013-builtin-name-untyped-recv` (`705e36969`), CI di PR fork #4. PR ke matz menunggu CI + persetujuan pengguna.
- Survei ~129 daftar jenis node ivar di analyzer: tidak ada bug yang bisa direproduksi; tidak membuka PR refactor. Laporan: `docs/review/survei-daftar-ivar-analyzer.md` (gitignored).
- Kilau masih memakai spinel `6626c0f05`.

**Pelajaran proses (juga di skill `spinel-notes`)**
- `git fetch` **tepat sebelum** membuat branch dari `origin/master`; cek ulang merge ke master terbaru sebelum PR.
- Setelah menukar source (`git show`, `stash`, `checkout`), hapus `.o` terkait sebelum `make`, lalu buktikan compiler mana yang aktif lewat tes (dua kali tertipu build yang tak rebuild).
- Setiap temuan CodeRabbit diverifikasi dulu terhadap kode: dari 8 temuan di PR kita, 4 valid, 4 tidak.

**Langkah berikutnya**
1. CI PR fork #4 hijau → minta izin → buka PR K-013 ke matz, tutup PR fork.
2. Pantau merge #6029 (K-004) dan PR K-013.
3. Setelah merge: naikkan compiler Kilau, jalankan ulang repro, cabut workaround (K-015 `Binds`, K-016 pola array, K-004 helper tes, K-013 nama `match_path` bisa kembali ke `match`).
4. Sisa: K-007 (diagnostik `unless yield`), K-014 (susun ulang bentuk lama dari riwayat git `migrator.rb`).

## 2026-09-30 ~03:20 WIB — Rencana 6 Fase 2: PR K-015, K-019, K-004 terbuka; alur CI di fork

**Status**
- Upstream sudah merge: #5789 (K-017), #5983 + #5997 (K-018), #6008 (K-016).
- PR terbuka ke matz: **#6027 (K-015)**, **#6028 (K-019)**, **#6029 (K-004)**. Ketiganya sudah hijau di CI fork sebelum dibuka.
- K-019 ternyata bukan soal alias: value object (struct) di ABI proc form dan di temp dispatch poly. Judul entri katalog sudah dikoreksi.
- Alur verifikasi baru: CI lewat PR di dalam fork (~12 mnt) menggantikan `make check` lokal (~55 mnt). Yang tetap lokal: uji merah, GC stress, perbandingan C benchmark (detail di skill `spinel-notes`, bagian Verification). Uji merah wajib memakai compiler yang terbukti dibangun ulang (pernah tertipu binary yang tidak di-rebuild).
- Kilau masih memakai spinel `6626c0f05`; belum berisi #6008 dan PR yang masih terbuka.

**Langkah berikutnya**
1. Pantau review #6027, #6028, #6029.
2. Setelah merge: naikkan compiler Kilau, jalankan ulang repro K-004/K-015/K-016/K-019, dan pertimbangkan mencabut workaround (K-015: `Kilau::DB::Binds`; K-016: pola array di `query_first`; K-004: helper tes berbasis method modul).
3. Sisa Fase 2: K-013, K-007, lalu K-014 (butuh bentuk kode lama; `kilau-old` sudah tidak ada).

## 2026-09-29 23:10 WIB — Compiler naik ke `6626c0f05`; K-017 terverifikasi; K-018 ditemukan

**Status**
- Kilau memakai spinel **`2026.09.12+2237 (6626c0f05)`** (`/usr/local`), yang berisi perbaikan K-017 (`dca09ca13`, matz/spinel#5789).
- Repro K-017 sekarang sama dengan CRuby (dengan `1ba12fb74` masih `nil given to int`).
- Suite dengan kompilasi segar: 14/14, 8/8, 4/4, CRuby 26/26.
- **K-018 (baru):** `spin test` yang dipanggil lewat PATH tidak melihat mtime compiler, sehingga setelah upgrade compiler semua tes tetap `(cached)` dan hasil hijaunya palsu. `Makefile` sekarang memakai `SPIN ?= $(shell command -v spin)`. Detail di `docs/CATALOG.md` K-018.

**Langkah berikutnya**
1. ~~Kembalikan `Model#save` ke bentuk `elsif`~~ selesai 2026-09-29 23:20 WIB; suite hijau.
2. K-018: PR https://github.com/matz/spinel/pull/5983 **di-merge** 2026-09-30 00:23 WIB. Tindak lanjut temuan CodeRabbit (komponen PATH kosong di `which`): PR https://github.com/matz/spinel/pull/5997 **di-merge** 2026-09-30 01:24 WIB. K-018 selesai. Commit upstream spinel sekarang memakai trailer `Co-Authored-By: Claude …` sesuai README spinel; PR #5789 sudah diberi komentar disclosure.
3. ~~Fase 2 K-016~~: PR https://github.com/matz/spinel/pull/6008 **di-merge** 2026-09-30 02:21 WIB. Fase 2 K-015: perbaikan di branch `k015-mixed-array-each` (commit `7afe7d02d`), diverifikasi lewat CI di PR fork https://github.com/yosefbennywidyo/spinel/pull/1 sebelum PR ke matz. Berikutnya: K-004/K-013/K-007 → K-019 (baru, alias) → K-014.

## 2026-09-29 17:44 WIB — Rencana 6: Fase 0 selesai, Fase 1 hampir, Fase 2 dimulai (PR K-017)

**Status**
- Kilau memakai spinel **`1ba12fb74`** (`/usr/local`). Suite 14/14, 8/8, 4/4, CRuby 26/26, e2e hijau. D-023: `gen routes` diadopsi.
- Rencana 6 **Fase 0** (uji ulang di spinel terbaru) selesai: K-010 dan K-011 diperbaiki upstream, sisanya masih ada. Tabel lengkap di `docs/CATALOG.md`.
- Rencana 6 **Fase 1** (repro minimal):

| K | Repro | Status |
|---|---|---|
| K-016 | `repro/k016_nested_block_assignment.rb` (37 baris) | ✅ minimal + 3 syarat terbukti |
| K-017 | `repro/k017_elsif_argument_evaluated_early.rb` | ✅ minimal + mekanisme (argumen `elsif` dievaluasi terlalu dini) |
| K-015 | `repro/k015_user_each_misreads_array_element.rb` | ✅ minimal + 3 syarat (`each` buatan pengguna yang `yield` membuat elemen Integer terbaca String) |
| K-014 | belum ada | 🟡 butuh rantai migrasi mati **dan** bagian program hidup (tes HTTP); reduksi dihentikan di sekitar 344 baris, tidak tersimpan |
| K-004, K-007, K-013 | repro minimal sudah ada sejak awal | — |

- Rencana 6 **Fase 2** (perbaikan di spinel):
  - **K-017 diperbaiki.** Di `emit_if` (`src/codegen_stmt.c`), prelude predikat `elsif` sekarang di-emit di dalam cabangnya. Tes `test/elsif_condition_args_wait_for_their_branch.rb`, `make check` hijau (4.597 pass).
  - Commit `05a5ebef6` di branch `elsif-condition-args-in-branch` (fork `yosefbennywidyo/spinel`).
  - **PR https://github.com/matz/spinel/pull/5789 di-merge oleh matz** (2026-09-29 17:49 WIB, merge commit `dca09ca13`). CI hijau.

**Lingkungan**
- Worktree spinel terbaru: `~/apps/me/gems/spinel-latest`, sedang di branch `elsif-condition-args-in-branch`. Remote `fork` = `git@github.com:yosefbennywidyo/spinel.git`. Untuk perbaikan berikutnya, buat branch baru dari `origin/master`.
- Setelah **setiap** `sudo make install` spinel, jalankan `sudo chmod a+r /usr/local/lib/spinel/packages/*/*.o` (K-009: sccache menulis mode 0640).
- Alat dan input reduksi Fase 1 disimpan di `~/apps/me/gems/kilau-private-20260929/phase1/` (di luar repo; `/tmp` sudah tidak bisa diandalkan). Isinya:
  - `repros.sh`, `old_shapes.sh`, `try.sh`,
  - `k014/` (input flatten + `oracle_run.sh`),
  - `k015/` (skrip greedy + tahapan),
  - `pr-k017.md` (deskripsi PR).
- Pelajaran reduksi sudah di skill `spinel-notes`:
  - `spinel-reduce` tidak punya checkpoint, dan file sementaranya bentrok kalau dua input bernama sama.
  - oracle harus mewajibkan program berjalan di CRuby.
  - bisection per file atau per method jauh lebih cepat daripada ddmin per baris.

**Langkah berikutnya (urutan disarankan)**
1. ~~Pantau PR #5789~~ di-merge 2026-09-29 17:49 WIB. Sisa: naikkan compiler Kilau ke spinel yang berisi `dca09ca13`, jalankan ulang `repro/k017_elsif_argument_evaluated_early.rb`, dan pertimbangkan kembali ke bentuk `elsif` di `Model#save`.
2. **Fase 2 K-016** (nilai salah diam-diam): mulai dari repro 37 baris. Ini bug inferensi/penangkapan variabel di blok bersarang yang diakses lewat proc tersimpan; periksa C yang di-emit untuk `found` (sel yang ditangkap).
3. **Fase 2 K-015** (segfault): mulai dari repro. Tebakan awal: dispatch poly `each` yang ikut mempertimbangkan `each` buatan pengguna salah membaca tag elemen. Periksa C untuk `binds.each` di `check_binds`.
4. **Fase 2 K-004 / K-013 / K-007**: repro minimalnya sudah ada.
5. **K-014**: lanjutkan reduksi dengan reducer rakus yang punya checkpoint (pola `greedy2.py`), memakai `k014/k014_run_flat.rb` + `oracle_run.sh`. Target: repro yang tetap berjalan di CRuby.
6. Setiap perbaikan: tes spinel + `make check` hijau → commit (email Gmail, tanpa atribusi Claude) → push ke `fork` → PR **hanya dengan izin pengguna per item**. Gaya PR: judul = subjek commit, body prosa + `Test: … (output taken from CRuby 4.0.6)`.
7. **Rencana 5** Fase A–C (daftar route, 405/HEAD, deteksi konflik), sekarang dengan `gen routes` sebagai jalur utama.
8. Minor yang ditunda: lihat entri 2026-09-29 12:xx di bawah.

## 2026-09-29 14:00 WIB — Spinel 1ba12fb74, K-009 dipahami, D-023: gen routes diadopsi

**Status repo**
- `main` dipublikasikan di https://github.com/yosefbennywidyo/kilau (MIT).
- Kilau memakai spinel **`2026.09.12+2124 (1ba12fb74)`**, terpasang di `/usr/local`. Suite 14/14, 8/8, 4/4, CRuby 26/26, e2e 11/11 × 2.

**Hasil Rencana 6 Fase 0** (tabel lengkap di `docs/CATALOG.md`)
- Diperbaiki upstream: K-010, K-011.
- Masih ada: K-004, K-007, K-013, K-014, K-015 (segfault), K-016 (nilai salah), K-017.
- K-012 tidak berubah (pelebaran 30 / 11).
- K-009 adalah masalah instalasi: sccache menulis `.o` dengan mode 0640, lalu `cp -r` saat install mempertahankannya. Setelah **setiap** `sudo make install` spinel, jalankan `sudo chmod a+r /usr/local/lib/spinel/packages/*/*.o`.

**D-023: `gen routes` diadopsi.** `blog_routes` adalah binary deploy dan benchmark utama. `blog` (route table) tetap sebagai mode dev/tes dan fallback. Dasarnya adalah S3 di dua compiler (+12–34% req/s, p99 c16 57 → 12–13 ms), sementara S1/S2/S4 setara.

**Langkah berikutnya**
1. Rencana 6 Fase 1: repro minimal K-016 → K-015 → K-017 → K-014, lalu Fase 2 perbaikan (K-004/K-007/K-013 sudah punya repro minimal). Batas waktu per bug belum diputuskan pengguna.
2. Rencana 5 Fase A–C (route listing, 405/HEAD, konflik), sekarang dengan `gen routes` sebagai jalur utama.
3. Kandidat upstream baru: installer spinel + sccache (K-009).

## 2026-09-29 12:39 WIB — Rencana 4 selesai: gen routes, benchmark vs Rails, FINDINGS

**Status repo**
- `main` = `f17d41f` (Rencana 3). Branch `plan-4-routes-bench` berisi Rencana 4 + dokumen Rencana 5/6, **belum di-merge**.
- Suite di ujung branch: `make test` framework 14/14, tool 8/8, blog 4/4. `make test-cruby` 26/26. `make e2e` 11/11 untuk `blog` dan `blog_routes`.
- Hasil: `bench/RESULTS.md` (sesi `bench/results/20260929-1108`) dan `docs/FINDINGS.md`. D-022 (`gen routes`) dan D-023 (adopsi ditunda) tercatat.

**Menjalankan**
```
make gen                               # templates + routes untuk blog (akar repo)
cd examples/blog && make               # build/bin/blog (route table) dan build/bin/blog_routes (gen routes)
bench/check_bodies.sh                  # gerbang: ketiga app menjawab identik
bench/run.sh                           # sesi penuh ~95 menit; QUICK=1 untuk smoke
ruby bench/summarize.rb bench/results/<stamp> > bench/RESULTS.md
```
Sebelum `bench/run.sh`: tutup app berat. Mesin tanpa kipas: urutan selang-seling dan jeda 20 dtk sudah bawaan.

**Hasil singkat (c64)**
- S1 `_ping`: kilau 17.128 / kilau-routes 17.156 / rails 9.122 req/s.
- S2: 16.339 / 16.389 / 5.815.
- S3 (100 baris): 2.530 / 3.304 / 3.256.
- S4 (POST): 8.815 / 8.818 / 2.990.
- Start 54 ms vs 1,4 dtk. RSS 33 MB vs 910 MB.

**Langkah berikutnya**
1. Pengguna memutuskan merge `plan-4-routes-bench`.
2. **Rencana 6 Fase 0** (dokumen rencana lokal, tidak dipublikasikan): build spinel `origin/master` (740 commit di depan) di worktree terpisah, uji ulang semua repro K dan suite. Lalu ukur ulang S3 untuk D-023.
3. **Rencana 5** Fase A–C .
4. Benchmark tahap berikutnya dengan k6, dari mesin terpisah (FINDINGS §8).
5. Minor yang ditunda:
   - dari Rencana 1–2: `Migrator#migrate` `.to_s`, cabang `Binds::NULL`, `ROLLBACK` yang menutupi error;
   - dari Rencana 3: CRLF di template, `{{ a | b }}` bitwise, `{{{ x }}}`.

**Pertanyaan riset: semua terjawab**

| ID | Status |
|---|---|
| R1 | tidak (K-012); eksperimen `gen routes`: 30 → 11 pelebaran, S3 +34% |
| R2 | sebagian |
| R3 | ya |
| R4 | ya (buffer); nilai boxed dari handler |
| R5 | ya |
| R6 | ya (0 `SQLITE_BUSY` di semua sel Kilau) |

**Kandidat upstream** (belum dilaporkan; cek dulu di spinel terbaru): K-004, K-007, K-010, K-011, K-013, K-015, K-016, K-017.

## 2026-09-29 09:33 WIB — Rencana 3 selesai: template ter-compile, R4 terjawab

**Status repo**
- `main` = `7314530` (Rencana 2 + dokumen Rencana 3).
- Branch `plan-3-templates`: commit Rencana 3 di atas `main`, **belum di-merge** (keputusan merge di pengguna).
- Semua hijau di ujung branch:
  - `make test` (spinel): framework 13/13, tool 6/6, blog 3/3
  - `make test-cruby`: 22/22 (sekarang dijalankan per direktori paket, seperti `spin test`)
  - `cd examples/blog && make e2e`: 11/11
- Keputusan baru: D-020 (subset sintaks), D-021 (lokasi hasil + golden yang dijalankan).

**Menjalankan blog**
```
cd examples/blog
make                        # kilau gen templates . lalu spin build blog
./build/bin/blog db migrate
./build/bin/blog start      # http://127.0.0.1:5150
```
Setelah mengubah `assets/views/**`, jalankan `make` lagi (atau `make templates`). `build/gen/templates.rb` tidak di-commit.
Kalau generator sengaja diubah, perbarui golden `tool/test/fixtures/templates.rb` (caranya ada di Rencana 3, Task 3).

**Langkah berikutnya**
1. Pengguna memutuskan merge `plan-3-templates` ke `main`, lalu hapus branch-nya.
2. **Rencana 4**: benchmark vs Rails 8 (spec §6.1–6.2, `oha`) dan `FINDINGS.md`, menjawab sisa **R6**. Keputusan `kilau gen routes` (dispatch tanpa proc) sekarang punya manfaat tambahan: parameter `Templates.posts_list/show/edit` ikut boxed karena K-012 (lihat R4), dan akan menyempit bersama handler.
3. Minor yang ditunda (tetap dari entri sebelumnya):
   - `Migrator#migrate` memakai `done.include?(migration.version)` tanpa `.to_s`.
   - `connection_cruby.rb` `values(binds)` tidak punya cabang `Binds::NULL` eksplisit.
   - Dari Rencana 1: `ROLLBACK` yang gagal menutupi error asli.

**Pertanyaan riset**

| ID | Status |
|---|---|
| R1 | tidak (K-012) |
| R2 | sebagian |
| R3 | ya |
| R4 | ya, buffernya; nilai ikut boxed dari handler (K-012) |
| R5 | ya |
| R6 | sebagian (Rencana 4) |

Kandidat laporan upstream dan bacaan wajib: sama seperti entri di bawah.

## 2026-09-28 17:12 WIB — akhir sesi: Rencana 2 selesai, menunggu keputusan merge

**Status repo**
- `main` = `d778e3c` (Rencana 1 + dokumen Rencana 2).
- Branch `plan-2-http-controller` = `1a71483`: 12 commit di atas `main`, **belum di-merge**. Keputusan merge ada di pengguna (opsi: merge lokal / PR / biarkan). Repo belum punya remote.
- Semua hijau di `1a71483`:
  - `make test` (spinel): framework 13/13, tool 2/2, blog 2/2
  - `make test-cruby`: 17/17
  - `cd examples/blog && make e2e`: 11/11 (termasuk 200 request dengan 32 koneksi paralel)
- Review akhir Rencana 2 selesai: 2 Important sudah diperbaiki (`1a71483`), 2 Minor ditunda (lihat bawah). Detailnya ada di catatan review lokal (tidak dipublikasikan).
- `.DS_Store` untracked. Abaikan saja, atau tambahkan ke `.gitignore`.

**Menjalankan blog**
```
cd examples/blog
make entities
./build/bin/blog db migrate
./build/bin/blog start      # http://127.0.0.1:5150
```
`make entities` hanya perlu dijalankan kalau migrasi berubah. Config ada di `config/<KILAU_ENV>.yaml`, dan setiap kunci bisa ditimpa dengan env `KILAU_*`.

**Langkah berikutnya**
1. Pengguna memutuskan cara merge `plan-2-http-controller` ke `main`, lalu hapus branch-nya.
2. Tulis **Rencana 3**: `kilau gen templates` (spec §4). Template gaya Tera di `assets/views/**` di-compile menjadi `build/gen/templates.rb`, lalu isi `examples/blog/src/views/posts.rb` diganti panggilan `Templates.*` dengan signature yang sama. Menjawab **R4**.
3. **Rencana 4**: benchmark vs Rails 8 (spec §6.1–6.2, alat `oha`) dan `FINDINGS.md`. Menjawab sisa **R6** (konkurensi 64). Di sini juga diputuskan apakah fallback dispatch hasil generate (`kilau gen routes`, tanpa proc) layak dibuat, karena **R1 = tidak** (K-012).
4. Minor yang ditunda:
   - `Migrator#migrate` memakai `done.include?(migration.version)` tanpa `.to_s`.
   - `connection_cruby.rb` `values(binds)` tidak punya cabang `Binds::NULL` eksplisit.
   - Dari Rencana 1: `ROLLBACK` yang gagal menutupi error asli.

**Wajib dibaca sebelum menulis kode**
- Skill global `spinel-notes`: gotcha Spinel dan teknik debug.
- `docs/CATALOG.md` K-001 s.d. K-017. Yang paling mahal adalah K-012 dan K-015 s.d. K-017: perilaku yang bergantung pada inferensi **seluruh program**. Menambah satu pemanggilan bertipe bisa menyembunyikan atau memunculkan bug. Reduksi selalu dilakukan dengan delta-debug pada program asli, karena repro mandiri biasanya tidak memicunya.
- `docs/DECISIONS.md` D-001 s.d. D-019. Penyimpangan penting dari spec:
  - D-004 → D-019: binds memakai builder bertipe `Kilau::DB::Binds`, bukan Array.
  - D-006: migrasi memakai DSL blok.
  - D-014: `request.request_method`.
  - D-015: tes request memakai `Testing::Client.new(hooks, app_context)`.
- Konvensi tes:
  - Mulai dengan `T = Kilau::Testing`, lalu `T.check(...)` (bukan `include`, lihat K-004).
  - Snapshot berisi stdout+stderr gabungan, dengan stderr muncul lebih dulu.
  - Tidak memakai StringIO (K-009).

**Pertanyaan riset**

| ID | Status |
|---|---|
| R1 | tidak (K-012) |
| R2 | sebagian |
| R3 | ya |
| R4 | belum (Rencana 3) |
| R5 | ya |
| R6 | sebagian (Rencana 4) |

**Kandidat laporan upstream ke spinel** (belum ada yang dilaporkan; perlu izin pengguna)

| ID | Masalah |
|---|---|
| K-004 | method yang menerima blok, lewat include di top level, tidak di-emit |
| K-010 | override method pada subclass exception gagal compile |
| K-011 | `%zz` didekode menjadi NUL |
| K-013 | method bernama bawaan pada receiver untyped |
| K-015 | crash pada array campuran (repro masih di atas app) |
| K-016 | penugasan dari blok bersarang hilang (repro masih di atas app) |
| K-017 | `elsif` + `raise` merusak cabang lain (repro masih di atas app) |
