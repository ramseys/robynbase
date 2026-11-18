require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Robyn2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Overrides of the 5.1 defaults, carried over from the old
    # new_framework_defaults*.rb initializers. Revisit these when load_defaults is
    # raised (see docs/plans/rails-8-upgrade.md, "Decision: load_defaults").
    config.action_controller.per_form_csrf_tokens = false
    config.action_controller.forgery_protection_origin_check = false
    config.action_view.form_with_generates_remote_forms = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
