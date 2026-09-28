# The blog: `blog start` serves it, `blog db migrate|rollback|status`
# manages its schema (spec §5.2).
require "kilau"
require_relative "../migration/migrator"
require_relative "../src/app"

exit Kilau::CLI.run(App.new, MIGRATIONS, ARGV)
