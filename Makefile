# Kilau development tasks. `test` runs every package's snapshot tests
# through spin (Spinel); `test-cruby` runs the same files under CRuby and
# diffs them against the same .expected snapshots. Both streams are merged,
# as spin test merges them (spinel #3405), and each test runs from its
# package directory, as spin test runs it. Both first generate the blog's
# templates and routes, which its views and blog_routes require (spec §4,
# §2.2).
# spin resolves its compiler as <dir of $0>/spinel. Invoked by bare name
# through PATH, $0 carries no directory, so spin falls back to the name
# "spinel", finds no such file to stat, and never counts the compiler's mtime:
# after a compiler upgrade every test binary is reused as "(cached)". An
# absolute path keeps the upgrade visible (K-018).
SPIN ?= $(shell command -v spin)
RUBY ?= ruby
PACKAGES ?= framework tool examples/blog
KILAU ?= tool/build/bin/kilau

.PHONY: test test-cruby tool gen

test: gen
	@for pkg in $(PACKAGES); do (cd $$pkg && $(SPIN) test) || exit 1; done

test-cruby: gen
	@mkdir -p build; fail=0; \
	for pkg in $(PACKAGES); do \
	  for t in $$(cd $$pkg && ls test/*_test.rb); do \
	    if (cd $$pkg && $(RUBY) -I $(CURDIR)/framework $$t) > build/cruby.out 2>&1 && diff -u $$pkg/$$t.expected build/cruby.out > build/cruby.diff; then \
	      echo "ok   $$pkg/$$t"; \
	    else \
	      echo "FAIL $$pkg/$$t"; head -40 build/cruby.diff; fail=1; \
	    fi; \
	  done; \
	done; exit $$fail

tool:
	cd tool && $(SPIN) build

gen: tool
	$(KILAU) gen templates examples/blog
	$(KILAU) gen routes examples/blog
