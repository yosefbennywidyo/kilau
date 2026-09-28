# Kilau development tasks. `test` runs every package's snapshot tests
# through spin (Spinel); `test-cruby` runs the same files under CRuby and
# diffs their stdout against the same .expected snapshots (stderr is kept
# apart, as spin test does).
SPIN ?= spin
RUBY ?= ruby
PACKAGES ?= framework

.PHONY: test test-cruby

test:
	@for pkg in $(PACKAGES); do (cd $$pkg && $(SPIN) test) || exit 1; done

test-cruby:
	@mkdir -p build; fail=0; \
	for t in $(foreach p,$(PACKAGES),$(wildcard $(p)/test/*_test.rb)); do \
	  if $(RUBY) -I framework $$t > build/cruby.out 2> build/cruby.err && diff -u $$t.expected build/cruby.out > build/cruby.diff; then \
	    echo "ok   $$t"; \
	  else \
	    echo "FAIL $$t"; head -40 build/cruby.diff; tail -5 build/cruby.err; fail=1; \
	  fi; \
	done; exit $$fail
