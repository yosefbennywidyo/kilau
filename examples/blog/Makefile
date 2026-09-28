# The blog's build steps. `entities` regenerates src/models/_entities from
# the migrations: migrate the development database with blog_schema, then
# read it back with the kilau tool (spec §5.3).
SPIN ?= spin
KILAU ?= ../../tool/build/bin/kilau
DB ?= db/development.sqlite3

.PHONY: entities

entities:
	$(MAKE) -C ../.. tool
	$(SPIN) build blog_schema
	./build/bin/blog_schema migrate --db $(DB)
	mkdir -p src/models/_entities
	$(KILAU) gen entities $(DB) src/models/_entities
