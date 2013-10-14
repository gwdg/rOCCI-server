# Insert Warden::Manager as Rack::Middleware
Rails.configuration.middleware.insert_before Rack::Head, Warden::Manager do |manager|
  manager.default_strategies :dummy
  manager.failure_app = UnauthorizedController
  manager.scope_defaults :default, :store => false
end

# Autoload strategies from Rails.root/lib/authentication_strategies
ActiveSupport::Dependencies.autoload_paths << Rails.root.join('lib')

# Enable strategies selected in Rails.root/config/config.yml
ROCCI_SERVER_CONFIG['authn'].each do |authn_strategy|
  authn_strategy = "#{authn_strategy.classify}Strategy"
  Rails.logger.info "AuthN subsystem: Enabling #{authn_strategy}"

  begin
    Warden::Strategies.add(:dummy, AuthenticationStrategies.const_get("#{authn_strategy}"))
  rescue NameError => err
    message = "There is no such authentication strategy available! [AuthenticationStrategies::#{authn_strategy}]"
    Rails.logger.error message
    raise ArgumentError, message
  end
end