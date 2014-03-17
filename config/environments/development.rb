ROCCIServer::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  # config.active_record.migration_error = :page_load

  # Set to :debug to see everything in the log.
  config.log_level = :debug

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # DM compatibility
  config.reload_classes_only_on_change = false

  # LogStasher
  # Enable the logstasher logs for the current environment
  config.logstasher.enabled = true

  # This line is optional if you do not want to suppress app logs in your <environment>.log
  config.logstasher.suppress_app_log = false

  # This line is optional, it allows you to set a custom value for the @source field of the log event
  config.logstasher.source = 'localhost'

  # Set path to configuration files
  config.rocci_server_etc_dir = Rails.root.join('etc')
end
