# K-040: scale-test for the colliding constants (spinel `Makefile` target `scale-test`)

Patches against matz/spinel `master` (verified on `cfc17dbe2`, 2026-11-10). See `docs/CATALOG.md` K-040/K-041.

- `01_scale_test_per_pass.patch` -- the replacement test: two work counters (`spinel-work-qvc`, `spinel-work-eck`)
  and the `scale-test` check on the colliding program alone. Verified on a clean tree: spinel-work builds and
  the whole `make scale-test` passes (rc 0; 2.00x and 2.00x).
- `02_work_by_pass.patch` -- `SPINEL_WORK_PASSES=1 build/spinel-work -c x.rb` prints the work per analysis
  pass (`spinel-work-pass: <units> <pass>`); the units sum to the `spinel-work` total.
- `03_mutation_harness.patch` -- test-only, generated ON TOP OF 01 (their contexts overlap, so apply 01 first):
  `K040_MUT=1|2|3` puts back the two halves of the code that `3f28a42c5` replaced (reads walk, pair loop), to
  prove a scale test goes red. Verified on the clean tree with 01+03: qc_value_collisions work at 2x the classes
  is 2.00x with `K040_MUT=0` and 3.65x with `K040_MUT=3` (limit 2.20, so the new check fails). Never for upstream.

Apply: `git apply 01_...`, then optionally `02_...` (independent) and `03_...` (needs 01), in a spinel checkout, `make -j2 build/spinel-work`, `make scale-test`.
