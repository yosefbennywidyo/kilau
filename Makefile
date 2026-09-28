# Kilau development tasks. `test` runs every package's snapshot tests
# through spin (Spinel); `test-cruby` runs the same files under CRuby and
# diffs them against the same .expected snapshots. Both streams are merged,
# as spin test merges them (spinel #3405).
SPIN ?= spin
RUBY ?= ruby
PACKAGES ?= framework tool

.PHONY: test test-cruby tool

test:
	@for pkg in $(PACKAGES); do (cd $$pkg && $(SPIN) test) || exit 1; done

test-cruby:
	@mkdir -p build; fail=0; \
	for t in $(foreach p,$(PACKAGES),$(wildcard $(p)/test/*_test.rb)); do \
	  if $(RUBY) -I framework $$t > build/cruby.out 2>&1 && diff -u $$t.expected build/cruby.out > build/cruby.diff; then \
	    echo "ok   $$t"; \
	  else \
	    echo "FAIL $$t"; head -40 build/cruby.diff; fail=1; \
	  fi; \
	done; exit $$fail

tool:
	cd tool && $(SPIN) build
