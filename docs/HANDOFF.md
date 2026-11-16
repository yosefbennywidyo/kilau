# HANDOFF — Kilau

Entri terbaru di atas. Entri lama (2026-09-28 s.d. 2026-11-14) dihapus pada 2026-11-15 karena isinya sudah tertutup
atau sudah dirangkum di bawah; versi lengkap terakhir ada di commit `59e79ef` (`git show 59e79ef:docs/HANDOFF.md`).

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
