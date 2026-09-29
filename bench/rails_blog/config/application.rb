require_relative "boot"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

# The Rails side of the Kilau benchmark (spec §6.1): the same schema,
# routes and markup as examples/blog, in production mode.
module RailsBlog
  class Application < Rails::Application
    config.load_defaults 8.1
    config.eager_load = true
    config.enable_reloading = false
    config.consider_all_requests_local = false
    config.hosts.clear
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "kilau-bench-not-a-secret")
    config.action_controller.default_protect_from_forgery = false
    config.log_level = :warn
    config.logger = ActiveSupport::Logger.new(ENV.fetch("RAILS_LOG", "log/production.log"))
    config.active_record.dump_schema_after_migration = false
    config.public_file_server.enabled = false
  end
end
