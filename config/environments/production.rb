ROCCIServer::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_files = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # Set log dir.
  rocci_logging_path = ENV['ROCCI_SERVER_LOG_DIR'].blank? ? Rails.root.join('log') : ENV['ROCCI_SERVER_LOG_DIR']
  raise Errors::ConfigurationError, "Logging directory #{rocci_logging_path.inspect} is not writable!" unless File.writable?(rocci_logging_path)

  config.log_tags = [:uuid]
  config.log_level = :info
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(File.join(rocci_logging_path, "#{Rails.env}.log"), 'daily'))

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :dalli_store, { namespace: 'ROCCIServer.cache', expires_in: 1.day, compress: true }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # LogStasher
  # Enable the logstasher logs for the current environment
  config.logstasher.enabled = true

  # Respect ENV['ROCCI_SERVER_LOG_DIR'] if applicable
  unless ENV['ROCCI_SERVER_LOG_DIR'].blank?
    path = File.join(ENV['ROCCI_SERVER_LOG_DIR'], "logstash_#{Rails.env}.log")
    FileUtils.touch path # prevent autocreate messages in log
    config.logstasher.logger = Logger.new(path, 'daily')
  end

  # This line is optional if you do not want to suppress app logs in your <environment>.log
  config.logstasher.suppress_app_log = false

  # This line is optional, it allows you to set a custom value for the @source field of the log event
  config.logstasher.source = if ENV['ROCCI_SERVER_HOSTNAME'].blank? || ENV['ROCCI_SERVER_PORT'].blank?
    (`hostname -f` || 'unknown').chomp
  else
    "#{ENV['ROCCI_SERVER_HOSTNAME']}_#{ENV['ROCCI_SERVER_PORT']}"
  end

  # Set path to configuration files
  config.rocci_server_etc_dir = if ENV['ROCCI_SERVER_ETC_DIR'].blank?
    Rails.root.join('etc')
  else
    Pathname.new(ENV['ROCCI_SERVER_ETC_DIR'])
  end
end
