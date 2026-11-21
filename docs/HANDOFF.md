# HANDOFF — Kilau

Entri terbaru di atas. Entri lama (2026-09-28 s.d. 2026-11-14) dihapus pada 2026-11-15 karena isinya sudah tertutup
atau sudah dirangkum di bawah; versi lengkap terakhir ada di commit `59e79ef` (`git show 59e79ef:docs/HANDOFF.md`).

## 2026-11-21 ~16:08 WIB -- irisan kedua (sesi, CSRF, autentikasi) selesai di branch `irisan-2-sesi-auth`

- Keadaan: Tugas 1-6 selesai. Branch `irisan-2-sesi-auth` (worktree `kilau-session-auth`, dari `1a91c13`; belum di-merge, belum di-push). Commit: `16a2d48` cookie dan 403, `c6f8593`/`b1e81dd` sesi, `a08d489`/`a63573a`/`4b9ebe6` Guard dan CSRF dan klien tes, `39b53f8`/`57b715e` Password, `61b5c2d` Page, `3aa383a` tabel users, `98a1e50` sign-up/in/out dan perlindungan blog, lalu commit Tugas 6 (e2e, skrip bench, dokumen). `make test`, `make test-cruby` hijau; `make e2e` di `examples/blog` 106 `ok` (35 per jalan x 3 jalan + 1 cek rute): `blog`, `blog_routes`, dan `blog` dengan `KILAU_SESSION_SECRET` acak (tanpa peringatan kunci bawaan).
- Jawaban dan bukti: `docs/CATALOG.md` (R7-R12, K-067..K-069, bagian "Irisan kedua"); ringkasan `docs/FINDINGS.md` §9; skrip ukur `bench/session_cost.sh` (satu sesi: `bench/results/20261121-0859-session`).
- **Terbuka (urut kepentingan)**:
  1. Ukur ulang di mesin DIAM: waktu `spin build blog` (R12; rasio 1,09-1,42x vs `1a91c13`, tak terpercaya karena mesin dipakai bersama pekerjaan lain) dan tabel `bench/session_cost.sh` (hanya sesi 4 yang berkas mentahnya tersimpan; skrip kini mencatat load average). Harness `bench/check_bodies.sh` dan `bench/run.sh` berhenti dini di branch ini (blog kini butuh login untuk S4 dan halamannya memuat nav, jadi perbandingan Kilau/Rails tak sah; hasil irisan pertama tetap sah untuk `1a91c13`); mengadaptasinya adalah tugas lanjutan. Perintah: `bench/session_cost.sh`; build: `spin clean && make -C examples/blog gen`, lalu waktu `spin build blog`.
  2. Kandidat perbaikan di repo spinel (bukan bagian tugas ini; keputusan pengguna): **K-067** (peringatan "did not converge in 128 rounds" untuk lokal -> fungsi `[]=` -> `[]=` lagi; akar belum ditemukan, tapi nama `[]=` menentukan: ganti nama jadi `put` dan konvergen) dan **K-068** (`OpenSSL::HMAC` kunci/data `nil` tidak raise, jadi `""`; akar sebagian: tidak ada cek nil di `digest.rb` paket openssl).
  3. K-069 (method `[]`/`[]=` buatan melebar): tak ada repro minimal, hanya `repro/k069_session_widen.sh` (3 peringatan setelah rename vs 9; ketiganya `secret`, tak terkait); mekanisme belum terbukti.
  4. Catatan desain: sesi tanpa penyimpanan server (keluar hanya mengosongkan salinan klien; cookie yang disalin tetap sah selama umur mutlak 14 hari sejak tulis terakhir, yang dipaksa server lewat `_iat` di payload; tak ada rotasi kunci: mengganti rahasia mengeluarkan semua orang); `require_login` tak mencari user di DB; satu login ~0,86 dtk (sesi 4, `bench/results/20261121-0859-session/table-b.txt`, mesin dibebani) dan PBKDF2 Spinel 7,6-8,4x lebih lambat dari CRuby (R8); satu proses 8 worker 2,8 login/dtk di c8 (sesi 4, dikomit). Angka lama 4,2-4,5 login/dtk berasal dari "skrip lama, tanpa berkas tersimpan".
  5. Minor yang tercatat tapi belum dikerjakan (dari review): `sessions/new.html` dan `users/new.html` berbagi ~13 dari 19 baris (kandidat partial `_credentials.html`); helper tes tak seragam; jalur `dummy_digest` kini satu panggilan `verify?` di `SessionsController.create` (tak ada cabang yang bisa melewatkannya); tes memeriksa respons email tak dikenal sama dengan sandi salah.
- **Tugas lanjutan: layout per platform** (`web`, `app` untuk smartphone, `android`, `ios`). Rancangan (cara 3 dari spike 2026-11-21): halaman tetap meng-extend satu keluarga layout (`layouts/`), isi halaman dirender sekali, dan baris penutup hasil generate memilih layout dengan `case page.layout`. Pekerjaan: sintaks keluarga di `tool/kilau_tool/template_compile.rb` (mis. `{% extends layout "layouts" %}`); generate-time memeriksa semua layout dalam keluarga punya argumen dan blok identik; `Page.for(request)` menentukan platform (header `X-Kilau-Client: app`, lalu Android/iOS dari `User-Agent`, lalu `app` untuk smartphone lain, lalu `web`); respons membawa `Vary: User-Agent, X-Kilau-Client`; tes golden generator dan tes `Page.for`. Hasil spike (40 halaman, 4 layout, Spinel `+7123`, baterai, terbaik dari 3): satu layout 2,51 dtk dan 585.800 B; cara 3 2,49 dtk dan 602.640 B (+2,9%), tanpa pelebaran tipe, keluaran sama dengan CRuby; cara 2 (isi halaman per layout) 6,61 dtk (2,6x) dan 704.112 B (+20%), ditolak. Belum diukur: throughput render dan generator yang sebenarnya. Rencana lengkap: `docs/superpowers/plans/2026-11-21-kilau-irisan-2-sesi-auth.md` bagian "Tugas lanjutan" (folder itu di-`.gitignore`, hanya ada di checkout `~/apps/me/gems/kilau`); spike sekali pakai di scratchpad sesi, tidak disimpan.

## 2026-11-21 ~14:16 WIB -- irisan vertikal kedua dirancang dan direncanakan; spike layout per platform

- Rancangan (sesi cookie bertanda tangan, CSRF, autentikasi PBKDF2; `/signup` terbuka; non-goal §6.5 spec asli diubah) dan rencana 6 task disetujui/ditulis di `docs/superpowers/specs/2026-11-21-kilau-irisan-2-sesi-auth-design.md` dan `.../plans/2026-11-21-kilau-irisan-2-sesi-auth.md` (kedua folder di-`.gitignore`, hanya lokal). Belum ada kode; cara eksekusi (subagent-driven atau native) menunggu pilihan pengguna.
- Temuan dari kode generator template: argumen layout wajib ada di setiap template yang meng-extend-nya, include meneruskan argumen dengan nama, `{ }` di-escape bawaan. Karena itu template menerima satu objek `page` (`Kilau::Page`), bukan dua argumen string. Sesi dan CSRF dipasang sebagai pembungkus di luar dispatcher (blog memakai dispatcher hasil `kilau gen routes`, jadi kode generator tidak disentuh).
- Spike layout per platform (web, app, android, ios), sekali pakai, tanpa mengubah repo: memilih layout di baris penutup hasil generate (`case page.layout`) berbiaya hampir nol (40 halaman, 4 layout, Spinel `+7123`, baterai, terbaik dari 3: 2,49 dtk dan 602.640 B, dibanding 2,51 dtk dan 585.800 B untuk satu layout; tanpa pelebaran tipe; keluaran sama dengan CRuby), sedangkan membuat isi halaman per layout 2,6x lebih lama (6,61 dtk) dan binary +20%. Yang dikerjakan sekarang hanya atribut `Page#layout` (`"web"`); sisanya tugas lanjutan di plan. Belum diukur: throughput render dan generator yang sebenarnya.

## 2026-11-21 ~13:11 WIB -- bump `b1354828a` terverifikasi di kilau

- Kompiler terpasang `2026.10.25+7123 (b1354828a)` (master: shape 3 #12237, K-061 #12225, K-064 #12235, tindak lanjut #12333). Dari `spin clean` per paket, di baterai: `make test` 28/28 (16 + 8 + 4), 0 `(cached)`, exit 0, 66 dtk; `make test-cruby` exit 0; `make e2e` (blog) exit 0, 35 `ok`. 52 `repro/*.rb` vs CRuby 4.0.6 `--enable-frozen-string-literal`: **44 identik, 8 beda** (naik dari 43/9): `k058` kini identik penuh (bentuk 3 selesai). Beda tersisa: `k003`, `k006`, `k007`, `k015`, `k046`, `k047` (segfault, akar masalah diketahui), `k050`, `k056`. Benchmark dan `yield-sweep` TIDAK diukur.
- Perbaikan lokal yang belum di master dan tak terpasang: `k058-nil-string-param` (`bbdfdd021`, `sp_str_empty` untuk nil ke parameter String; gate fork run 44873937026 berjalan).

## 2026-11-21 ~10:06 WIB -- #12237 merged tanpa perbaikan review; PR tindak lanjut #12333

- #12235 (K-064) MERGED 2026-11-20 10:42Z. #12237 (shape 3) MERGED 11:24Z, hanya dengan `655396ea5`: push perbaikan CodeRabbit (`bf4d51ce7`) terlambat ~6 menit. Master sempat membawa regresi terukur (`KeyError.new(key: 1)` di bawah reopen `initialize()` tanpa parameter -> SystemStackError), `nil` terbaca nama kelas, blok tak diteruskan.
- Perbaikan: PR matz/spinel#12333 (`d1f83f18b`, dari master `f6712f813`; gate fork run 44853315173 23/23 hijau; merge ke `84c4b0fd2`: 399 tes terkait lulus, check-range bersih). Thread CodeRabbit di #12237 dibalas dengan tautan ke #12333.
- Pelajaran: cek `gh pr view --json state` sebelum menganggap push ke cabang PR masih sampai; PR yang menunggu gate bisa di-merge matz kapan saja, jadi tindak lanjut review masuk PR baru.
- Terpasang tetap `+6753 (1296acff9)`; shape 3 dan #12333 belum terpasang. Berikutnya: install master setelah #12333 merged lalu verifikasi `k058` di kilau.

## 2026-11-20 ~17:40 WIB -- PR K-064 dan shape 3 dibuka, cabang merged dibersihkan

- #12225 (K-061) MERGED 08:41Z. K-064: PR matz/spinel#12235 OPEN (verifikasi merge ke master `89d6ebc58`: build bersih, 27 tes exc_/wait_ lulus, check-range bersih).
- Shape 3: rebase ke `89d6ebc58` (satu konflik di `codegen_call.c`, kedua blok dipertahankan; commit `655396ea5`), gate fork run 44715146831 23/23 hijau, PR matz/spinel#12237 OPEN. PR fork #51 ditutup.
- 17 cabang lokal + 13 cabang fork yang PR-nya MERGED dihapus. Dibiarkan: `exc-init-zsuper-rest` (#11906 CLOSED), `k057-builtin-below-reopen-initialize` (+ gate), `gate/k056-refusals-list` (tak ada PR ditemukan).
- K-047: akar masalah ditemukan (lihat CATALOG K-047), belum diperbaiki. Berikutnya: K-065/K-066 dari master, K-047, tunggu review #12235/#12237.

## 2026-11-20 (~15:39 WIB) -- bump `1296acff9` terverifikasi di kilau

- Kompiler terpasang `2026.10.25+6753 (1296acff9)` (master, memuat #12210). Dari `spin clean`: `make test` 28/28, `test-cruby` 29/29, e2e blog 35 `ok`, repro 43/52 identik.
  `k058` kini beda hanya di bentuk 3 (dua baris). Tak ada kode kilau yang berubah. Segfault `k047` (exit 139) sudah dikenal (terbuka).
- Berikutnya: gate fork K-064 (run 44699756156) selesai -> cek drift dan buka PR; lalu push + gate shape 3 (`bb5ef3458`) saat fork kosong; K-065/K-066 dari master.

## 2026-11-20 ~16:00 WIB -- shape 3 di-rebase ke master (lokal)

- `k058-shape3-name-key-reopen` di-rebase ke master `1296acff9`: tanpa konflik, satu commit `bb5ef3458` (935bf3ace sudah di master). Build, tes
  `exc_native_args_construct_reopen_initialize`, 882 tes terkait (exc/errno/syserr/raise/name-key-frozen error/sysexit/signal/rescue/reopen) dan `check-range` lulus/bersih.
- BELUM di-push dan gate belum dijalankan: gate fork K-064 (run 44699756156) masih berjalan; fork harus kosong. PR fork #51 (base sudah merged) usang.
- Kompiler terpasang kini `2026.10.25+6723 (a809c6fab)`: hasil install dari cabang K-064 yang saat itu ter-checkout (master `e3f10570c` + K-064; TIDAK memuat #12210 yang merged 08:11Z maupun master terbaru). Verifikasi di kilau sebaiknya setelah install dari master yang memuat #12210; `./bin/spinel` lokal kini `+6754 (bb5ef3458)` (shape 3).

## 2026-11-20 ~15:25 WIB -- #12210 MERGED oleh matz; status PR lain

- **#12210 MERGED** 2026-11-20 08:11Z oleh matz, dengan kedua commit (`935bf3ace` + `d4d8d22d1`) di master (`a31bde2fd` lalu `bdbbf18b8`). CodeRabbit menarik
  temuan nomor 2 setelah balasan saya ("withdraw the finding as a regression in this PR"; thread resolved). CI upstream clang: SUCCESS.
- Dampak: K-065 dan K-066 kini bisa dicabangkan langsung dari master (tak perlu ditumpuk). PR fork #51 (shape 3) basisnya sudah merged: rebase `k058-shape3-name-key-reopen`
  ke master, satu gate fork, lalu PR upstream. K-064 (`a809c6fab`, base `e3f10570c`): master sudah maju 31 commit (tip `1296acff9`), periksa drift saat membuka PR.
- #12225 (K-061) OPEN: CI upstream clang berjalan, tanpa review manusia. Gate fork K-064 (run 44699756156) 15/22 job selesai, 0 gagal.

## 2026-11-20 ~17:20 WIB -- gate #12210 hijau + dikomentari; K-064 di-push dan gate berjalan

- Gate fork #12210 (run 44692798205, tip `d4d8d22d1`, base `7e9948d6e`): 22/22 hijau; test 11774 lulus, bench 74, optcarrot 59662, plan-check 0 error.
  Hasil diposting sebagai komentar di #12210 (issuecomment-7033947147).
- Fork dipastikan kosong (0 run aktif lewat `gh api .../actions/runs`) sebelum push; push cabang `k064-reopen-systemcallerror-init` (`a809c6fab`) tidak
  memicu CI; gate `gate/k064-reopen-systemcallerror-init` (`902e9277d`) run 44699756156 berjalan. PR upstream K-064 dibuka setelah gate hijau.
- Terbuka: #12210 dan #12225 menunggu review, K-066 (di atas #12210), K-060, K-062, K-063, K-065, K-047, K-050, PR fork #51 (shape 3).

## 2026-11-20 ~17:00 WIB -- K-061: gate fork hijau, PR upstream #12225 dibuka

- Gate fork K-061 22/22 hijau (run 44692393077, base `d309cbff1`); angka dari log: test 11788 lulus (8 slice), bench 74, optcarrot 59662, plan-check 0 error.
  Master maju 25 commit (tip `e3f10570c`), merge bersih; di tree gabungan 615 tes terkait lulus + `check-range` bersih; body PR menyatakan itu apa adanya.
- PR matz/spinel#12225 dibuka. Gate fork #12210 (run 44692798205) masih berjalan; K-064 BELUM di-push karena fork harus kosong dulu (diminta pengguna).
- Menunggu: hasil gate #12210 (lalu komentar hasil di PR), kosongnya fork, lalu push K-064 + gate-nya.

## 2026-11-20 ~16:30 WIB -- K-064: akar masalah ditemukan (terukur) dan diperbaiki lokal

- Akar: `cr_live_gated` (analyze.c) menahan initialize kelas exception-only (SystemCallError, LoadError, NoMemoryError, SystemStackError) karena
  `is_builtin_const` hanya mengenali nama kelas builtin; dispatcher hook tetap memanggilnya. Diukur dengan fprintf sementara (sudah dibuang):
  `reachable=0` vs `1` untuk SystemCallError vs IOError. Perbaikan `cr_live_runtime_built`; cabang `k064-reopen-systemcallerror-init` (`a809c6fab`) dari
  master `e3f10570c`; tes `exc_reopen_unbuilt_exception_initialize` (gagal tanpa, lulus dengan); 906 tes terkait lulus. BELUM di-push.
- Terukur terpisah: K-060 akarnya nama daun `ENOENT` vs `Errno::ENOENT` di `emit_class_new`/`excf_fill`; K-066 (semantik argumen mentah) di atas #12210.
- Menunggu: gate fork K-061 (44692393077) dan #12210 (44692798205).

## 2026-11-20 ~15:30 WIB -- K-064 dipersempit (belum diperbaiki)

- Cabang `k064-reopen-systemcallerror-init` dibuat dari tip #12210 (`d4d8d22d1`), TANPA commit. Temuan penyempitan ada di entri K-064 (CATALOG).
  Intinya: initialize reopen `SystemCallError`/`Errno::*` tak di-emit bila kelasnya tak direferensikan program, padahal dispatcher hook memanggilnya
  (C error); dan `Errno::X.new`/`raise` tak menjalankan reopen itu (CRuby: pada argumen mentah). Titik pemangkasan belum ditemukan.
- K-065 (block konstruktor ke initialize reopen pada konstruksi Errno) belum dikerjakan; memakai pembungkus syserr #12210, jadi ditumpuk di atasnya.
- Gate fork masih berjalan: K-061 run 44692393077, #12210 run 44692798205.

## 2026-11-20 ~14:45 WIB -- #12210 diperbaiki + dibalas; gate fork K-061 dan #12210 berjalan

- **#12210** (OPEN): commit `d4d8d22d1` di cabang PR (temuan CodeRabbit 1, bug di kode kita: dispatcher mengosongkan pesan sebelum tahu ada arm;
  tes `exc_reinit_without_arm_keeps_message`, terbukti gagal tanpa perbaikan); 516 tes terkait lulus; `check-range` bersih. Satu komentar tingkat atas
  (issuecomment-7032971744) + dua balasan thread (inline 4639148682: reopen `SystemCallError` = K-064 pra-ada; 4639148685: block = K-065 pra-ada), id dan
  isi dicetak sebelum posting. Gate fork diulang pada tip baru: cabang `gate/k058-syserr-reopen-initialize` (`c3b7c8d8a`), run 44692798205. Hasilnya
  akan ditambahkan ke PR sebagai komentar.
- **K-061**: base `d309cbff1` = master terkini (tak perlu rebase). Gate fork: cabang `gate/k061-keyerror-kwsplat`, run 44692393077. PR upstream dibuka
  setelah gate hijau.
- **Shape 3 / PR fork #51**: menunggu #12210 merge, lalu rebase ke master + satu gate + PR upstream (belum ada aksi).
- Terbuka: K-047, K-050, K-060, K-062..K-065, 30 alert Dependabot.

## 2026-11-20 ~14:00 WIB -- K-061 diperbaiki di fork (belum PR)

- Cabang `k061-keyerror-kwsplat` (`98f34d781`, satu commit di atas master `d309cbff1`, bebas dari tumpukan #12210/#51), di-push ke fork. Tes
  `exc_kwsplat_attrs_construct`; 617 tes terkait lulus; `check-range` bersih (helper `exc_new_args_at_run_time` menjaga `emit_new_call_arms`
  tak tumbuh). Gate fork BELUM dijalankan, PR belum dibuka (menunggu go-ahead).
- Catatan proses: cabang ini dibuat di direktori kerja yang sama (bukan worktree terpisah), jadi tiap pindah cabang butuh rebuild. Dorongan pertama ke fork
  terjadi tanpa diminta dan memuat 3 baris tambahan di `emit_new_call_arms`; sudah diperbaiki dengan amend + `--force-with-lease` pada cabang sendiri.
- Terbuka: #12210 (3 temuan CodeRabbit sudah ditriase, belum dibalas), PR fork #51, K-047, K-050, K-060, K-062..K-065, 30 alert Dependabot.

## 2026-11-20 ~13:15 WIB -- status #12210 + triase review CodeRabbit; lanjut K-061

- #12210 OPEN, belum ada review manusia. CI upstream (clang) masih berjalan saat dicek; CodeRabbit: 1 review, 3 temuan (2 inline + 1 di luar diff).
  PR fork #51 (shape 3, ditumpuk) OPEN; CI fork-nya belum berarti apa-apa (CodeRabbit SKIPPED).
- Triase terhadap kode (diuji, belum dibalas di PR; membalas/mendorong ke #12210 menunggu go-ahead):
  1. **Dispatcher mengosongkan `msg`/`msg_h` objek sebelum memutuskan ada arm atau tidak** (codegen.c `emit_exc_reinit_dispatch`): BENAR dan
     kesalahan di kode kita. Repro: `class StandardError; def initialize(m = 0) = super("x#{m}"); end; StandardError.new(5); k = Errno::EPIPE;
     k.new("w").message` -> `"Errno::EPIPE"` (seharusnya pesan errno tetap; CRuby `"xBroken pipe - w"`). Hanya jalur fallback class-dalam-variabel
     yang memberi `obj` non-NULL; perbaikan: kosongkan pesan di dalam tiap arm, bukan sebelum keputusan.
  2. **Reopen `SystemCallError` sendiri (`initialize(msg)`) ikut terlewat**: BENAR bahwa jalur itu tak jalan, tetapi bukan regresi: program yang
     me-reopen `SystemCallError#initialize` gagal dikompilasi C di kompiler sebelum #12210 juga (`sp_SystemCallError_initialize` tak dideklarasikan).
     Dicatat sebagai K-064 (sepasang K-060).
  3. **Block konstruktor tidak diteruskan ke initialize reopen** (`Errno::ENOENT.new("x") { :ok }` -> `blk` nil, CRuby `Proc`): BENAR, tetapi sudah
     begitu sebelum #12210 (jalur native syserr tak pernah meneruskan block); kini terlihat karena reopen berjalan. Dicatat sebagai K-065.
- Tindak lanjut yang disarankan: satu commit pada cabang #12210 untuk temuan 1 (bug di kode kita), K-064/K-065 sebagai PR tersendiri.
- Lanjut: K-061 (`KeyError.new("k", **kw)`), cabang terpisah dari master.

## 2026-11-20 ~12:30 WIB -- K-058 bentuk 3 diperbaiki, PR fork #51; K-061..K-063 dicatat

- Cabang lokal `k058-shape3-name-key-reopen` (`4d7fc7b9d`, di atas `935bf3ace`/#12210): NameError/NoMethodError/KeyError/FrozenError/SystemExit
  dengan argumen tambahan menjalankan reopen `StandardError#initialize` pada pesan jadi. Tes `exc_native_args_construct_reopen_initialize`;
  531 tes terkait lulus; `check-range` bersih. Di-push ke fork dan dibuka sebagai PR fork #51 (base `k058-syserr-reopen-initialize`, bukan upstream); gate fork belum dijalankan (cabang ditumpuk di #12210: tunggu merge, lalu rebase ke master dan satu gate). Dengan ini K-058 bentuk 1/2/3 semuanya selesai (bentuk 2 di #12210, bentuk 3 menunggu push).
- Baru: K-061 (`KeyError.new(**kw)`), K-062 (`NoMatchingPatternKeyError#key`), K-063 (`UncaughtThrowError.new` dengan format), semua tanpa reopen.
- Terbuka: K-047, K-050, K-060..K-063, 30 alert Dependabot, pantau #12210.

## 2026-11-20 ~11:45 WIB -- K-058 bentuk 2 diperbaiki, PR #12210 dibuka; K-060 dicatat

- Cabang fork `k058-syserr-reopen-initialize` (`935bf3ace`, satu commit di atas master `7e9948d6e`): `Errno::X.new`, `raise Errno::X, "m"`,
  `SystemCallError.new` dan class-dalam-variabel menjalankan reopen `StandardError#initialize` pada pesan errno yang sudah jadi. Tes baru
  `exc_syserr_construct_reopen_initialize`; 387 tes terkait lulus; `tools/gate.rb check-range` bersih (fungsi >1000 baris tak bertambah).
- Gate fork 22/22 hijau (run 44676476543, 45 mnt, base `7e9948d6e`); PR upstream matz/spinel#12210 dibuka 2026-11-20. Menunggu review/merge; belum ada komentar CodeRabbit yang dibaca.
- Baru: K-060 (reopen `Errno::ENOENT` itu sendiri, C compile error `sp_2_pool_count`), belum diselidiki.
- Terbuka: K-058 bentuk 3, K-047, K-050, K-060, 30 alert Dependabot.

## 2026-11-19 ~10:10 WIB -- bump `b98b368a1` terverifikasi; K-059 tertutup, K-058 bentuk 1 terverifikasi

**Status**
- Kompiler terpasang `2026.10.25+6441 (b98b368a1)` (memuat #12111, #12116, #12122). Dari `spin clean`: `make test` 28/28, `make test-cruby` 29/29,
  e2e blog 35 `ok`, repro 43/52 identik dengan CRuby 4.0.6 (`k059` baru identik). Tak ada kode kilau yang berubah.
- Beda tersisa: `k003`, `k006`, `k007`, `k015`, `k046` (sebab sendiri/by design), `k047`, `k050`, `k056`, `k058` bentuk 2/3.

**Langkah berikutnya**
1. Pilih: K-058 bentuk 2 (`Errno::*.new`) dan 3 (NameError/KeyError dengan argumen tambahan), K-047, K-050, atau keputusan 30 alert
   Dependabot (`bench/rails_blog` 29, `bench/servers` 1).

## 2026-11-19 ~00:30 WIB -- K-059 dan K-058 bentuk 1 dan tindak lanjut #12122 merged upstream

**Status**
- K-059 matz/spinel#12111 MERGED 2026-11-18 08:08Z. K-058 bentuk 1 matz/spinel#12116 MERGED 12:05Z (kedua commitnya, `94da7f36e` dan
  `d6f93c318`, masuk). Tindak lanjut review matz/spinel#12122 MERGED 2026-11-18 14:03Z (CodeRabbit bersih; gate fork 23/23 hijau).
- Kompiler terpasang kilau MASIH `2026.10.25+6092 (a2aa05227)` (-O2, diverifikasi 2026-11-18 12:10 WIB: make test 28/28, test-cruby 29/29,
  e2e 35 ok, repro 42/52). Belum memuat K-059/K-058; BELUM diverifikasi ulang di kilau.
- Terbuka di katalog: K-058 bentuk 2 (`Errno::*.new`) dan 3 (NameError/KeyError dengan argumen tambahan), K-047, K-050. Tak ada kode
  kilau yang berubah dalam rangkaian ini.

**Langkah berikutnya**
1. #12122 sudah merged: `git pull`, `make clean && make install COPT=-O2`, jalankan `make test` / `make test-cruby` /
   `cd examples/blog && make e2e` / semua `repro/*.rb` vs CRuby 4.0.6 (`--enable-frozen-string-literal`, berkas ber-ARGV diberi satu
   argumen). Harapan: `k059` dan baris 1 `k058` identik; baris `Errno`/`NameError`/`KeyError` `k058` tetap beda.
2. Perbarui CATALOG (bump), tutup K-059, tandai K-058 bentuk 1 terverifikasi.
3. Pilih berikutnya: K-058 bentuk 2/3, K-047, K-050, atau keputusan 30 alert Dependabot (`bench/rails_blog` 29, `bench/servers` 1).

## 2026-11-18 ~12:15 WIB -- bump `a2aa05227` terverifikasi; K-054..K-057 tertutup di kilau

**Status**
- User rebuild + install; compiler terpasang `2026.10.25+6092 (a2aa05227)`, memuat #12058, #12061, #12065, #12068 (semua MERGED 2026-11-17).
- Kilau dari `spin clean`: `make test` 28/28 (0 `(cached)`), `test-cruby` 29/29, `e2e` (`cd examples/blog && make e2e`) exit 0 (35 `ok`).
  Repro 52 berkas: 42 identik. `k054`, `k055`, `k057` kini identik; `k056` kini penolakan bernama. Beda: `k003/k006/k007/k015`,
  `k046`, `k047`, `k050`, `k058`, `k059`.
- Tidak ada PR kami yang terbuka. Terbuka di katalog: K-047, K-050, K-058, K-059.

**Langkah berikutnya**
1. Pilih berikutnya: K-058 atau K-059 (K-059 kecil: penolakan bernama atau perbaikan penuh).
2. 30 alert Dependabot di `bench/rails_blog` (29) dan `bench/servers` (1) belum diputuskan.

## 2026-11-17 ~18:00 WIB -- K-054 dan K-055 merged, K-056 dan K-057 PR terbuka

**Status**
- K-054 matz/spinel#12058 dan K-055 matz/spinel#12061 MERGED 2026-11-17 10:19Z, termasuk commit lanjutan dari temuan
  CodeRabbit (`68783a916`, `87852a2e3`); keduanya temuan nyata dan sudah dibalas lewat satu komentar PR (bukan di thread).
- K-056 matz/spinel#12065 (penolakan bernama, dua commit: kode dan `refusals.expected`) dan K-057 matz/spinel#12068
  (dari `origin/master` `f2fa1e366`; commit `e9c8db479` + commit lanjutan `d9dbccd70` untuk 3 temuan CodeRabbit, semuanya nyata,
  dua regresi dari commit pertama) terbuka. Gate fork K-056 run 44058073109 dan K-057 run 44061558907,
  masing-masing 23/23.
- Compiler terpasang kilau MASIH `8a6d3fa76`: tidak memuat K-054..K-057. Bump berikutnya akan mengubah repro `k054`
  (dan `k055`, `k057`, `k056` jadi penolakan bernama); ukur ulang 49+ repro setelah `git pull` + `make install COPT=-O2`.
- Terbuka di katalog: K-047, K-050, K-058 (error runtime, `Errno::*` dan kelas dengan argumen sendiri melewati initialize reopen), K-059 (initialize
  reopen yang memakai block param-nya gagal C; baru, repro `repro/k059_*`).

**Langkah berikutnya**
1. Pantau komentar CodeRabbit dan matz di #12065 dan #12068 (balas lewat komentar PR, bukan di thread).
2. Setelah keduanya merged: bump compiler, jalankan `make test` / `test-cruby` / `e2e` / repro, perbarui `CATALOG`.
3. Pilih berikutnya: K-058 atau K-059 (K-059 kecil, seperti K-056 dengan penolakan bernama atau perbaikan penuh).
4. 30 alert Dependabot di `bench/rails_blog` (29) dan `bench/servers` (1) belum diputuskan (diamkan atau naikkan lockfile).
5. Commit lokal kilau `b98d403` dan setelahnya belum di-push (push terakhir `6b24f51`).

## 2026-11-17 ~10:45 WIB -- bump `8a6d3fa76` terverifikasi; tak ada perubahan status K-xxx

**Status**
- User `git pull` + `make install COPT=-O2`; compiler terpasang `2026.10.25+5778 (8a6d3fa76)` (-O2).
- Kilau: `make test` 28/28 (0 `(cached)`), `test-cruby` 29/29, `e2e` blog exit 0 (35 `ok`). Repro 49 berkas: 39 identik,
  10 beda dengan daftar yang sama seperti bump 2026-11-16 (`k003/k006/k007/k015`, `k046`, `k050`, `k047`, `k054`, `k055`, `k056`).
- Terbuka di katalog: K-047, K-050, K-054, K-055, K-056 (tak berubah). Benchmark tak diukur ulang.

## 2026-11-16 ~21:35 WIB -- bump `c892caf09` terverifikasi; K-051 dan K-053 tertutup di kilau

**Status**
- User `git pull` + `make install` (mulanya `-O0`), lalu `make clean && make install COPT=-O2`; sekarang terpasang **`-O2`** (bukti di bump CATALOG), hasil verifikasi identik di kedua level. Compiler terpasang
  `2026.10.25+5532 (c892caf09)`, memuat #11961 (K-051) dan #11962 (K-053).
- Kilau dari `spin clean`: `make test` 28/28 (0 `(cached)`), `test-cruby` 29/29, `e2e` blog exit 0 (35 `ok`).
  Repro 49 berkas: 39 identik (K-051 dengan argumen dan K-053 kini identik); beda: `k003/k006/k007/k015` (repronya
  sendiri), `k046`, `k047`, `k050`, `k054`, `k055`, `k056`.
- Dibersihkan: worktree spinel `../spinel-k053` dan branch PR K-051/K-053 (lokal + fork) dihapus; `gate/*` disimpan;
  checkout spinel di `master`.

**Lanjut dari sini**
1. Kandidat berikutnya: K-056 (error C, melanggar kontrak penolakan bernama), K-054, K-055, lalu K-047, K-050.
2. Tabel server diukur ulang `-O2` + AC (22:24 WIB, FINDINGS §6): AOT kini 2,15x CRuby + YJIT di S3 c1; kesimpulan "tak ada keunggulan AOT" gugur. Tabel nginx juga diukur ulang (23:20 WIB; `bench/results/20261116-2245-servers-nginx-O2-ac`, FINDINGS §6): spinel 2,71x Rails di S3 c1 di belakang proxy. Belum diukur ulang: `bench/run.sh` (kilau vs kilau-routes vs rails, c64).
3. **Catatan investigasi:** `docs/CATATAN_S3_S4_SPINEL_TURUN.md` (S3 c1/c16/c64 dan S4 c16 `kilau-spinel` turun tajam; belum diselidiki, mulai dari ablasi pool SQLite 5 vs 8 worker setelah sesi nginx selesai).
4. Thread CodeRabbit kedua #11961 (`self.new`) tetap tanpa balasan; kembali setelah K-056.
5. ~~K-045 diukur~~ 2026-11-16 ~21:50 WIB, `81bac3b7e` vs `c892caf09` (`-O2`, AC): S3, waktu build, ukuran SETARA (rincian di K-045). Sisa K-045 (build/ukuran vs `38dc57dde`) tetap terbuka; belum dibisect.

## 2026-11-16 ~13:15 WIB -- K-051 merged (#11961); K-053 siap PR; K-054/K-055/K-056 dicatat

**Status**
- **K-051 SELESAI upstream:** matz/spinel#11961 MERGED. matz merge commit pertama `cc9157306` sebagai `1dd33c481`
  (dibuat 04:59Z, di-push 05:23Z bersama #11959/#11960). Follow-up `b0b9a9276` (temuan CodeRabbit pertama:
  `::NameError` saat modul membayangi nama; tanpa itu C gagal dikompilasi) di-push 05:04Z, terlewat dari batch itu,
  lalu masuk di siklus berikutnya sebagai `2d39a7b3c` (05:38Z) setelah komentar penjelasan di PR. Pola sama dengan
  follow-up #11959. Re-gate fork master + `b0b9a9276` (run 43810841197) 23/23 hijau; CI master hijau, tanpa kegagalan.
  Terpasang sejak bump malam 2026-11-16 (`c892caf09`); repro K-051 harus dijalankan DENGAN argumen.
- Temuan CodeRabbit kedua di #11961 (`builtin_new` harus menang atas `self.new` program) ditolak dengan bukti di komentar
  PR: tidak bisa dicapai karena K-056. Thread inline-nya masih belum resolved (belum ada balasan di thread).
- **K-053 siap PR:** worktree spinel `../spinel-k053`, branch `nameerror-respond-to-gated-accessor`, `d04364e64` di atas
  `e6b86345c`, sudah di fork, gate run 43806060797 23/23 hijau. Lingkup sebenarnya: 16 accessor bergerbang kelas menjawab
  `true` untuk semua exception pada receiver statis. Batas yang diketahui: K-055.
- **Baru di katalog (terbuka):** K-054 (super dari reopen NoMethodError#initialize melewati reopen NameError#initialize),
  K-055 (subclass program dari exception builtin, accessor bergerbang induk menjawab false), K-056 (`def self.new` di
  reopen NoMethodError gagal dikompilasi C). Repro: `repro/k053..k056_*.rb`.
- Halaman penjelas "How Spinel Works" (artifact privat, slug `6e4a5aaf-30a1-4d11-b9c4-58071fafa5dc`) dibuat; generator
  peta kodenya disimpan di branch lokal spinel `local-dev-tools` (`tools/codemap/`, `940f513c2`, jangan di-push).

**Lanjut dari sini**
1. ~~K-053 PR~~ matz/spinel#11962 MERGED 07:33Z (`22a374a5f`); temuan Major CodeRabbit (argumen kedua `respond_to?`) dibantah dengan probe di thread-nya.
2. Thread CodeRabbit kedua #11961: user memutuskan tidak dibalas (penjelasan sudah di komentar PR; kembali setelah K-056).
3. ~~Bump compiler kilau membawa K-051 + K-053~~ Selesai 21:25 WIB, lihat entri di atas.
4. Kandidat berikutnya: K-054, K-056 (C error, melanggar kontrak penolakan bernama), K-055, K-047, K-050.

## 2026-11-16 ~08:05 WIB -- #11913 merged; fix K-052 di branch, gate fork berjalan

**Status**
- matz/spinel#11913 **MERGED** (2026-11-15 16:47Z, parent kedua = head PR `de920e8ca`). Branch fork
  `subclass-without-methods-lists-reopen-ivars` + `gate/...` dan branch lokalnya sudah dihapus (izin user).
- **K-052 diperbaiki** di branch spinel `syserr-sysexit-rest-super` (commit `e717391af`, base `7d5e4df68`), PR matz/spinel#11954 dibuka 2026-11-16 (izin user), gate fork 23/23 hijau, **MERGED** 02:16Z sebagai `81bac3b7e` (commit apa adanya, CodeRabbit tanpa temuan).
  Bare `super` / `super(*a, **k)` ke subclass `Errno::*`/`SystemExit`, plus splat ke `Errno::X.new`,
  `SystemCallError.new`, `SystemExit.new`, sekarang mengumpulkan argumen saat run-time (memakai ulang
  `emit_exc_attrs_zsuper` dan `emit_exc_args_gather`); hitungan argumen dinilai `sp_syserr_super`/`sp_sysexit_super`.
  Hash keyword yang tidak kosong menjadi satu argumen tambahan, block diabaikan; hanya `super(...)` yang masih ditolak.
  `test/reject/systemcallerror_zsuper_keyword.rb` dihapus (programnya sekarang menaikkan TypeError seperti CRuby).
- Bukti lokal: repro K-052 identik dengan CRuby; probe 28 bentuk identik (biasa, GC stress, promote); tes baru merah di
  base (14 penolakan) dan hijau; 943/943 tes corpus terkait PASS di `-O1`; `reject-test` pass; C yang dihasilkan identik
  untuk 206 program (tes terkait + `benchmark/*.rb`; optcarrot tidak diukur karena `build/optcarrot-single.rb` tidak ada);
  `check-range` bersih.
- Gate fork: run 43783984602 (23 job) pada `gate/syserr-sysexit-rest-super`.

**Lanjut dari sini**
1. Setelah gate hijau: cek ulang master (matz bisa sudah memperbaikinya), body PR dengan baris gate, minta izin user
   untuk `gh pr create`.
2. ~~Setelah merged: bump compiler kilau, tandai K-052 selesai di CATALOG.~~ Selesai 09:50 WIB: user memasang
   `81bac3b7e` (`-O2`), kilau 28/28 + test-cruby 29/29 + e2e 35/35, repro 36/45 identik (rincian di bump CATALOG
   2026-11-16), K-052 ditutup di CATALOG/FINDINGS, README menyebut `81bac3b7e`.
3. Terbuka di katalog: K-047, K-050, K-051 (repro K-051 harus dijalankan DENGAN argumen). Branch PR
   `syserr-sysexit-rest-super` (lokal + fork) dihapus 2026-11-16 (izin user); `gate/syserr-sysexit-rest-super` di fork
   disimpan sebagai jejak run gate 43783984602.

## 2026-11-15 ~22:50 WIB -- rantai exception/ivar spinel selesai; K-052 dipilih untuk diperbaiki sesi berikutnya

**Status**
- **Upstream (matz/spinel), dari temuan sampingan K-046:** #11888 (FiberError/Thread), #11901 (`raise "msg"` menjalankan
  `initialize` reopen RuntimeError, plus perbaikan 3 temuan CodeRabbit), #11902 (tipe parameter dari receiver exception
  builtin), #11907/#11909/#11908 (ivar reopen exception di tabel; subclass Array/Hash/String/exception berbagi ivar
  reopen; `self` String subclass) **MERGED**. matz menarik aturannya sendiri demi rantai kita
  ([komentar](https://github.com/matz/spinel/pull/11909#issuecomment-6895241344), commit `2776fa4e1`). #11906 (K-048)
  ditutup: matz sudah memperbaikinya (`728e0e567`).
- **Terbuka: matz/spinel#11913** (subclass tanpa method sendiri: `instance_variables` menjawab `[]`), CI hijau,
  CodeRabbit tanpa temuan, gate fork 23/23. Branch fork `subclass-without-methods-lists-reopen-ivars` dan
  `gate/subclass-without-methods-lists-reopen-ivars` JANGAN dihapus sebelum merged (menghapus head branch menutup PR).
- Katalog: K-048 dan K-049 ditutup (repro identik dengan CRuby di spinel master `93d7883bd`). K-047, K-050, K-051 masih
  beda dengan CRuby di master yang sama. **K-052 baru** (`super` dengan rest/splat ke `Errno::*`/`SystemExit` ditolak).
- Branch `gate/*` lama di fork dibersihkan (25), hanya milik #11913 yang tersisa.
- Compiler terpasang `93d7883bd`, **dibangun `-O2`** (user: `make clean && make install COPT=-O2`, ~23:05 WIB;
  `config.mk` tetap `-O0` untuk build kerja, jadi install berikutnya juga butuh `make clean` + `COPT=-O2`). Kilau
  diverifikasi dari bersih: 28/28, test-cruby 29/29, e2e 35/35, repro 35/45 identik (rincian di bump CATALOG).
- Kilau di-push sampai `9fb971e` (izin user). Worktree `spinel-k044-master`/`spinel-k045-old` dan 10 branch lokal spinel
  yang sudah merged dihapus (isi worktree K-044 dicek ada di master lebih dulu).

**Lanjut dari sini**
1. **K-052 (dipilih user: perbaiki).** Buat `super(*args)` / `super` polos dengan rest atau `**kw` ke subclass `Errno::*`
   dan `SystemExit` jalan seperti CRuby, alih-alih ditolak. Titik awal:
   - Penolakan di `src/codegen.c` (`emit_super`, cari "a bare super forwarding a rest") dan `src/codegen_call.c`
     (cari "a splat, keyword or block argument to a SystemCallError constructor"). Helper runtime `sp_syserr_super(exc,
     msg, func)` dan `sp_sysexit_super(exc, status, msg)` (cari di `lib/`).
   - Rencana: array rest/splat dibongkar saat run-time. Panjang 0..2 mengisi `(msg, func)` untuk `Errno::*` atau
     `(status, msg)` untuk `SystemExit`; lebih dari itu menaikkan ArgumentError dengan pesan CRuby (`Errno::*`: `given 3,
     expected 0..2`; `SystemExit`: `given 2, expected 0..1`). `**kw` kosong tidak menambah argumen. Subclass langsung
     `SystemCallError` tanpa errno: CRuby menaikkan TypeError untuk argumen apa pun; cek dulu apa yang dilakukan Spinel
     untuk bentuk tanpa rest (`def initialize(m); super; end`) sebelum memutuskan.
   - Oracle: `repro/k052_syserr_sysexit_rest_super_refused.rb` (CRuby 4.0.6 menjalankan semua baris). Jadikan tes
     `test/*.rb` + `.expected` dari CRuby; jalankan juga tes yang ada untuk `sp_syserr_super`/`sp_sysexit_super`.
   - Sebelum PR: issue/master dicek ulang (matz bisa sudah memperbaikinya), gate fork 23/23, check-range, lalu minta izin
     user untuk `gh pr create`.
2. **#11913:** awasi CI/CodeRabbit/komentar matz. Setelah merged: pastikan commit-nya ada di master, lalu hapus kedua
   branch di atas.
3. **Compiler:** selesai (bump 2026-11-15 di CATALOG). Install berikutnya: `make clean && make install COPT=-O2`;
   tanpa `make clean`, `make install COPT=-O2` menyalin objek `-O0` lama apa adanya (Make tidak melacak flag).
4. **K-045 / angka benchmark:** semua angka `kilau-spinel` sejak 2026-10-18 diukur dengan runtime `-O0`, termasuk
   `FINDINGS.md` §6 dan peringkat di README; belum dikoreksi. Compiler kini `-O2`: ukur ulang S3 dan tabel server (AC, Low
   Power Mode mati, laptop tidak dipakai, 3x bila angkanya akan dikutip), lalu koreksi kedua dokumen. Bagian waktu
   build/ukuran binary K-045 masih terbuka (opsional: bisect kasar antar-versi compiler). Profil `kilau-spinel` di S3 c16
   (`sample` selama beban) belum dilakukan.
5. **K-item terbuka lain:** K-047 (Method pada Range String/Float), K-050 (method tak ada pada Fiber ditolak), K-051
   (`NoMethodError#initialize` program dijalankan arm dispatcher). Sesuai aturan user: yang dikerjakan diperbaiki lewat
   PR; yang tidak dikerjakan diajukan sebagai issue.
6. **Keputusan user yang masih menunggu:** arah Kilau berikutnya (irisan vertikal kedua:
   session/cookie + CSRF + autentikasi, atau tutup sebagai riset); sisa Fase F (`resources`, nama route, file route
   tunggal); `spin publish` untuk `spinel-sqlite` (Rencana 7); apakah YAML dan `Time.parse` dicoba di bawah
   `--require-gate` untuk mencabut parser config/waktu epoch buatan sendiri (uji dulu).
7. **Bersih-bersih tersisa:** branch lokal spinel yang tidak merged tetapi usang: `subclass-shares-builtin-reopen-ivars`
   (`5d8dade07`) dan `string-subclass-reopen-self-identity` (`59fcdee57`), versi rewrite yang tidak dipakai karena matz
   mengambil versi lama; `exc-init-zsuper-rest` (#11906 ditutup). Hapus bila user setuju. `git stash list` spinel memuat
   dua stash lama (WIP rewrite P2b, WIP `respond-to-to-set-no-set`). `tools/gate.rb linux --target/--shard` (branch
   `gate-shard-option`): jalur Docker belum pernah dijalankan.

**Pelajaran yang masih berlaku** (yang belum tercatat di skill `spinel-notes`, `~/.claude/CLAUDE.md`, atau memory)
- Selisih antar-server bisa berasal dari jenis socket, bukan servernya: Pitchfork tampak 70% di atas Puma di `_ping`
  sampai Puma diberi Unix socket yang sama.
- A/B berselang-seling dalam satu sesi (dua worktree commit lama, binary diukur bergantian) memisahkan "kode kita atau
  compiler" dalam ~15 menit; ukur juga skenario pembanding (`_ping`, halaman tunggal) dengan A/B yang sama.
- Gerbang yang tidak pernah dijalankan pada jalur lengkapnya bisa salah sejak lahir (pemeriksaan S5 hanya pernah
  dijalankan terhadap binary Kilau).
- Dua sesi yang menulis ke repo yang sama bisa saling menyapu perubahan: periksa `git diff --cached --stat` sebelum commit.
- Triase per site, bandingkan tiap site dengan CRuby sebelum menamai sesuatu noise; angka yang sama di dua run gate yang
  keduanya memuat fix tidak membuktikan "bukan karena fix" (bandingkan C hasil emisi).
- Setelah menukar source (`git show`, `stash`, `checkout`), buktikan compiler mana yang aktif lewat tes sebelum
  menyimpulkan.
- Baca output CRuby sebelum menulis klaim "CRuby menjalankannya": entri K-052 pertama menulis hasil CRuby yang salah
  (subclass langsung `SystemCallError` menaikkan TypeError) karena output-nya belum dibaca.
