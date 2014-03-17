# Insert Warden::Manager as Rack::Middleware
Rails.configuration.middleware.insert_before Rack::Head, Warden::Manager do |manager|
  manager.default_strategies ROCCI_SERVER_CONFIG.common.authn_strategies.map { |strategy| strategy.to_sym }
  manager.failure_app = UnauthorizedController
  manager.scope_defaults :default, store: false
end

# Enable strategies selected in Rails.application.config.rocci_server_etc_dir/ENV.yml
ROCCI_SERVER_CONFIG.common.authn_strategies.each do |authn_strategy|
  authn_strategy_sym = authn_strategy.to_sym
  authn_strategy = "#{authn_strategy.camelize}Strategy"
  Rails.logger.info "[AuthN] Registering AuthenticationStrategies::#{authn_strategy}"

  strategy_config = ROCCI_SERVER_CONFIG.authn_strategies[authn_strategy_sym]
  Rails.logger.debug "[AuthN] with options: #{strategy_config.inspect}"
  begin
    Warden::Strategies.add(
      authn_strategy_sym,
      AuthenticationStrategies.const_get("#{authn_strategy}")
    ) { const_set(:OPTIONS, strategy_config) }
  rescue NameError => err
    message = "There is no such authentication strategy available! [AuthenticationStrategies::#{authn_strategy}]"
    Rails.logger.error "[AuthN] #{message}"
    raise ArgumentError, message
  end
end
