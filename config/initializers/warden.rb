Rails.configuration.middleware.insert_before Rack::Head, Warden::Manager do |manager|
  manager.default_strategies :dummy
  manager.failure_app = UnauthorizedController
  manager.scope_defaults :default, :store => false
end

# TODO: implement autoload from /app/strategies
ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/lib"
Warden::Strategies.add(:dummy, AuthenticationStrategies::DummyStrategy)