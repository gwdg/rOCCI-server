require File.expand_path('../boot', __FILE__)

# require 'rails/all'

# require "active_record/railtie"
require 'action_controller/railtie'
# require 'action_mailer/railtie'
require 'rails/test_unit/railtie'
# require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

# Extend Object with #deep_freeze
require 'ice_nine/core_ext/object'

# Added stuff
require 'timeout'
require 'ipaddr'

module ROCCIServer
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Autoload stuff from lib/
    config.autoload_paths << Rails.root.join('lib')

    config.assets.enabled = false

    config.generators do |generate|
      generate.helper false
      generate.assets false
      generate.view_specs false
      generate.resource_route false
      generate.orm false
      generate.test_framework :rspec
    end

    require File.expand_path('../version', __FILE__)
  end
end
