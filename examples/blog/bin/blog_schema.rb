# The blog's schema binary: framework + migration/ only, so it builds
# before src/models/_entities exists (spec §5.3).
require "kilau"
require_relative "../migration/migrator"

exit Kilau::SchemaCLI.run(MIGRATIONS, ARGV)
