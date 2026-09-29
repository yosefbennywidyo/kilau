# The blog's build steps. `make` compiles the templates, then the binary
# (spec §1, build flow). `entities` regenerates src/models/_entities from
# the migrations: migrate the development database with blog_schema, then
# read it back with the kilau tool (spec §5.3).
SPIN ?= spin
KILAU ?= ../../tool/build/bin/kilau
DB ?= db/development.sqlite3

.PHONY: all templates entities e2e

all: templates
	$(SPIN) build blog

templates:
	$(MAKE) -C ../.. tool
	$(KILAU) gen templates .

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
	rm -f $(E2E_DB) $(E2E_DB)-wal $(E2E_DB)-shm
	KILAU_DATABASE_PATH=$(E2E_DB) ./build/bin/blog db migrate
	./e2e.sh $(E2E_DB)
