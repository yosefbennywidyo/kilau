# The blog served by the dispatcher `kilau gen routes` writes (spec §2.2
# fallback): the same app, but every handler is called directly instead
# of through a stored proc (docs/CATALOG.md K-012).
require "kilau"
require_relative "../migration/migrator"
require_relative "../src/app"
require_relative "../build/gen/routes"

exit Kilau::CLI.run(RoutedApp.new, MIGRATIONS, ARGV)
