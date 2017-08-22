require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
# require "active_model/railtie"
require 'active_job/railtie'
# require "active_record/railtie"
require 'action_controller/railtie'
# require "action_mailer/railtie"
# require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ROCCIServer
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Read app-specific configuration
    config.rocci_server = config_for(:rocci_server)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    #
    config.active_job.queue_name_prefix = "rOCCI-server.#{Rails.env}"
    config.active_job.queue_name_delimiter = '.'

    # Pull version information
    require File.expand_path('../version', __FILE__)
  end
end
