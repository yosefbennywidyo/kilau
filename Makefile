# Kilau development tasks. `test` runs every package's snapshot tests
# through spin (Spinel); `test-cruby` runs the same files under CRuby and
# diffs them against the same .expected snapshots. Both streams are merged,
# as spin test merges them (spinel #3405), and each test runs from its
# package directory, as spin test runs it. Both first compile the blog's
# templates, which its views require (spec §4).
SPIN ?= spin
RUBY ?= ruby
PACKAGES ?= framework tool examples/blog
KILAU ?= tool/build/bin/kilau

.PHONY: test test-cruby tool templates

test:
	@for pkg in $(PACKAGES); do (cd $$pkg && $(SPIN) test) || exit 1; done

test-cruby:
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

templates: tool
	$(KILAU) gen templates examples/blog
