# The blog under CRuby behind a Rack server (README, "Running under a Rack
# server"). Run from this directory after `make gen`, with the framework
# and the sqlite package on the load path:
#
#   bundle exec puma -w 8 -t 5:5 -e production config.ru
#
# The Spinel binaries (build/bin/blog, blog_routes) serve themselves and do
# not use this file.
require "kilau/rack_app"
require_relative "src/app"
require_relative "build/gen/routes"

run Kilau::RackApp.new(RoutedApp.new)
