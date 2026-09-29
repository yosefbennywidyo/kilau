# The blog's build steps. `make` generates the templates and routes, then
# builds both binaries (spec §1, build flow): blog dispatches through the
# route table, blog_routes through the dispatcher `kilau gen routes`
# writes (spec §2.2 fallback). Their answers are identical; the benchmark
# compares their speed. `entities` regenerates src/models/_entities from
# the migrations: migrate the development database with blog_schema, then
# read it back with the kilau tool (spec §5.3).
SPIN ?= spin
KILAU ?= ../../tool/build/bin/kilau
DB ?= db/development.sqlite3

.PHONY: all gen entities e2e

all: gen
	$(SPIN) build blog
	$(SPIN) build blog_routes

gen:
	$(MAKE) -C ../.. tool
	$(KILAU) gen templates .
	$(KILAU) gen routes .

entities:
	$(MAKE) -C ../.. tool
	$(SPIN) build blog_schema
	./build/bin/blog_schema migrate --db $(DB)
	mkdir -p src/models/_entities
	$(KILAU) gen entities $(DB) src/models/_entities

# End-to-end: build the blog, migrate a scratch database, start the
# server on a free port, drive it with curl, stop it. Logs in /tmp.
E2E_DB ?= /tmp/kilau-e2e.sqlite3

e2e: all
	for bin in blog blog_routes; do \
	  rm -f $(E2E_DB) $(E2E_DB)-wal $(E2E_DB)-shm; \
	  KILAU_DATABASE_PATH=$(E2E_DB) ./build/bin/$$bin db migrate || exit 1; \
	  echo "== $$bin"; BIN=$$bin ./e2e.sh $(E2E_DB) || exit 1; \
	done
